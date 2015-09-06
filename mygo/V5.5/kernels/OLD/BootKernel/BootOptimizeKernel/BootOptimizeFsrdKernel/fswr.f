fl

fswrite fswr.f 

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
\ fsclear ( -- ) erase all files and initialize the eeprom file system
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
 

...

