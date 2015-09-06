package rpiGPIO

import "errors"
import "fmt"
import "os"
import "time"
import "unsafe"


// #include <stdio.h>
// #include <stdlib.h>
// #include <sys/mman.h>
import "C"

var gpioRegBase uintptr
var gpioSet *uint
var gpioClear *uint
var gpioLevel *uint
var InitErr error

func init() {
        mfile, err := os.OpenFile("/dev/mem", os.O_RDWR |os.O_SYNC, 0666)
	if  err == nil {
		fd := C.int(mfile.Fd())
		gpiomem := C.malloc(8191)
		if gpiomem == nil {
			err = errors.New( "init: malloc failed")
		}

		if  err == nil {
			up := uintptr( gpiomem)
			if up % 4096 != 0 {
				up = up + 4096 - (up % 4096)
			}
			np := unsafe.Pointer( up)
			gmap := C.mmap( np, 4096, C.PROT_READ | C.PROT_WRITE, C.MAP_SHARED |C.MAP_FIXED, fd, 0x20000000 + 0x200000)
			gpioRegBase = uintptr( gmap)
			if -1 == int(gpioRegBase) {
				err = errors.New( "init: mmap failed")
			}

			if err == nil {
				gps := gpioRegBase + 0x1C
				gpc := gpioRegBase + 0x28
				gpl := gpioRegBase + 0x34
				gpioSet = (*uint)(unsafe.Pointer(gps))
				gpioClear = (*uint)(unsafe.Pointer(gpc))
				gpioLevel = (*uint)(unsafe.Pointer(gpl))
			}
		}
	}
}


var IOpins = []uint{  0, 1, 4, 7, 8, 9,10,11,18,21,22,23,24,25}
var COGpins = []uint{ 8, 9,10,12,13,14,15,16,17,18,19,20,21,22}

var IOtoCOG = map[uint]uint{ 0:8, 1:9, 4:10, 7:22, 8:21, 9:19, 10:17, 11:20, 18:12, 21:13, 22:14, 23:15, 24:16, 25:18}
var COGtoIO = map[uint]uint{ 8:0, 9:1, 10:4, 22:7, 21:8, 19:9, 17:10, 20:11, 12:18, 13:21, 14:22, 15:23, 16:24, 18:25}

func IOSet( pin uint) {
	*gpioSet = uint(1) << pin
}
func CogSet( pin uint) {
	p , ok := COGtoIO[ pin]
	if ok {
		*gpioSet = uint(1) << p
	}
}
func IOGet( pin uint) bool {
	return ((*gpioLevel) & (uint(1) << pin)) != 0
}
func CogGet( pin uint) bool {
	rc := false
	p , ok := COGtoIO[ pin]
	if ok {
		rc = ((*gpioLevel) & (uint(1) << p)) != 0
	}
	return rc
}

func CogReset() {
	IOWriteFsel( 17 , 1)
	IOClear(17)
	time.Sleep( 1e6)
	IOSet(17)
}

func IOClear( pin uint) {
	*gpioClear = uint(1) << pin
}
func CogClear( pin uint) {
	p , ok := COGtoIO[ pin]
	if ok {
		*gpioClear = uint(1) << p
	}
}

func IOReadReg( offset uint) uint {
	a := gpioRegBase + uintptr(offset)
	addr := (*uint)(unsafe.Pointer(a))
	return *addr
}
func IOReadFsel( pin uint) int {
	if pin < 54 {
		offset := 4 *( pin / 10)
		shift := 3 * (pin % 10)
		return (int(IOReadReg( offset)) >> shift) & 7
	}
	return -1
}

func IOWriteFsel( pin uint, fsel uint) {
	if pin < 54 {
		offset := 4 *( pin / 10)
		shift := 3 * (pin % 10)
		a := gpioRegBase + uintptr(offset)
		addr := (*uint)(unsafe.Pointer(a))
		*addr = (*addr) & (0xFFFFFFFF &^ (7 << shift))
		*addr = (*addr) | (fsel << shift)
	}
}

func IODumpReg( offset uint) {
	fmt.Printf( "%04X: %08X\n", offset, IOReadReg(offset))
}

func IODump() {
	for i:=uint(0); i < 0x18; i +=4 {
		IODumpReg( i)
	}
	fmt.Printf( "\n")
	for i:=uint(0x34); i < 0x3C; i +=4 {
		IODumpReg( i)
	}
	fmt.Printf( "\nFSEL:\n")
	for i:=uint(0); i < 54; i++ {
		fmt.Printf( "%02d: %d ", i, IOReadFsel( i))
		if ((i +1) %10) == 0 {
			fmt.Printf( "\n")
		}
	}
	fmt.Printf( "\n")

}
