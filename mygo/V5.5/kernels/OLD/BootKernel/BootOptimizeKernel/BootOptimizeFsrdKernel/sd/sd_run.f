fl
\
\
fswrite sd_run.f
\
\
1 wconstant build_sdrun
\
\
\ sd_cogbufclr ( -- ) initialize the buffer to zeros
: sd_cogbufclr
	sd_cogbuf h80 bounds
	do
		0 i COG!
	loop
;


lockdict create a_shift forthentry
$C_a_lxasm w, h133  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z20yP[i l, z1SF03C l, z2WyQ88 l, zfyPOO l, z1SV04Q l, z2WyQ8W l, zoyPO1 l,
z1jix\1 l, z1bix\2 l, z1[ix\2 l, z3[yQCQ l, z1[ix\1 l, z1SyLI[ l, z1SV04h l, z2WyQ88 l,
z1SV04\ l, z2WyQ8W l, z1SyJQL l, z2WyPO0 l, z1bix\1 l, z1bix\2 l, z1XFb7l l, znyPO1 l,
z1[ix\2 l, z3[yQCb l, z1[ix\1 l, z1SV01X l, z1SV04M l, z1SV04P l, z1SV04Y l, z1SV04[ l,

freedict

lockdict create mem>cog forthentry
$C_a_lxasm w, h11E  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z2WiPmC l, z1SyLIZ l, z8iPeB l, z1KiZJC l, z20yPW1 l, z20yPO4 l, z2WiPZD l,
z3[yPnM l, z1SyLI[ l, z1SV01X l,
freedict

lockdict create cog>mem forthentry
$C_a_lxasm w, h11E  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z2WiPmC l, z1SyLIZ l, z1GiZ3C l, z20yPW1 l, z2WiPeC l, z8FPeB l, z20yPO4 l,
z3[yPnM l, z1SyLI[ l, z1SV01X l,
freedict
\
\
\
\ _sd_shift_out ( c1 -- ) shift out one char most siginficant bit first
: _sd_shift_out
	0 a_shift
;
\
\
\
\ _sd_shift_outlong ( n1 -- ) shift out one long most siginficant bit first
: _sd_shift_outlong
	1 a_shift
;
\
\
\ _sd_shift_in ( -- c1 ) shift in one char, most siginificant bit first
: _sd_shift_in
	h2 a_shift
;
\
\ _sd_shift_inlong ( -- n1 ) shift in one long, most siginificant bit first
: _sd_shift_inlong
	h3 a_shift
;
\
\
[ifdef _sd_debug
\ 8 times we can record
lockdict variable _times h1C allot freedict
]
\
\
\	REF1: p 128 / 116 7.2.3 Data Read
\	REF1: p 144 / 132 7.3.3 Control Tokens
\
\ _sd_readdata( n1 -- ) n1 number of bytes to read, n1 must be a multilpe of 4, and it does not include the crc,
\ 			the crc is discarded by this routine. The data is read to sd_cogbuf
: _sd_readdata
[ifdef _sd_debug
	cr ." _sd_readdata readlen: " dup .
	cnt COG@ _times h8 + L!
]
\
\ 						\ divide by 4 to get the long count
	h200 min 4/
\						\ wait for the data control token for 4000 loops
	0 h4000 0
	do
		_sd_shift_in
		hFE =
		if
			drop -1 leave
		then
	loop
[ifdef _sd_debug
	cnt COG@ _times hC + L!
]
	if
\						\ valid data control token
\						\ read in the data
		sd_cogbuf swap bounds
		do
			_sd_shift_inlong i COG!
		loop
[ifdef _sd_debug
		cnt COG@ _times h10 + L!
]
\						\ read the crc + 2 extra bytes
\						\ make sure the read is finished
		_sd_shift_inlong hFFFF and hFFFF <>
		if
\						\ we are getting more data
\						\ something is very wrong
			hA2 ERR
		then

	else
\					\ read timed out
		hA3 ERR
	then
[ifdef _sd_debug
	cnt COG@ _times h14 + L!
	sd_cogbuf h80 cogdump
]
;
\
\
\	REF1: p 129 / 117 7.2.4 Data Write
\	REF1: p 144 / 132 7.3.3 Control Tokens
\
\ _sd_writedata( n1 -- ) n1 number of bytes to write, n1 must be a multilpe of 4, and it does not include the crc,
\ 			the crc is written as FF  by this routine. The data is written from sd_cogbuf
: _sd_writedata
[ifdef _sd_debug
	cr ." _sd_writedata writelen: " dup . sd_cogbuf 80 cogdump
	cnt COG@ _times h8 + L!
]
\
	h200 min h4 max 4/
	hFE _sd_shift_out
	sd_cogbuf swap bounds
\
	do
		i COG@
		_sd_shift_outlong
	loop
	-1 dup _sd_shift_out _sd_shift_out
	h10000 0
	do
		_sd_shift_in
		dup hFF <>
		if
			leave
		else
			drop
		then	
	loop
\
	h7 and h5 <>
	if
\						\ some kind of write error
		hA4 ERR
	then
[ifdef _sd_debug
		cnt COG@ _times hC + L!
]
	h10000 0
	do
		_sd_shift_in
		dup hFF =
		if
			leave
		else
			drop
		then	
	loop
	hFF <>
[ifdef _sd_debug
		cnt COG@ _times h10 + L!
]
	if
\						\ still busy, something is very wrong
		hA5 ERR
	then
;
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p  70 /  58 Command Format
\
\
\ _sd_cmdr8 ( crc arg cmd -- n1 ) send the command, wait for response, n1 - the 8 bit response
\ n1 is set to all 1's (FFFFFFFF or -1) in the case of a timeout
: _sd_cmdr8
[ifdef _sd_debug
	cr ." _sd_cmdr8 CMD: " dup . ." ARG: " over .
]
\
\ Seems a number of cards need the a couple of clock pulses before the start bit for a command is
\ sent. Not yet able to dig up anything in the specs to verify this, but without this,
\ a number of cards do not work properly, this gives l->h clock transitions. With limited tesing
\ only a couple of clock pulses seem necessary, but it is just as easy to to do a get a byte,
\ issues 8 clocks, instead of 3 pulses 
\
\
\		_sd_di_out_h
\		_sd_clk_out_l _sd_clk_out_h
\		_sd_clk_out_l _sd_clk_out_h
\		_sd_clk_out_l
\
	_sd_shift_in drop
\
	h3F and h40 or
	_sd_shift_out
	_sd_shift_outlong
	_sd_shift_out
	-1 h10 0
	do
		_sd_shift_in dup hFF <>
		if
			nip leave
		else
			drop
		then
	loop
[ifdef _sd_debug
		." RESPONSE: " dup . cr
]
;
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p  70 /  58 Command Format
\
\
\ _sd_cmdr16 ( crc arg cmd -- n1 ) send the command, wait for response, n1 - the 16 bit response
\ n1 is set to all 1's (FFFFFFFF or -1) in the case of a timeout
: _sd_cmdr16
[ifdef _sd_debug
	cr ." _sd_cmdr16 CMD: " dup . ." ARG: " over .
]
	_sd_cmdr8 8 lshift _sd_shift_in or
[ifdef _sd_debug
	." RESPONSE: " dup . cr
]
;
\
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p  70 /  58 Command Format
\
\
\ _sd_cmdr8data ( datalen crc arg cmd -- n1 ) send the command, wait for response, the read the data into _sd_buf,
\  n1 - the 8 bit response n1 is set to all 1's (FFFFFFFF or -1) in the case of a timeout
: _sd_cmdr8data
[ifdef _sd_debug
	cr ." _sd_cmdr8data readlen: " >r >r >r dup . r> r> r>
	cnt COG@ _times 4 + L!
]
	_sd_cmdr8
	dup 0=
	if
		swap _sd_readdata
	then
;
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p  70 /  58 Command Format
\
\
\ _sd_cmdr40 ( crc arg cmd -- n1 n2 ) send the command, wait for response, n1 - the 8 bit response,
\ n2 - 32 bit response, n1 and n2 are set to all 1's (FFFFFFFF or -1) in the case of a timeout
: _sd_cmdr40
[ifdef _sd_debug
	cr ." _sd_cmdr40 CMD: " dup . ." ARG: " over .
]
	_sd_cmdr8 _sd_shift_inlong
[ifdef _sd_debug
	." RESPONSE: " over . dup . cr
]
;
\
\
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\
\ sd_blockread ( n1 -- ) n1 - the block number. Reads a 512 byte block into _sd_buf
: sd_blockread
[ifdef _sd_debug
	cr ." sd_blockread ENTER Block: " dup . cr
	cnt COG@ _times L!
]
	sd_lock
\						\ CMD17 0 - READ_SINGLE_BLOCK, Read 512 bytes
	h200 1
\						\ _sd_ccs = 0 means we use byte adressing to
\						\ the card
	rot _sd_ccs W@ 0=
	if
		h9 lshift
	then
	h11
	_sd_cmdr8data
	if
\						\ block read error
		hAC ERR
	then
	sd_unlock
[ifdef _sd_debug
	cnt COG@ _times h18 + L!
	cnt COG@ _times h1C + L!
	cr ." sd_blockread EXIT" cr
	lock?
]
;
\
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\
\ sd_blockwrite ( n1 -- ) n1 - the block number. Writes 512 byte block from _sd_buf
: sd_blockwrite
[ifdef _sd_debug
	cr ." sd_blockwrite ENTER Block: " dup . cr
	cnt COG@ _times L!
]
	sd_lock
\						\ CMD24 0 - WRITE_BLOCK, write 512 bytes
\						\ + 2 byte crc
	h200 1
\						\ _sd_ccs = 0 means we use byte adressing
\						\ to the card
	rot _sd_ccs W@ 0=
	if
		h9 lshift
	then
	h18
[ifdef _sd_debug
	cnt COG@ _times h4 + L!
]

	_sd_cmdr8
	if
\						\ block write error
		hAD ERR
	else
		_sd_writedata
	then
\						\ get status to make sure all was ok
\						\ CMD13 0 - SEND_STATUS, get the status reg,
\						\ make sure there were no errors
[ifdef _sd_debug
		cnt COG@ _times h14 + L!
]
	1 0 hD _sd_cmdr16
	if
\						\ one of the error bits was on
		hAE ERR
	then
	sd_unlock
[ifdef _sd_debug
	cnt COG@ _times h18 + L!
	cnt COG@ _times h1C + L!
	cr ." sd_blockwrite EXIT" cr
]
;
\
{

fl

coghere W@ wconstant v_sdbase
v_sdbase	wconstant v_sd_do
v_sd_do	1+	wconstant v_sd_di
v_sd_di	1+	wconstant v_sd_clk
\
\ make sure we sufficient cog memory
\
hA state orC!
\
h1F0 v_sdbase - h84 <
[if
cr cr cr cr cr cr c" INSUFFICIENT COG MEMORY IN THIS BUILD need " .cstr _sd_cogend v_sdbase - .
c" cog longs have " .cstr h1F0 v_sdbase - . cr cr cr cr cr cr cr
hA state andnC!
clearkeys
]
\
\
\
\ make sure we have not relocated, if we have the assembler code in sd_run.f will need to be reassembled
h112 build_BootOpt <> h140 coghere W@ <> or
[if
cr cr cr cr cr cr c" REASSEMBLE a_shift in sd_run.f - adjust the parameters in this check routine" .cstr cr cr cr cr cr cr
hA state andnC!
clearkeys
]
\
hA state andnC!

\ 
\ the block number of the current directory
\
v_sd_clk 1+	wconstant v_currentdir

hA state orC!


build_BootOpt :rasm
		spopt
		add	$C_treg1 , # __x0F
		jmp	$C_treg1

__x01
		mov	$C_treg6 , # h8
		shl	$C_stTOS , # h18
		jmp	# __x05
__x02
\ send the bits in $C_stTOS
		mov	$C_treg6 , # h20

__x05
\ hi bit to the carry flag
		rcl	$C_stTOS , # 1 wc
\ set data out accordingly
		muxc	outa , v_sd_di 

\ toggle clock
		or	outa , v_sd_clk
		andn	outa , v_sd_clk
\ loop
		djnz	$C_treg6 , # __x05
		andn	outa , v_sd_di
		spop	
		
		jmp	# __x0E


__x03
		mov	$C_treg6 , # h8
		jmp	# __x06
__x04
		mov	$C_treg6 , # h20

__x06
		spush
		mov	$C_stTOS , # 0
		or	outa , v_sd_di
__x07
\ clock high
		or	outa , v_sd_clk
\ read in bit
		test	v_sd_do , ina wc
		rcl $C_stTOS , # 1
\ clock low
		andn outa , v_sd_clk
\ loop
		djnz $C_treg6 , # __x07
		andn	outa , v_sd_di

__x0E
		jexit

__x0F
		jmp	# __x01
		jmp	# __x02
		jmp	# __x03
		jmp	# __x04
;asm a_shift

\ mem>cog ( memaddr cogaddr numlongs -- ) memaddr must be long aligned
\ cog>mem ( memaddr cogaddr numlongs -- ) memaddr must be long aligned
\           $C_stTOS  $C_treg1  $C_treg3

build_BootOpt :rasm

		spopt
		mov	$C_treg3 , $C_treg1

		spopt
__x01
		rdlong	$C_treg2 , $C_stTOS
		movd	__x02 , $C_treg1

		add	$C_treg1 , # 1
		add	$C_stTOS , # h4

__x02
		mov	$C_treg1 , $C_treg2
		djnz	$C_treg3 , # __x01

		spop
		jexit
;asm mem>cog


build_BootOpt :rasm

		spopt
		mov	$C_treg3 , $C_treg1

		spopt
		
__x01
		movs	__x02 , $C_treg1
		add	$C_treg1 , # 1
__x02
		mov	$C_treg2 , $C_treg1

		wrlong	$C_treg2 , $C_stTOS

		add	$C_stTOS , # h4

		djnz	$C_treg3 , # __x01

		spop
		jexit
;asm cog>mem

hA state andC!



}
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