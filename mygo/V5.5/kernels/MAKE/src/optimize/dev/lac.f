\
\
1 wconstant build_LogicAnalyzer
\
\
\ define this constant if the console code is needed
\
\
{
\ demo run on cog6


\ example1
\ 40 cycles clkfreq 40 2* /

c" 0 1000000 setHza 1  500000 setHzb" 0 cogx
c" 2  250000 setHza 3  125000 setHzb" 1 cogx
lac

\ example2
\ 41 cycles clkfreq 41 2* /
c" 0 975610 setHza 1 487805 setHzb" 0 cogx
c" 2 243902 setHza 3 121951 setHzb" 1 cogx
lac

\ example3
\ 50 cycles clkfreq 50 2* /

c" 0 800000 setHza 1 400000 setHzb" 0 cogx
c" 2 200000 setHza 3 100000 setHzb" 1 cogx
lac



\
\
\ if laconsole is not defined
\ example1
\ 40 cycles clkfreq 40 2* /

c" 0 1000000 setHza 1  500000 setHzb" 0 cogx
c" 2  250000 setHza 3  125000 setHzb" 1 cogx
80 0 la_sample+Trigger
40 0 la_sample+Trigger
20 0 la_sample+Trigger
4 0 la_sample+Trigger
1 0 la_sample+Trigger

\ example2
\ 41 cycles clkfreq 41 2* /
c" 0 975610 setHza 1 487805 setHzb" 0 cogx
c" 2 243902 setHza 3 121951 setHzb" 1 cogx
82 0 la_sample+Trigger
41 0 la_sample-Trigger
20 0 la_sample-Trigger
4 0 la_sample-Trigger
1 0 la_sample-Trigger

\ example3
\ 50 cycles clkfreq 50 2* /

c" 0 800000 setHza 1 400000 setHzb" 0 cogx
c" 2 200000 setHza 3 100000 setHzb" 1 cogx
50 la_sampleNoTrigger
25 la_sampleNoTrigger
4 la_sampleNoTrigger
1 la_sampleNoTrigger

}
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
\ pinout ( n1 -- ) set pin # n1 to an output
[ifndef pinout
: pinout
	>m dira COG@ or dira COG!
;
]

\
\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[ifndef variable
: variable
	lockdict create $C_a_dovarl w, 0 l, forthentry freedict
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
\
\
\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
[ifndef 2*
: 2* _xasm2>1IMM h0001 _cnip h05F _cnip ; 
]
\
\
\ key? ( -- t/f) true if there is a key ready for input
[ifndef key?
: key?
	io W@ h100 and 0=
;
]

\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[ifndef u*/mod
: u*/mod rot2 um* rot um/mod ; 
]

\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[ifndef u*/
: u*/ rot2 um* rot um/mod nip ; 
]

\ _cfo ( n1 -- n2 ) n1 - desired frequency, n2 freq a 
[ifndef _cfo
: _cfo clkfreq 1- min 0 swap clkfreq um/mod swap clkfreq 2/ >= abs + ; 
]

\ setHza ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctra
\ set the pin oscillating at the specified frequency
[ifndef setHza
: setHza _cfo frqa COG! dup pinout h10000000 + ctra COG! ; 
]

\ qHzb ( n1 n2 -- n3 ) n1 - the pin, n2 - the # of msec to sample, n3 the frequency
[ifndef qHzb
: qHzb
	swap h28000000 + 1 frqb COG! ctrb COG!
	h3000 min clkfreq over h3E8 u*/ h310 - phsb COG@ swap cnt COG@ + 0 waitcnt
	phsb COG@ nip swap - h3E8 rot u*/ ; 
]

\ setHzb ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctrb
\ set the pin oscillating at the specified frequency
[ifndef setHzb
: setHzb _cfo frqb COG! dup pinout h10000000 + ctrb COG! ; 
]

\ crcl ( -- ) cr and clear the line (for an ansi terminal)
[ifndef crcl
: crcl ." ~h0D~h1B~h5B~h4B" ; 
]

\ hm ( -- ) ansi home
[ifndef hm
: hm ." ~h1B~h5B~h48" ; 
]

\ hmclr ( -- ) ansi home and clear screen
[ifndef hmclr
: hmclr ." ~h1B~h5B~h48~h1B~h5B~h4A" ; 
]


\
\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[ifndef #C
: #C
	-1 >out W+! pad>out C!
	
;
]

\
\ _nf ( n1 -- cstr ) formats n1 to a fixed format 16 wide, leading spaces variable, one trailing space
[ifndef _nf
: _nf
	<# bl #C # # # h2C #C # # # h2C #C # # #  h2C #C # # # #>
	dup C@++ bounds
	do
		i C@ dup isdigit swap todigit 0<> and  
		if
			leave
			
		else
			bl i C!
		then
	loop
;
]

\
\ .num ( n1 -- ) print n1 as a fixed format number
[ifndef .num
: .num
	_nf .cstr
;
]

[ifndef freeDictStart
\ freeDictStart ( -- addr ) the start address of the unused dictionary, long aligned
: freeDictStart
	here W@ alignl
;
]

[ifndef freeDictEnd
\ freeDictEnd ( -- addr ) the end address of the unused dictionary, long aligned
: freeDictEnd
	dictend W@ h3 andn
;
]

[ifndef zeroFreeDict
\ zeroFreeDict ( -- ) zeros out all the unused dictionary
: zeroFreeDict
	freeDictEnd freeDictStart
	do
		0 i L!
	h4 +loop
;
]


\ This block is low level code which sets up and manipulates the assembler necessary 

\ variable definitions and addresses for assembler routines

\
\ _la_asample41+ ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples)
\ _la_asample18+ ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples)
\ _la_asample4 ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples)
\ _la_sample1 ( baseaddr startcount -- numsamples )
\

lockdict create _la_asample41+ forthentry
$C_a_lxasm w, h12A  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z2WiQBB l, z1SyLI[ l, z2WiQ3B l, z1SyLI[ l, z2WiPuB l, z1SyLI[ l, z2WiPmB l, z1SyLI[ l,
z2WiPeB l, z1SyLI[ l, z2WiPZB l, z2WiPRD l, z3jFPuH l, z3jFQ3H l, z2WiQFl l, z2WiQ7k l,
z20iQ3E l, z8FQBC l, z3riQ3E l, z2WiQFl l, z20yPW4 l, z3[yPf[ l, z1SV01X l,
freedict

lockdict create _la_asample18+ forthentry
$C_a_lxasm w, h131  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z2WiQBB l, z1SyLI[ l, z2WiQ3B l, z1SyLI[ l, z2WiPuB l, z1SyLI[ l, z2WiPmB l, z1SyLI[ l,
z1SyLI[ l, z2WiPZB l, z2WyPij l, z24yPfi l, z2WiPRD l, z3jFPuH l, z3jFQ3H l, z2Wi\yl l,
z2WiQ7k l, z20iQ3E l, z3riQ3E l, z2Wi]7l l, z20i[m2 l, z3[yPf\ l, z2WiPeB l, z8F\uC l,
z20i\J2 l, z20yPW4 l, z3[yPfd l, z1SV01X l, 0 l, 0 l,
freedict

lockdict create _la_asample4 forthentry
$C_a_lxasm w, h135  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z2WiQBB l, z1SyLI[ l, z2WiQ3B l, z1SyLI[ l, z2WiPuB l, z1SyLI[ l, z1SyLI[ l, z1SyLI[ l,
z2WiPZB l, z2WyPij l, z24yPb1 l, z1Ki\3D l, z24yPfn l, z2WiPRD l, z2Wi][j l, z1Ky][n l,
z20i[B2 l, z20i[J2 l, z20y[G1 l, z3[yPfX l, z1Gy]Cd l, z2Wi04k l, z1SV04l l, z2WiPeB l,
z8F]ZC l, z20i\R2 l, z20yPW4 l, z3[yPfe l, z1SV01X l, z2Wi07l l, z1SV000 l, z3jFPuH l,
z3jFQ3H l, 0 l,
freedict

lockdict create _la_asample1 forthentry
$C_a_lxasm w, h12E  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z2WiQBB l, z1SyLI[ l, z2WiPZB l, z2WyPij l, z24yPb1 l, z1Ki[JD l, z24yPfg l, z2WiPRD l,
z2Wi\fd l, z1Ky\fg l, z20iZR2 l, z20iZZ2 l, z20yZW1 l, z3[yPfR l, z1Gy\S[ l, z2Wi04e l,
z1SV04f l, z2WiPeB l, z8F\eC l, z20i[e2 l, z20yPWG l, z3[yPf\ l, z1SV01X l, z2Wi07l l,
z1SV000 l, z3ryQ80 l, 0 l,
freedict


\ this variable which is used to synch the 4 cogs which are doing interleaved sampling
variable _la_s1time

wvariable _la_s1addr

\ this variable value is the first of 4 sequential cogs used to sample every clock cycle, default to this cog 2

wvariable _la_s1cog 2 _la_s1cog W!
wvariable _la_s1size

\ _la_is1 ( -- ) this is the interleaved routine used by 4 cogs to sample very clock cycle
: _la_is1
	_la_s1addr W@ cogid _la_s1cog W@ - 2* 2* +
	_la_s1time L@ cogid _la_s1cog W@ - +
	_la_asample1
	2* 2* _la_s1size W!
;

\ _la_sample1 ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples)
: _la_sample1
	3drop 2drop
	_la_s1addr W!
	_la_s1cog W@ dup cogreset
	1+ dup cogreset
	1+ dup cogreset
	1+ cogreset
	zeroFreeDict
	h10 delms
	clkfreq cnt COG@ + _la_s1time L!
	c" _la_is1"
	dup _la_s1cog W@ cogx
	dup _la_s1cog W@ 1+ cogx
	dup _la_s1cog W@ 2+ cogx
	_la_s1cog W@ h3 + cogx
	_la_s1time L@ h8000 + 0 waitcnt drop
	_la_s1size W@
;

\ _la_sample ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numSamples )
: _la_sample
	h4 ST@ h310 >=
	if
		h3 ST@ h29 >=
		if
			_la_asample41+
		else

			h3 ST@ h12 >=
			if
				_la_asample18+
			else

				h3 ST@ h4 =
				if
					_la_asample4
				else
	
					h3 ST@ 1 =
					if
						_la_sample1
					else

						3drop 3drop 0
					then
				then
			then
		then
	else
		3drop 3drop 0
	then
;

variable _la_mask -1 _la_mask L!


\ _la_displayPin ( n1 n2 -- ) show 128 samples starting at position n1 for pin n2
: _la_displayPin
	>m dup _la_mask L@ and
	if
		swap 2* 2* freeDictStart + h200 bounds
		do
			i L@ over and if h2D else h5F then emit
		h4 +loop
	else
		drop
		h80 0
		do
			h58 emit
		loop
	then
	drop
;


wvariable _la_current 0 _la_current W!
wvariable _la_end h80 _la_end W!

variable _la_trigger 0 _la_trigger L!
variable _la_triggerEdge 1 _la_triggerEdge L!
variable _la_lastTriggerEdge 1 _la_lastTriggerEdge L!

variable _la_triggerFrequency 0 _la_triggerFrequency L!

variable _la_sampleInterval h28 _la_sampleInterval L!
variable _la_lastSampleInterval h28 _la_lastSampleInterval L!

variable _la_L10nc
\ _la_L10nc 10,000,000 / (clkfreq/1000) - the number of nS per clock count x 10
h989680 clkfreq h3E8 u/ u/ _la_L10nc L!

\ _la_L1 ( n1 -- ) emit n1 as decimal ###.#
: _la_L1
	hA u/mod swap <# # drop h2E #C # # # #> .cstr
;

\ _la_LST ( n1 -- ) emit n1 in (x)Seconds format
: _la_LST
	_la_L10nc L@ u* dup h2710 <
	if
		_la_L1 ."  nS"
	else
		h3E8 u/ dup h2710 <
		if
			_la_L1 ."  uS"
		else
			h3E8 u/ dup h2710 <
			if
				_la_L1 ."  mS"
			else
				drop
	thens
;

\
\ _lacv ( -- ) print out vertical lines every 16 position leaving 2 spaces at the beginning
: _lacv
	h11 spaces h7C emit
	h7 0
	do
		hF spaces h7C emit
	loop
	cr
;

\
\ _la_interval ( n1 -- ) adjust the sample interval by n1
: _la_interval
	_la_sampleInterval L@
	dup _la_lastSampleInterval L!
	over +
	_la_sampleInterval L!
	0<
	if
		_la_sampleInterval L@ h12 <
		if
			_la_sampleInterval L@ h4 <
			if
				1
				_la_triggerEdge L@ _la_lastTriggerEdge L!
				0 _la_triggerEdge L!
			else
				h4
			then
			_la_sampleInterval L!
		then
	else
		_la_sampleInterval L@ h12 <
		if
			_la_sampleInterval L@ h4 <
			if
				h4
				0 _la_triggerEdge L!
			else
				h12
			then
			_la_sampleInterval L!
		then
	then
	_la_lastSampleInterval L@ 1 =
	_la_sampleInterval L@ 1 <> and
	if
		_la_lastTriggerEdge L@ _la_triggerEdge L!
	then

;

\
\ _la_dStart ( flag flag n1 -- 0 -1 ) adjust the starting diplay position
: _la_dStart
	_la_current W@ + 0 max
	_la_end W@ h80 - 0 max min
	_la_current W!
	2drop 0 -1
;

\
\ _la_pin ( n1 -- ) adjust the trigger pin
: _la_pin
	_la_trigger L@ + 0 max h1F min
	_la_triggerEdge L@ 0= _la_sampleInterval 1 =  or
	if
		0 _la_triggerFrequency L!
	else
		dup hF0 qHzb _la_triggerFrequency L!
	then
	_la_trigger L!
;

\ _la_k1 ( key flag -- key flag ) process key input
: _la_k1
	over h7A = if
		-1 _la_dStart
	else over h78 = if
		h-A _la_dStart
	else over h63 = if
		h-64 _la_dStart
	else over h76 = if
		h-3E8 _la_dStart
	else over h5A = if
		1 _la_dStart
	else over h58 = if
		hA _la_dStart
	else over h43 = if
		h64 _la_dStart
	else over h56 = if
		h3E8 _la_dStart
	else over h61 = if
		-1 _la_interval
	else over h73 = if
		h-A _la_interval
	else over h64 = if
		h-64 _la_interval
	else over h66 = if
		h-3E8 _la_interval
	else over h67 = if
		h-2710 _la_interval
	else over h41 = if
		1 _la_interval
	else over h53 = if
		hA _la_interval
	else over h44 = if
		h64 _la_interval
	else over h46 = if
		h3E8 _la_interval
	else over h47 = if
		h2710 _la_interval
	thens
;

\
\ _la_h ( -- ) display header
: _la_h
	hm crcl
	."     Trigger Pin      -q    +Q: " _la_triggerEdge W@ 0= if ." NONE" else  _la_trigger L@ . then crcl
	."    Trigger Edge   -w +W SPACE: " _la_triggerEdge L@ 0=
		if ." NONE" else  _la_triggerEdge L@ 0< if ." --__" else  ." __--" else  then then crcl
	." Trigger Frequency         eE : "
	_la_triggerEdge L@ if _la_triggerFrequency L@ .num else ." NO TRIGGER FOUND" then crcl
		
	." Sample Interval -asdfg +ASDFG: " _la_sampleInterval L@ dup _la_LST  .num ." clock cycles" crcl
	."          Sample     <ENTER>" crcl
	."          Quit         <ESC>" crcl
	." Sample Display  -zxcv  +ZXCV : " _la_current W@ .num ." clock cycles of " _la_end W@ .num crcl
;


\ _la_k ( -- key flag ) process key input
: _la_k
\ ( key 0 -- )
	key 0
	over h71 = if
		-1 _la_pin
	else over h51 = if
		1 _la_pin
	else over h65 = if
		_la_trigger L@ h3E8 qHzb _la_triggerFrequency L!
	else over h45 = if
		_la_trigger L@ h7D0 qHzb _la_triggerFrequency L!
	else over h20 = if
		0 _la_triggerEdge L!
		0 _la_trigger L!
		0 _la_triggerFrequency L!
	else over h77 = if
		-1 _la_triggerEdge L!
		0 _la_pin
	else over h57 = if
		1 _la_triggerEdge L!
		0 _la_pin
	else over hD = if
		_la_sampleInterval L@ 1 =
		if
			hmclr
		then
\ _la_sample ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numSamples )
			zeroFreeDict
			freeDictStart
			freeDictEnd over - 2/ 2/
			_la_sampleInterval L@

			_la_triggerFrequency L@
			if
				_la_triggerEdge L@ 0>
				if
					0
					_la_trigger L@ >m
					dup
				else
					_la_trigger L@ >m
					0
					over
				then
			else
				0 0 0
			then
			_la_sample
			_la_end W! 
\		then

		2drop 0 -1
	else over h1B = if
		2drop -1 -1
	thens
	_la_k1
;

\
\ lac ( -- )
: lac
	0 _la_pin
	zeroFreeDict
	hmclr _la_h

	begin
		0
		begin
			drop key?
			if
				_la_k _la_h
			else
				0 0
			then
		until
		dup 0=
		if
			h20 0
			do
				_lacv
				space space
				_la_current W@ h10 + h80 bounds
				do
					h7 spaces _la_current W@ _la_sampleInterval L@ i u* + _la_LST h7C emit 
				h10 +loop
				cr
				_lacv

				i h4 bounds
				do
					h1F i - dup <# # # #> .cstr
					_la_current W@ swap _la_displayPin
					crcl
				loop
			h4 +loop
			hm
		then

	until
	hmclr
;



\ la_displaySamples ( n1 n2 -- ) display samples starting at position n1 for 8 pins starting at pin n2
: la_displaySamples
	dup h8 + swap
	do
		i <# # # #> .cstr
		dup i _la_displayPin
		cr
	loop drop
;

\ la_sampleNoTrigger ( n1 -- ) sample every n1 clocks and display 128 samples starting from position 0
: la_sampleNoTrigger
	>r
	freeDictStart freeDictEnd over - 2/ 2/
	r>
	0 0 0 _la_sample drop
 	0 0  la_displaySamples
 	0 h8  la_displaySamples
 	0 h10 la_displaySamples
 	0 h18 la_displaySamples
;

\ la_sample+Trigger ( n1 n2 -- ) sample every n1 clock +ve edge and display 128 samples starting from position 0,
\ trigger on pin n2
: la_sample+Trigger
	>r >r
	freeDictStart freeDictEnd over - 2/ 2/
	r>
 	0 r> >m dup _la_sample drop
 	0 0  la_displaySamples
 	0 h8  la_displaySamples
 	0 h10 la_displaySamples
 	0 h18 la_displaySamples
;

\ la_sample-Trigger ( n1 n2 -- ) sample every n1 clock -ve edge and display 128 samples starting from position 0,
\ trigger on la_triggerPin
: la_sample-Trigger
	>r >r
	freeDictStart freeDictEnd over - 2/ 2/
	r>
 	r> >m 0 over _la_sample drop
 	0 0  la_displaySamples
 	0 h8  la_displaySamples
 	0 h10 la_displaySamples
 	0 h18 la_displaySamples
;



{









fl

hA state orC!

\ _la_asample41+ ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples)
build_BootOpt :rasm
\ trigger mask
	mov	$C_treg6 , $C_stTOS
	spop
\ trigger after
	mov	$C_treg5 , $C_stTOS
	spop
\ trigger before
	mov	$C_treg4 , $C_stTOS
	spop

\ sample cycle
	mov	$C_treg3 , $C_stTOS
	spop

\ num samples
	mov	$C_treg2 , $C_stTOS
	spop

\ base address - $C_treg1
	mov	$C_treg1 , $C_stTOS

	mov	$C_stTOS , $C_treg2
\	 
\ $C_treg1 - baseaddr
\ $C_treg2 - numsamples
\ $C_treg3 - samplecycle
\ $C_treg4 - triggerbefore
\ $C_treg5 - triggerafter
\ $C_treg6 - triggermask
\
\
\ wait for trigger
\
	waitpeq $C_treg4 , $C_treg6
	waitpeq $C_treg5 , $C_treg6
\
\ get the sample and set up the count for the next sample 
\
\
\                                               t = 0
	mov	$C_treg6 , ina
\                                               t = 4
	mov	$C_treg5 , cnt
\                                               t = 8
	add	$C_treg5 , $C_treg3
\
\ $C_treg1 - baseaddr
\ $C_treg2 - numsamples
\ $C_treg3 - samplecycle
\ $C_treg4 - triggerbefore
\ $C_treg5 - nextcounttosample
\ $C_treg6 - current sample
\
__1
\
\ write out the sample
\
\                                               t = 12
	wrlong	$C_treg6 , $C_treg1
\
\ wait for the next sample time
\
\                                               t = 20 - 35
	waitcnt $C_treg5 , $C_treg3
\                                               t = 26 - 41
\                                                            t = 0
	mov	$C_treg6 , ina	
\                                                            t = 4
	add	$C_treg1 , # 4
\                                                            t = 8
	djnz	$C_treg2 , # __1
\                                                            t = 12

\ we are done
	jexit
\
;asm _la_asample41+





\ _la_asample18+ ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples )
build_BootOpt :rasm
\ trigger mask
	mov	$C_treg6 , $C_stTOS
	spop
\ trigger after
	mov	$C_treg5 , $C_stTOS
	spop
\ trigger before
	mov	$C_treg4 , $C_stTOS
	spop

\ sample cycle
	mov	$C_treg3 , $C_stTOS
	spop

\ num samples
\	mov	$C_treg2 , $C_stTOS
	spop

\ base address - $C_treg1
	mov	$C_treg1 , $C_stTOS

	mov	$C_treg2 , # par
	sub	$C_treg2 , # __buffer
	mov	$C_stTOS , $C_treg2
\	 
\ $C_treg1 - baseaddr
\ $C_treg2 - numsamples
\ $C_treg3 - samplecycle
\ $C_treg4 - triggerbefore
\ $C_treg5 - triggerafter
\ $C_treg6 - triggermask
\
\
\ wait for trigger
\
	waitpeq $C_treg4 , $C_treg6
	waitpeq $C_treg5 , $C_treg6
\
\ get the sample and set up the count for the next sample 
\
\
\                                               t = 0
	mov	__buffer , ina
\                                               t = 4
	mov	$C_treg5 , cnt
\                                               t = 8
	add	$C_treg5 , $C_treg3
\
\ $C_treg1 - baseaddr
\ $C_treg2 - numsamples
\ $C_treg3 - samplecycle
\ $C_treg4 - triggerbefore
\ $C_treg5 - nextcounttosample
\ $C_treg6 - current sample
\
__1
\
\ wait for the next sample time
\
\                                               t = 12
	waitcnt $C_treg5 , $C_treg3
\                                               t = 18
\                                                            t = 0
__2
	mov	__buffer1 , ina	
\                                                            t = 4
	add	__2 , $C_fDestInc
\                                                            t = 8
	djnz	$C_treg2 , # __1
\                                                            t = 12

	mov	$C_treg2 , $C_stTOS
__3
	wrlong	__buffer , $C_treg1


	add	__3 , $C_fDestInc
	add	$C_treg1 , # 4

	djnz	$C_treg2 , # __3


\ we are done
	jexit
__buffer
 0
__buffer1
 0
\
;asm _la_asample18+







\ _la_asample4 ( baseaddr numsamples samplecycle triggerbefore triggerafter triggermask -- numsamples )
build_BootOpt :rasm
\ trigger mask
	mov	$C_treg6 , $C_stTOS
	spop
\ trigger after
	mov	$C_treg5 , $C_stTOS
	spop
\ trigger before
	mov	$C_treg4 , $C_stTOS
	spop

\ sample cycle
	spop

\ num samples
	spop

\ base address - $C_treg1
	mov	$C_treg1 , $C_stTOS

	mov	$C_treg2 , # par
	sub	$C_treg2 , # 1
	movd	__3 , $C_treg2

	sub	$C_treg2 , # __buffer
	mov	$C_stTOS , $C_treg2

__1
	mov	__buffer , __inainst
__2
	movd	__buffer , # __buffer
	add	__1 , $C_fDestInc
	add	__2 , $C_fDestInc
	add	__2 , # 1
	djnz	$C_treg2 , # __1


	movs	__jmpinst , # __4
__3
	mov	0 , __jmpinst

	jmp	# __sample
		
__4

	mov	$C_treg2 , $C_stTOS
__5
	wrlong	__buffer , $C_treg1


	add	__5 , $C_fDestInc
	add	$C_treg1 , # 4

	djnz	$C_treg2 , # __5


\ we are done
	jexit


__inainst
	hA0BC01F2
__jmpinst
	h5C7C0000
\
\ wait for trigger
\
__sample
	waitpeq $C_treg4 , $C_treg6
	waitpeq $C_treg5 , $C_treg6
__buffer
 0

\
;asm _la_asample4




\ _la_asample1 ( baseaddr startcount -- numsamples )
build_BootOpt :rasm
\ startcount
	mov	$C_treg6 , $C_stTOS
	spop

\ base address
	mov	$C_treg1 , $C_stTOS



	mov	$C_treg2 , # par
	sub	$C_treg2 , # 1
	movd	__3 , $C_treg2

	sub	$C_treg2 , # __buffer
	mov	$C_stTOS , $C_treg2

__1
	mov	__buffer , __inainst
__2
	movd	__buffer , # __buffer
	add	__1 , $C_fDestInc
	add	__2 , $C_fDestInc
	add	__2 , # 1
	djnz	$C_treg2 , # __1


	movs	__jmpinst , # __4
__3
	mov	0 , __jmpinst

	jmp	# __sample
		
__4

	mov	$C_treg2 , $C_stTOS
__5
	wrlong	__buffer , $C_treg1

	add	__5 , $C_fDestInc
	add	$C_treg1 , # h10

	djnz	$C_treg2 , # __5


\ we are done
	jexit


__inainst
	hA0BC01F2
__jmpinst
	h5C7C0000
\
\ wait for trigger
\
__sample
	waitcnt $C_treg6 , # 0
__buffer
 0

\
;asm _la_asample1



hA state andC!








}

