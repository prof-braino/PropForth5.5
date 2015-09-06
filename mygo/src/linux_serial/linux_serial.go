package serial
// Serial io as raw as possible. 8 bits, no parity 1 stop bit, channel to provide DTR control
//
// comName := "/dev/ttyS1" 
// baudRate := 57600
// debug := false
//
// chanFromSerial, chanToSerial, charDTRSerial, chanQuitSerial, err := SerialChannels( comName, baud, debug)
//
// chanFromSerial = byte data channel from serial
// chanToSerial - byte data channel to serial 
// chanDTRSerial - bool channel to comtrol DTR - logical 1 means DTR active - rs232 level - +3-+15 volts 
// chanQuitSerial - send a bit on this channel to terminate
//
// based on http://code.google.com/p/goserial/
//
// Works with go version 1, tested on Ubuntu 12.04 (64-bit) running on VMworkstation

// #include <termios.h>
// #include <unistd.h>
// #include <sys/ioctl.h>
// #include <fcntl.h>
import "C"

import (
	"errors"
	"fmt"
	"os"
	"syscall"
	"time"
	"unsafe"
)

func SerialChannels( name string, baud int, debug bool) (chan byte, chan byte, chan bool, chan bool, error) {
	var err error
	var serFile *os.File
	var chFromSerial, chToSerial chan byte
	var chDTRSerial, chQuitSerial chan bool
	

        serFile, err = os.OpenFile(name, os.O_RDWR | syscall.O_NOCTTY | syscall.O_NONBLOCK, 0666)
	if  err == nil {

		fd := C.int(serFile.Fd())
		var st C.struct_termios

		_, err = C.tcgetattr(fd, &st)
		if err == nil {
			if C.isatty(fd) != 1 {
				err = errors.New( "Not a tty")
			}
		}

		var speed C.speed_t

		if err == nil {
			switch baud {
			case 230400:
				speed = C.B230400
			case 115200:
				speed = C.B115200
			case 57600:
				speed = C.B57600

			case 19200:
				speed = C.B19200
				
			case 9600:
				speed = C.B9600
				
			default:
				err = errors.New("Invalid baud rate")
			}
		}


		if err == nil {
			_, err = C.cfsetispeed(&st, speed)
			if err == nil {
				_, err = C.cfsetospeed(&st, speed)
			}
		}
	
		if err == nil {
			C.cfmakeraw(&st)
			_, err = C.tcsetattr(fd, C.TCSANOW, &st)
		}

		if err == nil {
			chFromSerial = make( chan byte, 8192)
			chQuitFrom := make( chan bool)
			go func() {
				datain := make( []byte, 1)
				for q := false; q == false ; {
					count, _ := serFile.Read( datain)
					for i := 0 ; i < count; i++ {
						if debug {
							if datain[i] == byte(0x0D) {
								fmt.Print("(\n)")
							} else {
								fmt.Printf("(%02X)", datain[i])
							}
						}
						chFromSerial <- datain[i]
					}
					select {
  					case q = <-chQuitFrom:
					default:
					}
					time.Sleep( 10)
				}
			}()
			
			chToSerial = make( chan byte, 8192)
			chQuitTo := make( chan bool)
			go func() {
				dataout := make( []byte, 1)
				for q := false; q == false; {
					dataout[ 0] = <- chToSerial
					if debug {
						if dataout[0] == byte(0x0D) {
							fmt.Print("[\n]")
						} else {
							fmt.Printf("[%c]", dataout[0])
						}
					}
					scount, serr := serFile.Write( dataout)
					if scount != 1 || serr != nil {
						fmt.Printf( "SERIAL ERROR: write error [%d][%s]\n", scount, serr)
					}
				}
			}()

			chDTRSerial = make( chan bool)
			chQuitDTR := make( chan bool)
			go func() {
				var param uint
				var ep syscall.Errno
				for q := false; q == false; {
					select {
					case q = <- chQuitDTR:
					case dtr := <-chDTRSerial:
						param = syscall.TIOCM_DTR
						if dtr {
							_, _, ep = syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd), syscall.TIOCMBIS, uintptr(unsafe.Pointer(&param)))
						} else {
							_, _, ep = syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd), syscall.TIOCMBIC, uintptr(unsafe.Pointer(&param)))
						}
						if ep != 0 {
							fmt.Printf( "SERIAL ERROR: DTR  error [%d]\n", ep)
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
	}

	return chFromSerial, chToSerial, chDTRSerial, chQuitSerial, err
}

