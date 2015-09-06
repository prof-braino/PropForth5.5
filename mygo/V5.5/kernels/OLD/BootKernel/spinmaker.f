fl

\
\ the _xc word is also a marker for the beginning of this file, see the spimaker word
\ _xc ( c1 c2 cstr  -- c1 -1 | cstr -1 0 )
: _xc
	rot2 over =
	if
		drop -1 0
	else
		nip -1
	then
;
[ifndef $C_a_doconl
    h52 wconstant $C_a_doconl
]

[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]


[ifndef $C_a__xasm2>0
    h21 wconstant $C_a__xasm2>0
]

[ifndef $C_a__xasm1>1
    h1C wconstant $C_a__xasm1>1
]

[ifndef $C_a__xasm2>flagIMM
    h1 wconstant $C_a__xasm2>flagIMM
]

[ifndef $C_a__xasm2>flag
    h4 wconstant $C_a__xasm2>flag
]

[ifndef $C_a__xasm2>1IMM
    h13 wconstant $C_a__xasm2>1IMM
]

[ifndef $C_a__xasm2>1
    h16 wconstant $C_a__xasm2>1
]

\
\
\ some very common formatting routines, for use with hex, decimal or octal
\ will work with other bases, but not optimally 
\
\
\ _bf ( n1 -- cstr )
[ifndef _bf
: _bf
	<# # # base W@ h10 < if # then #>
;
]
[ifndef .byte
\
\ .byte ( n1 -- )
: .byte
	_bf .cstr
;
]
\
\
\ _wf ( n1 -- cstr )
[ifndef _wf
: _wf
	<# # # # # base W@ h10 < if # base W@ hA < if # then then #>
;
]
\
\
\ .word ( n1 -- )
[ifndef .word
: .word
	_wf .cstr
;
]
\
\
\ _lf ( n1 -- cstr )
[ifndef _lf
: _lf
	<# # # # # # # # # base W@ h10 < if # # base W@ hA < if # then then  #>
;
]
\
\
\ .long ( n1 -- )
[ifndef .long
: .long
	_lf .cstr
;
]
\
\ lasti? ( -- t/f ) true if this is the last value of i in this loop
[ifndef lasti?
: lasti?
	1 RS@ h2 RS@ 1+ =
;
]

\
\ xc1 ( c1 -- cstr -1 | c1 0 ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xc1
	h22 c" quote" _xc
	if
		h23 c" hash" _xc
	if
		h30 c" z" _xc
	if
		h31 c" one" _xc
	if
		h32 c" two" _xc
	if
		h33 c" three" _xc
	if
		h34 c" four" _xc
	if
		h35 c" five" _xc
	if
		h36 c" six" _xc
	if
		h38 c" eight" _xc
	if
		h28 c" lparen" _xc
	if
		h29 c" rparen" _xc
	if
		0
	thens
;

\
\ xc2 ( c1 -- xx t/f ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xc2
	h5B c" sbo" _xc
	if
		h5C c" bs" _xc
	if
		h5D c" sbc" _xc
	if
		h3A c" colon" _xc
	if
		h3B c" scolon" _xc
	if
		h27 c" tick" _xc
	if
		h40 c" at" _xc
	if
		h21 c" bang" _xc
	if
		h3D c" eq" _xc
	if
		h3E c" gt" _xc
	if
		0
	thens
;

\
\ xc3 ( c1 -- xx t/f ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xc3
	h3C c" lt" _xc
	if
		h2D c" minus" _xc
	if
		h2B c" plus" _xc
	if
		h2F c" slash" _xc
	if
		h2A c" star" _xc
	if
		h2E c" dot" _xc
	if
		h2C c" comma" _xc
	if
		h24 c" dlr" _xc
	if
		h7B c" cbo" _xc
	if
		h7D c" cbc" _xc
	if
		h3F c" q" _xc
	if
		0
	thens
;

\
\ xlatnamechar ( c1 -- xx t/f ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xlatnamechar
	xc1
	if
		-1
	else
		xc2
		if
			-1
		else
			xc3
		then
	then
;

\
\ ixnfa ( n1 -- c-addr ) returns the n1 from the last nfa address
: ixnfa
	0 max wlastnfa W@
	begin
		over 0=
		if
			-1
		else
			swap 1- swap nfa>next dup 0=
		then
	until
	nip
;

\
\ .xstr ( c-addr u1 -- ) emit u1 characters at c-addr
: .xstr
	dup 0<>
	if
		bounds
		do
			i C@ xlatnamechar
			if
				.cstr
			else
				emit
			then
		loop
	else
		2drop
	then
;

\
\ .xstrname ( c-addr -- ) c-addr point to a forth name field, print the translated name
: .xstrname
	dup 0<>
	if
		namelen .xstr
	else
		drop ." ??? "
	then
;

\
\ xstrlen ( c-addr u1 -- u2 ) emit u1 characters at c-addr
: xstrlen
	dup 0<>
	if
		bounds 0 rot2
		do
			i C@ xlatnamechar
			if
				C@
			else
				drop 1
			then
			+
		loop
		nip
	else
		2drop 0
	then
;

\
\ xstrnamelen ( c-addr -- n1 ) c-addr points to a forth name field, n1 the tranlated length
: xstrnamelen
	dup namelen dup 0<>
	if
		xstrlen
	else
		nip
	then
;

\
\ nfacount ( -- n1 ) returns the number of nfas in the forth dictionary
: nfacount
	0 wlastnfa W@
	begin
		swap 1+ swap nfa>next dup 0=
	until
	drop
;

\
\ nfaix ( c-addr -- n1 ) returns the index of the nfa address, -1 if not found
: nfaix
	-1 swap 0 wlastnfa W@
	begin
		rot 2dup =
		if
			2drop swap -1 -1 -1
		else
			rot 1+ rot nfa>next dup 0=
		then
	until
	3drop
;

\
\ lastdef ( c-addr -- t/f ) true if this is the most recently defined word 
: lastdef
	c" wlastnfa" over name=
	over c" here" name= or
	over c" dictend" name= or
	over c" memend" name= or

	if
		drop 0
	else
		dup find
		if
			pfa>nfa =
		else
			2drop -1
		then
	then
; 

\
\ a variable which points to the last word spun out
wvariable lastSpinNFA

\
\ spinname ( c-addr -- ) emit a spin name
: spinname
	-1 swap h22 emit namelen 0 
	do
		C@++ dup h22 =
			if
				drop h22 emit ." ,$22" nip 0 swap
			else
				emit
			then
	loop
	drop
	if
		h22 emit
	then
;

\
\ spinwordheader ( n1 -- addr ) n1 is the nfa index, addr is the nfa
: spinwordheader
	cr h18 spaces ." word    "  
	lastSpinNFA W@ dup 0=
	if
		." 0" drop
	else
		." @" .xstrname ." NFA + $10"
	then 
	cr
	ixnfa dup lastSpinNFA W! dup .xstrname ." NFA" 
	dup xstrnamelen namemax and h15 swap - 1 max
	dup spaces ." byte    $" over C@ .byte ." ," over spinname
	cr 
	over .xstrname ." PFA" spaces ." word    "
;

\
\
\ spinwordasm ( addr -- ) the nfa address
: spinwordasm
	." (@a_" .xstrname ."  - @a_base)/4"
	cr
;  

\
\ spinwordconstant ( addr -- addr t/f ) addr is the nfa, false if the word was processed 
: spinwordconstant
	dup nfa>pfa W@ $C_a_doconw =
	if
		dup c" $H_" npfx
		if
			." (@a_doconw - @a_base)/4" cr h18 spaces ." word    "	
			dup ." @" namelen h3 - swap h3 + swap .xstr ." PFA  + $10"
			cr
			0
		else
			dup c" $C_" npfx
			if
				." (@a_doconw - @a_base)/4" cr h18 spaces ." word    "	
				dup ." (@" namelen h3 - swap h3 + swap .xstr ."  - @a_base)/4"
				cr
				0
			else
				dup c" $S_" npfx
				if
					." (@a_doconw - @a_base)/4" cr h18 spaces ." word    "	
					dup ." dlrS_" namelen h3 - swap h3 + swap .xstr
					cr
					0
				else
					-1
				then
			then
		then
	else
		-1
	then
;

\
\ isExecasm ( addr -- t/f) true if addr is one of the ifuncs
: isExecasm
	dup $C_a__xasm2>1 =
	over $C_a__xasm2>flag = or
	over $C_a__xasm1>1 = or
	swap $C_a__xasm2>0 = or
;
	
\
\ isExecasmIMM ( addr -- t/f) true if addr is one of the immediate ifuncs
: isExecasmIMM
	dup $C_a__xasm2>1IMM =
	swap $C_a__xasm2>flagIMM = or
;
	
\
\
: spindcmp1
	h18 spaces ." word    $"  2+ dup W@ .word
	cr
;

\
\
: spindcmp2
	h18 spaces ." long    $" 2+ alignl
	dup dup 2+ W@ .word W@ .word 2+
	cr
;

\
\
\ spindcmp ( addr -- addr t/f) process the post word data, flag true if at the end of the word
: spindcmp
	dup W@ dup $C_a_doconw = swap $C_a_dovarw = or
	if
		spindcmp1 -1
	else
		
	dup W@ isExecasmIMM
	if
		spindcmp1
		spindcmp1 0
	else

	dup W@ dup isExecasm
	swap $C_a_litw = or
	if
		spindcmp1 0
	else

	dup W@ dup $C_a_branch =
	over $C_a_(loop) = or
	over $C_a_(+loop) = or
	swap $C_a_0branch = or
	if
		spindcmp1 0
	else

	dup W@ dup $C_a_doconl =
	swap $C_a_dovarl = or
	if
		spindcmp2 -1
	else

	dup W@ $C_a_litl =
	if
		spindcmp2 0
	else

	dup W@ dup $H_dq = swap $H_cq = or
	if
		h18 spaces ." byte    $" 2+
		C@++ dup .byte ." ," 2dup
		h22 emit .str h22 emit
		+ alignw 2-
		cr 0
	else

	dup W@ $C_a_lxasm =
	if
		2+
		alignl
		dup L@ h9 rshift h1FF and 4*
		2dup bounds
		do
			h18 spaces ." long    $"
			i L@ .long cr	
		h4 +loop
		+ 2- -1
	else
		dup W@ $C_a_exit =
	thens
;


\
\ spinwordforth( addr1 -- addr2 ) addr1 is the nfa, addr2 is the pfa address at the end of this word
: spinwordforth
	nfa>pfa 2-
	begin
		2+ dup W@ dup pfa>nfa
		swap $C_fMask COG@ and
		if
			." @" .xstrname ." PFA + $10"
			cr
		else
			spinwordasm
		then
		spindcmp dup 0=
		if
			h18 spaces ." word    "
		then
	until
	2+
;

: _sw
	0 
	do
		i h7 and 0=
		if
			i 0<>
			if
				cr
			then
			h18 spaces ." WORD    0"
		else
			." ,0"
		then
	loop
;

: spinword
	dup spinwordheader dup C@ h80 and
	if
		spinwordconstant
		if
			spinwordforth over 1- ixnfa 2- swap - dup 0<>
			if
				alignw 2/ dup h8 >
				if
					alignw 2/
				then
				_sw
			else
				drop
			then
		else
			drop
		then
	else
		spinwordasm
	then
	drop
;

\
\
: cr18
	cr h18 spaces
;

\ spinmaker ( n1 -- ) generates the forth spin code, n1 number of longs to add
: spinmaker
	hex
	nfacount 1- dup
	c" _xc" find
	if
		cr
		." ForthDictStart"
		cr
		cr18 ." word    0"
		cr
		." wlastnfaNFA             byte    $88," h22 emit ." wlastnfa" h22 emit
		cr
		." wlastnfaPFA             word    (@a_dovarw - @a_base)/4"
		cr
		."                         word    @H_lastlfa + $12"
		cr
		cr18 ." word    @wlastnfaNFA + $10"
		cr
		." hereNFA                 byte    $84," h22 emit ." here" h22 emit
		cr
		." herePFA                 word    (@a_dovarw - @a_base)/4"
		cr
		."                         word    @wfreespacestart + $10"
		cr 
		cr18 ." word    @hereNFA + $10"
		cr
		." dictendNFA              byte    $87," h22 emit ." dictend" h22 emit
		cr
		." dictendPFA              word    (@a_dovarw - @a_base)/4"
		cr
		."                         word    @ForthMemoryEnd + $10"
		cr
		cr18 ." word    @dictendNFA + $10"
		cr
		." memendNFA               byte    $86," h22 emit ." memend" h22 emit
		cr
		." memendPFA               word    (@a_dovarw - @a_base)/4"
		cr
		."                         word    @ForthMemoryEnd + $10"
		cr 
	

		pfa>nfa nfaix - 0

		c" memend" lastSpinNFA W!
		do
			dup i - dup ixnfa
			lastdef
			if
				lasti?
				if
					." H_lastlfa"
					cr
				then
				spinword
			else
				drop
			then
		loop
		drop
		cr
		." wfreespacestart"
		cr
		d_5000 + d_16 u/mod 0 
		do
			cr18 ." long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0"
		loop
		dup 0<>
		if
			1-
			cr18 ." long    0"
			dup 0<>
			if
				0
				do
					." ,0"
				loop
			else
				drop
			then
		else
			drop
		then
		cr
		." ForthMemoryEnd"
		cr
		cr
	else
		3drop
	then
;

: echo
	begin
		-1 0 0 _wkeyto W@ 4 lshift 0
		do
			2drop fkey?
			if
				nip 0 swap -1 leave
			else
				0
			then
		loop
		if
			emit
		else
			drop
		then
	until
;
