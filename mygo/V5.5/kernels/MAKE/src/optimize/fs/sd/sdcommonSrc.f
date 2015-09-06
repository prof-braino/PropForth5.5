\
1 wconstant build_sdcommon
c" Loading sdcommon.f ..." .cstr
\
[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]
\
\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[ifndef variable
: variable
	lockdict create $C_a_dovarl w, 0 l, forthentry freedict
;
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
\
\ px? ( n1 -- t/f) true if pin n1 is hi
[ifndef px?
: px?
	>m _maskin
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
c" Loaded sdcommon.f~h0D" .cstr
