fl


\
\ fswrite sd_init.f
\
\
\ 1 wconstant _sd_debug
\
1 wconstant build_sd
\
[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]
\
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
\ 4/ ( n1 -- n1>>2 ) n2 is shifted arithmetically right2 bits
[ifndef 4/
: 4/ _xasm2>1IMM h0002 _cnip h077 _cnip ;
]
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
\ The structure which will be in cog memory
\
\ the adresses of the mask bits for the sd io
\
coghere W@ wconstant v_sdbase
v_sdbase	wconstant v_sd_do
v_sd_do	1+	wconstant v_sd_di
v_sd_di	1+	wconstant v_sd_clk
\
\ 
\ the block number of the current directory
\
v_sd_clk 1+	wconstant v_currentdir
\
\
\ set the data area for the buffer at the end of the assembler code, the allocation is done in sd_init 
\
v_currentdir 1+	wconstant sd_cogbuf
\
sd_cogbuf h80 +	wconstant _sd_cogend
\
\
\
\
wvariable _sd_initialized 0 _sd_initialized W!
\ sd_lock ( -- ) lock the sd card so no one else can use it
: sd_lock
	h3 lock
;
\
\ sd_unlock ( -- ) unlock the sd card
: sd_unlock
	h3 unlock
;
\
\	REF1: p 104 /  92 5.1 OCR register
\
\					\ this variable is a reflection of the ccs bit in the OCR
\					\ register, if 0, we send byte addresses
\					\ ( block aligned) to the card, otherwise block addresses,
\					\ only used internally in the driver
\					\ initialized by sd_init
wvariable _sd_ccs 0 _sd_ccs W!
\
\
\	REF1: p 107 /  95 5.3 CSD Register
\
\					\ this variable is a reflection of the CSD structure
\					\ version bits in the CSD register,
\					\  if 0, it is a Standard card, otherwise a High or
\					\ Extended Capacity card
\					\ initialized by sd_init
wvariable _sd_hc 0 _sd_hc W!
\
\
\	Card Size calculation
\
\	REF1: p 111 / 99 SIZE_C
\
\					\ this variable is the maximum block number for the card
\					\ initialized by sd_init (card capacity is this * 512)
variable _sd_maxblock 0 _sd_maxblock L!
\
\
\
\
\
\ SD CONFIG PARAMETERS BEGIN
\
\ definitions for io pins connecting to the sd card
\
[ifndef $S_sd_cs
19 wconstant $S_sd_cs
]
[ifndef $S_sd_di
20 wconstant $S_sd_di
]
[ifndef $S_sd_clk
21 wconstant $S_sd_clk
]
[ifndef $S_sd_do
16 wconstant $S_sd_do
]
\
\
\
\ SD CONFIG PARAMETERS END
\
\
\
\ sd_uninit ( -- ) "releases" the cog memory
\
: sd_uninit
	_sd_cogend v_sdbase
	do
		0 i COG!
	loop	
	v_sdbase coghere W!
;

\ sd_init ( -- ) call for every cog using the sd card
: sd_init
[ifdef _sd_debug
	cr ." sd_init ENTER~h0D" cr
	lock?
]
\
\					\ allocate longs in the cog as the data buffer
	_sd_cogend coghere W!
\					\ Set up the pins connected to the SD card
	$S_sd_di  dup pinlo pinout
	$S_sd_clk dup pinlo pinout
	$S_sd_do            pinin
	$S_sd_cs  dup pinlo pinout
\
	$S_sd_di  >m v_sd_di COG!
	$S_sd_do  >m v_sd_do COG!
	$S_sd_clk >m v_sd_clk COG!
\ 
	lockdict
	_sd_initialized W@ 0=
	if
		c" _sd_init" find
		if
			sd_lock
			execute
\
			-1 _sd_initialized W!
\
			sd_unlock
		else
			drop
		then
	then
	freedict
\
[ifdef _sd_debug
	cr ." sd_init EXIT" cr
]
;
\
\
\
\
\ 1 wconstant build_sdinit
\
\
\ constant ( x -- ) skip blanks parse the next word and create a constant, allocate a long, 4 bytes
[ifndef constant
: constant
	lockdict create $C_a_doconl w, l, forthentry freedict
;
]
\
\
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
\ ...
\ fl
\
\
\ fswrite sd_run.f
\
\
\ 1 wconstant build_sdrun
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
lockdict create a_shift forthentry
$C_a_lxasm w, h133  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z20yP[i l, z1SF03C l, z2WyQ88 l, zfyPOO l, z1SV04Q l, z2WyQ8W l, zoyPO1 l,
z1jix\1 l, z1bix\2 l, z1[ix\2 l, z3[yQCQ l, z1[ix\1 l, z1SyLI[ l, z1SV04h l, z2WyQ88 l,
z1SV04\ l, z2WyQ8W l, z1SyJQL l, z2WyPO0 l, z1bix\1 l, z1bix\2 l, z1XFb7l l, znyPO1 l,
z1[ix\2 l, z3[yQCb l, z1[ix\1 l, z1SV01X l, z1SV04M l, z1SV04P l, z1SV04Y l, z1SV04[ l,
\
freedict
\
lockdict create mem>cog forthentry
$C_a_lxasm w, h11E  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z2WiPmC l, z1SyLIZ l, z8iPeB l, z1KiZJC l, z20yPW1 l, z20yPO4 l, z2WiPZD l,
z3[yPnM l, z1SyLI[ l, z1SV01X l,
freedict
\
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
\
\
\ fl
\

\ fswrite sdfs.f
\
\
\ 1 wconstant build_sdfs
\
\
\
{

Status: ALPHA 2011 APR 01


sdfs is meant to be a very simple fast file system on top of sd_driver.

The design criteria are around small code size and speed, as opposed to generality
and versatility.


Main concepts:

1. A file system occupies n contiguos 512 byte blocks on the SD card. If it is
desired that the card should be FAT32 formatted, it should be possible to format
card, create a very large file, figure out which blocks the file occupies, and mount
sdfs to use those blocks.

This means sdfs could be manipulated on a pc by writing some code. This is NOT a goal of
the initial implementation.

The file system must not start at block 0, block 1 is the first valid block number.

This also means multiple file systems can be defined on one sd card, useful for isolating
functions like logging.

An sd card can be partitioned into multiple "disks", each which can contain one file system.
There is no partition table or disk routines, when a filesystem is created, the start and end
inherently defines the partion.

2. Files are 2 - n contigous blocks, the maximum file size is 2Gig, (max positive 32 bit
integer.) When a file is created, the space that is allocated to the file (the space is
allocated as blocks of 512 bytes) is the maximum size the file can grow to.
This trades space efficiency for a very simple and fast allocation.

3. File names must be 1 to 26 characters in length, and can only contain characters 0h30 - 0h7D.
There are no other restrictions on file names. It is recommended that names do not use special
characters. The reason for this is mapping urls to file names gets more complicated.

4. There is directory support, a directory is a fixed length file, whose name ends with a /
There is no other differentiator. A directory can contain up to 2048 entries. A simple hashing
mechanism makes navigation quick. (This hash function should be tested more thouroughly for at
some point, but initial testing seems ok.) This optimizes for opening files, the result is that
to list a directory the whole directory must be traversed, so directory "listing" is slower.
However, assuming the hash function performs reasonably, finding a file, and opening the file
file be fast, and not slow down as there are more entries in the directory.


The root directory is /

Pathnames are simple concatenated directory and file names. 

The maximum total length of a path name is 120 characters, this should make mapping urls to files
very easy, and allow the use of the pad for parsing and file name manipulation.

To access a file, or directory, the current directory must be set to the parent of the file or
directory. File access is only in that directory. This means no relative navigation or fully
qualified file names. Reasons are 2 fold, 1 simplicity, 2 security. This will bebome evident
when the http server is using the file system.


5. There is no limit on directory depth other than that which is imposed by the maximum path
name length. The deeper a file is in the structure, the longer it will take to navigate to it.

6. Each file has a header block, immediately followed by all the data blocks.

7. The header block number is used by routines to reference files and directories.

8. Block numbers are absolute, this makes debugging, repair, and verification much simpler.
Unfortunately it means you cannot easily move the file system around.

9. The main interface routines to sdfs are:


\ _sd_CrEaTe ( n1 n2 -- ) n1 - starting block, n2 - last block + 1, CREATE a file system, WIPES OUT DATA

\ sd_mount ( n1 -- ) mount the file system, n1 - the starting block of the file system,
\ the file system must be mounted before it is used


\ sd_createdir ( cstr -- n1 ) cstr is the name of the directory to create, n1 is the header block
\ of the directory. If this directory already exists, it returns the root block of the existing
\ directory


\ sd_cd.. ( -- ) make the parent directory the current directory

\ sd_cd ( cstr -- ) make cstr the current directory, if it does not exists, nothing happens
\ the directory name in cstr must have a / at the end of it
 
\ sd_cwd ( -- ) get the pathname of the current directory and copy it to pad

\ sd_ls ( -- ) list the current directory


\ sd_createfile ( cstr n1 -- n2) allocate n1 blocks, this includes the header block

\ sd_find ( filename -- blocknumber/0) search for filename in the current directory

\ sd_stat ( filename -- ) prints stats for the file


\ sd_write ( numblocks filename -- ) writes a new or existing file until ... followed immediately by a cr is encountered
\ if the file exists, writing will be truncated to the existing maximum file size allocated when the file was created


\ sd_trunc ( length filename -- ) sets the number of bytes used in the file to length

\ sd_appendblk( addr size blk -- )
\ sd_append( addr size filename -- )

\ sd_readblk ( n1 -- ) n1 - header block number of file,
\				read the file and emit the char
\ sd_read ( filename -- ) read the file and emit the chars

\ sd_loadblk ( n1 -- ) n1 - the header block for the fileloads the file,
\ 			routes the file to the next free forth cog
\ sd_load ( cstr -- ) loads the file, routes the file to the next free forth cog


\
\ These are provided for command line convenience
\

\ ls ( -- )
\ cd dirname ( -- )
\ cd.. ( -- )
\ cd/ ( -- )
\ cwd ( -- ) print the current directory
\ mkdir dirname ( -- )
\ fread filename ( -- )
\ fcreate filename ( numblocks_to_allocate -- )
\ fwrite filename ( numblocks_to_allocate -- )
\ fstat filename ( -- )


}
\
\
\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[ifndef #C
: #C
	-1 >out W+! pad>out C!
	
;
]
\
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
\
\ .num ( n1 -- ) print n1 as a fixed format number
[ifndef .num
: .num
	_nf .cstr
;
]
\
\ pad>cog ( n1 -- ) the cog address to start writing 32 longs
[ifndef pad>cog
: pad>cog 
	pad swap h20 mem>cog
;
]
\
\ tbuf>cog7 ( n1 -- ) the cog address to start writing 7 longs
[ifndef tbuf>cog7
: tbuf>cog7
	tbuf swap h7 mem>cog
;
]
\
\ cog>pad ( n1 -- ) the cog address to start reading 32 longs
[ifndef cog>pad
: cog>pad
	pad swap h20 cog>mem
;
]
\
\ cog>tbuf7 ( n1 -- ) the cog address to start reading 7 longs
[ifndef cog>tbuf7
: cog>tbuf7
	tbuf swap h7 cog>mem
;
]
\
\ _fnf ( --) file not found message
[ifndef _fnf
: _fnf
	cr ." FILE NOT FOUND" cr
;
]
\
\
{
file header block:

00 - 1F : 000 - 07F - a counted string which is the full pathname of this file, must be padded with blanks 
20 - 26 : 080 - 09B - a counted string which is the file name of this file, must be padded with blanks
27	: 09C - 09F - 20202020
28	: 0A0 - 0A3 - 20202020
29	: 0A4 - 0A7 - 20202020
2A	: 0A8 - 0AB - Length of file in bytes
2B	: 0AC - 0AF - Number of blocks allocated to this file (including the header block)
2C	: 0B0 - 0B4 - 20202020
2D	: 0B4 - 0B7 - 20202020
2E	: 0B8 - 0BB - the block number of the root directory
2F	: 0BC - 0BF - the block number of the parent directory
30	: 0C0 - 0C4 - 20202020
31	: 0C4 - 0C7 - 20202020
32	: 0C8 - 0CB - the first block in this files sytem \ same as the block number of the root directory
33	: 0CC - 0CF - The last block + 1 in this file system
34	: 0D0 - 0D4 - 20202020
35	: 0D4 - 0D7 - 20202020
36	: 0D8 - 0DB - if this is the root header block, this is the first free block, otherwise ignored
37 - 7F	: 0DC - 1FF - blanks

directory entry:

000 - 01B - counted string, the file name, field must be padded with blanks
01C - 01F - header block number of file

32 bytes, 16 directory entries / 512 byte block  -- 2048 directory enties = 128 blocks
}
\
\
\
\ sd_mount ( n1 -- ) mount the file system, n1 - the starting block of the file system,
\ the file system must be mounted before it is used
: sd_mount
	sd_init v_currentdir COG!
;
\
\ sd_cwd ( -- ) get the pathname of the current directory and copy it to pad
: sd_cwd
	v_currentdir COG@ sd_blockread
	sd_cogbuf cog>pad
;
\
\ _sd_initdir ( n1 -- ) n1, directory block number, initialize the directory
: _sd_initdir
	sd_cogbuf h80 bounds
	do
		h20202020 i COG!
	loop
	sd_cogbuf h80 bounds
	do
		h20202000 i COG!
		 0 i h7 + COG!
	h8 +loop
	1+ h80 bounds
	do
		i sd_blockwrite
	loop
;
\ _sd_alloc ( n1 -- n2 ) n1 - number of blocks to allocate, n2 - starting block, assumes v_currentdir is valid
: _sd_alloc
	v_currentdir COG@ sd_blockread
	sd_cogbuf h2E + COG@
	sd_lock
\					\ ( n1 rootblock -- ) 
	dup sd_blockread swap
\					\ ( rootblock  n1 -- ) 
	sd_cogbuf h36 + COG@ tuck
\					\ ( rootblock  firstfreeblock n1 firstfreeblock -- ) 
	+ dup sd_cogbuf h36 + COG!
\					\ ( rootblock  firstfreeblock newfirstfreeblock -- ) 
	sd_cogbuf h33 + COG@ <
	if
\					\ ( rootblock  firstfreeblock -- ) 
		swap sd_blockwrite
	else
		hFD ERR		
	then
	sd_unlock
;
\
\ _sd_hash ( cstr -- hash ) hashes a name to a value between 0 & 7F
: _sd_hash
	tbuf h20 bl fill tbuf ccopy
	0 tbuf h1C bounds
	do
		i L@ xor 
	h4 +loop
	dup h10 rshift xor dup h8  rshift xor h7F and
;
\
\
\ _sd_setdirentry ( filename blocknumber -- ) write the directory entry
: _sd_setdirentry
	over _sd_hash
\							( filename blocknumber hash -- )
	h80 0
	do
		dup i + h7F and v_currentdir COG@ 1+ +
\							( filename blocknumber hash dirblock -- )
		sd_lock
		dup sd_blockread
		sd_cogbuf h80 bounds
		do
			i COG@ h20202000 =
			if
\							( filename blocknumber hash dirblock -- )
				i tbuf>cog7
				rot i h7 + COG!
\							( filename hash dirblock -- )
				dup sd_blockwrite
				0 rot2 leave
\							( filename 0 hash dirblock -- )
			then
		h8 +loop
		sd_unlock
		drop
		over 0=
		if
			leave
		then
\							( filename blocknumber hash -- )
	loop
	drop nip
	0<>
	if
		hFE ERR
	then
;
\
\ sd_find ( filename -- blocknumber/0) search for filename in the current directory
: sd_find
	dup _sd_hash -1
\							( filename hash flag -- )
	h80 0
	do        
		over i + h7F and v_currentdir COG@ 1+ +
		sd_blockread
\							( filename hash flag -- )
		sd_cogbuf h80 bounds
		do
			i COG@ h20202000 =
			if
				drop 0 leave
\							( filename hash 0  -- )
			else
				i cog>tbuf7 rot dup tbuf cstr=
\							( hash flag filename t/f  -- )
				if
					rot2 drop i h7 + COG@ leave
\							( filename hash blocknumber  -- )
				else
					rot2
\							( filename hash -1  -- )
				then
\				
			then
		h8 +loop
		dup -1 <>
		if
			leave
		then
\							( filename hash blocknumber/0 -- )
	loop
	nip nip
;
\
\   
\ sd_createfile ( cstr n1 -- n2) allocate n1 blocks, this includes the header block,
\  create a directory entry, and write the file header,
\ n2 is the block number of the file header
: sd_createfile
	over sd_find dup
	if
		nip nip
		dup sd_blockread
	else
		drop

		tuck
		_sd_alloc tuck
		_sd_setdirentry
\							\ ( n1 fileheaderblocknumber -- )
		v_currentdir COG@ sd_blockread
		sd_cogbuf cog>pad
		tbuf pad cappend
\							\ ( n1 fileheaderblocknumber -- )
		sd_cogbuf pad>cog padbl
		sd_cogbuf h20 + tbuf>cog7
		0 sd_cogbuf h2A + COG! 
		swap sd_cogbuf h2B + COG!
		v_currentdir COG@ sd_cogbuf h2F + COG!
		h20202020 sd_cogbuf h36 + COG!
		dup sd_blockwrite
	then
;
\
\
\ sd_createdir ( cstr -- n1 ) cstr is the name of the directory to create, n1 is the header block
\ of the directory. If this directory already exists, it returns the root block of the existing
\ directory
: sd_createdir
	dup C@++ + 1- C@ h2F <>
	if
		hFA ERR
	then
	dup sd_find dup
	if
		nip
	else
		drop
		sd_lock
		h81 sd_createfile
		dup _sd_initdir
		sd_unlock
	then
;
\
\
\ sd_ls ( -- ) list the current directory
: sd_ls
	v_currentdir COG@ 1+ h80 bounds
	do
		i sd_blockread
		sd_cogbuf h80 bounds
		do
			i COG@ h20202000 <>
			if
				i h7 + COG@ .
				tbuf i h7 bounds
				do i COG@ over L! 4+ loop drop
				tbuf .cstr cr
			then
		h8 +loop
	loop
;
\
\
\ sd_cd.. ( -- ) make the parent directory the current directory
: sd_cd..
	v_currentdir COG@ sd_blockread
	sd_cogbuf h2F + COG@ v_currentdir COG!
;
\
\
\ sd_cd ( cstr -- ) make cstr the current directory, if it does not exists, nothing happens
\ the directory name in cstr must have a / at the end of it
: sd_cd
	dup C@++ + 1- C@ h2F <>
	if
		hFA ERR
	then
	sd_find dup 0<>
	if
		v_currentdir COG!
	else
		drop
	then
;
\
\
\ _fsk ( n1 -- n2) n1<<8 or a key from the input
[ifndef _fsk
: _fsk
	h8 lshift key or
;
]
\
\ sd_write ( numblocks filename -- ) writes a new or existing file until ... followed immediately by a cr is encountered
\ if the file exists, writing will be truncated to the existing maximum file size allocated when the file was created
: sd_write
\ t0/t1 a long which is the number of bytes written
\ tbuf - a long which is the file size
	0 t0 L!
\							( numblocks filename -- )
	over 1+ sd_createfile
	sd_cogbuf h2B + COG@ 1- h200 u* tbuf L!
	dup 1+
\							( numblocks blocknumber blocknumber+1 -- )
	rot
	key _fsk _fsk _fsk
\							( blocknumber blocknumber+1 numblocks keys -- )
	rot2 bounds
	do
\							( blocknumber keys -- )
		sd_cogbuf h80 bounds
		do
			pad h80 bounds
			do
\							check to see if we have a ... at the end of a line
				h2E2E2E0D over =
				if
					leave
				else
					dup h18 rshift
					dup emit
					i C!
					t0 L@ dup tbuf L@ <
					if
						1+ t0 L! _fsk
					else
						2drop h2E2E2E0D leave
					then
				then
			loop
			i pad>cog
			h2E2E2E0D over =
			if
				leave
			then
		h20 +loop
		i sd_blockwrite
		h2E2E2E0D over =
		if
			leave
		then
	loop
	drop dup sd_blockread
	t0 L@ sd_cogbuf h2A + COG!
	sd_blockwrite
	padbl
;
\
\ sd_readblk ( n1 -- ) n1 - header block number of file,
\				read the file and emit the chars
: sd_readblk
\							should validate
	dup
	if
		dup sd_blockread 1+
\ 							( firstblock -- )
		sd_cogbuf h2A + COG@
		h200 u/mod
\ 							( firstblock remainder numblocks -- )
		rot swap
\							( remainder firstblock numblocks -- )
		dup
		if
			2dup bounds
			do
				i sd_blockread
				sd_cogbuf h80 bounds
				do
					i cog>pad
					pad h80 .str
				h20 +loop
			loop
		then
\ 							( remainder firstblock numblocks -- )
		+ sd_blockread
\ 							( remainder -- )
		sd_cogbuf h80 bounds
		do
			i
			cog>pad
			pad over h80 min
			.str
			h80 -
			dup 0 <=
			if
				leave
			then
		h20 +loop
		drop				
	else
		drop
	then
	padbl
;
\
\ sd_read ( filename -- ) read the file and emit the chars
: sd_read
	sd_find sd_readblk
;
\
\ sd_load ( cstr -- ) loads the file, routes the file to the next free forth cog
: sd_load
	cogid nfcog iolink
	sd_read cr cr
	cogid iounlink
;
\
\ sd_loadblk ( n1 -- ) n1 - the header block for the fileloads the file,
\ 			routes the file to the next free forth cog
: sd_loadblk
	cogid nfcog iolink
	sd_readblk cr cr
	cogid iounlink
;
\
\
\ sd_trunc ( length filename -- ) sets the number of bytes used in the file to length
: sd_trunc
	sd_find dup
	if
		dup sd_blockread
		swap sd_cogbuf h2B + COG@ h200 u* min
		sd_cogbuf h2A + COG!
		sd_blockwrite
	else
		drop
	then
	padbl
;
\
\
\
\ sd_stat ( filename -- ) prints stats for the file
: sd_stat
	sd_find dup
	if
		sd_blockread
		." File Length:~h09~h09" sd_cogbuf h2A + COG@
		dup h200 u/mod swap if 1+ then .num ."  blocks " .num ."  bytes~h0D"
		." Num Blocks Allocated:~h09" sd_cogbuf h2B + COG@
		dup .num ."  blocks " h200 u* .num ."  bytes~h0D"
	else
		drop
	then
;
\
\
\ _readlong ( addr -- long ) reads an unaligned long
: _readlong
	dup h3 and
	if
		dup h3 + C@ h8 lshift
		over 2+ C@ or h8 lshift
		over 1+ C@ or h8 lshift
		swap C@ or
	else
		L@
	then
;
\
\
\ _sd_appendbytes ( src byteoffset nbytes  -- updatedsrc )
\ t0	- nybtes
\ t1	- byteoffset
\ tbuf	- src
: _sd_appendbytes
	dup 0=
	if
		2drop
	else
		t0 W!
		t1 W!
		tbuf W!

		t1 W@ h3 and
		if
\							( -- )
			h4 t1 W@ h3 and -
\							( nfillbytes -- )
			-1 over h3 lshift rshift
\							( nfillbytes cogbufmask --  )
			t1 W@ 4/ sd_cogbuf + tuck COG@
\							( nfillbytes cogaddr cogbufmask cogbufdata --  )
			and
\							( nfillbytes cogaddr cogbufdata --  )
\
			tbuf W@ _readlong t1 W@
			h3 and h3 lshift
			lshift or			
\							( nfillbytes cogaddr cogbufdata --  )
			swap COG!
			dup t1 W+!
			dup tbuf W+!
			negate t0 W+!
\							( -- )
		then
\
		tbuf W@ t1 W@ 4/ sd_cogbuf + t0 W@ h4 u/mod swap
		if
			1+
		then
		bounds
		do
			dup _readlong
			i COG!
			h4 +
		loop
		drop
		tbuf W@ t0 W@ +
	then
;
\
\ sd_appendblk( addr size headerblk -- ) append buffer of size to the file at headerblk
: sd_appendblk
	dup sd_blockread
\							( addr size fileblock -- )
	over sd_cogbuf h2A + COG@
\							( addr size fileblock size filesize -- )
	+ dup sd_cogbuf h2B + COG@ h200 u*
\							( addr size fileblock newsize newsize allocatedsize -- )
	<
	if
\							( addr size fileblock newsize -- :: newsize fileblock )
		>r dup >r 1+
\							( addr size firstdatablock --  :: newsize fileblock )
		sd_cogbuf h2A + COG@
		h200 u/mod rot +
\							( addr size offset datablock --  :: newsize fileblock )
		begin
			dup >r sd_blockread
\							( addr size offset -- :: newsize fileblock datablock size -- )
			over >r rot swap
\							( size addr offset -- :: newsize fileblock datablock size -- )
			h200 over - r> min
\							( size addr offset numbytesthisblock -- :: newsize fileblock datablock -- )
			dup >r _sd_appendbytes r>
\							( size addr numbytesthisblock -- :: newsize fileblock datablock -- )
			rot swap - 0
\							( addr size 0 -- :: newsize fileblock datablock -- )
			over 0 <= r>
			dup sd_blockwrite
			1+
			swap
\							( addr size 0 datablock flag -- :: newsize fileblock -- )
		until
		r> dup sd_blockread
		r> sd_cogbuf h2A + COG!
		sd_blockwrite
	then
	drop 3drop
;
\
\ sd_append( addr size filename -- ) append buffer of size to the file
: sd_append
	sd_find dup
	if
		sd_appendblk	
	else
		3drop
	then
;
\
\
\ _sd_dn ( dirname -- t/f )
: _sd_dn
	C@++ + 1- C@ h2F <>
	if
		." INVALID DIRNAME~h0D"
		0
	else
		-1
	then
;
\
\
\ ls ( -- )
: ls sd_ls ;
\
\ cd dirname ( -- )
: cd
	parsenw
	dup 0= 
	if
		drop
	else
		dup _sd_dn
		if
			sd_cd
		else
			drop
		then
	then
;
\
\
\
\ cd.. ( -- )
: cd.. sd_cd.. ;
\
\ cd/ ( -- )
: cd/ v_currentdir COG@ sd_blockread sd_cogbuf h2E + COG@ v_currentdir COG! ;
\
\ cwd ( -- ) print the current directory
: cwd
	sd_cwd pad .cstr cr padbl
;
\
\
\ mkdir dirname ( -- )
: mkdir
	parsenw dup 0=
	if
		drop
	else
		dup _sd_dn
		if
			sd_createdir drop
		else
			drop
		then
	then
;
\
\
\ _sd_fsp ( -- cstr ) filename, if cstr is 0 no file found
: _sd_fsp
	parsenw dup
	if
		dup sd_find 0=
		if
			drop 0
		then
	then
;
\
\
\ fread filename ( -- )
: fread _sd_fsp dup if sd_read else drop _fnf then ;
\
\ fcreate filename ( numblocks_to_allocate -- )
: fcreate parsenw dup if swap sd_createfile drop else 2drop then ;
\
\ fwrite filename ( numblocks_to_allocate -- )
: fwrite parsenw dup if sd_write else 2drop then ;
\
\ fstat filename ( -- )
: fstat _sd_fsp dup if sd_stat else drop _fnf then ;
\
\ fload filename ( -- )
: fload _sd_fsp dup if sd_load else drop _fnf then ;
\


\
\ assuming you want to mount the filesystem on boot, if sdfs is not used
\
\
c" onboot" find drop pfa>nfa 1+ c" onb001" C@++ rot swap cmove
\
\ onboot ( n1 -- n1) load the file sd_boot.f
: onboot
	onb001 1 sd_mount 
\ do not execute sd_boot.f if escape has been hit
	fkey? and fkey? and or h1B <>
	if
		c" sdboot.f" sd_load
	then
;



