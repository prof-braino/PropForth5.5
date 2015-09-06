mountsys

1 fwrite boot23.f
mountsys
2 4 rfsend serial.f
2 4 rfsend bootplab23.f
...


100 fwrite bootplab23.f


\
\ BEGIN boot and configure subprop
\

\ mcs? ( mcscog -- )
[ifndef mcs?
: mcs?  ." FRAME COUNT: " cogio dup h34 + L@ . ." ERROR COUNT: " h38 + L@ . cr ;
]


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


[ifndef term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup h6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]

1 wconstant SUBPROP

{
c" boot.f    LOADING norom.f" _bmsg
fload norom.f

c" boot.f    LOADING mcs.f" _bmsg
fload mcs.f

}


1 wconstant build_norom

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



1 wconstant build_mcs
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
\ (mcsinit) ( addr n1 n2 n3 -- addr ) addr - the channel structure address, n1 master pin n2 the slave pin,
\                                     n3 is the reset pin
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
	1- h5 lshift h10 or state C!
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









1 wconstant  build_mcsnorom

\ this is what the cogs on the subprop will do on reset
: onreset
	unlockall 4 state orC! version W@ cds W! drop
;



\ this is what the subprop will do on boot
\ 



: onboot
	16 pinout
	16 pinhi


	8 0
	do
		i cogid <>
		if
			i cogreset
		then
	loop

\
\ drop error codes
\
	drop 0 

	h80 0
	do
		h1C 1 qHzb h90000 hA0000 between
		if
			c" h1C h1D hFF h8 mcsslave" h7 cogx h10 delms
			h10000 0
			do
				h7 cogio mcsstate@ 4 =
				if
					leave
				then
			loop

			h5 0
			do
				i 0 h7 i (ioconn)
			loop
		then
	loop
;


: bootsubprop2
	4 state andnC!
	2 3 0 1 rambootnx
	c" 2 3 0 8 mcsmaster" 6 cogx
	h1000 0
	do
		1 delms
		6 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	6 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;



: bootsubprop3
	4 state andnC!
	6 7 4 5 rambootnx
	c" 6 7 4 8 mcsmaster" 3 cogx
	h1000 0
	do
		1 delms
		3 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	3 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;



: bootplab2
	c" bootsubprop2" 5 cogx

	h4000 0
	do
		1 delms
		5 cogstate C@ hA =
		if
			leave
		then
	loop
;

: bootplab3
	c" bootsubprop3" 2 cogx

	h4000 0
	do
		1 delms
		2 cogstate C@ hA =
		if
			leave
		then
	loop
;


\ bootplab2

\ bootplab3


: bootplab23
	c" bootsubprop2" 5 cogx
	c" bootsubprop3" 2 cogx

	h2000 0
	do
		1 delms
		5 cogstate C@ hA =
		2 cogstate C@ hA = and
		if
			leave
		then
	loop
;

bootplab23

5 cogstate C@ hA =
[if
	c" 2 propid W!" 6 0 rcogx
	7 1 6 0 (ioconn)
 	c" forget SUBPROP" 6 0 rcogx
]

2 cogstate C@ hA =
[if
	c" 3 propid W!" 3 0 rcogx
	7 2 3 0 (ioconn)
 	c" forget SUBPROP" 3 0 rcogx
]

forget SUBPROP

...

