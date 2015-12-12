fl



1 wconstant build_hdserial

{
forth routines 25kbps max (80 Mhz clock), 14.5kpbs max for open collector
assembler routines 3.636Mbs max (80Mhz clock - max is clkfreq / 22)

because of rounding the actual bitrate will be:

clkfreq clkfreq desiredbaud u/ u/

usage:

\ allocate a serial structure, the txpin and the rxpin can be the same pin
d_9600 d_9600 d_16 d_16 hdserialStruct ser

\ to send data 
data ser hdserialTx
\ or for Open Collector drive
data ser hdserialTxOC

\ to receive data - this will wait for a byte
ser hdserialRx


to run tests:

uncomment hdserial_test definition
load this file

test -	starts test uses cog 0 & 1 , use pin 16 as the serial pin
	pin 17 is the default for test_syncPin, test_syncPin will
	be low while a character is transmitting. This is useful
	for debugging and syncing with LogicAnalyzer.
	Specifying an invalid output pin for test_syncPin will
	disable this.

testOC - same as test, but uses open collector

test_stat - dumps current test stat

test_test_error - causes an error by putting "noise on the pin"


}

\
\ uncomment this to use the forth routines instead of assembler
\
\ 1 wconstant hdserial_forth

\
\ uncomment this to include test routines
\
 1 wconstant hdserial_test

{
half duplex serial structure
00 - 04 -- rx bitticks
04 - 08 -- tx bitticks
08 - 0C -- rx pin mask
0C - 10 -- tx pin mask
}
\ hdserialStruct ( rxbaud txbaud rxpin txpin -- )
: hdserialStruct
	lockdict variable hC allot lastnfa nfa>pfa 2+ alignl freedict
	tuck swap >m swap hC + L!
	tuck swap >m swap h8 + L!
	tuck swap clkfreq swap u/ swap h4 + L!
	swap clkfreq swap u/ swap L!
;

{
fl
build_BootOpt :rasm
\ treg6 - serpin mask
\ treg5 - bitticks
\ treg4 - cnt nextbit
\ treg1 - serialStruct
\ stTOS - data
	spopt

	add	$C_treg1 , # h4
	rdlong	$C_treg5 , $C_treg1
	add	$C_treg1 , # h8
	rdlong	$C_treg6 , $C_treg1
\
\ serpin high
\
	or	outa , $C_treg6
	or	dira , $C_treg6
\
\ data + 2 stop bits + start bit
\
	or	$C_stTOS , __h300
	shl	$C_stTOS , # 1
\
\ first loop tick count count
\
	mov	$C_treg4 , $C_treg5
	add	$C_treg4 , cnt
	mov	$C_treg3 , # d_11
__txloop
	waitcnt	$C_treg4 , $C_treg5
	test	$C_stTOS , # 1 wz
	muxnz	outa , $C_treg6
	shr	$C_stTOS , # 1
	djnz	$C_treg3 , # __txloop
	spop
\
\ serpin in
\
	andn	dira , $C_treg6
\
	jexit
__h300
	h300
;asm hdserialTx


build_BootOpt :rasm
\ treg6 - serpin mask
\ treg5 - bitticks
\ treg4 - cnt nextbit
\ treg1 - serialStruct
\ stTOS - data
	spopt

	add	$C_treg1 , # h4
	rdlong	$C_treg5 , $C_treg1
	add	$C_treg1 , # h8
	rdlong	$C_treg6 , $C_treg1
\
\ serpin high
\
	andn	dira , $C_treg6
	andn	outa , $C_treg6
\
\ data + 2 stop bits + start bit
\
	or	$C_stTOS , __h300
	shl	$C_stTOS , # 1
\
\ first loop tick count count
\
	mov	$C_treg4 , $C_treg5
	add	$C_treg4 , cnt
	mov	$C_treg3 , # d_11
__txloop
	waitcnt	$C_treg4 , $C_treg5
	test	$C_stTOS , # 1 wz
	muxz	dira , $C_treg6
	shr	$C_stTOS , # 1
	djnz	$C_treg3 , # __txloop
	spop
\
\ serpin in
\
	andn	dira , $C_treg6
\
	jexit
__h300
	h300
;asm hdserialTxOC

build_BootOpt :rasm
\ treg6 - serpin mask
\ treg5 - bitticks
\ treg4 - cnt nextbit
\ treg1 - serialStruct
\ stTOS - data

	rdlong	$C_treg5 , $C_stTOS
	add	$C_stTOS , # h8
\
\ receive bit counter
\
	mov	$C_treg3 , # d_8
\
	rdlong	$C_treg6 , $C_stTOS
\
\ serpin as input
\
	andn	dira , $C_treg6
\
\ data byte
\
	mov	$C_stTOS , # 0
\
\ first loop tick count, 1.25 bit times  so we sample closer to the middle
\ necessary in the assembler routine, in the forth routine, the delays of the loop setup
\ make this unecessary so we only use 1 bit time
\
	mov	$C_treg4 , $C_treg5
	shr	$C_treg4 , # 2
	add	$C_treg4 , $C_treg5

\
\ wait for a hi to lo transition
\
	waitpeq	$C_treg6 , $C_treg6
	waitpne	$C_treg6 , $C_treg6
\
\ first loop tick count
\
	add	$C_treg4 , cnt
__rxloop
	waitcnt	$C_treg4 , $C_treg5
	test	$C_treg6 , ina	wz
\
	shr	$C_stTOS , # 1
	muxnz	$C_stTOS , # h_80
\
	djnz	$C_treg3 , # __rxloop
\
	jexit
;asm hdserialRx 
}

[ifndef hdserial_forth


lockdict create hdserialTx forthentry
$C_a_lxasm w, h128  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z20yPW4 l, z8iQ3C l, z20yPW8 l, z8iQBC l, z1bixZH l, z1bixmH l, z1biPSa l,
zfyPO1 l, z2WiPuG l, z20iPyk l, z2WyPjB l, z3riPuG l, z1YVPO1 l, z1vixZH l, zbyPO1 l,
z3[yPnV l, z1SyLI[ l, z1[ixmH l, z1SV01X l, zC0 l,
freedict


lockdict create hdserialTxOC forthentry
$C_a_lxasm w, h128  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z20yPW4 l, z8iQ3C l, z20yPW8 l, z8iQBC l, z1[ixmH l, z1[ixZH l, z1biPSa l,
zfyPO1 l, z2WiPuG l, z20iPyk l, z2WyPjB l, z3riPuG l, z1YVPO1 l, z1rixmH l, zbyPO1 l,
z3[yPnV l, z1SyLI[ l, z1[ixmH l, z1SV01X l, zC0 l,
freedict

lockdict create hdserialRx forthentry
$C_a_lxasm w, h125  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z8iQ3B l, z20yPO8 l, z2WyPj8 l, z8iQBB l, z1[ixmH l, z2WyPO0 l, z2WiPuG l, zbyPr2 l,
z20iPuG l, z3jFQBH l, z3nFQBH l, z20iPyk l, z3riPuG l, z1YFQFl l, zbyPO1 l, z1vyPQ0 l,
z3[yPnV l, z1SV01X l,
freedict

]

[ifdef hdserial_forth

\ _maskPinin ( mask -- )
: _maskPinin
	dira COG@ swap andn dira COG!
;

\ _maskPinout ( mask -- )
: _maskPinout
	dira COG@ swap or dira COG!
;


\ hdserialRx ( serialStruct -- data)
: hdserialRx
	dup h8 + L@ dup _maskPinin
\
\ serialStruct serpinmask --
\
	swap L@
\
\ serpinmask  bitticks--
\
\
\ wait for a start bit
\
	over dup dup dup
	waitpeq waitpne
	0 swap
\
\ serpinmask data bitticks --
\
\ sample first bit in 1 bit times
\
	dup cnt COG@ +
\
\ serpinmask data bitticks cnt_nextbit --
\
\ receive the bits, lsb first
\
	d8 0
	do
\
\ serpinmask data bitticks cnt_nextbit --
\
		over waitcnt
		3 ST@ _maskin
\
\ serpinmask data bitticks cnt_nextbit flag --
\
		if
			h80
		else
			0
		then
		3 ST@ 1 rshift or 2 ST!
	loop
\
\ clean up
\
	2drop nip
;



\ hdserialTX ( data serialStruct -- )
: hdserialTx
\
\ serpin hi
\
	dup hC + L@ dup _maskouthi dup _maskPinout swap
\
\ data serpinmask serialStruct
\
	4 + L@
\
\ data serpinmask bitticks --
\
\
\ data + 2 stop bits + start bit
\
	rot h300 or 1 lshift swap
\
\ serpinmask bits bitticks --
\
	dup cnt COG@ +
\ 
\ serpinmask bits bitticks cnt_nextbit --
\
\ send the bits, lsb first, send 1 stop bit at the beginning and one at the end
\
	d11 0
	do
\
\ serpinmask bits bitticks cnt_nextbit --
\
		over waitcnt
		2 ST@
\
\ serpinmask bits bitticks cnt_nextbit bits --
\
		dup 1 and
		if
			4 ST@ _maskouthi
		else
			4 ST@ _maskoutlo
		then
		1 rshift 2 ST!
	loop
\
\ clean up
\
	3drop
\
\ serpinmask -- 
	_maskPinin
;


\ hdserialTxOC ( data serialStruct -- )
: hdserialTxOC
\
\ serpin hi
\
	dup hC + L@ dup _maskoutlo dup _maskPinin swap
\
\ data serpinmask serialStruct
\
	4 + L@
\
\ data serpinmask bitticks --
\
\
\ data + 2 stop bits + start bit
\
	rot h300 or 1 lshift swap
\
\ serpinmask bits bitticks --
\
	dup cnt COG@ +
\ 
\ serpinmask bits bitticks cnt_nextbit --
\
\ send the bits, lsb first, send 1 stop bit at the beginning and one at the end
\
	d11 0
	do
\
\ serpinmask bits bitticks cnt_nextbit --
\
		over waitcnt
		2 ST@
\
\ serpinmask bits bitticks cnt_nextbit bits --
\
		dup 1 and
		if
			4 ST@ _maskPinin
		else
			4 ST@ _maskPinout
		then
		1 rshift 2 ST!
	loop
\
\ clean up
\
	3drop
\
\ serpinmask -- 
	_maskPinin
;
]


[ifdef hdserial_test

d_9600 d_9600 d_16 d_16 hdserialStruct ser

d_17 wconstant test_syncPin

\ _maskPinin ( mask -- )
: _maskPinin
	dira COG@ swap andn dira COG!
;

\ _maskPinout ( mask -- )
: _maskPinout
	dira COG@ swap or dira COG!
;


variable numtestchars
variable numtesterrors

: test_transmit
	c" TEST_TX" cds W!
	4 state andnC!
	test_syncPin 0 d_31 between
	if
		test_syncPin >m dup _maskPinout
	else
		0
	then
	begin
		key over _maskoutlo ser hdserialTx dup _maskouthi
	0 until
;

: test_transmitOC
	c" TEST_TX" cds W!
	4 state andnC!
	test_syncPin 0 d_31 between
	if
		test_syncPin >m dup _maskPinout
	else
		0
	then
	begin
		key over _maskoutlo ser hdserialTxOC dup _maskouthi
	0 until
;

: test_loop
	0 numtestchars L!
	0 numtesterrors L!
	c" TEST_RX" cds W!
	4 state andnC!
	0 cogreset 100 delms c" test_transmit" 0 cogx
	cogid 0 ioconn
	0 begin
		dup numtestchars L!
		dup hFF and dup emit
		ser hdserialRx
		2dup <>
		if
			numtesterrors L@ 1+ numtesterrors L!
			hex c" actual: " .concstr .conbyte c"  expected: " .concstr .conbyte .concr
		else
			2drop
		then
		1+
	0 until
;

: test_loopOC
	0 numtestchars L!
	0 numtesterrors L!
	c" TEST_RX" cds W!
	4 state andnC!
	0 cogreset 100 delms c" test_transmitOC" 0 cogx
	cogid 0 ioconn
	0 begin
		dup numtestchars L!
		dup hFF and dup emit
		ser hdserialRx
		2dup <>
		if
			numtesterrors L@ 1+ numtesterrors L!
			hex c" actual: " .concstr .conbyte c"  expected: " .concstr .conbyte .concr
		else
			2drop
		then
		1+
	0 until
;

: test
	1 iodis
	1 cogreset 100 delms c" test_loop" 1 cogx
;

: testOC
	1 iodis
	1 cogreset 100 delms c" test_loopOC" 1 cogx
;

: test_stat
	." num chars: " numtestchars L@ . ." num errors: " numtesterrors L@ . cr
;

: test_test_error
	ser hC + L@
	dup _maskouthi dup _maskPinout
	d_10 delms
	dup _maskoutlo _maskPinin
;

\ test_set_baud ( baud -- )
: test_set_baud
	clkfreq swap u/ ser 2dup L! 4+ L!
;
]

