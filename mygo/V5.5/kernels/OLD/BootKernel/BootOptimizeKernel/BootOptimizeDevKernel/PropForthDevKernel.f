fl


\ fswrite DevKernel.f
\ mountsys
\ 100 fwrite DevKernel.f

1 wconstant build_DevKernel

\ Copyright (c) 2011 Sal Sanci
\ 
\ These words are all optional words.



\ serflags? ( n1 -- n2 ) n2 are the serial flags for the serial driver running on cog n1
[ifndef serflags?
: serflags?
	cogio hC8 + L@
;
]

\ sersetflags ( n2 n1 -- O ) for the serial driver running on cog n1, set the flags to n2
[ifndef sersetflags
: sersetflags
	cogio hC8 + L!
;
]

\ sersendbreak ( n2 n1 -- ) for the serial driver running on cog n1, send a break of n2 clock cycles
[ifndef sersendbreak
: sersendbreak
	cogio hC4 + L!
;
]

[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]

[ifndef $C_a__xasm2>1IMM
    h13 wconstant $C_a__xasm2>1IMM
]

[ifndef $C_a__xasm2>1
    h16 wconstant $C_a__xasm2>1
]

[ifndef $C_a_doconl
    h52 wconstant $C_a_doconl
]

[ifndef $C_rsTop
    h112 wconstant $C_rsTop
]

[ifndef $C_stTop
    hF2 wconstant $C_stTop
]

[ifndef $C_stTOS
    hCB wconstant $C_stTOS
]

[ifndef $C_rsPtr
    hCA wconstant $C_rsPtr
]

[ifndef $C_stPtr
    hC9 wconstant $C_stPtr
]

\
\ lasti? ( -- t/f ) true if this is the last value of i in this loop, assume an increment of 1
[ifndef lasti?
: lasti?
	1 RS@ h2 RS@ 1+ =
;
]

\
\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[ifndef #C
: #C
	-1 >out W+! pad>out C!
;
]

\
\
\ some very common formatting routines, for use with hex, decimal or octal
\ will work with other bases, but not optimally 
\
\
\ _nd ( n1 -- n2 ) internal format routine
[ifndef _nd
: _nd
	base W@ d_40 over <
	if
		d_6
	else
		d_15 over <
		if
			d_8
		else
			d_9 over <
			if
				d_10
			else
			d_7 over <
				if
					d_11
				else
				d_6 over <
					if
						d_12
					else
						d_3 over <
						if
							d_16
						else
							d_32
	thens
	nip
	swap u/mod swap 0<>
	if
		1+
	then
;
]	
\
\ _ft ( n1 divisor -- cstr ) internal format routine
[ifndef _ft
: _ft
\ set to output an underscore every 4 digits, or 3 if the base it 8 - 10
	h4 base W@ h_8 h_A between
	if
		1-
	then
	rot2
	<#
	_nd 0
	do
		#
		over i 1+ swap u/mod drop
		0=
		if
			lasti? 0=
			if
				h_5F #C
			then
		then
	loop
	#>
	nip
;
]
\ _bf ( n1 -- cstr ) format n1 as a byte
[ifndef _bf
: _bf
	4 _ft
;
]
\
\ .byte ( n1 -- ) output a byte
[ifndef .byte
: .byte
	h_FF and _bf .cstr
;
]
\
\
\ _wf ( n1 -- cstr ) format n1 as a word
[ifndef _wf
: _wf
	h_FFFF and 2 _ft
;
]
\
\
\ .word ( n1 -- ) output a word
[ifndef .word
: .word
	_wf .cstr
;
]
\
\
\ _lf ( n1 -- cstr ) format n1 as a long
[ifndef _lf
: _lf
	1 _ft
;
]
\
\
\ .long ( n1 -- ) output a long
[ifndef .long
: .long
	_lf .cstr
;
]
\
\
\ xor ( n1 n2 -- n1_xor_n2 ) \ bitwise xor
[ifndef xor
: xor _xasm2>1 h0DF _cnip ;
]
\
\
\ 4- ( n1 -- n1-4 )
[ifndef 4-
: 4- _xasm2>1IMM h0004 _cnip h10F _cnip ;
]
\
\
\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
[ifndef 2*
: 2* _xasm2>1IMM h0001 _cnip h05F _cnip ; 
]
\
\
\ 4/ ( n1 -- n1>>2 ) n2 is shifted arithmetically right2 bits
[ifndef 4/
: 4/ _xasm2>1IMM h0002 _cnip h077 _cnip ;
]
\
\ u> ( u1 u2 -- t/f ) \ flag is true if and only if u1 is greater than u2
\ [ifndef u>
\ : u> _xasm2>flag h110E _cnip ;
\ ]
\
\ u< ( u1 u2 -- t/f ) \ flag is true if and only if u1 is less than u2
\ [ifndef u<
\ : u< _xasm2>flag hC10E _cnip ;
\ ]
\
\ invert ( n1 -- n2 ) bitwise invert n1
[ifndef invert
: invert
	-1 xor
;
]
\
\
\ rashift ( n1 n2 -- n3) \ n3 = n1 shifted right arithmetically n2 bits
\ [ifndef rashift
\ : rashift _xasm2>1 h077 _cnip ;
\ ]
\
\
\ decimal ( -- ) set the base for decimal
[ifndef decimal
: decimal
	hA base W!
;
]
\
\
\ ibound ( -- n1 ) the upper bound of i
[ifndef ibound
: ibound
	1 RS@
;
]
\
\
\ _words ( cstr -- ) prints the words in the forth dictionary starting with cstr, 0 prints all
[ifndef _words
: _words 
	0 >r lastnfa ." NFA (Forth/Asm Immediate eXecute) Name"
	begin
		2dup swap dup
		if
			npfx
		else
			2drop -1
		then
		if
			r> dup 0=
			if
				cr
			then
			1+ h3 and >r
			dup .word space dup C@ dup h80 and
			if
				h46 
			else
				h41
			then
			emit dup h40 and
			if
				h49
			else
				h20
			then
			emit h20 and
			if
				h58
			else
				h20
			then
			emit space dup .strname dup C@ namemax and h15 swap - 0 max spaces
		then
		nfa>next dup 0=
	until
	r> 3drop cr
;
]
\
\
\ words ( -- ) prints the words in the forth dictionary, if the pad has another string following, with that prefix
[ifndef words
: words
	parsenw _words
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
\
\ px ( t/f n1 -- ) set pin # n1 to h - true or l false
[ifndef px
: px
	swap
	if 
		pinhi
	else
		pinlo
	then
;
]
\
\
\ eeprom read and write routine for the prop proto board AT24CL256 eeprom on pin 28 sclk, 29 sda
\
\ _sdai ( -- ) eeprom sda in
[ifndef _sdai
: _sdai
	h1D pinin
;
]
\
\ _sdao ( -- ) eeprom sda out
[ifndef _sdao
: _sdao
	h1D pinout
;
]
\
\ _scli ( -- ) eeprom clk in
[ifndef _scli
: _scli
	h1C pinin
;
]
\
\
\ _scll ( -- ) eeprom clk out
[ifndef _sclo
: _sclo
	h1C pinout
;
]
\
\
[ifndef _sdal
\ _sdal ( -- ) eeprom sda lo
: _sdal
	h20000000 _maskoutlo
;
]
\
\
\ _sdah ( -- ) eeprom sda hi
[ifndef _sdah
: _sdah
	h20000000 _maskouthi
;
]
\
\
\ _scll ( -- ) eeprom clk lo
[ifndef _scll
: _scll
	h10000000 _maskoutlo
;
]
\
\
\ _sclh ( -- ) eeprom clk hi
[ifndef _sclh
: _sclh
	h10000000 _maskouthi
;
]
\
\
\ _sda? ( -- t/f ) read the state of the sda pin
[ifndef _sda?
: _sda?
	h20000000 _maskin
;
]
\
\
\ _eestart ( -- ) start the data transfer
[ifndef _eestart
: _eestart
	_sclh _sclo _sdah _sdao _sdal _scll
;
]
\
\
\ _eestop ( -- ) stop the data transfer
[ifndef _eestop
: _eestop
	_sclh _sdah _scll _scli _sdai
;
]
\
\
[ifndef 1lock
\ 1lock( -- ) equivalent to 1 lock
: 1lock 1 lock ;
]
\
[ifndef 1unlock
\ 1unlock( -- )  equivalent to 1 unlock
: 1unlock 1 unlock ;
]
\
\
\ the eereadpage and eewritePage words assume the eeprom are 64kx8 and will address up to 
\ 8 sequential eeproms
\ eewritepage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
[ifndef eewritepage
: eewritepage
	1lock
	1 max rot dup hFF and swap dup h8 rshift hFF and swap h10 rshift h7 and 1 lshift
	_eestart hA0 or _eewrite swap _eewrite or swap _eewrite or
	rot2 bounds
	do
		i C@ _eewrite or
	loop
	_eestop hA delms
	1unlock
;
]
\
\
\ EW! ( n1 eeAddr -- ) write n1 to the eeprom
[ifndef EW!
: EW!
	swap t0 W! t0 2 eewritepage
	if
		hA ERR
	then
;
]
\
\
\ saveforth( -- ) write the running image to eeprom UPDATES THE CURRENT VERSION STR
[ifndef saveforth
: saveforth
	c" wlastnfa" find
	if
		version W@ dup C@ + dup C@ 1+ swap C!
		pfa>nfa here W@ swap
		begin dup W@ over EW! 2+ dup h3F and 0= until
		do
			ibound i - h40 min dup i dup rot 
			eewritepage if hA ERR then _p? if h2E emit then
		+loop	 
	else
		drop
	then
	_p?
	if
		cr
	then
;
]


\	
\ st? ( -- ) prints out the stack
\ [ifndef st?
: st?
	." ST: " $C_stPtr COG@ 2+ dup $C_stTop <
	if
		$C_stTop swap - 0
		do
			$C_stTop 2- i -  COG@ dup 0<
			if
				base W@ hA = if h2D emit negate then
			then
			.long space
		loop
	else
		drop
	then
	cr
;
]

\
\ sc ( -- ) clears the stack
[ifndef sc
: sc
	$C_stTop $C_stPtr COG@ - 3 -
	_p?
	if
		dup .
		." items cleared" cr
	then
	dup 0>
	if
		0
		do
			drop
		loop
	else
		drop
	then
;
]

\ _pna ( pfa -- ) print the address, contents and forth name
\ [ifndef _pna
: _pna

	dup .word h3A emit W@ dup .word space pfa>nfa .strname space
;
]

\ pfa? ( addr -- t/f) true if addr is a pfa 
[ifndef pfa?
: pfa?
	dup pfa>nfa dup C@ dup h80 and 0= swap namemax and 0<> rot nfa>pfa rot
	if
		W@
	then
	rot = and
;
]

\ rs? ( -- ) prints out the return stack
\ [ifndef rs?
: rs?
	." RS: " $C_rsTop $C_rsPtr COG@ 1+ - 0
	do
		$C_rsTop 1- i - COG@ dup 2- W@ pfa?
		if
			2- _pna
		else
			.long space
		then
	loop
cr
;
]


[ifndef lock?
\ lock? ( -- ) displays the status of the locks
: lock?
	h8 0
	do
		_lockarray i + C@
\ 						\ ( count/cog == - )
		dup
		h4 rshift
		swap hF and
\ 						\ ( count cog == - )
		." Lock: " i .
		2dup h8 < swap 0> and
		if
			."   Locking cog: " . 
			."   Lock count: " .
		else
			2drop
		then
		cr
	loop
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
\ constant ( x -- ) skip blanks parse the next word and create a constant, allocate a long, 4 bytes
[ifndef constant
: constant
	lockdict create $C_a_doconl w, l, forthentry freedict
;
]

\
\ abs ( n1 -- abs_n1 ) absolute value of n1
[ifndef abs
: abs
	_xasm1>1 h151 _cnip
;
]

\ andC! ( c1 addr -- ) and c1 with the contents of address
[ifndef andC!
: andC!
	dup C@ rot and swap C!
;
]

\ rev ( n1 n2 -- n3 ) n3 is n1 with the lower 32-n2 bits reversed and the upper bite cleared
[ifndef rev
: rev
	_xasm2>1 h079 _cnip
;
]

\
\ revb ( n1 -- n2 ) n2 is the lower 8 bits of n1 reveresed
[ifndef revb
: revb
	h18 rev
;
]

\
\ px? ( n1 -- t/f) true if pin n1 is hi
[ifndef px?
: px?
	>m _maskin
;
]

\
\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[ifndef waitcnt
: waitcnt
	_xasm2>1 h1F1 _cnip
;
]

\ waitpeq ( n1 n2 -- ) \ wait until state n1 is equal to ina anded with n2
[ifndef waitpeq
: waitpeq
	_xasm2>0 h1E0 _cnip
;
]

\ waitpne ( n1 n2 -- ) \ wait until state n1 is not equal to ina anded with n2
[ifndef waitpne
: waitpne
	_xasm2>0 h1E8 _cnip
;
]

\ j ( -- n1 ) the second most current loop counter
[ifndef j
: j
	$C_rsPtr COG@ h5 + COG@
;
]

\
\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[ifndef u*/mod
: u*/mod
	rot2 um* rot um/mod
;
]

\
\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[ifndef u*/
: u*/
	rot2 um* rot um/mod nip
;
]

\
\ sign ( n1 n2 -- n3 ) n3 is the xor of the sign bits of n1 and n2 
[ifndef sign
: sign
	xor h80000000 and
;
]

\ * ( n1 n2 -- n1*n2) n1 multiplied by n2
[ifndef *
: * um*
	drop
;
]

\
\ */mod ( n1 n2 n3 -- n4 n5 ) n5 = (n1*n2)/n3, n4 is the remainder. Uses a 64bit intermediate result.
[ifndef */mod
: */mod
	2dup sign >r abs rot dup r> sign
	>r abs rot abs um* rot um/mod r>
	if
		negate swap negate swap
	then
;
]

\ */ ( n1 n2 n3 -- n4 ) n4 = (n1*n2)/n3. Uses a 64bit intermediate result.
[ifndef */
: */
	*/mod nip
;
]

\
\ /mod ( n1 n2 -- n3 n4 ) \ signed divide & mod  n4 = n1/n2, n3 is the remainder
[ifndef /mod
: /mod
	2dup sign >r abs swap abs swap u/mod r>
	if
		negate swap negate swap
	then
;
]

\
\ / ( n1 n2 -- n1/n2) n1 divided by n2
[ifndef /
: /
	/mod nip
;
]

\
\ (forget) ( cstr -- ) wind the dictionary back - caution
[ifndef (forget)
: (forget)
	dup
	if
		find
		if
			pfa>nfa nfa>lfa dup here W! W@ wlastnfa W!
		else
			_p?
			if
				.cstr h3F emit cr
			then
		then
	else
		drop
	then
;
]

\
\ forget ( -- ) wind the dictionary back to the word which follows - caution
[ifndef forget
: forget
	parsenw (forget)
;
]


\
\ the eereadpage and eewritePage words assume the eeprom are 64kx8 and will address up to 
\ 8 sequential eeproms
\ eereadpage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
[ifndef eereadpage 
: eereadpage
	1lock
	1 max rot dup hFF and swap dup
	h8 rshift hFF and swap h10 rshift h7 and
	1 lshift dup >r
	_eestart hA0 or _eewrite swap _eewrite or swap _eewrite or
	_eestart r> hA1 or _eewrite or
	rot2 bounds
	do
		lasti? _eeread i C!
	loop
	_eestop
	1unlock
;
]

\
\ EW@ ( eeAddr -- n1 ) read a word from the eeprom
[ifndef EW@
: EW@
	t0 2 eereadpage
	if
		hB ERR 
	then
	t0 W@
;
]

\
\ EC@ ( eeAddr -- c1 ) read a byte from the eeprom
[ifndef EC@
: EC@
	EW@ hFF and
;
]

\
[ifndef (dumpb)
: (dumpb)
	cr over .word space dup .word _ecs bounds
;
]

\ [ifndef (dumpm)
: (dumpm)
	cr .word _ecs
;
]

\
[ifndef (dumpe)
: (dumpe)
	tbuf h10 bounds
	do
		i C@ .byte space
	loop
	h2 spaces tbuf h10 bounds
	do
		i C@ dup bl h7E between invert if drop h2E then emit
	loop
;
]

\
\ dump  ( adr cnt -- ) dump main memory, uses tbuf
[ifndef dump
: dump
	(dumpb)
	do
		i  (dumpm)
		i tbuf h10 cmove
		(dumpe)
	h10 +loop
	cr
;
]

\ edump  ( adr cnt -- ) dump eeprom, uses tbuf
[ifndef edump
: edump
	(dumpb)
	do
		i (dumpm)
		i tbuf h10 eereadpage
		if
			tbuf h10 0 fill 
		then
		(dumpe)
	h10 +loop
	cr
;
]

\ cogdump  ( adr cnt -- ) dump cog memory
\ [ifndef cogdump
: cogdump
	cr over .word space dup .word _ecs bounds
	do
		cr i .word _ecs i h4 bounds
		do
			i COG@ .long space
		loop
	h4 +loop
	cr
;
]

\
\ .cogch ( n1 n2 -- ) print as x(y)
[ifndef .cogch
: .cogch
	dup -1 =
	if
		2drop ." X(X)"
	else
		<# h29 #C # h28 #C drop # #> .cstr
	then
;
]


\ io>cogchan ( addr -- n1 n2 ) addr -> n1 cogid, n2 channel
[ifndef io>coghan
: io>cogchan
	dup $H_cogdata dup $S_cdsz 3 lshift + between
	if
		$H_cogdata - $S_cdsz u/mod h7 and dup cognchan rot h4 u/ min
	else
		drop -1 dup
	then
;
]

\
\ cog? ( -- ) print out cog information
\ [ifndef cog?
: cog?
	h8 0
	do
		." Cog:" i dup . ."  #io chan:" dup cognchan .
		cogcds W@  version W@ C@ over C@ - spaces .cstr
		i cogio i cognchan 0
		do
			i 4* over + 2+ W@ dup 0=
			if
				drop
			else
				space space j i .cogch ." ->" io>cogchan .cogch 
			then
		loop
		drop
		cr
	loop
;
]
\
\ build? ( -- ) print out build information
\
[ifndef build?
: build?
	cr
	c" build_" _words
	cr
	version W@ .cstr cr
;
]
\
\ free ( -- ) display free main bytes and current cog longs
[ifndef free
: free
	dictend W@ here W@ - . ." bytes free - " par coghere W@ - . ." cog longs free" cr
;
]


\
\ rnd ( -- n1 ) n1 is a random number from 00 - FF
[ifndef rnd
: rnd
	cnt COG@ h8 rshift cnt COG@ xor hFF and
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
\ these routine will output to the console, they will not block, so characters may drop in the case of collisions
\
[ifndef .conwait
\ .conwait ( -- ) if con is not ready for a char, wait long enough for a char to transmit 
: .conwait
	$S_con cogio h200 0
	do
		dup W@ h100 and
		if
			leave
		then
	loop
	drop
;
]
\ 
[ifndef .conemit
\ .conemit ( c1 -- ) emit cr to console, non blocking, may get overwritten
: .conemit
	.conwait
	$S_con cogio W!
;
]

\
\ .concstr ( cstr -- ) emit cstr to console, non blocking, may get overwritten 
[ifndef .concstr
: .concstr
	C@++ dup
	if
		bounds
			do
				i C@ .conemit
			loop
	else
		2drop
	then
;
]

\
\ .con ( n1 -- ) print n1 to the console, non blocking, may get overwritten
[ifndef .con
: .con <# #s #> .concstr bl .conemit ; ]

\
\ .concr ( -- ) emit a cr to the console, non blocking, may get overwritten 
[ifndef .concr
: .concr
	hD .conemit
;
]
\ some very common formatting routines, for use with hex, decimal or octal
\ will work with other bases, but not optimally 

\
[ifndef .conbyte
\ .con ( c1 -- ) print byte c1 to the console, non blocking, may get overwritten
: .conbyte
	_bf .concstr
;
]

\
[ifndef .conword
\ .conword ( n1 -- ) print n1 to console, non blocking, may get overwritten
: .conword
	_wf .concstr
;
]

\
[ifndef .conlong
\ .conlong ( n1 -- ) print n1 to console, non blocking, may get overwritten
: .conlong
	_lf .concstr
;
]

\
\ .const? ( -- ) prints out the stack to the console, non blocking, may get overwritten
[ifndef .const?
: .const?
	c" ST: " .concstr $C_stPtr COG@ 2+ dup $C_stTop <
	if
		$C_stTop swap - 0
		do
			$C_stTop 2- i -  COG@
			dup 0<
			if
				base W@ hA = if h2D .conemit negate then
			then
			.conlong bl .conemit
		loop
	else
		drop
	then
	.concr
;
]


\ this changes the name of the last onreset word
\
c" onreset" find drop pfa>nfa 1+ c" onre001" C@++ rot swap cmove

\ onreset ( n1 -- ) reset message and error n1 on a reset, echo to the console 
: onreset
	dup onre001
\
\ Noisy reset messages
	_p? swap
	dup 0= if c"  ok" else
	dup 1 = if c"  MAIN STACK OVERFLOW" else
	dup h2 = if c"  RETURN STACK OVERFLOW" else
	dup h3 = if c"  MAIN STACK UNDERFLOW" else
	dup h4 = if c"  RETURN STACK UNDERFLOW" else
	dup h5 = if c"  OUT OF FREE COGS" else
	dup h6 = if c"  LOCK COUNT OVERFLOW" else
	dup h7 = if c"  LOCK TIMEOUT" else
	dup h8 = if c"  UNLOCK ERROR" else
	dup h9 = if c"  OUT OF FREE MAIN MEMORY" else
	dup hA = if c"  EEPROM WRITE ERROR" else
	dup hB = if c"  EEPROM READ ERROR" else
		c"  UNKNOWN ERROR "
	thens 
	rot
	if
		_p?
		if
			prop W@ pad ccopy
			propid W@ <# #s #> pad cappend
			c"  Cog" pad cappend
			cogid pad cappendn
			c"  RESET - last status: " pad cappend
			swap <# #s #> pad cappend
			pad cappend
			
			2lock
			.concr c" CON:" .concstr pad .concstr .concr
			cr pad .cstr cr
			2unlock
			padbl
		else
			2drop
		then
	else
		2drop
	then
;


...




