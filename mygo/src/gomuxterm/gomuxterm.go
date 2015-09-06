package main
// This package provides as raw serial io as possible.
// There are
//
//
//

import (
	"errors"
	"fmt"
	"os"
	"net"
	"runtime"
	"muxserial"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type TCPChannels struct {
	to chan byte
	from chan byte
	quit chan bool
	closeTCP chan bool

	conn *net.TCPConn

	fromMux chan byte
	toMux chan byte

	disconMux chan bool

	mx *muxserial.MuxSerialStruct
}

var debug bool = false

func main() {
	var errb  error
	var intargs [5]int
	runtime.GOMAXPROCS(runtime.NumCPU())

	fmt.Printf( "Using %d CPUs\n", runtime.GOMAXPROCS(-1))

	if len(os.Args) != 7 {
		errb = errors.New("Incorrect number of arguments")
	}
	for i := 0; errb == nil && i < 5; i++ {
		n, e := strconv.ParseInt( os.Args[i+2], 10, 32)
		intargs[i] = int(n)
		errb = e
	}
	if errb != nil {
		fmt.Printf( "usage: %s comPort baud numChannels rawPort telnetPort debug[0|1]\n", os.Args[0])
		return
	}
	debug = intargs[4] != 0

	chanFromStdin := make( chan byte)
	go func() {
		data := make( []byte, 1)
		for {
			count, _ := os.Stdin.Read( data)
			if count > 0 && data[ 0] != 10 {
				chanFromStdin <- data[0]
			}
		}
	}()
	mx, err := muxserial.MuxSerialChannels( os.Args[1], intargs[0], intargs[1], debug)
	if err != nil {
		fmt.Printf( "ERROR: %s\nusage: %s comPort baud numChannels rawPort telnetPort\n", err, os.Args[0])
		return
	}

	go func(){
		rawChannel := ListenTCPall( intargs[2])
		telnetChannel := ListenTCPall( intargs[3])
		for{
			select {
			case rch := <- rawChannel:
				rch.mx = mx
				go RawServer( rch)

			case tch := <- telnetChannel:
				tch.mx = mx
				go TelnetServer( tch)
			}
		}
	}()


	for q := false; q == false; {
		inchar := <- chanFromStdin
		if inchar == 'q' {
			q = true
		}
	}
	mx.Close()
}
var controlServerHelp string = `

CONTROL PANEL
h       - prints help
?       - print status
q       - disconnect

nn c    - connects to channel nn as a telnet connection (CTL-c will invoke CONTROL PANEL)

n1 n2 s - run a loopback speed test on channel n1 for n2 bytes -- 4 <= n1 <= %d, 100 <= n2 <= 10000

n1 n2 t - run a send speed test on channel n1 for n2 bytes (data from prop) --  0 <= n1 <= 3, 100 <= n2 <= 10000

n1 n2 u - run a receive speed test on channel n1 for n2 bytes (data to prop) --  0 <= n1 <= 3, 100 <= n2 <= 10000

`

var srForthTest string = `

[ifndef sendst
: sendst
	8 state orC!
	0 do accept loop cr
;
]

[ifndef recst
: recst
	0 do pad d_100 .str loop
;
]
`

var m sync.Mutex

func StringOut(str string, out chan byte) {
	m.Lock()
	h := []byte(str)
	for _,c := range(h) {
		if c == byte(0x0A) {
			c = byte(0x0D)
		}
		out<- c
	}
	m.Unlock()
}
func chFlush( ch chan byte) {
	for q := false; q == false; {
		select {
		case <-ch:
		case <-time.After(500e6):
			q = true
		}
	}
}


func sendSpeedTest(tcpch *TCPChannels, out chan byte, muxch int, nbytes int) {
	tm, fm, dm, e := tcpch.mx.ClientConnect(muxch)
	if e == nil{
		StringOut( srForthTest, tm)
		if nbytes < 100 {
			nbytes = 100
			}
		nbytes = int( (float32(nbytes)/100)) * 100
		nloops := nbytes / 100

		StringOut( fmt.Sprintf("%d sendst\r", nloops),tm)
		chFlush( fm)
		then := time.Now()
		for j := 0; j < nloops; j++ {
			for i := 0; i < 99; i++ {
				tm<- byte( 0x40 + (i & 0xF))
			}
			tm<- byte(0x0D)
		}
		<-fm
		st := time.Now().Sub(then).Nanoseconds()
		res := fmt.Sprintf("Mux Channel %02d Send Chars/sec %6.2f\n", muxch, 1e9/(float64(st)/float64(nbytes)))
		
		StringOut( res, out)
		dm <- true
	}

}
func receiveSpeedTest(tcpch *TCPChannels, out chan byte, muxch int, nbytes int) {
		
	tm, fm, dm, e := tcpch.mx.ClientConnect(muxch)
	if e == nil{
		StringOut( srForthTest, tm)
		if nbytes < 100 {
			nbytes = 100
			}
		nbytes = int( (float32(nbytes)/100)) * 100
		nloops := nbytes / 100

		chFlush( fm)

		then := time.Now()
		StringOut( fmt.Sprintf("%d recst\r", nloops), tm)
		for j := 0; j < nloops; j++ {
			for i := 0; i < 100; i++ {
				<-fm
			}
		}
		rt := time.Now().Sub(then).Nanoseconds()
		res := fmt.Sprintf("Mux Channel %02d  Rec Chars/sec %6.2f\n", muxch, 1e9/(float64(rt)/float64(nbytes)))
		StringOut( res, out)
		dm <- true
	}

}

func loopbackSpeedTest(tcpch *TCPChannels, out chan byte, muxch int, nbytes int) {
	tm, fm, dm, e := tcpch.mx.ClientConnect(muxch)
	if e == nil{
		receiveTime := make(chan int64)
		go func() {
			for i := 0; i < nbytes; i++ {
				tm<- byte( 0x40 + (i & 0xF))
				if debug {
					fmt.Printf("snd %02X %d\n", muxch, i)
				}
			}
		}()
		go func() {
			then := time.Now()
			for i := 0; i < nbytes; i++ {
				if debug {
					fmt.Printf("rec %02X %d\n", muxch, i)
				}
				<-fm
			}
			receiveTime<- time.Now().Sub(then).Nanoseconds()
		}()
		rc := <-receiveTime
		res := fmt.Sprintf("Mux Channel %02d  Loop Chars/sec: %6.2f\n", muxch, 1e9/(float64(rc)/float64(nbytes)))
		StringOut( res, out)
		dm <- true
	}

}
func ControlServer(tcpch *TCPChannels) {
	fmt.Printf("New Control Connection %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
	fromTelnetFilter, toTelnetFilter, filterReady := TelnetFilters( tcpch)
	<-filterReady

	help := fmt.Sprintf( controlServerHelp,  tcpch.mx.NumMuxChannels())
	StringOut(help, toTelnetFilter)
	buf := make([]byte, 0, 512)
	ibuf := make([]int, 256)

	tcpq := false
	for oq := false; oq == false && tcpq == false; {
		buf = buf[:0]
		for q := false; q == false && oq == false && tcpq == false; {
			select {
			case data := <-fromTelnetFilter:
				if data == byte(0x08) {
					toTelnetFilter <- data
					toTelnetFilter <- byte(0x20)
					toTelnetFilter <- data
					buf = buf[:len(buf)-1]
				} else if data == byte(0x0D) {
					toTelnetFilter <- data
					q = true
				} else {
					buf = append(buf, data)
					toTelnetFilter <- data
				}
			case tcpq = <- tcpch.quit:
			}
		}

		var pbuf []int
		if tcpq == false {
			s := string(buf)
			f := strings.Fields(s)
			pbuf = ibuf[: len(f)]
			for i := 0; i < len(f) && oq == false; i++ {
				n, e := strconv.ParseInt( f[i], 10, 32)
				if e == nil {
					ibuf[i] = int(n)
				} else {
					switch f[i] {
					case "h":
						ibuf[i] = -1
					case "?":
						ibuf[i] = -2
					case "q":
						ibuf[i] = -3
					case "c":
						ibuf[i] = -4
					case "s":
						ibuf[i] = -5
					case "t":
						ibuf[i] = -6
					case "u":
						ibuf[i] = -7
					default:
						ibuf[i] = -9
					}
				}
			}
		}
		n1 := -999
		n2 := -999
		for _ , tok := range(pbuf) {
			if tok < 0 {
				switch tok {
				case -2:
					
				case -3:
					oq = true
					tcpch.closeTCP <- true

				case -4:

					if 0 <= n2 && n2 < tcpch.mx.NumMuxChannels() &&
						tcpch.mx.IsClientConnected(n2) == false {
						fmt.Printf( "Connecting to %d\n", n2)
						tcpch.toMux, tcpch.fromMux, tcpch.disconMux, _ = tcpch.mx.ClientConnect(n2)
						defer TelnetServer( tcpch)
						oq = true
					} else {
						StringOut(help, toTelnetFilter)
					}
					n1,n2 = -999,-999
					
				case -5:
					if 4 <= n1 && n1 < tcpch.mx.NumMuxChannels() && 100 <= n2 && n2 <= 10000 {
						go loopbackSpeedTest(tcpch, toTelnetFilter, n1, n2)
					} else {
						StringOut(help, toTelnetFilter)
					}
					n1,n2 = -999,-999

				case -6:
					if 0 <= n1 && n1 < 4 && 100 <= n2 && n2 <= 10000 {
						go sendSpeedTest(tcpch, toTelnetFilter, n1, n2)
					} else {
						StringOut(help, toTelnetFilter)
					}
					n1,n2 = -999,-999

				case -7:
					if 0 <= n1 && n1 < 4 && 100 <= n2 && n2 <= 10000 {
						go receiveSpeedTest(tcpch, toTelnetFilter, n1, n2)
					} else {
						StringOut(help, toTelnetFilter)
					}
					n1,n2 = -999,-999

				default:
					StringOut(help, toTelnetFilter)
				}
			} else {
				if n1 != -999 && n2 != -999 {
					StringOut(help, toTelnetFilter)
				}
				n1 , n2 = n2, tok
			}

		}
	}

	close(toTelnetFilter)
	fmt.Printf("Control Connection Closed %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
}

func RawServer(tcpch *TCPChannels) {
	fmt.Printf("New Raw Connection %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
	flag := false
	for i := tcpch.mx.NumMuxChannels() -1; flag == false &&i >= 0; i-- {
		if tcpch.mx.IsClientConnected(i) == false {
			tcpch.toMux, tcpch.fromMux, tcpch.disconMux, _ = tcpch.mx.ClientConnect(i)
			flag = true
		}
	}
	if flag == false {
		tcpch.closeTCP<- true
		fmt.Printf("No available mux channels -- Raw Connection %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
		return
	}
			
	peerQuit := make( chan bool)
	go func() {
		for q := false; q ==false; {
			select {
			case q = <-peerQuit:
			case d := <-tcpch.fromMux:
				tcpch.to<- d
			}
		}
	}()

	for q := false; q == false; {
		select {
		case q = <-tcpch.quit:
			peerQuit<- true
		case d := <-tcpch.from:
			tcpch.toMux<- d
		}
	}
	tcpch.disconMux <- true
	tcpch.fromMux = nil
	tcpch.toMux = nil
	tcpch.disconMux = nil
	fmt.Printf("Raw Connection Closed %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
}

/*
Telnet control
FF - IAC
FE - DONT
FD - DO
FC - WONT
FB - WILL
01 - ECHO
03 - Suppress goahead

Telnet sends either 0x0d 0x0a or 0x0d 0x00 - in both cases send only 0x0d

expand 0x0d to 0x0d 0x0a
*/


func TelnetFilters( tcpch *TCPChannels) (chan byte, chan byte, chan bool) {
	peerQuit := make(chan bool)
	ready := make( chan bool)
	fromTelnetFilter := make( chan byte, 4096)
	toTelnetFilter := make( chan byte, 4096)

	go func() {
		for d := range( toTelnetFilter) {
			tcpch.to<- d
			if d == byte(0x0D) {
				tcpch.to <- byte(0x0A)
			}
		}
		peerQuit<- true
	}()

	go func() {
		tcpch.to <- 0xFF
		tcpch.to <- 0xFB
		tcpch.to <- 0x01
		tcpch.to <- 0xFF
		tcpch.to <- 0xFB
		tcpch.to <- 0x03
		ready<- true
		for q := false; q == false; {
			select {
			case q = <-peerQuit:
			case data := <-tcpch.from:
				if data == 0xFF {
					data1 := byte(0)
					data2 := byte(0)
					select {
					case data1 = <- tcpch.from:
					case q = <-peerQuit:
					}
					select {
					case data2 = <- tcpch.from:
					case q = <-peerQuit:
					}
					if data1 == 0xFB && data2 == 0x03 {
						data1 = 0xFD
					} else if data1 == 0xFD && data2 == 0x03 {
						data1 =0xFB
					} else if data1 == 0xFD && data2 == 0x01 {
						data1 =0xFB
					} else if data1 == 0xFC {
						data1 = 0xFE
					} else if data1 == 0xFE {
						data1 = 0xFC
					} else {
						data = 0
					}
					if data == 0xFF {
						tcpch.to <- data
						tcpch.to <- data1
						tcpch.to <- data2
					}
				} else if data == 0x0D  {
					fromTelnetFilter <- data
					data1 := byte(0)
					select {
					case data1 = <- tcpch.from:
					case q = <-peerQuit:
					}
					if data1 != 0x00 && data1 != 0x0A {
						fromTelnetFilter <- data1
					}
				} else {
					fromTelnetFilter <- data
				}
			}
		}
	}()
	return fromTelnetFilter, toTelnetFilter, ready
}


func TelnetServer(tcpch *TCPChannels) {
	fmt.Printf("New Telnet Connection %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
	if tcpch.toMux == nil {
		for i := 0; i < tcpch.mx.NumMuxChannels(); i++ {
			if tcpch.mx.IsClientConnected(i) == false {
				tcpch.toMux, tcpch.fromMux, tcpch.disconMux, _ = tcpch.mx.ClientConnect(i)
				break
			}
		}
	}

	peerQuit := make( chan bool)
	fromTelnetFilter, toTelnetFilter, filterReady := TelnetFilters( tcpch)
	<-filterReady
	go func() {
		for q := false; q ==false; {
			select {
			case q = <- peerQuit:

			case d := <-tcpch.fromMux:
				toTelnetFilter <- d
			}
		}
	}()

	for q := false; q == false; {
		select {
		case q = <-tcpch.quit:

		case data := <-fromTelnetFilter:
			if data == 0x03  {
				q = true
				defer ControlServer( tcpch)
			} else {
				tcpch.toMux <- data
			}
		}
	}
	peerQuit <- true
	close(toTelnetFilter)
	tcpch.disconMux <- true
	tcpch.fromMux = nil
	tcpch.toMux = nil
	tcpch.disconMux = nil
	fmt.Printf("Telnet Connection Closed %v <--> %v\n", tcpch.conn.LocalAddr(),tcpch.conn.RemoteAddr())
}

func ListenTCPall( port int) chan *TCPChannels {
	conn_chan := make( chan *TCPChannels)
	for _, s := range(GetIPs()) {
		addr := net.TCPAddr{ s, port}
		listener, err := net.ListenTCP("tcp", &addr)
		if err != nil {
			fmt.Printf( "\nCould not listen on %v:%d ERROR: %s\n\n", s, port, err.Error())
		} else {
			fmt.Printf( "Listening on %v:%d\n", s, port)
			go func( *net.TCPListener, chan *TCPChannels) {
				for{
					tcp_conn, err := listener.AcceptTCP()
					if tcp_conn == nil || err != nil {
						fmt.Printf("\nCould not accept connection. ERROR: %s\n\n",err.Error())
						continue
					}
					conn_chan <- TCPConnectionChannels( tcp_conn)
				}
			}( listener, conn_chan)
		}
	}
	return conn_chan
}

func GetIPs() []net.IP {
	x, _ := net.InterfaceAddrs()

	var addrs = make([]string, len(x) + 1)
	flag := false

	for i, xx := range x {
		ip1, _, err := net.ParseCIDR(xx.String())
		ip2 := net.ParseIP(xx.String())
		
		if err == nil && ip1 != nil && ip1.String() != "0.0.0.0" {
			addrs[i] = ip1.String()
		} else if ip2 != nil && ip2.String() != "0.0.0.0" {
			addrs[i] = ip2.String()
		}
		if addrs[i] == "127.0.0.1" {
			flag = true
		}
	}
	if !flag {
		addrs[ len(addrs)-1] = "127.0.0.1"
	}
// filter out IPv6 for now
	for i , s := range(addrs) {
		if strings.Contains(s, "::") {
			addrs[ i] = ""
		}
	}
	sort.Strings( addrs)

	var begin int
	for i, s := range(addrs) {
		if s != "" {
			begin = i
			break
		}
		
	}
	var ips = make( []net.IP, len(addrs[begin:]))
	for i , s := range( addrs[ begin:]) {
		ips[i] = net.ParseIP(s)
	}
	return ips
}

func TCPConnectionChannels(client *net.TCPConn)(*TCPChannels) {
	rc := &TCPChannels{ make(chan byte,4096), make(chan byte,4096), make(chan bool), make( chan bool), client, nil,nil,nil,nil}

	peerQuit := make( chan bool)
	go func( tcpch *TCPChannels) {
		datain := make( []byte, 4096)
		for q:= false; q == false; {
			count, err := tcpch.conn.Read( datain)
			if err != nil {
				if err.Error() != "EOF" {
					fmt.Printf( "\n\nConnection Read Error: %s\n\n", err.Error())
				}
				tcpch.quit <- true
				peerQuit <- true
				q = true
			}
			din := datain[:count]
			for _,c := range(din) {
				tcpch.from <- c
			}
			select {
			case q = <-tcpch.closeTCP:
				tcpch.conn.Close()
				tcpch.quit <- true
				peerQuit <- true
			default:
			}
		}
	}(rc)

	go func(tcpch *TCPChannels) {
		dataout := make( []byte, 4096)
		var wcount int
		var readflag bool

		for q := false; q == false ; {

			select {
			case dataout[ 0] = <- tcpch.to:
				for readflag, wcount = true, 1; readflag && wcount < 4096; wcount++ {
					select {
					case dataout[wcount] = <- tcpch.to:
					default:
						readflag = false
						wcount--
					}
				}
				dout := dataout[:wcount]

				tcpch.conn.Write( dout)

			case q = <- peerQuit:
			}
				
		}
	}(rc)

	return rc
}

