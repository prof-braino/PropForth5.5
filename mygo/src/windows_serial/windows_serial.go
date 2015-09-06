package serial
// Serial io as raw as possible. 8 bits, no parity 1 stop bit, channel to provide DTR control
//
// comName := "com3" 
// baudRate := 57600
// debug := false
//
// chanFromSerial, chanToSerial, charDTRSerial, chanQuitSerial, err := SerialChannels( comName, baud, debug)
//
// chanFromSerial = byte data channel from serial
// chanToSerial - byte data channel to serial 
// chanDTRSerial - bool channel to control DTR - logical 1 means DTR active - rs232 level - +3-+15 volts 
// chanQuitSerial - send a bit on this channel to terminate
//
// based on http://code.google.com/p/goserial/
//
// Works with go version 1, tested on Windows 7(64 bit) and xp (32bit)
import (
	"errors"
	"fmt"
	"os"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

type structDCB struct {
	DCBlength, BaudRate uint32
	flags [4]byte
	wReserved, XonLim, XoffLim uint16
	ByteSize, Parity, StopBits byte
	XonChar, XoffChar, ErrorChar, EofChar, EvtChar byte
	wReserved1 uint16
}

type structTimeouts struct {
	ReadIntervalTimeout uint32
	ReadTotalTimeoutMultiplier uint32
	ReadTotalTimeoutConstant uint32
	WriteTotalTimeoutMultiplier uint32
	WriteTotalTimeoutConstant uint32
}

func SerialChannels( name string, baud int, debug bool) (chan byte, chan byte, chan bool, chan bool, error) {
	var serFile *os.File
	var handle syscall.Handle
	var rl sync.Mutex
	var wl sync.Mutex
	var ro *syscall.Overlapped
	var wo *syscall.Overlapped

	chFromSerial := make(chan byte,8192)
	chToSerial := make(chan byte,8192)
	chQuitSerial := make(chan bool)
	chDTRSerial := make(chan bool)

	if len(name) >0 && name[0] != '\\' {
		name = "\\\\.\\" + name
	}
	handle, err := syscall.CreateFile( syscall.StringToUTF16Ptr(name),
		syscall.GENERIC_READ|syscall.GENERIC_WRITE, 0, nil, syscall.OPEN_EXISTING,
		syscall.FILE_ATTRIBUTE_NORMAL|syscall.FILE_FLAG_OVERLAPPED, 0)

	if err == nil {
		serFile = os.NewFile( uintptr(handle), name)
	}
	if err == nil {
		err = setCommState(handle, baud)
	}
	if err == nil {
		err = setupComm(handle, 64, 64)
	}
	if err == nil {
		err = setCommTimeouts(handle)
	}
	if err == nil {
		err = setCommMask(handle)
	}
	if err == nil {
		ro, err = newOverlapped()
	}
	if err == nil {
		wo, err = newOverlapped()
	}
	
	if  err != nil {
		err = errors.New( "OpenPort ERROR: " + err.Error())
	} else {
		chFromSerial = make( chan byte, 8192)
		chQuitFrom := make( chan bool)
		go func() {
			var count int
			var done uint32
			then := time.Now()
			datain := make( []byte, 8192)
			for q := false; q == false; {
				rl.Lock()
				readerr := resetEvent(ro.HEvent)
				if readerr == nil {
					readerr = syscall.ReadFile(handle , datain, &done, ro)
					if readerr == syscall.ERROR_IO_PENDING {
						count, readerr = getOverlappedResult(handle, ro)
					} else {
						count = int(done)
					}
				}
				rl.Unlock()
				
				din := datain[:count]

				if debug && len(din) > 0 {
					now := time.Now()
					fmt.Printf("\n(%v(%d)", now.Sub(then), len(din))
					then = now
					for _, c := range( din) {
						if c < byte(0x20) || c > byte(0x7E) {
							fmt.Printf("{%02X}",c)
						} else {
							fmt.Printf("%c", c)
						}
					}
					fmt.Print(")")
				}
				for _, c := range( din) {
					chFromSerial <- c
				}
				select {
  				case q = <-chQuitFrom:
				default:
				}
				time.Sleep(10)
			}
		}()

		chToSerial = make( chan byte, 8192)
		chQuitTo := make( chan bool)
		go func() {
			dataout := make( []byte, 256)
			var count, wcount int
			var readflag bool
			then := time.Now()
			for q := false; q == false; {
				select {
				case q = <- chQuitTo:
				case dataout[ 0] = <- chToSerial:
					for readflag, wcount = true, 1; readflag && wcount < 256; wcount++ {
						select {
						case dataout[wcount] = <- chToSerial:
						default:
							readflag = false
							wcount--
						}
					}

					dout := dataout[:wcount]
					
					if debug {
						now := time.Now()
						fmt.Printf("\n\t[%v[%d]", now.Sub(then), len(dout))
						then = now
						for _, c := range( dout) {
							if c < byte(0x20) || c > byte(0x7E) {
								fmt.Printf("{%02X}",c)
							} else {
								fmt.Printf("%c", c)
							}
						}
						fmt.Print("]")
					}

					wl.Lock()

					writeerr := resetEvent(wo.HEvent)
					if  writeerr == nil {
						var n uint32 = uint32( wcount)
						writeerr = syscall.WriteFile( handle, dout, &n, wo)
						count = int( n)
						if writeerr == syscall.ERROR_IO_PENDING {
							for i := 0; i < 10; i++ {
								count, writeerr = getOverlappedResult(handle, wo)
								if count != wcount {
									fmt.Printf( "Serial port write erro3 %d %s %v %v %v\n", i,  writeerr, writeerr, count, wcount)
								} else {
									break
								}
								time.Sleep( 10)
							}
						}
					}
					wl.Unlock()
					if count != wcount {
						fmt.Printf( "Serial port write error1 %s %v %v %v\n", writeerr, writeerr, count, wcount)
					}
						
				}
			}
		}()

		chQuitDTR := make( chan bool)
		go func() {
			for q := false; q == false; {
				select {
				case q = <- chQuitDTR:
				case dtr := <-chDTRSerial:
					if dtr {
						escapeCommFunction( handle, 5)
					} else {
						escapeCommFunction( handle, 6)
					}
				}
			}
		}()
		
		go func() {
			<- chQuitSerial
			serFile.Close()
			chQuitFrom <- true
			chQuitTo <- true
			chQuitDTR <- true
		}()
	}

	return chFromSerial, chToSerial, chDTRSerial, chQuitSerial, err
}

var (
	nSetCommState,
	nEscapeCommFunction,
	nSetCommTimeouts,
	nSetCommMask,
	nSetupComm,
	nGetOverlappedResult,
	nCreateEvent,
	nResetEvent uintptr
)

func init() {
	handle, err := syscall.LoadLibrary("kernel32.dll")
	if err == nil {
		nSetCommState = getProcAddr(handle, "SetCommState")
		nEscapeCommFunction = getProcAddr(handle, "EscapeCommFunction")
		nSetCommTimeouts = getProcAddr(handle, "SetCommTimeouts")
		nSetCommMask = getProcAddr(handle, "SetCommMask")
		nSetupComm = getProcAddr(handle, "SetupComm")
		nGetOverlappedResult = getProcAddr(handle, "GetOverlappedResult")
		nCreateEvent = getProcAddr(handle, "CreateEventW")
		nResetEvent = getProcAddr(handle, "ResetEvent")
		syscall.FreeLibrary(handle)
	} else {
		panic("LoadLibrary " + err.Error())
	}
}

func getProcAddr(handle syscall.Handle, name string) uintptr {
	addr, err := syscall.GetProcAddress(handle, name)
	if err != nil {
		panic(name + " " + err.Error())
	}
	return addr
}

func escapeCommFunction(handle syscall.Handle, fparam int) error {
	r, _, err := syscall.Syscall(nEscapeCommFunction, 2, uintptr(handle), uintptr(fparam), 0)
	if r == 0 {
		return err
	}
	return nil
}

func setCommState(handle syscall.Handle, baud int) error {
	var params structDCB
	params.DCBlength = uint32(unsafe.Sizeof(params))
	params.flags[0] = 0x01 // fBinary
	params.BaudRate = uint32(baud)
	params.ByteSize = 8
	r, _, err := syscall.Syscall(nSetCommState, 2, uintptr(handle), uintptr(unsafe.Pointer(&params)), 0)
	if r == 0 {
		return err
	}
	return nil
}
//
// timeout set to be as short as possible
//
func setCommTimeouts(handle syscall.Handle) error {
	var timeouts structTimeouts
	const MAXDWORD = 1<<32 - 1
	timeouts.ReadIntervalTimeout = MAXDWORD
	timeouts.ReadTotalTimeoutMultiplier = 0
	timeouts.ReadTotalTimeoutConstant = 0
	timeouts.WriteTotalTimeoutMultiplier = 1
	timeouts.WriteTotalTimeoutConstant = 1
	r, _, err := syscall.Syscall(nSetCommTimeouts, 2, uintptr(handle), uintptr(unsafe.Pointer(&timeouts)), 0)
	if r == 0 {
		return err
	}
	return nil
}

func setupComm(handle syscall.Handle, in, out int) error {
	r, _, err := syscall.Syscall(nSetupComm, 3, uintptr(handle), uintptr(in), uintptr(out))
	if r == 0 {
		return err
	}
	return nil
}

func setCommMask(handle syscall.Handle) error {
	const EV_RXCHAR = 0x0001
	r, _, err := syscall.Syscall(nSetCommMask, 2, uintptr(handle), EV_RXCHAR, 0)
	if r == 0 {
		return err
	}
	return nil
}

func resetEvent(handle syscall.Handle) error {
	r, _, err := syscall.Syscall(nResetEvent, 1, uintptr(handle), 0, 0)
	if r == 0 {
		return err
	}
	return nil
}

func newOverlapped() (*syscall.Overlapped, error) {
	var overlapped syscall.Overlapped
	r, _, err := syscall.Syscall6(nCreateEvent, 4, 0, 1, 0, 0, 0, 0)
	if r == 0 {
		return nil, err
	}
	overlapped.HEvent = syscall.Handle(r)
	return &overlapped, nil
}

func getOverlappedResult(handle syscall.Handle, overlapped *syscall.Overlapped) (int, error) {
	var n int
	r, _, err := syscall.Syscall6(nGetOverlappedResult, 4,
	uintptr(handle),
	uintptr(unsafe.Pointer(overlapped)),
	uintptr(unsafe.Pointer(&n)), 1, 0, 0)
	if r == 0 {
		return n, err
	}
	return n, nil
}



