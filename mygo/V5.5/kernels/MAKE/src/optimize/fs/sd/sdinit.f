\
\
\
1 wconstant build_sdinit
c" Loading sdinit.f ..." .cstr

\
\ (forget) ( cstr -- ) wind the dictionary back to the word which follows - caution
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
\
\ forget ( -- ) wind the dictionary back to the word which follows - caution
[ifndef forget
: forget
	parsenw (forget)
;
]
\
\
\ 4/ ( n1 -- n1>>2 ) n2 is shifted arithmetically right2 bits
[ifndef 4/
: 4/ _xasm2>1IMM h0002 _cnip h077 _cnip ;
]
\
\
\ basic pin functions to drive the sd card
\
\
: _sd_cs_out $S_sd_cs pinout ;
: _sd_di_out $S_sd_di pinout ;
: _sd_clk_out $S_sd_clk pinout ;
: _sd_do_in $S_sd_do pinin ;
\
: _sd_cs_out_l $S_sd_cs pinlo ;
: _sd_cs_out_h $S_sd_cs pinhi ;
: _sd_di_out_l $S_sd_di pinlo ;
: _sd_di_out_h $S_sd_di pinhi ;
: _sd_clk_out_l $S_sd_clk pinlo ;
: _sd_clk_out_h $S_sd_clk pinhi ;
\
\
\
\
\
\
\
\ Low level Routines to read and write bytes and longs to the sd card
\
\
\ _sd_shift_out ( c1 -- ) shift out one char most siginficant bit first
: _sd_shift_out
	h80 h8 0
	do
		2dup and
		if
			_sd_di_out_h
		else
			_sd_di_out_l
		then
		1 rshift
		_sd_clk_out_l _sd_clk_out_h
	loop
	2drop
	_sd_clk_out_l
	_sd_di_out_l
;
\
\
\ _sd_shift_outlong ( n1 -- ) shift out one long most siginficant bit first
: _sd_shift_outlong
	dup h18 rshift _sd_shift_out
	dup h10 rshift _sd_shift_out
	dup h8 rshift _sd_shift_out
	_sd_shift_out
;
\
\
\ _sd_shift_in ( -- c1 ) shift in one char, most siginificant bit first
: _sd_shift_in
	_sd_di_out_h
	0 h8 0
	do
		1 lshift
		_sd_clk_out_l _sd_clk_out_h
		$S_sd_do px?
		if
			1 or
		then
	loop
	_sd_clk_out_l
	_sd_di_out_l
; 
\
\
\ _sd_shift_inlong ( -- n1 ) shift in one long, most siginificant bit first
: _sd_shift_inlong
	_sd_shift_in h8 lshift
	_sd_shift_in or h8 lshift
	_sd_shift_in or h8 lshift
	_sd_shift_in or
;
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
\
	if
\						\ valid data control token
\						\ read in the data
		sd_cogbuf swap bounds
		do
			_sd_shift_inlong i COG!
		loop
\						\ read the crc + 2 extra bytes
\						\ make sure the read is finished
		_sd_shift_inlong hFFFF and hFFFF <>
		if
\						\ we are getting more data
\						\ something is very wrong
			hA2 ERR
		then
\
	else
\					\ read timed out
		hA3 ERR
	then
[ifdef _sd_debug
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
	_sd_cmdr8 h8 lshift _sd_shift_in or
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
\	Should support SD v2 standard, H & X 
\	***** only tested with a Kingston 2G card V2, SDSC, and an 8G no name phone card SDHC
\
\ _sd_init ( -- ) initialize the SD card, this routine is only called once for the propeller
: _sd_init
[ifdef _sd_debug
	cr ." _sd_init ENTER" cr
]
\
\	REF1: p 123
\	REF2: Power On
\
\						\ >74 clock pulses, reset
\						\ in development, when there was a bug, sometimes
\						\ the sd card would be in a bad state
\						\ 74 clock pulses did not seem to reset it
\						\ 1000 hex did (doesn't take much longer)
\						\ we will retry the whole initialize up to 8 times
	-1 h8 0
	do
		_sd_di_out_h
		_sd_clk_out_h
		_sd_cs_out_h
		h1000 0
		do
			_sd_clk_out_l _sd_clk_out_h
		loop
\
\						\ select the card forever
		_sd_cs_out_l
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p 126 / 7.2.1 Mode Selection and Initialization
\	REF2: Software Reset
\	REF3
\
\						\ CMD0 0 - GO_IDLE_STATE
		h95 0 0 _sd_cmdr8
		1 =
		if
			drop 0 leave
		then
	loop
	if
\						\ card did not respond
		hA6 ERR
	then
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p 126 / 114 7.2.1 Mode Selection and Initialization
\	REF1: p  63 /  51 4.3.13 Send Interface Condition Command (CMD8)
\	REF1: p  85 /  73 4.9.6 R7 (Card interface condition)
\	REF2: How to support SDC Ver2 and high capacity cards
\	REF3
\
\
\
\
	-1 h8 0
	do
\						\ CMD8 1AA - SEND_IF_COND - the card send the
\						\ interface condition
		h87 h1AA h8 _sd_cmdr40
		h1AA = swap 1 = and
		if
			drop 0 leave
		then
	loop
\						\ checking for valid SD ver2 or higher, supports
\						\ 2.7 - 3.6 volts
	if
\						\ it is something else, MMC support or sd version
\						\ 1 could be added here
		hA7 ERR
	then
\
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p 126 / 114 7.2.1 Mode Selection and Initialization
\	REF3
\ 						\ try ACMD41 40000000 (CMD55 - CMD41)
\						\ SD_SEND_OP_COND, initialize
\						\ the sd card, telling it we support hi capacity
 	-1 h100 0
	do
		1 0 h37 _sd_cmdr8
		drop

		1 h40000000 h29 _sd_cmdr8
		0=
		if
			drop 0 leave
		then
	loop
	if
\						\ card did not initialize, doesn't support
\						\ hi capacity host?
\ 						\ try ACMD41 0 (CMD55 - CMD41) SD_SEND_OP_COND,
\						\ initialize
\						\ the sd card, telling it we do not support hi
\						\ capacity
		-1 h100 0
		do
			1 0 h37 _sd_cmdr8
			drop
\
			1 0 h29 _sd_cmdr8
			0=
			if
				drop 0 leave
			then
		loop
		if
\						\ card did not initialize
			hA8 ERR
		then
	then
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p 126 / 114 7.2.1 Mode Selection and Initialization
\	REF1: p 104 /  92 5.1 OCR register
\						\ CMD58 0 - SEND_OCR, get the OCR register,
\						\ make sure we are powered up
\						\ and find out if the ccs bit is set,
\						\ if yes the card is SDHC or SDXC and
\						\ can only be addressed as 512 byte blocks
	1 0 h3A _sd_cmdr40
	swap 0<> over h80000000 and 0= or
	if
\						\ card did not indicate ready, or the
\						\ power up status was not set
		hA9 ERR
	then
\						\ set the ccs flag accordingly
	h40000000 and 0<> _sd_ccs W!
		
\
\	REF3
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p 126 / 114 7.2.1 Mode Selection and Initialization
\	REF1: p 104 /  92 5.1 OCR register
\						\ CMD16 512 SET_BLOCKLEN, set the block length
\						\ to 512 bytes
	_sd_ccs W@ 0=
	if
		1 h200 h10 _sd_cmdr8
		if
\						\ setting the block length to 512 bytes failed
			hAA ERR
		then
	then
\
\
\
\	REF1: p 135 / 123 7.3.1.3 Detailed Command Description
\	REF1: p 141 / 129 7.3.2 Responses
\	REF1: p 107 /  95 5.3 CSD Register
\						\ CMD9 0 - SEND_CSD, get the CSD register,
\						\ check the structure version
\
	h10 1 0 h9 _sd_cmdr8data
	if
		hAB ERR
	then
\
\
	sd_cogbuf COG@
	h40000000 and
	if
		1 _sd_hc W!
\
\	Card Size calculation
\
\	REF1: p 116 / 104 SIZE_C
\
		sd_cogbuf 1+ COG@ h3F and h10 lshift
		sd_cogbuf 2+ COG@ h10 rshift or 1+
		hA lshift _sd_maxblock L! 
	else
		0 _sd_hc W!
\
\	Card Size calculation
\
\	REF1: p 111 / 99 SIZE_C
\
\							\ READ_BL_LEN , this is the blocksize
\							\ for size calc
\		_sd_buf 5 + C@ F and >m
		sd_cogbuf 1+ COG@ h10 rshift hF and >m
\							\ C_SIZE + 1
\		_sd_buf 6 + dup C@ 3 and 8 lshift over st?
\		1+ C@ or 2 lshift swap st?
\		2+ C@ C0 and 6 rshift or 1+ st?
		sd_cogbuf 1+ COG@ h3FF and h2 lshift
		sd_cogbuf 2+ COG@ h1E rshift or 1+
\							\ 2 exp C_SIZE_MULT +2 
\		_sd_buf 9 + dup C@ 3 and 1 lshift
\		swap 1+ C@ 7 rshift or 2+ >m
		sd_cogbuf 2+ COG@ hF rshift h7 and 2+ >m
\
\							\ the maximum block number
		u* u* h200 u/ _sd_maxblock L!
\
	then
[ifdef _sd_debug
	_sd_hc W@
	if
		." SH"
	else
		." SD"
	then
	." SC initialize success # of Blocks: " _sd_maxblock L@ . cr
	cr ." _sd_init EXIT" cr
]
;
\
\
\ sd_init
\
\
\ forget build_sdinit
\
\
\
c" Loaded sdinit.f~h0D" .cstr

