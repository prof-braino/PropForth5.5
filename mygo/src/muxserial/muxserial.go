package muxserial
import (
	"errors"
	"fmt"
	"serial"
	"time"
)

const TOTAL_COG_BUFFER_SIZE = 1024

const MAX_ALLOWABLE_PACKET_SIZE = 256

type indexData struct {
	index byte
	count int
	data [MAX_ALLOWABLE_PACKET_SIZE]byte
}

type muxChannel struct {
// when data is sent to the mux an ack will come back on this channel
	ackMuxToData chan bool
// data comes in from the mux on this channel
	fromMux chan indexData
// connection to the client
	fromClient chan byte
	toClient chan byte
// for termination
	quitGO_C chan bool
	quitGO_D chan bool
// whether or not this channel is connected
	connected bool
}

type MuxSerialStruct struct {
	alive bool
	debug bool
	maxPacketSize int
	numMuxChannels int
	fromSerial chan byte
	toSerial chan byte
	quitSerial chan bool
	dtrSerial chan bool
	quitGO_A chan bool
	quitGO_B chan bool
	mux []*muxChannel
}

func MuxSerialChannels( name string, baud int, numChannels int, debug bool) (*MuxSerialStruct, error) {
	var r = new( MuxSerialStruct)
	var err error
	var lshift uint
	
	r.debug = debug

	if numChannels <= 8 {
		lshift = 6
		r.numMuxChannels = 8
	} else if numChannels <= 16 {
		lshift = 5
		r.numMuxChannels = 16
	} else {
		lshift = 4
		r.numMuxChannels = 32
	}

	r.maxPacketSize = 1 << lshift

	r.mux = make([]*muxChannel, r.numMuxChannels)
	for i := 0; i < r.numMuxChannels; i++ {
		r.mux[i] = new(muxChannel)
		r.mux[i].ackMuxToData = make(chan bool,1)
		r.mux[i].fromMux = make(chan indexData,1)
		r.mux[i].fromClient = make(chan byte, 4096)
		r.mux[i].toClient = make(chan byte, 4096)
		r.mux[i].quitGO_C = make(chan bool)
		r.mux[i].quitGO_D = make(chan bool)
		r.mux[i].connected = false
	}
	
	r.fromSerial, r.toSerial, r.dtrSerial, r.quitSerial, err = serial.SerialChannels( name, baud, debug)
	if err != nil {
		return nil, err
	}


	forthConstDef := fmt.Sprintf("d_%d wconstant _MX_BSHIFT\nd_%d wconstant _MX_BSIZE\nd_%d wconstant _MX_BMASK\nd_%d wconstant _MX_NUM_CHAN\nd_%d wconstant _MX_BUF_OFFSET\n\n",
		lshift, r.maxPacketSize, r.maxPacketSize-1, r.numMuxChannels, 4*r.numMuxChannels)

	for retryCount, syncok := 1, false; syncok == false; retryCount++ {
		if retryCount > 5 {
			return nil, errors.New("Propeller not initializing MX")
		}
// to reset the prop
		fmt.Printf("\nRebooting propeller, try %d\n", retryCount)
		r.dtrSerial <- false
		time.Sleep( 1e8)
		r.dtrSerial <- true
		time.Sleep( 1e8)
		r.dtrSerial <- false
// give the prop time to reboot
		time.Sleep(2e9)
		r.flush()

		fmt.Printf("Sending constant definitions:\n\n%s", forthConstDef)
		r.sendString( forthConstDef)
		r.flush()

		fmt.Print("Sending code...\n")
		r.sendString( scode)
		r.flush()

		fmt.Print("Sending start command... Waiting for sync\n")
		r.sendString( "gos\r")
		syncok = r.sync()
	}
	fmt.Print("Starting serial multiplexer\n")

	r.startMux()

	return r,nil
}


func (m *MuxSerialStruct) NumMuxChannels( ) int {
	return m.numMuxChannels
}

func (m *MuxSerialStruct) sendString(str string) {
	if m.alive == false {
		for _, c := range(str) {
			if c == '\n' {
				c = '\r'
			}
			m.toSerial <- byte(c)
		}
	}
	return
}
func (m *MuxSerialStruct) flush( ) {
	if m.alive == false {
		for q := false ; q == false; {
			select {
			case <- m.fromSerial:
			case <- time.After( 500e6):
				q = true
			}
		}
	}
	return
}

func (m *MuxSerialStruct) sync( )bool {
	if m.alive == true {
		return false
	}
	syncok := false
	for q := false ; q == false; {
		select {
		case  ch := <- m.fromSerial:
			if ch == byte(0x21) {
				syncok = true
				q = true
				m.toSerial <- byte(0x21)
			}

		case <- time.After( 1000e6):
			q = true
		}
	}
	return syncok
}

func (m *MuxSerialStruct) IsClientConnected(index int) bool {
	return m.mux[index].connected && m.alive
}
func (m *MuxSerialStruct) ClientConnect(index int) ( chan byte, chan byte, chan bool, error) {
	if m.alive {
		if m.mux[index].connected == false {
			m.mux[index].connected = true
			md := make( chan bool)
			go func() {
				<- md
				m.mux[index].connected = false
			}()
			return m.mux[index].fromClient, m.mux[index].toClient, md,  nil
		} else {
			return nil, nil, nil, errors.New("Client Channel in use")
		}
	}
	return nil, nil, nil, errors.New("MuxSerialChannel not alive")
}
func (m *MuxSerialStruct) Close( ) ( ) {
	select {
	case m.quitSerial <- true:
	default:
	}
	select {
	case m.quitGO_A <- true:
	default:
	}
	select {
	case m.quitGO_B <- true:
	default:
	}
	for _,mx := range( m.mux) {
		select {
		case mx.quitGO_C <- true:
		default:
		}
		select {
		case mx.quitGO_D <- true:
		default:
		}
	}
	return
}


func (r *MuxSerialStruct) startMux( ) {
	r.alive = true
//
// all data from the individual mux channels comes here
//
	muxToData := make(chan indexData,32)
//
// all acks from the indidual channels come in here
//
	ackMuxFromData := make(chan byte,32)

/*
                     _____________                                       _______________________
chFromSerial-byte-->|             |------>mux[i].fromMux-indexData----->|                       |>---->mux[i].toClient-byte---->
                    |             |                                   |<|                       |
                    |   GO_B      |<------quitGO_B-bool--<            | |  GO_D 4-32 instances  |<-----quitGO_D[i]
                    |             |                                   | |                       |
                    |_____________|------>mux[i].ackMuxToData-bool-|  | |_______________________|
                                                                   |  |
                                                                   |  |
                                                                   |  |
                                                                   |  |
                                                                   |  |
                     _____________                                 |  |    _______________________
chToSerial<-byte---<|             |<------muxToData-indexData<--|  |--|->|                       |<-----mux[i].fromClient-byte--<
                    |             |                             |-----|-<|                       |
                    |   GO_A      |<------quitGO_A-bool--<            |  |  GO_C 4-32 instances  |<-----quitGO_C[i]
                    |             |                                   |  |                       |
                    |_____________|<------ackMuxFromData-byte---------|  |_______________________|



                           

*/
//
// The multiplexer which sends data to the serial channel 
// each channel sends data here, and the packets are constructed
// and sent sequentially to the serial channel
//
// GO_A
//
	go func() {
		for quit := false; quit == false; {
			select {
			case t := <- muxToData:
				if r.debug {
					fmt.Printf("\n\t\t\tGO_A>[[%02X %02X]]", t.index, t.count)
				}
				r.toSerial <- t.index + 0x60
				data := t.data[:t.count]
				r.toSerial <- byte(t.count + 0x20 )
				for _,c := range(data) {
					r.toSerial <- c
				}
				if r.debug {
					fmt.Printf("\n\t\t\t<GO_A[[%02X %02X]]", t.index, t.count)
				}
			case i := <- ackMuxFromData:
				if r.debug {
					fmt.Printf("\n\t\t\tGO_A>[[%02X ACK]]", i)
				}
				r.toSerial <- i + byte(0x40)
				if r.debug {
					fmt.Printf("\n\t\t\t<GO_A[[%02X ACK]]", i)
				}
			case quit = <- r.quitGO_A:
			}
		}
	}()

//
// The multiplexer which receives from the serial channel, and distributes data to the 
// individual multiplexer channels
//
// GO_B
//
	go func() {
		var t indexData
		for quit := false; quit == false; {
			select {
			case chin := <- r.fromSerial:
				if chin >= byte(0x40) && chin < byte(0x40 + r.numMuxChannels) {
					if r.debug {
						fmt.Printf("\n\t\tGO_B((%02X ACK))>", chin - byte(0x40))
					}
					r.mux[chin - byte(0x40)].ackMuxToData <- true
					if r.debug {
						fmt.Printf("\n\t\t<GO_B((%02X ACK))", chin - byte(0x40))
					}
				} else if chin >= byte(0x60) && chin < byte( 0x60 + r.numMuxChannels) {
					t.index = chin - byte(0x60)
					ch := <- r.fromSerial
					t.count = int(ch) - 0x20
					if r.debug {
						fmt.Printf("\n\t\tGO_B((%02X %02X))>", t.index, t.count)
					}
					for i := 0; i < t.count; i++ {
						t.data[i] =  <- r.fromSerial
					}
					if r.debug {
						fmt.Printf("\n\t\tGO_B((%02X %02X))-", t.index, t.count)
					}
					r.mux[t.index].fromMux <- t
					if r.debug {
						fmt.Printf("\n\t\t<GO_B((%02X %02X))", t.index, t.count)
					}
				}
			case quit = <-r.quitGO_B:
			}
		}
	}()



	for idx := 0; idx < r.numMuxChannels; idx++ {
//
// The individual multiplexer channels which route data from the client to the mux
//
// GO_C
//
		go func( i int, m *muxChannel  ) {
			var t indexData
			t.index = byte(i)
			for quit := false; quit == false; {
				t.count = 1
				select {
				case t.data[0] = <- m.fromClient:
					mn := r.maxPacketSize - 1
					for q := false; t.count < mn && q == false; t.count++ {
						select {
						case t.data[ t.count] = <- m.fromClient:
						default:
							t.count--
							q = true
						}
					}
//					then := time.Now()
					if r.debug {
						fmt.Printf("\n\t\t\t\t\t\t\tGO_C>[[[%02X %02X]]]", t.index, t.count)
					}
/*
					now := time.Now()
					fmt.Printf("\n\t\t\t\t\t\t\tGO_C>[%v[[%02X %02X]]]", now.Sub(then), t.index, t.count)
					then = now
*/
					muxToData <- t
/*
					now = time.Now()
					fmt.Printf("\n\t\t\t\t\t\t\tGO_C-[%v[[%02X %02X]]]", now.Sub(then), t.index, t.count)
					then = now
*/
					if r.debug {
						fmt.Printf("\n\t\t\t\t\t\t\tGO_C-[[[%02X %02X]]]", t.index, t.count)
					}
					<-m.ackMuxToData
/*
					now = time.Now()
					fmt.Printf("\n\t\t\t\t\t\t\t<GO_C[%v[[%02X %02X]]]", now.Sub(then), t.index, t.count)
					then = now
*/
					if r.debug {
						fmt.Printf("\n\t\t\t\t\t\t\t<GO_C[[[%02X ACK]]]", t.index)
					}

				case quit = <- m.quitGO_C:
				}
			}
		}(idx,r.mux[idx])
//
// The individual multiplexer channels which route data from the mux to the client
//
// GO_D
//
		go func(m *muxChannel) {
			for quit := false; quit == false; {
				select {
				case t := <- m.fromMux:
					if r.debug {
						fmt.Printf("\n\t\t\t\t\t\tGO_D>(((%02X %02X)))", t.index, t.count)
					}
					for _,c := range(t.data[:t.count]) {
						m.toClient <- c
					}
					if r.debug {
						fmt.Printf("\n\t\t\t\t\t\tGO_D-(((%02X %02X)))", t.index, t.count)
					}
					ackMuxFromData <- t.index
					if r.debug {
						fmt.Printf("\n\t\t\t\t\t\t<GO_D(((%02X ACK)))", t.index)
					}
				case quit = <- m.quitGO_D:
				}
			}
		}(r.mux[idx])
	}
	r.alive = true
	return
}
