package cogCommandProcessor

import (
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

/*

*/

func (cp *CogCommandProcessor) CommandProcessor( scriptName string, fromCog chan byte, toCog chan byte, log chan string) chan byte {
	cp.scriptFileName = scriptName
	cp.chanFromCog = fromCog
	cp.chanToCog = toCog
	cp.chanConsoleLog = log

	cp.chanCommand = make( chan byte)

	go cp.processCommands()
	return cp.chanCommand
}

type CogCommandProcessor struct {
	chanFromCog, chanToCog, chanFromCogSaved, chanToCogSaved, chanCommand chan byte
	chanConsoleLog chan string

	chanReceiveTimeout, chanEmitQuit, chanEmitTickle, chanUnsave chan bool

	receiveDelay time.Duration
	cps int64
	binary, echo, passThrough bool

	data, currentLine []byte
	fields []string

	scriptFileName, logFileName, resultFileName, outputFileName string

	logFile, resultFile, outputFile *os.File
	sync.Mutex
}

func (cp *CogCommandProcessor) SetReceiveTimeout( t time.Duration) {
	cp.receiveDelay = t
}
func (cp *CogCommandProcessor) SetCps( t int64) {
	cp.cps = t
}




var Help string = `
Commands - blank lines ignored, buffered input hit <ENTER>, ${environmet_variable} is expanded if defined
Environment variables in the form $XXX are translated to hXXX by SXW (where XXX are valid forth hex characters including _)

\ -- comment line

X words -- send words+cr to cog
Y words -- send words to cog
S file  -- send contents of file to cog

x nn      -- send character represented by nn (hex) to the cog, do not wait for a response
s word    -- send word to the cog, do not wait for a response
scr words -- send words + cr to the cog, do not wait for a response

L logFile    -- set log to logFile
R resultFile -- send results to resultFile
O outputFile -- send results to outputFile instead of resultFile
CO -- close output file and send results back to resultFile
CR -- close the result file
CL -- close the log file

SR file  -- send file to the result/output file
SW words -- send word+cr+lf to the output file
SXW words -- send word+cr+lf to the output file (translate $ to h at the beginning of a word)

r scriptFile -- run scriptFile, state of echo, cps, receiveTimeout, logFile, and resultFile are passed to the script

rc scriptFile1 - scriptFileN -- run scriptFile concurrently, state of echo, cps, receiveTimeout, are passed to the script

ipc ipaddr:port -- connect to ipaddr:port
mux muxchannel  -- connect to muxchannel
dis             -- disconnect from muxchannel or ipchannel

b 0|1 -- set binary mode on/off, does not send 0x0A to cog in non-binary mode
e 0|1 -- echo results to screen, useful for debugging

cps nnnn -- set the transmit character rate to a maximum of nnnn characters / sec (over a 256 byte burst)
t nnnn   -- set receiveTimeout to nnnn milliSeconds -- post command

w -- wait for output

CTL-G - Toggles command/terminal mode
CTL-Z - exit
`


func (cp *CogCommandProcessor) logOutputRaw( s string ){
	cp.chanConsoleLog <- s
	if cp.logFile != nil {
		cp.logFile.WriteString(s)
	}
}
func (cp *CogCommandProcessor) logOutput( s string ){
	cp.logOutputRaw( fmt.Sprintf("%s::%s %s\r\n", cp.scriptFileName, time.Now().Local(), s))
}
func (cp *CogCommandProcessor) logError( s string ){
	str := fmt.Sprintf("*************ERROR****** %s::%s %s\r\n", cp.scriptFileName, time.Now().Local(), s)
	cp.logOutputRaw( str)
	if cp.resultFile != nil {
		cp.resultFile.WriteString(s)
	}
	if cp.outputFile != nil {
		cp.outputFile.WriteString(s)
	}
	time.Sleep(2e9)
	os.Exit( -1)
}
func (cp * CogCommandProcessor) getLine( ) bool {
	var count int
	var ok bool
	if cp.passThrough {
		t := cp.echo
		cp.echo = true
		for ok = true; ok && cp.passThrough; {
			var c byte
			c,ok = <- cp.chanCommand
			switch c {
			case '\x07':
				cp.passThrough = false
			default:
				cp.chanToCog <- c
			}
		}
		cp.passThrough = false
		cp.echo = t
	}
	for ok,count = true,0; count < len(cp.data) && ok; count++ {
		cp.data[count],ok = <- cp.chanCommand
		if ok && cp.data[count] == byte(0xD) {
			count++
			break
		}
		time.Sleep(10)
	}
	cp.currentLine = cp.data[:count]
	cp.fields = strings.Fields(string(cp.currentLine))
	for i,v:=range(cp.fields) {
		if v[0] == '$' && v[1] == '{' && v[len(v)-1] == '}' {
			cp.fields[i] = os.ExpandEnv(v)
		}
	}
	return ok
}
func (cp *CogCommandProcessor) processComment() {
	cp.logOutputRaw(fmt.Sprintf("%s\r\n", cp.currentLine))
	cp.fields = cp.fields[0:0]
}
func (cp *CogCommandProcessor) processCreate() (string, *os.File){
	var fp *os.File
	var name string
	var e error

	if len(cp.fields) < 2 {
		cp.fields = cp.fields[0:0]
	} else {
		name = cp.fields[1]
		fp, e = os.Create(name)
		if e != nil {
			cp.logError(fmt.Sprintf( "Error creating %s:: %s\n", name, e))
		}
		cp.fields = cp.fields[2:]
	}
	return name,fp
	
}
func (cp *CogCommandProcessor) processFile1(name string) (string, *os.File){
	fp,e := os.Open(name)
	if e != nil {
		cp.logError(fmt.Sprintf( "Error opening %s:: %s\n", name, e))
	}
	return name,fp
}

func (cp *CogCommandProcessor) processFile() (string, *os.File){
	name := cp.parseString()
	return cp.processFile1(name)
}
func (cp *CogCommandProcessor) parseString() string {
	var rc string
	if len(cp.fields) < 2 {
		cp.fields = cp.fields[0:0]
	} else {
		rc = cp.fields[1]
		cp.fields = cp.fields[2:]
	}
	return rc
}
func (cp *CogCommandProcessor) parseInt64() int64 {
	var rc int64
	s := cp.parseString()
	n, e := strconv.ParseInt( s, 10, 32)
	if e != nil {
		cp.logError( fmt.Sprintf("Error parsing integer %s:: %s", s, e))
	} else {
		rc = int64( n)
	}
	return rc
}

func (cp *CogCommandProcessor) parseHex64() int64 {
	var rc int64
	s := cp.parseString()
	n, e := strconv.ParseInt( s, 16, 32)
	if e != nil {
		cp.logError( fmt.Sprintf("Error parsing hex integer %s:: %s", s, e))
	} else {
		rc = int64( n)
	}
	return rc
}

func (cp *CogCommandProcessor) processScriptFile() {
	name,fp := cp.processFile( )
	if fp != nil {
		cp.chanEmitQuit <- true
		var np CogCommandProcessor
		nc := np.CommandProcessor( name, cp.chanFromCog, cp.chanToCog, cp.chanConsoleLog)
		np.logFile = cp.logFile
		np.resultFile = cp.resultFile
		np.resultFileName = cp.resultFileName
		np.logFileName = cp.logFileName
		np.echo = cp.echo
		np.cps = cp.cps
		np.receiveDelay = cp.receiveDelay
		d := make([]byte, 4096)
		for {
			nb , e := fp.Read( d)
			if e != nil && e != io.EOF {
				np.logError( fmt.Sprintf( "Error reading script file:: %s\n", e))
				break
			}
			if nb == 0 {
				break 
			} else {
				for _,c := range(d[:nb]) {
					if c != byte(0x0A) {
						nc <- c
						time.Sleep( 10)
					}
				}
			}
		}
		nc <- byte(0x0D)
		nc <- byte(0x0D)
		close( nc)
		fp.Close()
		cp.emitLogger()
	}
	cp.logFiles()
}
func (cp *CogCommandProcessor) processConcurrentScriptFile() {
	var chanSyncDone []chan bool = make( []chan bool, 0, 256)
	cp.chanEmitQuit <- true

	for _,v := range(cp.fields[1:]) {
		name, fp := cp.processFile1(v)
		if fp != nil {
			qc := make(chan bool)
			chanSyncDone = append( chanSyncDone, qc)
			go func ( p *CogCommandProcessor, s string, chanDone chan bool) {
				var np CogCommandProcessor
				dummyFromCog := make(chan byte)
				dummyToCog := make(chan byte)
				nc := np.CommandProcessor( name, dummyFromCog, dummyToCog, p.chanConsoleLog)
				np.echo = p.echo
				np.cps = p.cps
				np.receiveDelay = p.receiveDelay
				d := make([]byte, 4096)
				for {
					nb , e := fp.Read( d)
					if e != nil && e != io.EOF {
						np.logError( fmt.Sprintf( "Error reading script file:: %s\n", e))
						break
					}
					if nb == 0 {
						break 
					} else {
						for _,c := range(d[:nb]) {
							if c != byte(0x0A) {
								nc <- c
								time.Sleep( 10)
							}
						}
					}
				}
				nc <- byte(0x0D)
				nc <- byte(0x0D)
				close( nc)
				fp.Close()
				chanDone <- true
			}( cp, name, qc)
		}
	}
	for _,ch := range( chanSyncDone) {
		<- ch
	}
	cp.fields = cp.fields[0:0]
	time.Sleep(cp.receiveDelay)
	cp.emitLogger()
	cp.logFiles()
}
func (cp *CogCommandProcessor) processLogFile() {
	var fp * os.File
	cp.logFileName,fp = cp.processCreate( )
	if fp != nil {
		if cp.logFile != nil {
			cp.logFile.Close()
		}
		cp.logFile = fp
	}
	cp.logFiles()
}
func (cp *CogCommandProcessor) processResultFile() {
	var fp * os.File
	cp.resultFileName,fp = cp.processCreate()
	if fp != nil {
		if cp.resultFile != nil {
			cp.resultFile.Close()
		}
		cp.resultFile = fp
	}
	cp.logFiles()
}
func (cp *CogCommandProcessor) processOutputFile() {
	var fp * os.File
	cp.outputFileName,fp = cp.processCreate()
	if fp != nil {
		if cp.outputFile != nil {
			cp.outputFile.Close()
		}
		cp.outputFile = fp
	cp.logFiles()
	}
}
func (cp *CogCommandProcessor) closeOutputFile() {
	if cp.outputFile != nil {
		cp.outputFile.Close()
		cp.outputFile, cp.outputFileName = nil, ""
	}
	cp.fields = cp.fields[1:]
	cp.logFiles()
}
func (cp *CogCommandProcessor) closeResultFile() {
	if cp.resultFile != nil {
		cp.resultFile.Close()
		cp.resultFile, cp.resultFileName = nil, ""
	}
	cp.fields = cp.fields[1:]
	cp.logFiles()
}
func (cp *CogCommandProcessor) closeLogFile() {
	if cp.logFile != nil {
		cp.logFile.Close()
		cp.logFile, cp.logFileName = nil, ""
	}
	cp.fields = cp.fields[1:]
	cp.logFiles()
}

func (cp *CogCommandProcessor) logFiles( ){
	s := fmt.Sprintf("\r\n scriptFileName: %s\r\n   logFileName: %s\r\nresultFileName: %s\r\noutputFileName: %s\r\n",
		cp.scriptFileName, cp.logFileName, cp.resultFileName, cp.outputFileName )
	cp.logOutput( s)
	if cp.resultFile != nil {
		cp.resultFile.WriteString( s)
	}
}

func (cp *CogCommandProcessor) logDelays( ){
	cp.logOutput( fmt.Sprintf( " %d cps  Receive Delay %v Echo: %v Binary: %v\n",
		cp.cps, cp.receiveDelay, cp.echo, cp.binary))
}

func (cp *CogCommandProcessor) emitter( d []byte) []byte {
	if len(d) > 0 {
		if cp.echo {
			cp.chanConsoleLog <- string( d)
		}
		if cp.outputFile != nil {
			cp.outputFile.Write( d)
		} else if cp.resultFile != nil {
			cp.resultFile.Write( d)
		}
		d = d[0:0]
	}
	return d
}
func (cp *CogCommandProcessor) emitLogger() {
	go func() {

		cp.chanEmitQuit = make( chan bool)
		cp.chanEmitTickle = make( chan bool)

		d := make([]byte, 0, 2048)
		for q:= false; q == false; {
			select {
			case c := <-cp.chanFromCog:
				d = append( d, c)
				if len(d) == cap(d) ||  ( len(d) > 2 && d[len(d)-2] == byte(0x0D) && d[len(d)-1] == byte(0x0A)) {
					d = cp.emitter( d)
				}
			case q = <- cp.chanEmitQuit:
				d = cp.emitter( d)

			case <- cp.chanEmitTickle:

			case <- time.After(cp.receiveDelay):
				d = cp.emitter( d)
				cp.Lock()
				if cp.chanReceiveTimeout != nil {
					cp.chanReceiveTimeout <- true
				}
				cp.Unlock()
			}
		}
		cp.chanEmitQuit = nil
	}()

}
func (cp *CogCommandProcessor) disconnect() {
	if cp.chanUnsave == nil {
		cp.logError( "dis: not connected")
	} else {
		cp.logOutput( "dis: disconnecting")
		cp.chanUnsave <- true
		<- cp.chanUnsave
		cp.chanUnsave = nil
	}
	cp.fields = cp.fields[1:]
	
}
func (cp *CogCommandProcessor) ipConnect() {
	var e error
	var conn *net.TCPConn
	var tcpaddr *net.TCPAddr

	ipaddr := cp.parseString()
	cp.logOutput( fmt.Sprintf( "Connecting to ip addr [%s]", ipaddr))
	if cp.chanUnsave != nil {
		e = errors.New( "Only one level of connection nesting allowed")
	}
	if e == nil {
		tcpaddr, e = net.ResolveTCPAddr( "tcp", ipaddr)
		if e == nil {
			conn,e = net.DialTCP( "tcp", nil, tcpaddr)
		}
	}
	if e != nil {
		cp.logError(fmt.Sprintf( "Connecting to ip addr [%s] - [%v] ", ipaddr, e))
	} else {
		cp.logOutput( fmt.Sprintf( "Connected to ip addr [%s]", ipaddr))

		cp.chanFromCogSaved = cp.chanFromCog
		cp.chanToCogSaved = cp.chanToCog
		cp.chanUnsave = make( chan bool)

		var chanTCPQuit chan bool
		cp.chanFromCog, cp.chanToCog, chanTCPQuit = cp.TcpChan( conn)

		go func( ) {
			select {
			case <- cp.chanUnsave:
				conn.Close()
				<- chanTCPQuit

			case errTCP := <- chanTCPQuit:
				
				if errTCP {
					cp.logError( fmt.Sprintf( " Read error from ip addr [%s]", ipaddr))
				} else {
					cp.logOutput( fmt.Sprintf( "Remote disconnect from ip addr [%s]", ipaddr))
					conn.Close()
					<-cp.chanUnsave
				}
			}

			cp.chanToCog = cp.chanToCogSaved
			cp.chanFromCog = cp.chanFromCogSaved
			cp.chanUnsave <- true
			cp.logOutput( fmt.Sprintf( "Disconnected from ip addr [%s]", ipaddr))
		}( )

	}
}

func (cp *CogCommandProcessor) processCommands() {

	cp.binary = false
	cp.data = make( []byte, 4096)
	cp.emitLogger()

	cp.logOutput( "STARTING SCRIPT FILE")
	for ; cp.getLine(); {
		for ; len(cp.fields) > 0; {
			switch cp.fields[0] {
			case "\\":
				cp.processComment()
			case "L":
				cp.processLogFile()
			case "R":
				cp.processResultFile()
			case "O":
				cp.processOutputFile()
			case "CO":
				cp.closeOutputFile()
			case "CR":
				cp.closeResultFile()
			case "CL":
				cp.closeLogFile()
			case "r":
				cp.processScriptFile()
			case "rc":
				cp.processConcurrentScriptFile()
			case "S":
				cp.sendFile()
			case "X":
				cp.sendStrings(true)
			case "Y":
				cp.sendStrings(false)
			case "SR":
				cp.echoFile()
			case "SW":
				cp.echoWords()
			case "SXW":
				cp.echoHexWords()
			case "b":
				cp.binary = cp.parseInt64() != int64(0)
			case "e":
				cp.echo = cp.parseInt64() != int64(0)
			case "cps":
				cp.cps = cp.parseInt64()
			case "x":
				d := cp.parseHex64()
				cp.chanToCog <-  byte(d)
				cp.logOutput( fmt.Sprintf( "SEND: [%d]", d))
			case "s":
				str := cp.parseString()
				for _,c := range([]byte(str)){
					cp.chanToCog <-  c
				}
				cp.logOutput( fmt.Sprintf( "SEND: [%s]", str))
			case "scr":
				s := ""
				for _,s1 := range( cp.fields[1:]) {
					s = s + s1 + " "
				}
				for _,c := range([]byte(s)){
					cp.chanToCog <-  c
				}
				cp.chanToCog <- byte( 0x0D)
				cp.logOutput( fmt.Sprintf( "SEND: [%s]+cr", s))
				cp.fields = cp.fields[0:0]
			case "t":
				cp.receiveDelay = time.Duration( cp.parseInt64() * 1e6)
			case "\x07":
				cp.passThrough = true
				cp.fields = cp.fields[0:0]
			case "ipc":
				cp.ipConnect()
			case "dis":
				cp.disconnect()
			case "w":
				cp.Lock()
				cp.chanReceiveTimeout = make( chan bool)
				cp.Unlock()
				cp.chanEmitTickle <- true
				<- cp.chanReceiveTimeout
				cp.Lock()
				cp.chanReceiveTimeout = nil
				cp.Unlock()
				cp.logOutput( "WAIT DONE")

				cp.fields = cp.fields[1:]
			case "h":
				cp.logOutputRaw( Help)
				cp.fields = cp.fields[1:]
			default:
				cp.logOutput( fmt.Sprintf( "INVALID COMMAND: [%s]", cp.fields[0]))
				cp.fields = cp.fields[1:]
			}
		}
	}
	cp.logOutput( "DONE SCRIPT FILE")
	cp.chanEmitQuit <- true
}
func (cp *CogCommandProcessor) echoFile() {
	name,fp := cp.processFile( )
	if fp != nil {
		cp.logDelays()
		cp.logOutput( fmt.Sprintf( "ECHOING: %s", name))
		d := make( []byte, 4096)
		for {
			nb , e := fp.Read( d)
			if e != nil && e != io.EOF {
				cp.logError( fmt.Sprintf( "Error reading file:: %s\n", e))
				break
			}
			if nb == 0 {
				break 
			} else {
				for _,c := range(d[:nb]) {
					cp.chanFromCog <- c
				}
			}
		}
		cp.logOutput( fmt.Sprintf( "DONE ECHOING: %s", name))
		time.Sleep( 1e8)
	}
}
	
func (cp *CogCommandProcessor) echoWords() {
	cp.logDelays()
	s := ""
	for _,s1 := range( cp.fields[1:]) {
		s = s + s1 + " "
	}
	cp.logOutput( fmt.Sprintf( "ECHOING: %s",s ))
	if len(s) > 0 {
		s = s[ :len(s) - 1]
	}
	s = s + "\x0D\x0A"
	for _, c := range([]byte(s)) {
		cp.chanFromCog <- c
	}
	cp.fields = cp.fields[0:0]
	cp.logOutput( fmt.Sprintf("DONE ECHOING: %s", s))
	time.Sleep(1e8)
}
func (cp *CogCommandProcessor) echoHexWords() {
	cp.logDelays()
	s := ""
	for _,s1 := range( cp.fields[1:]) {
		if len(s1) > 1 && s1[0] == '$' {
			f := true
			for _,hn := range(s1[1:]) {
				f = f && ((hn >= '0' && hn <= '9') || (hn >= 'A' && hn <= 'F') || hn == '_')
			}
			if f {
				s1 = "h" + s1[1:]
			}
		}
		s = s + s1 + " "
	}
	cp.logOutput( fmt.Sprintf( "ECHOING: %s",s ))
	if len(s) > 0 {
		s = s[ :len(s) - 1]
	}
	s = s + "\x0D\x0A"
	for _, c := range([]byte(s)) {
		cp.chanFromCog <- c
	}
	cp.fields = cp.fields[0:0]
	cp.logOutput( fmt.Sprintf("DONE ECHOING: %s", s))
	time.Sleep(1e8)
}
func (cp *CogCommandProcessor) sendFile() {
	name,fp := cp.processFile( )
	if fp != nil {
		cp.logDelays()
		cp.logOutput( fmt.Sprintf( "SENDING: %s", name))
		d := make( []byte, 4096)
		for {
			nb , e := fp.Read( d)
			if e != nil && e != io.EOF {
				cp.logError( fmt.Sprintf( "Error reading file:: %s\n", e))
				break
			}
			if nb == 0 {
				break 
			} else {
				dd := d[:nb]
				for {
					ddd := dd
					if len(dd) > 256 {
						ddd = dd[:256]
					} else {
						ddd = dd
					}
					for _,c := range(ddd) {
						if cp.binary == true || c != byte(0x0A) {
							cp.chanToCog <- c
						}
					}
					if cp.cps > 0 {
						time.Sleep( time.Duration(int64(len(ddd)) * 1e9 / cp.cps ))
					}
					if len(dd) <= 256 {
						break
					} else {
						dd = dd[ 256:]
					}
				}
			}
		}
		cp.logOutput( fmt.Sprintf( "DONE SENDING waiting for output: %s", name))
		cp.Lock()
		cp.chanReceiveTimeout = make( chan bool)
		cp.Unlock()
		cp.chanEmitTickle <- true
		<- cp.chanReceiveTimeout
		cp.Lock()
		cp.chanReceiveTimeout = nil
		cp.Unlock()
		cp.logOutput( fmt.Sprintf( "DONE: %s", name))
		time.Sleep( 1e8)
	}
}
	
func (cp *CogCommandProcessor) sendStrings(f bool) {
	cp.logDelays()
	s := ""
	for _,s1 := range( cp.fields[1:]) {
		s = s + s1 + " "
	}
	if len(s) > 0 {
		s = s[ :len(s) - 1]
	}
	cp.logOutput( fmt.Sprintf( "SENDING: %s",s ))
	if f {
		s = s + "\x0D"
	}
	for _, c := range([]byte(s)) {
		cp.chanToCog <- c
	}
	cp.fields = cp.fields[0:0]
	if cp.receiveDelay > 0 { 
		cp.logOutput( fmt.Sprintf("DONE SENDING waiting for output: %s", s))
		cp.Lock()
		cp.chanReceiveTimeout = make( chan bool)
		cp.Unlock()
		cp.chanEmitTickle <- true
		<- cp.chanReceiveTimeout
		cp.Lock()
		cp.chanReceiveTimeout = nil
		cp.Unlock()
	} 	
	cp.logOutput( fmt.Sprintf( "DONE: %s", s))
	time.Sleep(1e8)
}


func (cp *CogCommandProcessor) TcpChan(conn *net.TCPConn) (chan byte, chan byte, chan bool) {

	chanFrom := make(chan byte,4096)
	chanTo := make(chan byte,4096)

	chanTCPQuit := make( chan bool)
	peerQuit := make( chan bool)

	go func( ) {
		datain := make( []byte, 4096)
		for q:= false; q == false; {
			count, err := conn.Read( datain)
			if err != nil {
				peerQuit <- true
				chanTCPQuit <- err != io.EOF
				q = true
				count = 0
			}
			din := datain[:count]
			for _,c := range(din) {
				chanFrom <- c
			}
		}
	}()

	go func( ) {
		dataout := make( []byte, 4096)
		var wcount int
		var readflag bool

		for q := false; q == false ; {

			select {
			case dataout[ 0] = <- chanTo:
				for readflag, wcount = true, 1; readflag && wcount < 4096; wcount++ {
					select {
					case dataout[wcount] = <- chanTo:
					default:
						readflag = false
						wcount--
					}
				}
				dout := dataout[:wcount]

				conn.Write( dout)

			case q = <- peerQuit:
			}
		}
	}( )

	return chanFrom, chanTo, chanTCPQuit
}
