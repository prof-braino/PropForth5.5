\
\
\
[ifdef _sd_debug
\
\ test_cogbufdump ( -- ) dumps the contents of sd_cogbuf
: test_cogbufdump
	cr
	sd_cogbuf h80 cogdump
;
\
\
\
\ test_patternfill ( n1 -- )
: test_patternfill
	dup dup h8 lshift or dup h10 lshift or
\
	sd_cogbuf h80 bounds
	do
		dup i COG!
		1+
	loop
	drop
	." Buffer filled starting with: " . cr
;
\
\
\ test_rndpattern ( -- )
: test_rndpattern
	rnd test_patternfill
;
\
\
\ test_hex ( -- )
: test_hex
	hex
	." Hex mode" cr
;
\
\ test_decimal ( -- )
: test_decimal
	decimal
	." Decimal mode" cr
;
\
\ test_dumptimes ( -- )
: test_dumptimes
	h8 1
	do
		." Times " i 4* <# # # #> .cstr  ." +   "
		_times i 4* + dup L@ swap h4 - L@ - clkfreq hF4240 u/ u/ . ." usec" cr
	loop
	." Total time  " _times h1C + L@ _times L@ - clkfreq hF4240 u/ u/ . ." usec" cr
;
\
\
\ stackdepth ( -- n1 )
: stackdepth
	$C_stTop $C_stPtr COG@ - h3 -
;
\
\
\ test_help ( -- )
: test_help
	cr
	." ~009~009b # - read a block" cr
	." ~009~009c # - pattern fill buffer" cr
	." ~009~009d # - write block" cr
	." ~009~009e   - initialize" cr
	." ~009~009f   - zero out buffer" cr
	." ~009~009g   - random fill buffer" cr
	." ~009~009h   - dump buffer" cr
	." ~009~009i   - sd_lock" cr
	." ~009~009j   - sd_unlock" cr
	." ~009~009k   - lock?" cr
	." ~009~009m   - Hex mode" cr
	." ~009~009n   - Decimal mode" cr
	." ~009~009o   - Dump times" cr
	." ~009~009q - quit" cr
;
\
\ create a menu structure of the test routines,
lockdict
herewal
here W@ 0 w, 							\ the size of the structure in bytes
\ the address (test_addr)	#parameters (#params)	the menu key (menuchar)
' sd_blockread		w,	1 c,			h62 c,
' test_patternfill	w, 	1 c,			h63 c,
' sd_blockwrite		w,	1 c,			h64 c,
' sd_init		w,	0 c,			h65 c,
' sd_cogbufclr		w,	0 c,			h66 c,
' test_rndpattern	w,	0 c,			h67 c,
' test_cogbufdump	w,	0 c,			h68 c,
' sd_lock		w,	0 c,			h69 c,
' sd_unlock		w,	0 c,			h6A c,
' lock?			w,	0 c,			h6B c,
' test_hex		w,	0 c,			h6D c,
' test_decimal		w,	0 c,			h6E c,
' test_dumptimes	w,	0 c,			h6F c,
\								\ update the structure size
here W@ over 2+ -  over W!
\								\ the address of the structure
wconstant test_structure		
freedict
\
\
\ exec_test ( params #params menuchar -- t/f ) executes the menu in the test_jumptable,
\					if the # params match, true if test executed
: exec_test
	h8 lshift or
	0 >r
	0 test_structure 2+ test_structure W@ bounds
	do
\ 						\ ( params #params/menuchar 0 == 0 )
		over i 2+ W@ =
		if
\			
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
\ sd_test ( -- )
: sd_test
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
]
\
...