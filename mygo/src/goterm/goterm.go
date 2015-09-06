package main

import (
	"cogCommandProcessor"
	"fmt"
	"io"
	"net"
	"os"
	"runtime"
	"serial"
	"strconv"
	"time"
)

var debug bool = false

func main() {
	var err error
	var baud, cmdIndex int
	var chanFromSerial, chanToSerial chan byte
	var chanDTRSerial, chanQuitSerial, chanQuitTcp chan bool
	var conn *net.TCPConn
	var tcpaddr *net.TCPAddr

	runtime.GOMAXPROCS(runtime.NumCPU())

	cp := new( cogCommandProcessor.CogCommandProcessor)
	cp.SetReceiveTimeout( time.Duration(3e9))
	cp.SetCps( 5000)


	if len(os.Args) > 1 {
		tcpaddr, err = net.ResolveTCPAddr( "tcp", os.Args[1])
		if err == nil {
			conn,err = net.DialTCP( "tcp", nil, tcpaddr)
			if err == nil {
				chanFromSerial, chanToSerial, chanQuitTcp = cp.TcpChan( conn)
			}
		}
		cmdIndex = 2
	}

	if chanFromSerial == nil && len(os.Args) > 2 {
		b, errc := strconv.ParseInt( os.Args[2], 10, 32)
		err = errc
		baud = int( b)
		if err == nil {
			chanFromSerial, chanToSerial, chanDTRSerial, chanQuitSerial, err = serial.SerialChannels( os.Args[1], baud, debug)
		}
// to reset the prop
		chanDTRSerial <- false
		time.Sleep( 1e8)
		chanDTRSerial <- true
		time.Sleep( 1e8)
		chanDTRSerial <- false
		cmdIndex = 3
		
	}


	if err != nil || chanFromSerial == nil {
		fmt.Printf( "error: %s\nusage: %s [ipaddr:port | com_port baud] [commands]*\n%s", err, os.Args[0], cogCommandProcessor.Help)
		return
	}

	conLog := make( chan string)
	go func() {
		for s := range  conLog {
			fmt.Print( s)
		}
	}()
	
	var sName string
	if len(os.Args) > cmdIndex {
		sName = "LINE COMMANDS"
	} else {
		sName = "USER INPUT"
	}

	time.Sleep( 3e9)

	chanCommand := cp.CommandProcessor( sName, chanFromSerial, chanToSerial, conLog)

	if len(os.Args) > cmdIndex {
		for _,s := range( os.Args[cmdIndex:]) {
			fmt.Println( s)
			for _,c := range( s) {
				chanCommand <- byte(c)
			}
			chanCommand <- byte(0x20)
		} 
		chanCommand <- byte( 0x0D)
		chanCommand <- byte( 0x0D)
		close(chanCommand)
		return
	}

	chanCommand <- byte( 'h')
	chanCommand <- byte( 0x0D)
	d := make( []byte, 2048)
	for {
		c, e := os.Stdin.Read( d)
		for _,ch := range( d[:c]) {
			if ch == byte(0x0A) {
				ch = byte(0x0D)
			}
			chanCommand <- ch
			if ch == byte(0x0D) {
				break
			}
		}
		time.Sleep( 10)

		if chanQuitTcp != nil {
			select {
			case <- chanQuitTcp:
				e = io.EOF
			default:
			}
		}

		if e == io.EOF {
			break
		}
	}
	if chanQuitSerial != nil {
		chanQuitSerial <- true
	}
	if chanQuitTcp != nil {
		
	}
	close( conLog)
}
