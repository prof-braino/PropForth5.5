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
\
\
{

\ the assembler code which drives the channel

fl

\ a cog special register
[ifndef phsa
h1FC	wconstant phsa
]


build_BootOpt :rasm

	jmp	# __begin

\ the output pin used for the communication
__pinout
 1
\ the input pin used for the communication
__pinin
 1
\ the registers in which the data is received
__1rxdata0
 0
__2rxdata1
 0
__3rxcontrol
 0
\ the registers in which the data is transmitted
__4txdata0
 0
__5txdata1
 0
__6txcontrol
 0






\ packs 4 words from sendbuf into $C_treg3, and sets the bit in __6txcontrol if there is a byte to transmit
\ bytes and bits to indicate a byte for consumption are packed in small endian order
\
__7bl
		mov	$C_treg3	, # 0
		mov	$C_treg6 	, # h4
__Flp
		shr	__6txcontrol , # 1
		shr	$C_treg3	, # h8
		rdword	$C_treg1	, $C_stTOS
		mov	$C_treg2	, $C_treg1
		shl	$C_treg1	, # h18
		and	$C_treg2	, # h100 wz
	if_z	or	$C_treg3	, $C_treg1
	if_z	or	__6txcontrol , # h80
		add	$C_stTOS	, # h4
		djnz	$C_treg6	, # __Flp	
__8blret
		ret


\ load the sendbuf into the tx registers, set the appropriate bits to indicate there is a byte for consumption 
\ (b0-b7 of txcontrol), or in the ackowledge bits for what has been received (b8-b15 of txcontrol) and set the
\ checksum (b16 - b31 of txcontrol)
\
__9loadregs
\ accessing chchannel offest 0, inc 4 * 8 = 20, dec 20
		mov	__6txcontrol , # 0

		jmpret	__8blret , # __7bl
		mov	__4txdata0 , $C_treg3			

		jmpret	__8blret , # __7bl
		mov	__5txdata1 , $C_treg3			

		or	__6txcontrol , __3rxcontrol

		mov	$C_treg4	, __4txdata0
		xor	$C_treg4	, __5txdata1
		xor	$C_treg4	, __6txcontrol
		xor	$C_treg4	, # h155
		mov	$C_treg5	, $C_treg4
		shr	$C_treg5	, # h10
		xor	$C_treg4	, $C_treg5
		shl	$C_treg4	, # h10
		or	__6txcontrol , $C_treg4		

		sub	$C_stTOS , # h20
__Aloadregsret
		ret

\ full duplex xmt / rec of the tx / rx registers 3 registers sent, 3 registers received
\ 0-6(variables) 9-a(loadregs)

\ phsa 32-bit data to transmit, returns 32-bits received in phsa
__7trreg
		mov	$C_treg6 , # h20
__Flp
			test	__pinin , ina wc
			rcl	phsa , # 1
		djnz	$C_treg6	, # __Flp wz
__8trregret
		ret


\ xmt / rec then precess the received data
\ 0-6(variables) 9-A(loadregs) B-C(txrx)

__Btxrx
\ xmt / rec the registers, control register first, then data1, the data0
\ 0-6(variables) 7-8(trreg) 9-A(loadregs) B-C(txrx)

		mov	phsa , __6txcontrol
		jmpret	__8trregret , # __7trreg
		mov	__3rxcontrol , phsa

		mov	phsa , __5txdata1
		jmpret	__8trregret , # __7trreg
		mov	__2rxdata1 , phsa

		mov	phsa , __4txdata0
		jmpret	__8trregret , # __7trreg
		mov	__1rxdata0 , phsa
	
		absneg phsa , # 1

\ add one to the counter in the channel structure
\ accessing mcscnt
		mov	$C_treg6	, $C_stTOS
		add	$C_treg6	, # h34

\ check the checksum, if there is an error zero out rxcontrol and add one to the error counter in the structure
		mov	$C_treg4	, __1rxdata0
		xor	$C_treg4	, __2rxdata1
		xor	$C_treg4	, __3rxcontrol
		xor	$C_treg4	, # h155

		mov	$C_treg5	, $C_treg4
		shr	$C_treg5	, # h10
		xor	$C_treg4	, $C_treg5
		shl	$C_treg4	, # h10 wz

		rdlong	$C_treg5	, $C_treg6
		add	$C_treg5	, # 1
		wrlong	$C_treg5	, $C_treg6

\ accessing mcserr
		add	$C_treg6	, # h4
	if_nz	mov	__3rxcontrol , # 0

	if_nz	rdlong	$C_treg5	, $C_treg6
	if_nz	add	$C_treg5	, # 1
	if_nz	wrlong	$C_treg5	, $C_treg6

\ debugging
\
\		 
\		add	$C_treg6	, # h4
\
\	if_z	rdlong	$C_treg5	, $C_treg6
\	if_z	add	$C_treg5	, # 1
\	if_z	wrlong	$C_treg5	, $C_treg6
\

\ process the acknowledge bits in b8-15 of the rxcontrol register
\ set the corresponding word in sendbuf to h100 indicating we are ready to receive another byte
\
\ accessing chchannel offest 0, inc 4 * 8 = 20, dec 20

		mov	$C_treg5	, # h100
		mov	$C_treg1	, __3rxcontrol
		mov	$C_treg6	, # h8
__Flp
		test	$C_treg1	, # h100 wz
	if_nz	wrword	$C_treg5	, $C_stTOS
		shr	$C_treg1	, # 1
		add	$C_stTOS	, # h4
		djnz	$C_treg6	, # __Flp
		sub	$C_stTOS , # h20

\ process the received data in rxdata0 and rxdata1, if the corresponding receive channel bits in b8-15 of the rxcontrol register
\ if the corresponding word in recbuf is h100 indicating we are ready to receive another byte, write the byte
\ 
\
\ accessing mcsrecbuf
		add	$C_stTOS	, # h20
		mov	$C_treg5	, # h2
		mov	$C_treg4	, __1rxdata0
__Elp
		mov	$C_treg6	, # h4
__Flp
			mov	$C_treg3	, $C_treg4
			shr	$C_treg4	, # h8
			shr	__3rxcontrol , # 1 wc	
	if_c		rdword	$C_treg1	, $C_stTOS
			and	$C_treg3	, # hFF
			test	$C_treg1	, # h100 wz
	if_c_and_nz	wrword	$C_treg3	, $C_stTOS
			add	$C_stTOS	, # h2
			djnz	$C_treg6	, # __Flp
		mov	$C_treg4	, __2rxdata1
		djnz	$C_treg5	, # __Elp
	
		sub	$C_stTOS	, # h30


\ and finally
\
\ move the character to the destination specified by the emit pointer, or if it is zero,
\ toss it into the bit bucket
\
\ process the state of the received characters in recbuf and send back the corresponding acknowledge bits
\ state 100 - ready to receive a byte
\ state 0xx - a valid bytes
\ state 400 - the byte has been read, but no acknowledge bit has been sent
\ state 200 - the acknowledge bit has been sent
\ *** only one state change at a time in this routine please


\ accessing chchannel + 2
	mov	__5txdata1 , $C_stTOS
	add	__5txdata1 , # h2
	mov	$C_treg4	, # h7
	shl	$C_treg4	, # h8
\
\ accessing mcsrecbuf	
		add	$C_stTOS	, # h20
		mov	__3rxcontrol , # 0
		mov	$C_treg5	, # h100
		mov	__1rxdata0 , # h100
		mov	__2rxdata1 , __1rxdata0
		shl	__2rxdata1 , # 1
		mov	__4txdata0 , __2rxdata1
		shl	__4txdata0 , # 1

		mov	$C_treg6	, # h8
__Flp
		rdword	$C_treg3	, $C_stTOS

\ move the character to the destination specified by the emit pointer, or if it is zero,
\ toss it into the bit bucket
	test	$C_treg3	, $C_treg4 wz
 if_nz	jmp	# __Dnochar
	rdword	$C_treg2	, __5txdata1 wz
 if_z	mov	$C_treg3	, __4txdata0
 if_z	jmp	# __Dnochar
	rdword	$C_treg1	, $C_treg2
	test	$C_treg1	, __1rxdata0 wz
 if_nz	wrword	$C_treg3	, $C_treg2
 if_nz	mov	$C_treg3	, __4txdata0
__Dnochar

\ process the flags
\ 200 -> 100
		test	$C_treg3	, __2rxdata1 wz
	if_nz	wrword	__1rxdata0 , $C_stTOS
\ 400 -> 200 + flag
		test	$C_treg3	, __4txdata0 wz
	if_nz	wrword	__2rxdata1 , $C_stTOS
	if_nz	or	__3rxcontrol , $C_treg5
		shl	$C_treg5	, # 1
		add	__5txdata1 , # h4
		add	$C_stTOS	, # h2
		djnz	$C_treg6	, # __Flp
		sub	$C_stTOS	, # h30

__Ctxrxret
		ret




 
__mastermcs
__Flp
		jmpret	__Aloadregsret , # __9loadregs
		mov phsa , # 0
		waitpne	__pinin , __pinin
		jmpret	__Ctxrxret , # __Btxrx
		jmp	# __Flp

__slavemcs
__Flp
		jmpret	__Aloadregsret , # __9loadregs
		waitpne	__pinin , __pinin
		mov phsa , # 0
\ delay 4 cycles, this will have the slave 1 cycle behind the master, as opposed to 3 cycles ahead
		nop			
		jmpret	__Ctxrxret , # __Btxrx
		jmp	# __Flp


__begin
		spopt
		mov	__pinout , $C_stTOS
		spop
		mov	__pinin , $C_stTOS
		spop
		cmp	$C_treg1 , # 0 wz
	if_nz	jmp	# __mastermcs
		jmp	# __slavemcs

;asm a_mcs


}
\
\
[ifdef mcs_dbg
\
\
\
\
\
\ test_hex ( -- )
: test_hex
	h10 base W!
	." Hex mode" cr
;
\
\ test_decimal ( -- )
: test_decimal
	hA base W!
	." Decimal mode" cr
;
\
\ stackdepth ( -- n1 )
: stackdepth
	$C_stTop $C_stPtr COG@ - h3 -
;
\
wvariable master_pin h14 master_pin W!
wvariable slave_pin h15 slave_pin W!
\
wvariable master_cog 0 master_cog W!
wvariable slave_cog 1 slave_cog W!
\
wvariable xmt/rec_cog h2 xmt/rec_cog W!
\
lockdict wvariable rec_array h100 w, h100 w, h100 w, h100 w, h100 w, h100 w, h100 w, h100 rec_array W! freedict
\
variable xmt_bytes 0 xmt_bytes L!
variable rec_bytes 1 rec_bytes L!
\
\
\
wvariable num_active_channels 1 num_active_channels W!
\
: set_mcs_pins
	h1F and swap h1F and 2dup =
	if
		1+ h1F and
	then
	master_pin W!
	slave_pin W!
;
\
: set_mcs_cogs
	h7 and swap h7 and 2dup =
	if
		1+ h7 and
	then
	master_cog W!
	slave_cog W!
;
\
: set_xmt/rec_cog
	h7 and 
	xmt/rec_cog W!
;
\
: C+!
	dup C@ rot + swap C!
;
\
\
{
fl


build_BootOpt :rasm

		jmp	# __3

__master_cogio
 0
__xmt_bytes
 0
__rec_array
 0
__rec_bytes
 0
__num_active_channels
 0
__v_a5
 hA5
__v_100
 h100

__3
		mov	__master_cogio , $C_stTOS
		spop
		mov	__xmt_bytes , $C_stTOS
		spop
		mov	__num_active_channels , $C_stTOS
		spop
		mov	__rec_bytes , $C_stTOS
		spop
		mov	__rec_array , $C_stTOS
		spop
__1
		rdlong	$C_treg6 , __xmt_bytes
		rdlong	$C_treg5 , __rec_bytes

		rdword	$C_treg3 , __num_active_channels

		mov	$C_treg4 , __master_cogio
		
		mov	$C_treg2 , __rec_array
__2
				rdword	$C_treg1 , $C_treg4
				test	$C_treg1 , # h100 wz
			if_nz	add	$C_treg6 , # 1
			if_nz	wrword	__v_a5 , $C_treg4
				add	$C_treg4 , # h4

				rdword	$C_treg1 , $C_treg2
				test	$C_treg1 , # h100 wz
			if_z	add	$C_treg5 , # 1 
			if_z	wrword	__v_100 , $C_treg2
				add	$C_treg2 , # h2
		djnz	$C_treg3 , # __2

		wrlong	$C_treg6 , __xmt_bytes
		wrlong	$C_treg5 , __rec_bytes
	jmp	# __1
;asm a_xmtrec

}
\
lockdict create a_xmtrec forthentry
$C_a_lxasm w, h138  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z1SV04R l, 0 l, 0 l, 0 l, 0 l, 0 l, z2\ l, z40 l,
z2WiYZB l, z1SyLI[ l, z2WiYeB l, z1SyLI[ l, z2WiZ3B l, z1SyLI[ l, z2WiYuB l, z1SyLI[ l,
z2WiYmB l, z1SyLI[ l, z8iQCL l, z8iQ4N l, z4iPnO l, z2WiPvK l, z2WiPfM l, z4iPZF l,
z1YVP[0 l, z20oQ81 l, z45ZBF l, z20yPr4 l, z4iPZD l, z1YVP[0 l, z20tQ01 l, z4AZJD l,
z20yPb2 l, z3[yPnd l, z8FQCL l, z8FQ4N l, z1SV04\ l,
freedict
\
: xmt/rec
\
\	master_cog W@ cogio
\
\	master_cog W@ cogio v_master_cogio COG!
\	v_xmt_bytes COG!
\	num_active_channels v_num_active_channels COG!
\
\	rec_bytes v_rec_bytes COG!
\	rec_array v_rec_array COG!
\
	rec_array
	rec_bytes
	num_active_channels
	xmt_bytes
	master_cog W@ cogio
\
	a_xmtrec
\
\	begin
\
\		xmt_bytes L@
\		over num_active_channels W@ 4* bounds
\		do
\			i W@ 100 and
\			if
\				1+ A5 i W!
\			then
\		4 +loop
\		xmt_bytes L!
\
\
\		rec_bytes L@
\		rec_array num_active_channels W@ 2* bounds
\		do
\			i W@ 100 and 0=
\			if
\				1+ 100 i W!
\			then
\		2 +loop
\		rec_bytes L!
\
\		0
\	until
;
\
\
: set_num_active
	1 max h8 min num_active_channels W!
;
\
\
: mcs_stats
	." Master Pin:      " master_pin W@ . cr
	." Slave Pin:       " slave_pin W@ . cr cr
	." Master Cog:      " master_cog W@ . cr
	." Slave Cog:       " slave_cog W@ . cr cr
\
	." Xmt/Rec Cog:     " xmt/rec_cog W@ . cr cr
\
	." Master Errors:   "  master_cog W@ cogio mcserr L@ . cr
	." Slave Errors:    " slave_cog W@ cogio mcserr L@ . cr cr
\
	." Master Frames:   "  master_cog W@ cogio mcscnt L@ . cr
	." Slave Frames:    " slave_cog W@ cogio mcscnt L@ . cr cr
\
	." Master State:   "  master_cog W@ cogio mcsstate@ . cr
	." Slave State:    " slave_cog W@ cogio mcsstate@ . cr cr
\
 	master_cog W@ cogio mcscnt dup L@
 	slave_cog  W@ cogio mcscnt dup L@
	xmt_bytes dup L@
	rec_bytes dup L@
\
	clkfreq cnt COG@ + 0 waitcnt drop
	swap L@ swap - >r
	swap L@ swap - >r
	swap L@ swap - >r
	swap L@ swap -
\
\
	." Master frames/s: " dup . cr
	." Master bps:      " h60 u* . cr cr
	." Slave  frames/s: " r> dup . cr
	." Slave  bps:      " h60 u* . cr cr
\
\
	." Num Channels:    " num_active_channels W@ . cr cr
\
	." XMT byte/sec:    " r> dup . cr
	." XMT bits/sec:    " dup h8 u* . cr cr
	." XMT byte/sec/ch: " num_active_channels W@ u/ dup . cr
	." XMT bits/sec/ch: " h8 u* . cr cr
	." REC byte/sec:    " r> dup . cr
	." REC bits/sec:    " dup h8 u* . cr cr
	." REC byte/sec/ch: " num_active_channels W@ u/ dup . cr
	." REC bits/sec/ch: " h8 u* . cr cr
\
;
\
: start_mcs
	master_cog W@ cogstop
	slave_cog W@ cogstop
	xmt/rec_cog W@ cogstop
\
	master_cog W@ cogio h20 0 fill
	slave_cog W@ cogio h20 0 fill
\
	master_cog W@ cogreset
	slave_cog W@ cogreset
	xmt/rec_cog W@ cogreset
\
\
	h100 delms
\
	base W@
	hex
\
	c" h" tbuf ccopy
	master_pin W@ tbuf cappendn
	c"  h" tbuf cappend
	slave_pin W@ tbuf cappendn
	c"  h" tbuf cappend
	hFF tbuf cappendn
	c"  h" tbuf cappend
	h8 tbuf cappendn
	c"  mcs" tbuf cappend
\
	tbuf C@
\
	c" master" tbuf cappend
	tbuf master_cog W@ cogx
\
	tbuf .cstr cr
\
	tbuf C!
\
	c" slave" tbuf cappend
	tbuf slave_cog W@ cogx
\
	tbuf .cstr cr
\
	base W!
\
	h100 delms
	h8 0
	do
		slave_cog W@ cogio i 4* + dup 2+ W!
	loop
	h8 0
	do
		rec_array i 2* + master_cog W@ cogio i 4* + 2+ W!	
	loop
\
	c" xmt/rec" xmt/rec_cog W@ cogx
	cog?
	mcs_stats
; 
\
\
\
\ test_help ( -- )
: test_help
	cr
	." ~h09~h09a # # - set mcs pins" cr
	." ~h09~h09b # # - set mcs cogs" cr
	." ~h09~h09c #   - set xmt/rec cog" cr
	." ~h09~h09d     - start mcs" cr
	." ~h09~h09e #   - set number active channels" cr
	." ~h09~h09f     - stats" cr
	." ~h09~h09g     - cog?" cr
	." ~h09~h09q     - quit" cr
;
\
\ create a menu structure of the test routines,
lockdict
herewal
here W@ 0 w, 							\ the size of the structure in bytes
\ the address (test_addr)	#parameters (#params)	the menu key (menuchar)
' set_mcs_pins		w,	h2 c,			h61 c,
' set_mcs_cogs		w,	h2 c,			h62 c,
' set_xmt/rec_cog	w,	1 c,			h63 c,
' start_mcs		w, 	0 c,			h64 c,
' set_num_active	w,	1 c,			h65 c,
' mcs_stats		w,	0 c,			h66 c,
' cog?			w,	0 c,			h67 c,
\								\ update the structure size
here W@ over 2+ -  over W!
\								\ the address of the structure
wconstant test_structure		
freedict
\
\
\ exec_test ( params #params menuchar -- t/f ) executes the menu in the test_jumptable,
\				if the # params match, true if test executed
: exec_test
	h8 lshift or
	0 >r
	0 test_structure 2+ test_structure W@ bounds
	do
\ 						\ ( params #params/menuchar 0 == 0 )
		over i 2+ W@ =
		if
			
			drop i leave
		then
	h4 +loop
\ 						\ ( params #params/menuchar struct_addr/0 == 0 )
	swap hFF and swap dup
\
\
\
	if
\ 						\ ( params #params struct_addr/0 == 0 )
\						\ ( params #params struct_addr/0 == 0 )
		swap >r W@
\						\ ( params #params test_addr == 0 #params )
		stackdepth >r
\						\ ( params #params test_addr == 0 #params stackdepth )
		dup 0=
		if
\						\ test routine address in structure was zero
\						\ undefined routine?
			hEE ERR
		then
		execute
\						\ ( - == 0 #params stackdepth )
		r> stackdepth - r> <>
		if
\						\ test routine consumed the wrong number
\						\ of parameters from the stack
			hEF ERR
		then
\						\ ( - == 0 )
		r> drop -1 >r
\						\ ( - == -1 )
	then
\						\ ( params #params struct_addr/0 == 0 )
	r>
	if
\						\ ( - == - )
		-1
	else	
\ 						\ ( params #params 0 == 0 )
		drop
		dup 1+ 0
		do
			drop
		loop
		0
	then
\						\ ( 0/-1 == - )	
; 
\
\
\ test_getnumber ( -- n1 t/f)
: test_getnumber
	parsenw
\						\ ( cstr/0 == - )
	dup
	if
\						\ ( cstr/0 == - )
		dup C@++ isnumber
\						\ ( cstr t/f == - )
		if
\						\ got a valid number
			C@++ number -1
\						\ ( n1 -1 == - )
		else
\						\ print an error message
			_udf dup .cstr cr
			0
\						\ ( cstr 0 == - )			
		then
	else
		0
\						\ ( 0 0 == - )			
	then
;
\
\ test_params ( -- n1 .. ncount count)
: test_params
	0 >r
\						\ ( == count )
	begin
		test_getnumber
\						\ ( ... n1/ctr -1/0 == count )
		if
						\ ( ... n1 == count )
			r> 1+ >r 0
						\ ( ... n1 0 == count+1 )
		else
\						\ ( ... -1 == count )
			drop -1
		then
	until
	r>
\						\ ( ... count == - )
;
\
\	
\
\		
\
\ test_mcs ( -- )
: test_mcs
	test_help
	begin
\						\ get a line from the input and parse the first word
		pad padsize accept drop
		0 >in W!
		parsenw dup
		if
\						\ ( cstr == - )
			C@++ 1 =
\						\ ( cstr+1 length == - )
			if
				C@ dup h71 =
				if
\						\ ( char == - )
					drop -1
\						\ ( -1 == - )
				else
\						\ ( char == - )
					>r
					test_params
					r>
\						\ ( params #params menuchar == - )
					exec_test
						\ ( 0/-1 == - )
					0=
					if
						test_help
					then
					0
\						\ ( 0 == - )
				then
			else
\						\ ( cstr == - )
				drop test_help 0
\						\ ( 0 == - )
			then
		else
\						( cstr == - )
			drop test_help 0
\						\ ( 0 == - )
		then
	until
;
\
\
]

