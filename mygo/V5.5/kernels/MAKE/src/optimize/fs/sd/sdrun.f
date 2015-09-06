\
\
\
\
1 wconstant build_sdrun
c" Loading sdrun.f ..." .cstr

\
\
\ 4/ ( n1 -- n1>>2 ) n2 is shifted arithmetically right2 bits
[ifndef 4/
: 4/ _xasm2>1IMM h0002 _cnip h077 _cnip ;
]
\
\
\ sd_cogbufclr ( -- ) initialize the buffer to zeros
: sd_cogbufclr
	sd_cogbuf h80 bounds
	do
		0 i COG!
	loop
;
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
c" Loaded sdrun.f~h0D" .cstr


