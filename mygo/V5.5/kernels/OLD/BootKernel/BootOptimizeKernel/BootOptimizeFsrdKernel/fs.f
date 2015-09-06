fl


\ fs - eeprom file system
\
\	This makes it easy to set up a file system, and then only have the read functions
\	available. Takes less code space and provides a measure of protection.
\
\ IMPORTANT: Do not install this kernel on a system with on 32k of EEprom, such as the Demo board.
\           If you write files, result may be indeterminate.
\
\
\ A very simple file system for eeprom. The goal is not a general file system, but a place to put text
\ (or code) in eeprom so it can be dynamically loaded by propforth
\
\ the eeprom area start is defined by fsbot and the top is defined by fstop
\ The files are in eeprom memory as such:
\ 2 bytes - length of the contents of the file
\ 1 byte	- length of the file name (this is a normal counted string, counted strings can be up
\		255 bytes in length, the length here is limited for space reasons)
\ 1 - 31 bytes	- the file name
\ 0 - 65534 bytes	- the contents of the file
\
\ the last file has a length of 65535 (0hFFFF)
\ 
\ the start of every file is aligned with eeprom pages, for efficient read and write, this is 64 bytes
\
\ Status: 2010NOV24 Beta
\
\ 2011FEB03 - fix to align page reads to page addresses so crossing eeproms does not cause a problem _fsread
\
\ 2011MAY31 - stable, reformat, updated error codes, added error message for file not found, added RO option

\
\ main routines
\
\ fsload filename	- reads filename and directs it to the next free forth cog, every additional nested fsload
\			  requires an additional free cog
\ fsread filename	- reads the file and echos it directly to the terminal
\ fswrite filename	- writes the file to the filesystem - takes input from the input until ...\0h0d is encounterd
\			- ie 3 dots followed by a carriage return
\ fsls			- lists the files
\ fsclear		- erases all files
\ fsdrop		- erases the last file
\
\
\ The most common problem is forgetting the ...\h0d at the end of the file you want to write. Usually an fsdrop will
\ erase the last file which is invalid.


{

Usage example:

	load this file
	type in fsclear
	load the contents below - select from the fl to 1 line past ... - need the last cr
	type in fsls - gives the list of the files
	type fsload demo - loads demo, which loads the other 3 files


fl

\ some simple files for testing
fswrite demo
fsload hello.f
fsload bye.f
fsload aloha.f
...


fswrite hello.f
\ hello ( --)
: hello ." Hello world" cr ;
...

fswrite bye.f
\ bye ( --)
: bye ." Goodbye world" cr ;
...

fswrite aloha.f
\ aloha ( t/f -- ) 
: aloha if ." Hello" else ." Goodbye" then ."  world" cr ;
...

\ end of example files


}



\
\ define only one of these, build_fsRO is useful when you want to be able to read files
\ but want to make sure no-one can write them
\
\ remember there are still eeprom write routines in the boot kernel
\ so safety is not guaranteed
\

1 wconstant build_fsrd

[ifndef $C_a_doconl
    h52 wconstant $C_a_doconl
]


\ constant ( x -- ) skip blanks parse the next word and create a constant, allocate a long, 4 bytes
[ifndef constant
: constant
	lockdict create $C_a_doconl w, l, forthentry freedict
;
]

\
\ CONFIG PARAMETERS BEGIN
\
h8000	constant	fsbot		\ the start adress in eeprom for the file system
h10000	constant	fstop		\ the end address in the eeprom for th file system
h40	wconstant	fsps		\ a page size which works with 32kx8 & 64kx8 eeproms
					\ and should work with larger as well. MUST BE A POWER OF 2
\
\ CONFIG PARAMETERS END
\

\
\ lasti? ( -- t/f ) true if this is the last value of i in this loop
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
\ _nd ( n1 -- n2 )
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
\ _ft ( n1 divisor -- cstr )
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
\ _bf ( n1 -- cstr )
[ifndef _bf
: _bf
	4 _ft
;
]
\
\ .byte ( n1 -- )
[ifndef .byte
: .byte
	h_FF and _bf .cstr
;
]
\
\
\ _wf ( n1 -- cstr )
[ifndef _wf
: _wf
	h_FFFF and 2 _ft
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
	1 _ft
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
\
\
[ifndef 1lock
: 1lock 1 lock ;
]
\
[ifndef 1unlock
: 1unlock 1 unlock ;
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
[ifndef _sdai
: _sdai
	h1D pinin
;
]
\
\
[ifndef _sdao
: _sdao
	h1D pinout
;
]
\
\
[ifndef _scli
: _scli
	h1C pinin
;
]
\
\
[ifndef _sclo
: _sclo
	h1C pinout
;
]
\
\
[ifndef _sdal
: _sdal
	h20000000 _maskoutlo
;
]
\
\
[ifndef _sdah
: _sdah
	h20000000 _maskouthi
;
]
\
\
[ifndef _scll
: _scll
	h10000000 _maskoutlo
;
]
\
\
[ifndef _sclh
: _sclh
	h10000000 _maskouthi
;
]
\
\
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


\ the eereadpage and eewritePage words assume the eeprom are 64kx8 and will address up to 
\ 8 sequential eeproms
\ eereadpage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
[ifndef eereadpage 
: eereadpage
	1lock
	1 max rot dup hFF and swap dup h8 rshift hFF and swap h10 rshift h7 and 1 lshift dup >r
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


\ _fsk ( n1 -- n2)
[ifndef _fsk
: _fsk
	h8 lshift key or
;
]

\ _fnf ( --)
[ifndef _fnf
: _fnf
	cr ." FILE NOT FOUND" cr
;
]

\ _fspa ( addr1 -- addr2) addr2 is the next page aligned address after addr1
: _fspa
	fsps 1- + fsps 1- andn
;

\ _fsnext ( addr1 -- addr2 t/f) addr - the current file address, addr2 - the next addr, t/f - true if we have
\				gone past the end of the eeprom. t0 -length of the current file
\				t1 - length of the file name (char)
: _fsnext
	t0 W@ t1 C@ + 2+ 1+ + _fspa dup fstop >=
;

\ _fsrd ( addr1 addr2 n1 -- ) addr1 - the eepropm address to read, addr2 - the address of the read buffer
\ n1 - the number of bytes to read
: _fsrd
	dup >r rot dup r> + fstop 1- >
	if
		hB ERR
	then
	rot2 eereadpage
	if
		hA ERR
	then
;

\ _fsfree ( -- n1 ) n1 is the first location in the file system, -1 if there are none
: _fsfree
	-1 fsbot
	begin
\ read 3 bytes into t0, t1 and process
		dup t0 3 _fsrd t0 W@ hFFFF =
		if
			nip dup -1
		else
			_fsnext
		then
	until
	drop
;

\ _fsfind ( cstr -- addr ) find the last file named cstr, addr is the eeprom address, 0 if not found
: _fsfind
	fsbot 0 >r
	begin
\ read namesizemax 1F + 3 bytes into t0, t1, and tbuf
		dup t0 h22 _fsrd t0 W@ hFFFF =
		if
			-1
		else
			over t1 cstr=
			if
				r> drop dup >r
			then
			_fsnext
		then
	until
	2drop r>
;

\ _fslast ( -- addr ) find the last file, 0 if not found
: _fslast
	0 fsbot
	begin
\ read namesizemax 1F + 3 bytes into t0, t1, and tbuf
		dup t0 h22 _fsrd t0 W@ hFFFF =
		if 
			-1
		else
			nip dup
			_fsnext
		then
	until
	drop
;


\ fsfree ( -- )
: fsfree
	_fsfree dup -1 =
	if
		0
	else
		fstop swap -
	then
	cr .long ."  bytes free in EEPROM file system" cr
;

\ fsls ( -- ) list the files
: fsls
	cr fsbot
	begin
\ read namesizemax 1F + 3 bytes into t0, t1, and tbuf
		dup t0 h22 _fsrd t0 W@ hFFFF =
		if
			-1
		else
			dup .long space t0 W@ .word space t1 .cstr cr
			_fsnext
		then
	until
	drop fsfree
;

\ _fsread ( cstr -- )
: _fsread
	_fsfind dup
	if
\ read 3 bytes into t0, t1 and process
		dup t0 h3 _fsrd
		t1 C@ + 2+ 1+ t0 W@ bounds
		do
\ align to page
			fsps i fsps 1- and -
\ only get what we need
			ibound i - min
\ read the bytes
			i pad h2 ST@ _fsrd
\ emit them
			pad over .str
		+loop
	else
		drop
	then
	padbl
;

\ _fsp ( -- cstr ) filename, if cstr is 0 no file found
: _fsp
	parsenw dup
	if
		dup _fsfind 0=
		if
			drop 0
		then
	then
;
		

\ fsread ( -- ) filename
: fsread
	_fsp dup 
	if
		_fsread
	else
		drop _fnf
	then
;

\ _fsload ( cstr -- )
: _fsload
	dup _fsfind
	if
		lockdict cogid nfcog iolink freedict
		_fsread cr cr cogid iounlink
	else
		drop
	then
;

\ fsload filename ( -- ) send the file to the next free forth cog
: fsload 
	_fsp dup
	if
		_fsload
	else
		drop _fnf
	then
;


\ this changes the name of the last onboot word
\
c" onboot" find drop pfa>nfa 1+ c" onb001" C@++ rot swap cmove

\ execute file boot.f if it exists
: onboot
	onb001
\ do not execute boot.f if escape has been hit
	fkey? and fkey? and or h1B <>
	if
		c" boot.f" _fsload
	then
;




\ fs - eeprom file system
\
\ A very simple file system for eeprom. The goal is not a general file system, but a place to put text
\ (or code) in eeprom so it can be dynamically loaded by propforth
\
\ the eeprom area start is defined by fsbot and the top is defined by fstop
\ The files are in eeprom memory as such:
\ 2 bytes - length of the contents of the file
\ 1 byte	- length of the file name (this is a normal counted string, counted strings can be up
\		255 bytes in length, the length here is limited for space reasons)
\ 1 - 31 bytes	- the file name
\ 0 - 65534 bytes	- the contents of the file
\
\ the last file has a length of 65535 (0hFFFF)
\ 
\ the start of every file is aligned with eeprom pages, for efficient read and write, this is 64 bytes
\
\ Status: 2010NOV24 Beta
\
\ 2011FEB03 - fix to align page reads to page addresses so crossing eeproms does not cause a problem (fsread)
\
\ 2011MAY31 - stable, reformat, updated error codes, added error message for file not found, added RO option

\
\ main routines
\
\ fsload filename	- reads filename and directs it to the next free forth cog, every additional nested fsload
\			  requires an additional free cog
\ fsread filename	- reads the file and echos it directly to the terminal
\ fswrite filename	- writes the file to the filesystem - takes input from the input until ...\0x0d is encounterd
\			- ie 3 dots followed by a carriage return
\ fsls			- lists the files
\ fsclear		- erases all files
\ fsdrop		- erases the last file
\
\
\ The most common problem is forgetting the ...\h0d at the end of the file you want to write. Usually an fsdrop will
\ erase the last file which is invalid.



1 wconstant build_fswr

\
\
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
\ EW@ ( eeAddr -- n1 )
[ifndef EW@
: EW@
	t0 h2 eereadpage
	if
		hB ERR
	then
	t0 W@
; ]

\ EC@ ( eeAddr -- c1 )
[ifndef EC@
: EC@
	EW@ hFF and
;
]


\
\
\ EW! ( n1 eeAddr -- )
[ifndef EW!
: EW!
	swap t0 W! t0 h2 eewritepage
	if
		hA ERR
	then
;
]
\ _fswr ( addr1 addr2 n1 -- ) addr1 - the eepropm address to write, addr2 - the address to write from
\ n1 - the number of bytes to write
: _fswr
	dup >r rot dup r> + fstop 1- >
	if
		hA ERR 
	then
	rot2 eewritepage
	if
		hA ERR
	then
;
\ fsclr ( -- )
\ : fsclr
\ 	padbl fstop fsbot
\	do
\		i pad fsps _fswr 2e emit
\	fsps +loop
\	-1 fsbot EW!
\ ;
\
: fsclear
	-1 fsbot EW!
; 
\ fswrite filename ( -- ) writes a file until ... followed immediately by a cr is encountered
: fswrite
	_fsfree dup -1 <> parsenw dup rot and
	 if
\ set the file length to 0, copy in the file name
		0 pad W! dup C@ 2+ 1+ pad + swap pad 2+ ccopy
\ find the first free page
		0 swap key _fsk _fsk _fsk
\ ( eaddr1 n1 addr2 n2 ) eaddr - start of file in the eeprom, n1 - bytes written so far, addr2 - next addr in the pad,
\ n2 - a 4 byte key buffer
		begin
\ check to see if we have a ... at the end of a line
			h2E2E2E0D over = if
				-1
			else
\ get a key from the key buffer, write it the the pad
				tuck h18 rshift
				dup emit
				over C! 1+ tuck pad - fsps =
				if
\ we have a page worth of data, write it out
					nip rot2 2dup + pad fsps _fswr fsps + rot pad swap
				then	
\ get another key			
				_fsk 0
			then
		until
\ any keys left?
		drop pad - dup 0> if
\ write the leftover, not a full page
		>r 2dup + pad r> dup >r _fswr r> +
		else 
			drop
		then
\ write the length of FFFF for the next file
		2dup + hFFFF swap _fspa dup fstop 1- <
		if
			EW!
		else
			2drop
		then	
\ subtract the length of the filename +1, and the 2 bytes which are the length of the file, and update the length of the file 
		over 2+ EC@ 2+ 1+ - swap EW!
	else
		2drop clearkeys 
	then
	padbl
;

\ fsdrop ( -- ) deletes last file
: fsdrop
	_fslast dup -1 = 
	if
		drop
	else
		hFFFF swap EW!
	then
;
 

