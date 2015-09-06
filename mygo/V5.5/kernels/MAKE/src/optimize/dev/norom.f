
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


c" onboot" find drop pfa>nfa 1+ c" onb001" C@++ rot swap cmove

: onboot onb001
\ get rid of any error code on the stack, not valid
	drop 0 
\ set the prompts assuming we are the master
	c" MASTERProp" prop W! 0 propid W!
	h40 0
	do
		h1C 1 qHzb h90000 hA0000 between
		if
\ reset the prompts to slave prompts
			c"  SLAVEProp" prop W! h8 propid W!
			1 _finit andnC! leave
		then
	loop
;
 
{

fl

\ the assembler for the eeprom emulator
\
\


build_BootOpt :rasm

		mov	__7v_sdata , $C_stTOS
		spop
		mov	__6v_sclk , $C_stTOS
		spop
		jmp	# __5
__6v_sclk
 0 
__7v_sdata
 0
__1_32k
 h8000



\ wait for a start bit from the slave prop
__8slavewaitstart
		waitpeq	__6v_sclk	, __6v_sclk
		waitpeq	__7v_sdata	, __7v_sdata
		waitpne	__7v_sdata	, __7v_sdata		
		waitpne __6v_sclk	, __6v_sclk
__9slavewaitstartret
		ret


\ read a byte from the slave prop, give it an ack
__Aslavereadbyte
		mov	$C_treg6 	, # h8
__Flp
\ wait for a positive edge on the clock
		waitpeq __6v_sclk	, __6v_sclk
\ wait for a negative edge
		waitpne __6v_sclk	, __6v_sclk
		djnz	$C_treg6	, # __Flp

\ set the ack bit for the slave, master receives ack bit from eeprom (ignore)
		or	dira	, __7v_sdata
\ wait for a positive edge on the clock
		waitpeq __6v_sclk	, __6v_sclk
\ wait for a negative edge on the clock
		waitpne __6v_sclk	, __6v_sclk
\ release the ack bit for the slave
		andn	dira	, __7v_sdata
__Bslavereadbyteret
		ret





__5
		andn	dira	, __6v_sclk
		andn	dira	, __7v_sdata
		andn	outa	, __7v_sdata

\ wait for a start bit
		jmpret	__9slavewaitstartret , # __8slavewaitstart

\ read the start command and the address
		jmpret	__Bslavereadbyteret , # __Aslavereadbyte
		jmpret	__Bslavereadbyteret , # __Aslavereadbyte
		jmpret	__Bslavereadbyteret , # __Aslavereadbyte

\ wait for a start bit
		jmpret	__9slavewaitstartret , # __8slavewaitstart
		jmpret	__Bslavereadbyteret , # __Aslavereadbyte

\ read 32k bytes		
		mov	$C_treg6	, __1_32k
		mov	$C_treg1	, # 0
__Flp
		rdbyte	$C_treg2	, $C_treg1
		add	$C_treg1	, # 1

		mov	$C_treg5	, # h8
__Elp
\ read the data from the master's ram and echo to the slave
		test	$C_treg2	, # h80 wc
		shl	$C_treg2	, # 1
		muxnc	dira	, __7v_sdata

\ wait for a positive edge
		waitpeq	__6v_sclk	, __6v_sclk
\ wait for a negative edge
		waitpne	__6v_sclk	, __6v_sclk

		djnz	$C_treg5	, # __Elp

		andn	dira	, __7v_sdata

\ wait for a positive edge
		waitpeq	__6v_sclk	, __6v_sclk

\ wait for a negative edge
		waitpne	__6v_sclk	, __6v_sclk
		djnz	$C_treg6	, # __Flp

		jexit

;asm a_ram		


}



