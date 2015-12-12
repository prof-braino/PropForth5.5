\
\ the boot file for the build system
\

fl

fswrite boot.f

[ifndef rcogx
\ rcogx ( cstr cog channel -- ) send cstr to the cog/channel
: rcogx
	io 2+ W@
\ ( cstr cog channel oldio+2 -- )
	rot cogio
\ ( cstr channel oldio+2 cogio -- )
	rot 4* +
\ ( cstr oldio+2 chaddr -- )
	io 2+ W!
\ ( cstr oldio+2 -- )
	swap .cstr cr
	io 2+ W!
;
]

[ifndef build_sdfs
: rfsend
	2drop ." NO~h0D"
;
]

[ifndef rfsend
\ rfsend filename ( cog channel -- )
: rfsend
	4* swap cogio +
	_sd_fsp dup
	if
\ ( chaddr fname -- )
		io 2+ W@
\ ( chaddr fname oldio+2 -- )
		rot io 2+ W!
\ ( fname oldio+2 -- )
		swap
		sd_read
		io 2+ W!
	else
		2drop _fnf
	then
;
]





[ifndef term
: term
	over cognchan min ." Hit CTL-P to exit term, CTL-Q exit nest1 CTL-R exit nest2 ... CTL-exit nest9~h0D~h0A"
	>r >r cogid 0 r> r> (iolink)
	begin
		key dup h10 =
		if
			drop -1
		else
			dup h11 h19 between
			if
				1-
			then
			emit 0
		then
	until
	cogid iounlink
;
]

\ sersetflags ( n2 n1 -- O ) for the serial driver running on cog n1, set the flags to n2
[ifndef sersetflags
: sersetflags
	cogio hC8 + L!
;
]
\
\ invert ( n1 -- n2 ) bitwise invert n1
[ifndef invert
: invert
	-1 xor
;
]
\
\ pinin ( n1 -- ) set pin # n1 to an input
[ifndef pinin
: pinin
	>m invert dira COG@ and dira COG!
;
]
\
\
\ pinout ( n1 -- ) set pin # n1 to an output
[ifndef pinout
: pinout
	>m dira COG@ or dira COG!
;
]
\
\ pinlo ( n1 -- ) set pin # n1 to lo
[ifndef pinlo
: pinlo
	>m _maskoutlo
;
]
\
\
\ pinhi ( n1 -- ) set pin # n1 to hi
[ifndef pinhi
: pinhi
	>m _maskouthi
;
]
\
\
\
\ _snet ( -- ) load the serial driver, and start it on cog 4
[ifndef _snet
: _snet
	4 cogreset
	h10 delms
	c" hD hC hE100 serial" 4 cogx
	h100 delms
	1 4 sersetflags 
	1 7 sersetflags 
;
]
\
\
\ snet ( -- ) reset the spinnret board, start a serial driver, and connect a terminal
[ifndef snet
: snet
	_snet hE dup pinlo dup pinout 1 delms dup pinhi pinin
	h10 delms h4 0 term 0 7 sersetflags
;
]
\
\ resnet ( -- ) start a serial driver and connect a terminal to the spinneret board
[ifndef resnet
: resnet
	_snet h10 delms h4 0 term 0 7 sersetflags
;
]
\
\
\ nsnet ( n1 -- ) start a serial driver, send n1 characters
[ifndef nsnet
: nsnet
	h10 delms
	cogid 0 4 0 (iolink)
	0
	do
		key emit
	loop
	cogid iounlink
;
]


1 wconstant build_norom

\
\ An eeprom free boot for the slave, the master prop emulates the eeprom
\ and sends it's eeprom image, or a ram image
\
\
\ Status: working - Beta
\
\
\ Prototype - the master is a propeller protoboard @ 5 MHZ with a 64kx8 rom
\ (should be ok with a demo board and 32kx8 eeprom
\
\ add a prop chip, used a 40 pin dip
\ ran power and ground 2 0.1 uF caps between the power and ground pins, close to the chip
\
\ 10k pullup resistor on  IO 29 - the pin normally hookup up to sda on the eeprom
\
\ Protoboard			Prop Chip	
\ IO 8 	-> 220 ohm resistor 	-> IO 28 (this pin normally hooks up to scl on the eeprom)
\ IO 9 	-> 220 ohm resistor 	-> IO 29 (this pin normally hooks up to sda on the eeprom, 10k pullup resistor as well)
\ IO 10	->			-> RESET
\ IO 11 ->			-> XI

\ this is a serial port connection so we can talk to PropForth on the Prop Chip
\
\ IO 0	->			-> IO 30
\ IO 1	->			-> IO 31
\
\
\ PLAB0 configuration
\
\ 10k pullup resistor on  IO 29 - the pin normally hookup up to sda on the eeprom
\
\ Spinneret			Prop Chip	
\ IO 26 ->			-> IO 28 (this pin normally hooks up to scl on the eeprom)
\ IO 27	->			-> IO 29 (this pin normally hooks up to sda on the eeprom, 10k pullup resistor as well)
\ IO 24	->			-> RESET
\ IO 25 ->			-> XI
\
\ 26 27 24 25 rambootnx
\
\

\ a cog special register
[ifndef ctra
h1F8	wconstant ctra 
]

\ a cog special register
[ifndef ctrb
h1F9	wconstant ctrb 
]

\ a cog special register
[ifndef frqa
h1FA	wconstant frqa 
]

\ a cog special register
[ifndef frqb
h1FB	wconstant frqb 
]


\ a cog special register
[ifndef phsa
h1FC	wconstant phsa 
]

\ a cog special register
[ifndef phsb
h1FD	wconstant phsb 
]
[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]
\
\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[ifndef variable
: variable
	lockdict create $C_a_dovarl w, 0 l, forthentry freedict ;
]
\
\ invert ( n1 -- n2 ) bitwise invert n1
[ifndef invert
: invert
	-1 xor
;
]
\
\
\ pinin ( n1 -- ) set pin # n1 to an input
[ifndef pinin
: pinin
	>m invert dira COG@ and dira COG!
;
]
\
\
\ pinout ( n1 -- ) set pin # n1 to an output
[ifndef pinout
: pinout
	>m dira COG@ or dira COG!
;
]
\
\
\ pinlo ( n1 -- ) set pin # n1 to lo
[ifndef pinlo
: pinlo
	>m _maskoutlo
;
]
\
\
\ pinhi ( n1 -- ) set pin # n1 to hi
[ifndef pinhi
: pinhi
	>m _maskouthi
;
]

\
\ abs ( n1 -- abs_n1 ) absolute value of n1
[ifndef abs
: abs
	_xasm1>1 h151 _cnip
;
]


\
\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[ifndef waitcnt
: waitcnt
	_xasm2>1 h1F1 _cnip
;
]

\ _cfo ( n1 -- n2 ) n1 - desired frequency, n2 freq a 
[ifndef _cfo
: _cfo
	clkfreq 1- min 0 swap clkfreq um/mod swap clkfreq 2/ >= abs +
;
]

\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[ifndef u*/mod
: u*/mod
	rot2 um* rot um/mod
;
]

\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[ifndef u*/
: u*/
	rot2 um* rot um/mod nip
;
]

\ setHza ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctra
\ set the pin oscillating at the specified frequency
[ifndef setHza
: setHza
	_cfo frqa COG! dup pinout h10000000 + ctra COG!
;
]

\ qHzb ( n1 n2 -- n3 ) n1 - the pin, n2 - the # of msec to sample, n3 the frequency
[ifndef qHzb
: qHzb
	swap h28000000 + 1 frqb COG! ctrb COG!
	h3000 min clkfreq over h3E8 u*/ 310 -
	phsb COG@ swap cnt COG@ + 0 waitcnt
	phsb COG@ nip swap - h3E8 rot u*/
;
]

\ setHzb ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctrb
\ set the pin oscillating at the specified frequency
[ifndef setHzb
: setHzb
	_cfo frqb COG! dup pinout h10000000 + ctrb COG!
;
]

\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[ifndef term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup h6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]


lockdict create a_ram forthentry
$C_a_lxasm w, h142  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z2WiZBB l, z1SyLI[ l, z2WiZ3B l, z1SyLI[ l, z1SV04c l, 0 l, 0 l, z800 l,
z3jFZ4O l, z3jFZCP l, z3nFZCP l, z3nFZ4O l, z1SV000 l, z2WyQ88 l, z3jFZ4O l, z3nFZ4O l,
z3[yQCX l, z1bixnP l, z3jFZ4O l, z3nFZ4O l, z1[ixnP l, z1SV000 l, z1[ixnO l, z1[ixnP l,
z1[ix[P l, z1SyZvR l, z1Sy\4W l, z1Sy\4W l, z1Sy\4W l, z1SyZvR l, z1Sy\4W l, z2WiQCQ l,
z2WyPW0 l, ziPeC l, z20yPW1 l, z2WyQ08 l, z1XVPd0 l, zfyPb1 l, z1nixnP l, z3jFZ4O l,
z3nFZ4O l, z3[yQ4q l, z1[ixnP l, z3jFZ4O l, z3nFZ4O l, z3[yQCn l, z1SV01X l,
freedict


wvariable (rb04s) 0 (rb04s) W!






\ ramboot ( n1 n2 n3 -- ) n1 - the pin connected to the slave sclk, n2 - the pin connected to the slave sda,
\  n3 the pin connected to the slave reset, boot the slave and load it with and image of our ram
: ramboot
	dup pinlo dup pinout 1 delms dup pinhi pinin
\ ( slaveclk slavesda -- )
	over >m swap >m
\ ( slaveclk slaveclkmask slavesdamask  -- )
	a_ram
\ ( slaveclk -- ) send a signal on pin slaveclk indicating we are the master
	dup h97000 setHza h800 delms 0 ctra COG! pinin
;

\ rambootnx ( n1 n2 n3 n4 -- )  n1 - the pin connected to the slave sclk, n2 - the pin connected to the slave sda,
\  n3 the pin connected to the slave reset, n4 is the pin to use as a clock output
\ boot the slave and load it with and image of our ram
: rambootnx
\ set the clkmode to pll16 xin, if someone else has not already
	lockdict (rb04s) 1+ dup C@ dup 1+ rot C! 0=
	if
		h4 C@ (rb04s) C!
		h67 4 C!
	then
	freedict
\ set the clock out to be our clock / 16
	0 L@ h4 rshift setHzb
\ boot from ram
	ramboot
\ reset the clkmode to pll16 xin, if someone else has not already
	lockdict (rb04s) 1+ dup C@ 1- dup rot C! 0=
	if
		(rb04s) C@ h4 C!
	then
freedict
;


: onboot
	$S_con iodis
	$S_con cogreset
	h10 delms
	c" initcon" $S_con cogx
	h100 delms
	cogid >con
	8 0
	do
		i cogid <>
		i $S_con <> and
		if
			i cogreset
		then
	loop

\ get rid of any error code on the stack, not valid
	drop 0 
	h40 0
	do
		h1C 1 qHzb h90000 hA0000 between
		if
			1 _finit andnC! leave
		then
	loop
;



\
\
1 wconstant build_mcs
\ 1 wconstant mcs_dbg
\
\
\ Copyright (c) 2010 Sal Sanci
\
\ A synchronous  multi channel communication protocol between 2 props
\ only using 2 pins. Provide 8 full duplex I/O channels which can easily connect to forth io
\
\ Status: working - Beta
\
\ wire 2 pins from the master cog to the slave cog, they can be different pins
\ the pin defined as master pin on the master, must be connected to the the pin defined as master pin on the slave
\ the pin defined as slave  pin on the master, must be connected to the the pin defined as slave  pin on the slave
\ the reset pin is irrelevant for the communication, but is part of the structure, define as FF if unused
\
\ One cog on each propeller is used to drive the communication.
\
\ BOTH PROPS MUST BE AT THE SAME CLOCK SPEED
\
\ so assuming:
\	masterprop:	pin 14 - master pin (pin 20 in decimal)
\			pin 15 - slave pin  (pin 21 in decimal)
\	slaveprop:	pin 14 - master pin
\			pin 15 - slave pin
\
\ wire pin 14 of the master to pin 14 of the slave
\ wire pin 15 of the master to pin 15 of the slave
\ series resistor of 200 - 400 ohms are optional, they will prevent a short in case of software misconfiguration
\
\
\ SINGLE PROP EXAMPLE - because of a beautiful architecture the prop, you can run both channels on on prop chip
\ as a matter of fact, the code was developed and debugged this way, and can use LogicAnalyzer to look at the signals.
\ Hooking up 2 chips, it then worked without fuss.
\
\ The big differences we start a master cog and a slave cog running on one chip. For this example we will use 
\ cog 0 as the master cog and cog 5 as the slave cog
\
\
\ load this file, make sure you are connected to cog 6
\
\ If you want to use LogicAnalyzer to look at the signals
\
\ Load LogicAnalyzer then load this file
\
\ Define the 2 following routines or uncomment _mcs_dbg and use the test program to get stats/speed
{

fl

: mcsinit
	c" h14 h15 hFF h3 mcsmaster" h4 cogx
	c" h14 h15 hFF h3 mcsslave" h5 cogx
	h100 delms
	0  0 h5 0  (ioconn)
	1  0 h5 1  (ioconn)
	h2 0 h5 h2 (ioconn) ;


: mcs? h4 cogio dup mcscnt L@ . mcserr L@ . h5 cogio dup mcscnt L@ . mcserr L@ . cr ;



}
\
\ This starts up cog 5 as the slave mcs cog, and connects cogs 0 - 2 to the slave cog
\ The master cog starts on cog 4, and connects to the master cog via pins 14 and 15
\
\ type:
\			mcsinit mcs?
\			4 0 term 
\
\ this connects to the master cog, which communicates to the slave cog, which connects to cog 0
\
\			4 1 term 
\
\ this connects to the master cog, which communicates to the slave cog, which connects to cog 1
{
Under the Hood:

Assuming a 80Mhz props, the raw wire transmission send and receives a bit every 12 cycles, so the full
duplex raw bit rate is 6.7M bits/sec.

Communication is packed into a 96 bit frame, which has 8 bytes, CRC, + flow control. So the
theoretical maximum number of frames per second is 69,444. But since one cog is running both the
flow control protocol and the wire protocol, the real maximum throughput is about 22,730 frames
per second. So about twice the time is spent on the protocol as the wire.

If we factor the code to run on 2 cogs, this should increase throughput.

Some real world results from test, the throughput per channel goes down from 13298 bytes/sec/channel
with only one channel running to 11364 bytes/sec/channel with 8 channels running. This is about half the
frame rate, since each byte is synchronously acknowledged.


This decline is due to the frame rate going down slightly as more time is spent on protocol.

If comparing this to rs232, factor the bit rates up by 25% for comparison, as a minimum of one start
bit and stop bit is required for each byte for rs232.

"test" loops the channels on the slave cog, so that each byte received is transmitted. The display of
cog? indicates the channels of the master cog are routed to cog X channel X, this is because
they are routed them to a location for testing.

The xmt/rec code is written in assembler, to simulate the fastest possible source/sink of bytes. 


Prop0 Cog6 ok
test

                a # # - set mcs pins
                b # # - set mcs cogs
                c #   - set xmt/rec cog
                d     - start mcs
                e #   - set number active channels
                f     - stats
                g     - cog?
                q     - quit
d

CON:Prop0 Cog0 RESET - last status: 0 ok

CON:Prop0 Cog1 RESET - last status: 0 ok

CON:Prop0 Cog2 RESET - last status: 0 ok
Cog:0  #io chan:8                              MCS  0(0)->5(1)  0(1)->5(1)  0(2)->5(1)  0(3)->5(1)  0(4)->5(1)  0(5)->5(1)  0(6)->5(1)  0(7)->5(1)
Cog:1  #io chan:8                              MCS  1(0)->1(0)  1(1)->1(1)  1(2)->1(2)  1(3)->1(3)  1(4)->1(4)  1(5)->1(5)  1(6)->1(6)  1(7)->1(7)
Cog:2  #io chan:1 PropForth v4.5 2011MAY31 17:30 0
Cog:3  #io chan:1 PropForth v4.5 2011MAY31 17:30 0
Cog:4  #io chan:1 PropForth v4.5 2011MAY31 17:30 0
Cog:5  #io chan:1 PropForth v4.5 2011MAY31 17:30 0
Cog:6  #io chan:1 PropForth v4.5 2011MAY31 17:30 0  6(0)->7(0)
Cog:7  #io chan:1                           SERIAL  7(0)->6(0)
Master Pin:      0
Slave Pin:       1
Master Cog:      0
Slave Cog:       1

Xmt/Rec Cog:     2
Master Errors:   0
Slave Errors:    0

Master frames/s: 26599
Master bps:      2553504

Slave  frames/s: 26597
Slave  bps:      2553312

Num Channels:    1

XMT byte/sec:    13298
XMT bits/sec:    106384

XMT byte/sec/ch: 13298
XMT bits/sec/ch: 106384

REC byte/sec:    13298
REC bits/sec:    106384

REC byte/sec/ch: 13298
REC bits/sec/ch: 106384

e 8
f
Master Pin:      0
Slave Pin:       1
Master Cog:      0
Slave Cog:       1

Xmt/Rec Cog:     2
Master Errors:   0
Slave Errors:    0

Master frames/s: 22730
Master bps:      2182080

Slave  frames/s: 22729
Slave  bps:      2181984

Num Channels:    8

XMT byte/sec:    90912
XMT bits/sec:    727296

XMT byte/sec/ch: 11364
XMT bits/sec/ch: 90912

REC byte/sec:    90912
REC bits/sec:    727296

REC byte/sec/ch: 11364
REC bits/sec/ch: 90912



Low level timing:

pin 21 is the slave pin
pin 20 is the master pin

LogicAnalyzer trace, sample every cycle


			test	v_pinin , ina wc
			rcl	phsa , # 1
		djnz	_treg6	, # __Flp wz


0 - Execute N-1 Fetch N                    		rcl phsa , # 1  / djnz 
1 -  Write Result N-1                      		rcl phsa , # 1  / djnz
2 -   Fetch Source N                       		djnz	_treg6	, # __Flp wz
3 -    Fetch Dest N                        		djnz	_treg6	, # __Flp wz
4 -     Execute N Fetch N+1                		djnz	_treg6	, # __Flp wz / test
5 -      Write Result N                    		djnz	_treg6	, # __Flp wz 
6 -       Fetch Source N+1                 		test	v_pinin , ina wc
7 -        Fetch Dest N+1                  		test	v_pinin , ina wc
8 -         Execute N+1 Fetch N+2 FetchLiveReg		test	v_pinin , ina wc
9-           Write Result N+1
10 -          Fetch Source N+2
11 -           Fetch Dest N+2
12 -            Execute N+2 Fetch N+3
13 -             Write Result N+2
            
                               11111
                 012345678901234                      
                  |Master Sets Data on pin 20
                  |        
                  ||Slave Sets Data on pin 21
                  ||     
                  ||     |Master Reads Data on pin 21
                  ||     |  
                  ||     ||Slave Reads Data on pin 20
                  ||     ||
21_________________------------____________------------____________------------____________------------____________------------___
20________________-------------___________-------------___________-------------___________-------------___________-------------___
                 |               |               |               |               |               |               |               |
         200.0 nS|       400.0 nS|       600.0 nS|       800.0 nS|       001.0 uS|       001.2 uS|       001.4 uS|       001.6 uS|
                 |               |               |               |               |               |               |               |


}
\
\
\
[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]
\
[ifndef $C_stTop
    hF2 wconstant $C_stTop
]
\
[ifndef $C_stPtr
    hC9 wconstant $C_stPtr
]
\
\
\
\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[ifndef variable
: variable
	lockdict create $C_a_dovarl w, 0 l, forthentry freedict
;
]
\
\
\ abs ( n1 -- abs_n1 ) absolute value of n1
[ifndef abs
: abs
	_xasm1>1 h151 _cnip
;
]
\
\ invert ( n1 -- n2 ) bitwise invert n1
[ifndef invert
: invert
	-1 xor
;
]
\
\
\ pinin ( n1 -- ) set pin # n1 to an input
[ifndef pinin
: pinin
	>m invert dira COG@ and dira COG!
;
]
\
\
\ pinout ( n1 -- ) set pin # n1 to an output
[ifndef pinout
: pinout
	>m dira COG@ or dira COG!
;
]
\
\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[ifndef waitcnt
: waitcnt
	_xasm2>1 h1F1 _cnip
;
]
\
\ a cog special register
[ifndef ctra
h1F8	wconstant ctra 
]
\
\ a cog special register
[ifndef ctrb
h1F9	wconstant ctrb 
]
\
\ a cog special register
[ifndef frqa
h1FA	wconstant frqa 
]
\
\ a cog special register
[ifndef frqb
h1FB	wconstant frqb
]
\
\ a cog special register
[ifndef phsa
h1FC	wconstant phsa 
]
\
\ a cog special register
[ifndef phsb
h1FD	wconstant phsb 
]
\
\ px? ( n1 -- t/f) true if pin n1 is hi
[ifndef px?
: px?
	>m _maskin 
;
]
\
\ sign ( n1 n2 -- n3 ) n3 is the xor of the sign bits of n1 and n2 
[ifndef sign
: sign
	xor h80000000 and
; 
]
\
\ */mod ( n1 n2 n3 -- n4 n5 ) n5 = (n1*n2)/n3, n4 is the remainder. Uses a 64bit intermediate result.
[ifndef */mod
: */mod
	2dup sign >r abs
	rot dup r> sign >r
	abs rot abs um* rot um/mod 
	r>
	if
		negate swap negate swap
	then
; 
]
\
\ */ ( n1 n2 n3 -- n4 ) n4 = (n1*n2)/n3. Uses a 64bit intermediate result.
[ifndef */
: */
	*/mod nip
; 
]
\
\ rnd ( -- n1 ) n1 is a random number from 00 - FF
[ifndef rnd
: rnd
	cnt COG@ h8 rshift
	cnt COG@ xor hFF and
	; 
]
\
\ rndtf ( -- t/f) true or false randomly
[ifndef rndtf
: rndtf
	rnd h7F >
;
]
\
\ rndand ( n1 -- n2) n2 is randomly n1 or 0
[ifndef rndand
: rndand
	rnd h7F > and
; 
]
\
\ _cfo ( n1 -- n2 ) n1 - desired frequency, n2 freq a 
[ifndef _cfo
: _cfo
	clkfreq 1- min
	0 swap clkfreq
	um/mod swap clkfreq 2/
	>= abs +
; 
]
\
\ setHza ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctra
\ set the pin oscillating at the specified frequency
[ifndef setHza
: setHza
	_cfo frqa COG!
	dup pinout h10000000 + ctra COG!
;
]
\
\ qHzb ( n1 n2 -- n3 ) n1 - the pin, n2 - the # of msec to sample, n3 the frequency
[ifndef qHzb
: qHzb
	swap h28000000 + 1 frqb COG!
	ctrb COG!
	h3000 min clkfreq over
	h3E8 */ h310 - phsb COG@
	swap cnt COG@ + 0 waitcnt
	phsb COG@
	nip swap -
	h3E8 rot */
;
]
\
\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[ifndef term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup h6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]
\
lockdict create a_mcs forthentry
$C_a_lxasm w, h1A9  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z1SV06X l, z1 l, z1 l, 0 l, 0 l, 0 l, 0 l, 0 l,
0 l, z2WyPj0 l, z2WyQ84 l, zbyZO1 l, zbyPj8 l, z4iPZB l, z2WiPeC l, zfyPWO l,
z1YyPf0 l, z1bdPmC l, z1btZQ0 l, z20yPO4 l, z3[yQCU l, z1SV000 l, z2WyZO0 l, z1Sy\4S l,
z2WiZBE l, z1Sy\4S l, z2WiZJE l, z1biZSO l, z2WiPvP l, z1fiPvQ l, z1fiPvR l, z1fyPwL l,
z2WiQ3F l, zbyQ0G l, z1fiPuG l, zfyPrG l, z1biZRF l, z24yPOW l, z1SV000 l, z2WyQ8W l,
z1XFYil l, znyyW1 l, z3]yQCu l, z1SV000 l, z2Wiy[R l, z1Syant l, z2WiZ7v l, z2Wiy[Q l,
z1Syant l, z2WiYyv l, z2Wiy[P l, z1Syant l, z2WiYqv l, z2fyyW1 l, z2WiQBB l, z20yQ8n l,
z2WiPvM l, z1fiPvN l, z1fiPvO l, z1fyPwL l, z2WiQ3F l, zbyQ0G l, z1fiPuG l, zhyPrG l,
z8iQ3H l, z20yQ01 l, z8FQ3H l, z20yQ84 l, z2WoZ00 l, z8\Q3H l, z20oQ01 l, z85Q3H l,
z2WyQ40 l, z2WiP[O l, z2WyQ88 l, z1YVP[0 l, z45Q3B l, zbyPW1 l, z20yPO4 l, z3[yQDU l,
z24yPOW l, z20yPOW l, z2WyQ02 l, z2WiPvM l, z2WyQ84 l, z2WiPmF l, zbyPr8 l, zcyZ01 l,
z4fPZB l, z1WyPmy l, z1YVP[0 l, z44PmB l, z20yPO2 l, z3[yQDb l, z2WiPvN l, z3[yQ5a l,
z24yPOj l, z2WiZJB l, z20yZG2 l, z2WyPr7 l, zfyPr8 l, z20yPOW l, z2WyZ00 l, z2WyQ40 l,
z2WyYn0 l, z2WiYvM l, zfyYr1 l, z2WiZCN l, zfyZ81 l, z2WyQ88 l, z4iPmB l, z1YFPmF l,
z1SL06B l, z6iPfQ l, z2WdPnP l, z1SQ06B l, z4iPZD l, z1YFP[M l, z45PmD l, z2W\PnP l,
z1YFPnN l, z45YmB l, z1YFPnP l, z45YuB l, z1b\Z3G l, zfyQ01 l, z20yZG4 l, z20yPO2 l,
z3[yQE1 l, z24yPOj l, z1SV000 l, z1SyaCc l, z2WyyW0 l, z3nFYfL l, z1Sylfy l, z1SV06M l,
z1SyaCc l, z3nFYfL l, z2WyyW0 l, 0 l, z1Sylfy l, z1SV06R l, z1SyLIZ l, z2WiYZB l,
z1SyLI[ l, z2WiYeB l, z1SyLI[ l, z26VPW0 l, z1SL06M l, z1SV06R l,
freedict
\
\ a_mastermcs ( addr -- addr) addr - a pointer to a channel structure, MUST be long aligned
\ a_slavemcs ( addr -- addr)
\ Channel structure
\ has 8 full duplex channels, with built in flow control, which can interface easily to forth cogs
\
\
\ 00 - 20 - 8 longs each representing a channel
\ 20 - 30 - 8 words, the recbuf, the bytes received by the channels are buffered here
\ 30 - byte, the master pin out
\ 31 - byte, the slave pin out
\ 32 - byte, the reset pin
\ 33 - byte, the state - used by domaster and doslave
\ 34 - long, a count of how many full duplex 96 bit exchanges there have been
\ 38 - long, a count of how many checksum errors there have been
\ 3C - long, a long used for debugging
\
\ the members of the structure
: mcsrecbuf h20 + ;
: mcspinm@ h30 + C@ ;
: mcspins@ h31 + C@ ;
: mcspinm! h30 + C! ;
: mcspins! h31 + C! ;
: mcsreset@ h32 + C@ ;
: mcsreset! h32 + C! ;
: mcsstate@ h33 + C@ ;
: mcsstate! h33 + C! ;
: mcscnt h34 + ;
: mcserr h38 + ;
\ : mcsdbg h3C + ;
\
\ (mcsinit) ( addr n1 n2 n3 -- addr ) addr - the channel structure address,
\           n1 master pin n2 the slave pin, n3 is the reset pin
: (mcsinit)
	h1F and h10 lshift
	swap h1F and h8 lshift or
	swap h1F and or over h30 + L!
	dup h20 bounds
	do
		h0100 i L! 
	h4 +loop 
	dup mcsrecbuf h10 bounds
	do
		h01000100 i L!
	h4 +loop 
	dup mcscnt 0 over L!
	4+ 0 over L! 4+ 0 swap L!
;
\
\ base routines which synch and help determine if the master / slave is online
\
\ (mcsres) ( addr -- addr )
: (mcsres)
	dup mcspinm@ pinin
	dup mcspins@ pinin
	0 over mcsstate!
	0 ctra COG!
	0 ctrb COG!
;
\
\ (mcssynsm) ( addr -- addr ) send out the signal indicating we are the master
: (mcssynsm)
	(mcsres)
	dup mcspins@
	pinin dup mcspinm@
	hA7000 setHza
;
\
\ (mcssynss) ( addr -- addr ) send out the signal indicating we are the slave
: (mcssynss)
	(mcsres)
	dup mcspinm@
	pinin dup mcspins@
	h77000 setHza
;
\
\ (mcssyncm) ( addr -- addr t/f ) check for a valid master signal
: (mcssyncm)
	dup mcspinm@ 1 qHzb hA0000 hB0000 between
;
\
\ (mcssyncs) ( addr -- addr t/f ) check for a valid slave signal
: (mcssyncs)
	dup mcspins@ 1 qHzb h70000 h80000 between
;
\
\ (mcssyn )( addr -- addr ) auto negotiate communication, if this is used a 200 - 400 ohm resistor should be connected
\ in series with each of the mcs lines, ie master pin and slave pin, to limit current in the case of a collision
\ in the initial negotiation
: (mcssyn)
	h10000 0 do
		(mcssynsm) 0 swap rndtf h8 and h8 + 0 do
			(mcssyncs) if swap 1+ swap then
		loop
		swap h2 >
	 	if
			leave h2 over mcsstate!
		else
			(mcssynss) 0 swap rndtf h8 and h8 + 0
			do
				(mcssyncm)
				if
					swap 1+ swap
				 then
			loop
			swap 2 >
			if
				leave 2 over mcsstate!
			then
		then
	loop ;
\
\ waithi ( n1 -- ) make sure pin n1 is high and not oscillating
: waithi
	h1000 0
	do
		dup px?
		if
			 0 h1000 0
			 do
				over px?
				if
					1+
				else
					leave
				then
			loop
		else
			0
		then
   		hFF0 >
		if
			leave
		else
			1 delms
		then
	 loop
	 drop
;
\
: (mcs)
	1- numchan C! h4 state andnC!
	>r io rot2 r>
	(mcsinit)
	(mcsres)
	1 over mcsstate!
;
\
\ this starts the cog as a master channel
\ mcsmaster ( n1 n2 n3 n4 -- ) n1 - master pin, n2 slave pin, n3 reset pin, n4 number of channels
: mcsmaster
	c" MCS_MASTER WAITING" cds W!
	(mcs) (mcssynsm)
	begin
		(mcssyncs)
	until
	h10 delms
\
	dup mcspinm@ dup pinout
	0 ctra COG! 0 ctrb COG!
	0 frqa COG!
	h10000000 + ctra COG!
	h80000000 phsa COG! 
\
	dup mcspins@ waithi
	h60 delms
	h4 over mcsstate!
	dup mcspins@ >m 
	over mcspinm@ >m
	c" MCS_MASTER CONNECTED" numpad ccopy
	numpad cds W!
	4 state andnC!
	-1 a_mcs
;
\
\ this starts the cog as a slave channel, and connects cogs 0 - n4 as forth cogs, these cogs should be already started
\ and free as forth cogs
\ mcsslave ( n1 n2 n3 n4  -- ) n1 - master pin, n2 slave pin, n3 reset pin, n4 number of channels
: mcsslave
	c" MCS_SLAVE WAITING" cds W!
	(mcs) (mcssynss)
	begin
		(mcssyncm)
	until
	h10 delms
\
	dup mcspins@ dup pinout
	0 ctra COG! 0 ctrb COG!
	0 frqa COG!
	h10000000 + ctra COG!
	h80000000 phsa COG! 
\
	dup mcspinm@ waithi
	h10 delms
	h4 over mcsstate!
	dup mcspinm@ >m 
	over mcspins@ >m
	c" MCS_SLAVE CONNECTED" numpad ccopy
	numpad cds W!
	4 state andnC!
	0 a_mcs
;

\
\ After getting norom, and mcs working the 2 together
\
\ load this file
\ run 0 onboot
\ 5 0 term
\
\
\



1 wconstant  build_mcsnorom


c" onboot" find drop pfa>nfa 1+ c" onb002" C@++ rot swap cmove
: onboot
	 onb002 h80 delms
	h2 _finit andnC!
	_finit W@ 1 and
	if

\
\ Reference regression system
\
\
		h8 h9 hA hB rambootnx
		c" h8 h9 hA h5 mcsmaster" h5 cogx h10 delms

\
\ Spinneret PLAB0
\
\		d26 d27 d24 d25 rambootnx
\		c" d26 d27 d24 d5 mcsmaster" h5 cogx h10 delms


		h10000 0
		do
			h5 cogio mcsstate@ h4 =
			if
				h2 _finit orC!
				leave
			then
		loop
	else
		c" h1C h1D hFF h5 mcsslave" h5 cogx h10 delms
		h10000 0
		do
			h5 cogio mcsstate@ 4 =
			if
				h2 _finit orC!
				leave
			then
		loop
		h5 0
		do
			i 0 h5 i (ioconn)
		loop
	then
;		

hA state orC! version W@ .cstr cr cr cr
: findEETOP
	0
	h100000 h8000
	do
		i t0 2 eereadpage
	if
		leave
	else
		i h7FFE + t0 3 eereadpage
		if
			leave
		else
			drop i h8000 +
		then
	then
	h8000 +loop
;

c" boot.f - Finding top of eeprom, " .cstr findEETOP ' fstop 2+ alignl L! c" Top of eeprom at: " .cstr fstop . cr

c" boot.f - PropForth booting subprop~h0D~h0D" .cstr hA state andnC!

: onreset6
	onreset
	_finit W@ 1 and
	if
		c" MAST" prop W@ ccopy
		0 onboot
		$S_con iodis $S_con cogreset 100 delms
		c" 6 7 57600 serial" 7 cogx 100 delms
		6 >con

		_finit W@ 2 and
		if
			." Slave Prop Booted and connected~h0D"
		else
			." ERROR: Slave Prop not connected~h0D"
		then
		c" build_norom"
	else
		$S_con iodis $S_con cogreset h7FFF dup memend W! dictend W! 
		c" SLAV" prop W@ ccopy
		8 propid W!
		c" $S_con" find
		if
			2+ 5 swap W!
		else
			drop
		then
		c" build_fsrd"
	then
	(forget)
;

c" boot.f - DONE PropForth Loaded~h0D~h0D" .cstr hA state andnC!






...

