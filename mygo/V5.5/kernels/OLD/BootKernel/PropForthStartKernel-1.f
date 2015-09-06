fl
\ Copyright (c) 2012 Sal Sanci
\
\
\ These variables are the current dictionary limits cannot really easily redefine these variable on a running forth system,
\ it really screws things up to redefine requires multiple steps and caution, not worth the bother usually.
\ wlastnfa - access as a word, the address of the last nfa
\ wlastnfa W@ wvariable wlastnfa wlastnfa W!
\ memend - access as a word, the end of memory available to PropForth
\ memend  W@ wvariable memend  memend  W!
\ here - access as a word, the current end of the dictionary space being used
\ here    W@ wvariable here    here    W!
\ dictend - access as a word, the end of the total dictionary space
\ dictend W@ wvariable dictend dictend W!
\ 
\ Constants which reference the cogdata space are effectively variables with a level of indirection. Refedinition of these,
\ if the base variable is the same, is reasonable and can be done on a running system. Caution with other variables.
\
\
\ lock 0 - the main dictionary
\ lock 1 - the eeprom, and other devices on the eeprom lines
\ lock 2 - is used cooperatively by error messages, and messages during boot/reset to the console
\
\
\
\
1 wconstant build_BootKernel
\
\
\ propid - access as a word, the numeric id of this prop
wvariable propid 0 propid W!
\
\
\ the default prop and version strings
: (prop) c" Prop" ;
: (version) c" PropForth v5.3 2012MAY31 15:00 0" ;
\
\
\ pointers to the prop and version strings 
\ prop - access as a word, the address of the string identifier of this prop
wvariable prop
\ version - access as a word, the address of the string version of PropForth
wvariable version
\
\
\ This word variable is 0 (spin code) when the propeller is rebooted and set to non-zero when
\ forth is initialized
_finit W@ wvariable _finit _finit W!
\
\
\ The size of the cog's data area, this will be initialized by $S_cdsz defined as a spin constant
$S_cdsz wconstant $S_cdsz
\
\ Word constant, the txpin of the serial driver
$S_txpin wconstant $S_txpin
\ Word constant, the rxpin of the serial driver
$S_rxpin wconstant $S_rxpin
\ Word constant, the initial starting baud rate of the serial driver
$S_baud wconstant $S_baud
\
\
\ prop 7 is normally the console channel, this is the prop which handles communication to the console, and
\ provides the interface to the rest of the cogs
$S_con wconstant $S_con
\
\
\ These constants are all intialized to the running values, so any following words compile correctly. If you add constants
\ that are used by the base compiler, follow the practice. 
\ Any word constant which begins with $H_xxx is compiled with the value @xxxPFA + $10 - which is the exection address.
\ Any word constant which begins with $C_xxx is compiled with the value (@xxx - @a_base)/4 - execution address.
\
\ This is the address of the assembler which is loaded to a PropForth cog
$H_entry wconstant $H_entry
\
\
\ This is a pointer to the main cogdata area
$H_cogdata	wconstant	$H_cogdata
\
\
\ This is ' cq - the routine which handles the word c"
$H_cq	wconstant	$H_cq
\
\
\ This is ' dq - the routine which handles the word ."
$H_dq		wconstant	$H_dq
\
\
\ These constants are all assembler addresses
$C_a_exit	wconstant $C_a_exit
$C_a_dovarw	wconstant $C_a_dovarw
$C_a_doconw	wconstant $C_a_doconw
$C_a_branch	wconstant $C_a_branch
$C_a_litw	wconstant $C_a_litw
$C_a_2>r	wconstant $C_a_2>r
$C_a_(loop)	wconstant $C_a_(loop)
$C_a_(+loop)	wconstant $C_a_(+loop)
$C_a_0branch	wconstant $C_a_0branch
$C_a_litl	wconstant $C_a_litl
$C_a_lxasm	wconstant $C_a_lxasm
\
\ the end of the variables used by the interpreter in th cog, start of the cog free space
$C_varEnd wconstant $C_varEnd
\
\
\ if one of these bits is on, the adress if a forth word address
\
$C_fMask wconstant $C_fMask
\
\ a register which is used to initialize the cog and the par register on a reset
\
$C_resetDreg wconstant $C_resetDreg
\
\ the forth instruction pointer
\
$C_IP wconstant $C_IP
\
\
\ Address for the a_next routine
$C_a_next	wconstant $C_a_next
\
\
\
\
\
\ This is space constant
bl	wconstant bl
\
\
\ -1 or true, used frequently
: -1 hFFFFFFFF ;
\
\
\ 0 or false, used frequently
0	wconstant	0
1	wconstant	1
2	wconstant	2
\ : 2 2 ;
\
\
\ This is the par register, always initalized to point to this cogs section of cogdata
h1F0	wconstant par
\
\
\ the other cog special registers
\ cnt - address of the the global cnt register for this cog
h1F1	wconstant cnt
\ ina - address of the the ina register for this cog
h1F2	wconstant ina
\ outa - address of the the outa register for this cog
h1F4	wconstant outa
\ dira - address of the the dira register for this cog
h1F6	wconstant dira
\
\
\ This word variable defines the number of loops for an input timeout
_wkeyto  W@ wvariable _wkeyto  _wkeyto  W!
\
\ 
\ _ cnip ( -- )  Use in the _xasm*>* words to get rid of litw word
lockdict
: _cnip
	here W@ 2- dup W@ over 2- W! here W!
; immediate
freedict
\
\ the conditions for _xasm2>1 & _xasm2>1IMM
\
\
\ 1XXX - c = 0 and z = 0 above
\ 3XXX - c = 0           above or equal
\ 5XXX -           z = 0 not equal
\ AXXX -           z = 1 equal	
\ CXXX - c = 1           below
\ EXXX - c = 1 or  z = 1 below or equal
\
\
\ the assembler codes for all the _xasm
\
\ ADD		- h107
\
\ AND		- h0C7
\ ANDN		- h0CF
\
\ CMP		- h10E
\ CMPS		- h186
\
\ HUBOP		- h01F
\
\ MIN		- h097
\ MINS		- h087
\ MAX		- h09F
\ MAXS		- h08F
\
\ NEG		- h14F
\
\ OR		- h0D7
\
\ RDBYTE	- h007
\ RDLONG	- h017
\ RDWORD	- h00F
\
\ SAR		- h077
\
\ SHL		- h05F
\ SHR		- h057
\
\ SUB		- h10F
\
\ WRBYTE	- h000
\ WRLONG	- h010
\ WRWORD	- h008
\
\ XOR		- h0DF
\
\
\ _xasm2>flagIMM ( n1 n2 -- n ) \ there is first an immediate word, then assembler operation
\ is specified by the literal which follows (replaces the i field)
' _xasm2>flagIMM asmlabel _xasm2>flagIMM
\
\
\ _xasm2>flag ( n1 n2 -- n ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _xasm2>flag asmlabel _xasm2>flag
\
\
\ _xasm2>1IMM ( n1 n2 -- n ) \ there is first an immediate word, then assembler operation
\ is specified by the literal which follows (replaces the i field)
' _xasm2>1IMM asmlabel _xasm2>1IMM
\
\
\ _xasm2>1 ( n1 n2 -- n ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _xasm2>1 asmlabel _xasm2>1
\
\
\ _xasm1>1 ( n -- n ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _xasm1>1 asmlabel _xasm1>1
\
\
\ _xasm2>0 ( n1 n2 -- ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _xasm2>0 asmlabel _xasm2>0
\
\
\ lxasm ( addr -- ) load the assembler at addr and execute it
' lxasm asmlabel lxasm
\
\
\ _dictsearch ( nfa cstr -- n1) nfa - addr to start searching in the dictionary, cstr - the counted string to find
\	n1 - -1 if found, 0 if not found, a fast assembler routine
' _dictsearch asmlabel _dictsearch
\
\
\ _maskin ( n -- t/f ) n is the bit mask to read in
' _maskin asmlabel _maskin
\
\
\ _maskoutlo ( n -- ) set the bits in n low
' _maskoutlo asmlabel _maskoutlo
\
\
\ _maskouthi ( n -- ) set the bits in n hi
' _maskouthi asmlabel _maskouthi
\
\
\ name= ( nfa cstr -- t/f)
' name= asmlabel name=
\
\
\ cstr= ( cstr cstr -- t/f)
\ ' cstr= asmlabel cstr=
\
\
\ and ( n1 n2 -- n1 ) \ bitwise n1 and n2
: and _xasm2>1 hC7 _cnip ;
\
\
\ andn ( n1 n2 -- n1 ) \ bitwise n1 and inverted n2
: andn _xasm2>1 hCF _cnip ;
\
\
\ L@ ( addr -- n1 ) \ fetch 32 bit value at main memory addr
: L@ _xasm1>1 h17 _cnip ;
\
\
\ C@ ( addr -- c1 ) \ fetch 8 bit value at main memory addr
: C@ _xasm1>1 7 _cnip ;
\
\
\ W@ ( addr -- h1 ) \ fetch 16 bit value at main memory addr
: W@ _xasm1>1 h9 _cnip ;
\
\
\ RS@ ( addr -- n1 ) \ fetch n1th value down the return stack, 0 is the top of stack
' RS@ asmlabel RS@
\
\
\ ST@ ( addr -- n1 ) \ fetch n1th value down the stack, 0 is the top of stack
' ST@ asmlabel ST@
\
\
\ COG@ ( addr -- n1 ) \ fetch 32 bit value at cog addr
' COG@ asmlabel COG@
\
\
\ L! ( n1 addr -- ) \ store 32 bit value (n1) at main memory addr
: L! _xasm2>0 h10 _cnip ;
\
\
\ C! ( c1 addr -- ) \ store 8 bit value (c1) main memory at addr
: C! _xasm2>0 h0 _cnip ;
\
\
\ W! ( h1 addr -- ) \ store 16 bit value (h1) main memory at addr
: W! _xasm2>0 8 _cnip ;
\
\
\ RS! ( n1 n2 -- ) \ store n1 at the n2th position on the return stack, 0 is the top of stack
' RS! asmlabel RS!
\
\
\ ST! ( n1 n2 -- ) \ store n1 at the n2th position on the stack, 0 is the top of stack
' ST! asmlabel ST!
\
\
\ COG! ( n1 addr -- ) \ store 32 bit value (n1) at cog addr
' COG! asmlabel COG!
\
\
\ branch \ 16 bit branch offset follows -  -2 is to itself, +2 is next word
' branch asmlabel branch
\
\
\ hubopr ( n1 n2 -- n3 ) n2 specifies which hubop (0 - 7), n1 is the source datcog, n3 is returned, 
: hubopr _xasm2>1 h1F _cnip ;
\
\
\ hubopf ( n1 n2 -- t/f ) n2 specifies which hubop (0 - 7), t/f is the 'c' flag is set from the hubop
: hubopf _xasm2>flag hC01F _cnip ;
\
\
\ doconw ( -- h1 ) \ push 16 bit constant which follows on the stack - implicit a_exit
' doconw asmlabel doconw
\
\
\ doconl ( -- n1 ) \ push a 32 bit constant which follows the stack - implicit a_exit
' doconl asmlabel doconl
\
\
\ dovarw ( -- addr ) \ push address of 16 bit variable which follows on the stack - implicit a_exit
' dovarw asmlabel dovarw
\
\
\ dovarl ( -- addr ) \ push address of 32 bit variable which follows the stack - implicit a_exit
' dovarl asmlabel dovarl
\
\
\ drop ( n1 -- ) \ drop the value on the top of the stack
' drop asmlabel drop
\
\
\ dup ( n1 -- n1 n1 )
\ ' dup asmlabel dup
: dup h0 ST@ ;
\
\
\ = ( n1 n2 -- t/f ) \ compare top 2 32 bit stack values, true if they are equal
: = _xasm2>flag hA186 _cnip ;
\
\
\ exit the current forth word, and back to the caller
' exit asmlabel exit
\
\
\ > ( n1 n2 -- t/f ) \ flag is true if and only if n1 is greater than n2
: > _xasm2>flag h1186 _cnip ;
\
\
\ litw ( -- h1 ) \  push a 16 bit literal on the stack
' litw asmlabel litw
\
\
\ litl ( -- n1 ) \  push a 32 bit literal on the stack
' litl asmlabel litl
\
\
\ lshift (n1 n2 -- n3) \ n3 = n1 shifted left n2 bits
: lshift _xasm2>1 h5F _cnip ;
\
\
\ < ( n1 n2 -- t/f ) \ flag is true if and only if n1 is less than n2
: < _xasm2>flag hC186 _cnip ;
\
\
\ max ( n1 n2 -- n1 ) \ signed max of top 2 stack values
: max _xasm2>1 h87 _cnip ;
\
\
\ min ( n1 n2 -- n1 ) \ signed min of top 2 stack values
: min _xasm2>1 h8F _cnip ;
\
\
\ - ( n1 n2 -- n1-n2 ) \ subtracts n2 from n1
: - _xasm2>1 h10F _cnip ;
\
\
\ or ( n1 n2 -- n1_or_n2 ) \ bitwise or
: or _xasm2>1 hD7 _cnip ;
\
\
\ xor ( n1 n2 -- n1_xor_n2 ) \ bitwise xor
: xor _xasm2>1 hDF _cnip ;
\
\
\ over ( n1 n2 -- n1 n2 n1 ) \ duplicate 2 value down on the stack to the top of the stack
\ ' over asmlabel over
: over h1 ST@ ;
\
\
\ + ( n1 n2 -- n1+n2 ) \ sum of n1 & n2
: + _xasm2>1 h107 _cnip ;
\
\
\ rot ( n1 n2 n3 -- n2 n3 n1 ) \ rotate top 3 value on the stack
\ ' rot asmlabel rot
: rot h2 ST@ h2 ST@ h2 ST@ 3 ST! 3 ST! 0 ST! ;
\
\
\ rshift ( n1 n2 -- n3) \ n3 = n1 shifted right logically n2 bits
: rshift _xasm2>1 h57 _cnip ;
\
\
\ r> ( -- n1 ) \ pop top of RS to stack
' r> asmlabel r>
\
\
\ >r ( n1 -- ) \ pop stack top to RS
' >r asmlabel >r
\
\
\ 2>r ( n1 n2 -- ) \ pop top 2 stack to RS
' 2>r asmlabel 2>r
\
\
\ 0branch ( t/f -- ) \ branch it top of stack value is zero 16 bit branch offset follows,
\ -2 is to itself, +2 is next word
' 0branch asmlabel 0branch
\
\
\ (loop) ( -- ) \ add 1 to loop counter, branch if count is below limit offset follows,
\ -2 is to itself, +2 is next word
' (loop) asmlabel (loop)
\
\
\ (+loop) ( n1 -- ) \ add n1 to loop counter, branch if count is below limit, offset follows,
\ -2 is to itself, +2 is next word
' (+loop) asmlabel (+loop)
\
\
\ swap ( n1 n2 -- n2 n1 ) \ swap top 2 stack values
: swap
	1 ST@ 1 ST@ 2 ST! 0 ST!
;
\
\
\ negate ( n1 -- 0-n1 ) the negative of n1
: negate _xasm1>1 h14F _cnip ;
\
\
\ reboot ( -- ) reboot the propellor chip
: reboot hFF 0 hubopr ;
\
\
\ cogstop ( n -- ) stop cog n
: cogstop
	dup 3 hubopr drop
	cogio 4+ $S_cdsz 2- 2- 0 fill
;
\
\
\ cogreset ( n1 -- ) reset the forth cog
: cogreset
\ stop the cog, and 0 out the cog data area, if it is not the cog we are on
	7 and dup cogid <>
	if
		dup cogstop
	then
\ start up the cog
	dup dup cogio h10 lshift $H_entry 2 lshift or or 2 hubopr drop
\ wait for the cog to come alive, for a bit of time
	cogstate h8000 0
	do
		dup C@ 4 and
		if
			leave
		then
	loop
	drop
;
\
\
\ reset ( -- ) reset this cog
: reset cogid cogreset ;
\
\
\ clkfreq ( -- u1 ) the system clock frequency
: clkfreq 0 L@ ;
\
\
\ In this next section is the definition of the variables which are defined for each cog in main memory
\ The offsets of these variables must be manually updated in optsym.f. They are
\ h04 wconstant $V_pad
\ h83 wconstant $V_lc
\ h84 wconstant $V_t0
\ h86 wconstant $V_t1
\ h88 wconstant $V_tbuf
\ hA8 wconstant $V_numpad
\ hCB wconstant $V_debugcmd
\ hCC wconstant $V_debugValue
\ hD0 wconstant $V_cds
\ hD2 wconstant $V_base
\ hD4 wconstant $V_execword
\ hD8 wconstant $V_coghere
\ hDA wconstant $V_>out
\ hDC wconstant $V_>in
\ hDE wconstant $V_lasterr
\ hDF wconstant $V_state
\
\
\
\ _p+ ( offset -- addr )  the offset is added to the contents of the par register, giving an address references 
\ the cogdata
: _p+	par COG@ + ;
\
\
\ IO for propforth is done via an io channel. An io channel is a long which is treated
\ as 2 words. The io channel which connects to the interpreter is at the beginning
\ of the cog data area. It is defined as io. Any cogs io is defined as n cogio.
\
\ The structure of the long is 2 words as follows:
\ io     (word) - this is the input, if the h0100 bit is set, it means the interpreter
\                 is ready to accept input. To send a byte to the input write h00cc,
\                 where cc is the byte value. This word is used by key? and key
\ io + 2 (word) - this is a pointer to the where the output of the channel goes
\                 This word is used by emit? and emit.
\                 If this word is 0, the ouput destination is not valid and emit
\                 will simply "throw away the output. If it is not zero, it is assumed
\                 to be a pointer to an io channel. Thus the output of an io channel
\                 always points to the input of another io channel.
\
\
\
\
\ cogio ( n -- addr) the address of the data area for cog n
: cogio 7 and $S_cdsz u* $H_cogdata + ;
\
\
\ cogiochan ( n1 n2 -- addr ) cog n1, channel n2 ->addr
: cogiochan over cognchan 1- min 4* swap cogio + ;
\
\
\ io  ( -- addr ) the address of the io channel for the cog
: io
	par COG@
;
\
\
\ ERR ( n1 -- ) clear the input queue, set the error n1 and reset this cog
: ERR
	clearkeys lasterr C! reset
;
\
\
\ (iodis) ( n1 n2 -- ) cog n1 channel n2 disconnect, disconnect this cog and the cog it is connected to
: (iodis)
	cogiochan 2+ dup W@ swap 0 swap W! dup
	if
		0 swap 2+ W!
	else
		drop
	then
;
\
\
\ iodis ( n1 -- ) cogid to disconnect, disconnect this cog and the cog it is connected to
: iodis
	0 (iodis)
;
\
\
\ (ioconn) ( n1 n2 n3 n4 -- ) connect cog n1 channel n2 to cog n3 channel n4, disconnect them from other cogs first
: (ioconn)
	2dup (iodis) >r >r 2dup (iodis) r> r>
	cogiochan rot2 cogiochan 2dup 2+ W! swap 2+ W!
;
\
\
\ ioconn ( n1 n2 -- ) connect the 2 cogs, disconnect them from other cogs first
: ioconn
	0 tuck (ioconn)
;
\
\
\ (iolink) ( n1 n2 n3 n4 -- ) links the 2 channels, output of cog n1 channel n2 -> input of cog n3 channel n4,
\  output of n3 channel n4 -> old output of n1 channel n2
: (iolink)
		cogiochan rot2 cogiochan swap over
		2+ W@ over 2+ W! swap 2+ W!
;
\
\
\ iolink ( n1 n2 -- ) links the 2 cogs, output of n1 -> input of n2, output of n2 -> old output of n1
: iolink
	0 tuck (iolink)
;
\
\
\ (iounlink) ( n1 n2 -- ) unlinks cog n1 channel n2
: (iounlink)
	cogiochan 2+ dup W@ 2+
	dup W@ rot W! 0 swap W!
;
\
\
\ iounlink ( n1 -- ) unlinks the cog n1
: iounlink 0 (iounlink) ;
\
\
\ pad  ( -- addr ) access as bytes, or words and long, the address of the pad area - used by accept for keyboard input,
\ can be used carefully by other code
: pad
	4 _p+
;
\
\ cogpad ( n1 -- addr ) the address of pad for cog n1
: cogpad
	cogio 4+
;
\
\
\ pad>in ( -- addr ) addr is the address to the start of the parse area.
: pad>in
	>in W@ pad +
;
\
\
\ the maximum name length allowed must be 1F
h1F wconstant namemax
\
\
\ the size of the pad area, 128 bytes
h80 wconstant padsize
\
\
\ _lc ( -- addr) the address of the last character in the pad, filled by the parse word
: _lc
	h83 _p+
;
\
\
\ these are temporay variables, and by convention are only used within a word
\ caution, make sure you know what words you are calling
\ t0 - access as a word, temp variable
: t0
	h84 _p+
;
\
\ t1 - access as a word, temp variable
: t1
	h86 _p+
;
\
\   h20 (32) byte array overflows into numpad
\ tbuf - access as a chars, words, or longs. Temp array of 32 bytes
: tbuf
	h88 _p+
;
\
\
\ numpad ( -- addr ) the of the area used by the numeric output routines, can be used carefully by other code
: numpad
	hA8 _p+
;
\
\ cognumpad ( n1 -- addr ) the address of numpad for cog n1
: cognumpad
	cogio hA8 +
;
\
\
\ pad>out ( -- addr ) addr is the address to the the current output byte
: pad>out
	>out W@ numpad +
;
\
\
\ the size of the numpad, 34 bytes the largest number we can deal with is 33 digits
h22 wconstant numpadsize
\
\ numchan ( -- addr) the number of channels this cog supports
: numchan
	hCA _p+
;
\
\ debugcmd  ( -- addr ) the address of the debugcmd as a word, used to commincate from forth cog to request a reset, 
\ or for traces
\ : debugcmd
\ 	hCB _p+
\ ;
\
\ : cogdebugcmd
\	cogio hCA +
\ ;
\
\
\ debugvalue  ( -- addr ) the address of the debugvalue as a long, used in conjuction with debugcmd
\ : debugvalue
\ 	hCC _p+
\ ;
\
\ : cogdebugvalue
\	cogio hCC +
\ ;
\
\
\ cds ( -- addr) access as a word, the display string for this cog
: cds
	hD0 _p+
;
\
\
\ cogcds ( n1 -- addr) the address of the display string for cog n1
: cogcds
	cogio hD0 +
;
\ base ( -- addr ) access as a word, the address of the base variable
: base
	hD2 _p+
;
\
\
\ execword ( -- addr ) a long, an area where the current word for execute is stored
: execword
	hD4 _p+
;
\
\
\ execute ( addr -- ) execute the word - pfa address is on the stack
: execute
	dup $C_fMask COG@ and
	if
\ *********************************** for debugging support
\		dup execword W!
		$C_IP COG!
	else
		execword W!
		$C_a_exit execword 2+ W!
		execword $C_IP COG!
	then
;
\
\
\ coghere ( -- addr ) access as a word, the first unused register address in this cog
: coghere
	hD8 _p+
;
\
\
\ >out ( -- addr ) access as a word, the offset to the current output byte
: >out
	hDA _p+
;
\
\
\ >in ( -- addr ) access as a word, addr is the var the offset in characters from the start of the input buffer to
\ the parse area.
: >in
	hDC _p+
;
\
\ lasterr ( -- addr ) access as a char, an errorcode, set by ERR, and the kernel - if 0 - no error
: lasterr
	hDE _p+
;
\
\
\ state ( -- addr) access as a char
\ bit 0 -  0 - interpret mode / 1 - forth compile mode
\ bit 1 -  0 - prompts and errors on / 1 - prompts and errors off
\ bit 2 -  0 - Other / 1 - PropForth cog
\ bit 3 -  0 - accept echos chars on / 1 - accept echos chars off
\ bit 4 -  0 - accept echos line off / 1 - accept echos line on
\ bit 5 - 7 - free
: state
	hDF _p+
;
\
\ cogstate ( n1 -- addr ) the address of state for cog n1
: cogstate
	cogio hDF +
;
\
\
\ _p? ( -- t/f) true if prompts and errors are on
: _p?
	2 state C@ and 0=
;
\
\
\ cognchan ( n1 -- n2 ) n2 is the number of io channels for cog n1
: cognchan
	cogio hCA + C@ 1+
;
\
\
\ >con ( n1 -- ) disconnect the current cog, and connect the console to the cog n1
: >con
	$S_con ioconn
;
\
\
\ compile? ( -- t/f ) true if we are in a compile
: compile?
	state C@ 1 and
;
\
\
\ _femit? (c1 ioaddr -- t/f) true if the output emitted a char, a fast non blocking emit
: _femit?
	2+ W@ dup
	if
		dup W@ h100 and
		if
			swap hFF and swap W! -1
		else
			2drop 0
		then
	else
		2drop -1
	then
;
\
\
\ femit? (c1 -- t/f) true if the output emitted a char, a fast non blocking emit
: femit?
	io _femit? ;
\
\
\ emit ( c1 -- ) emit the char on the stack
: emit
	begin
		dup femit?
	until
	drop
;
\
\
\ _fkey? ( ioaddr -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
: _fkey?
	dup W@ dup h100 and
	if
		drop 0
	else
		h100 rot W! -1
	then
;
\
\
\ fkey? ( -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
: fkey?
	io _fkey?
;
\
\
\ key ( -- c1 ) get a key
: key
	0
	begin
		drop fkey?
	until
;
\
\
\ 2dup ( n1 n2 -- n1 n2 n1 n2 ) copy top 2 items on the stack
: 2dup
	over over
;
\
\
\ 2drop ( n1 n2 -- ) drop top 2 items on the stack
: 2drop
	drop drop
;
\
\
\ 3drop ( n1 n2 n3 -- ) drop top 3 items on the stack
: 3drop
	2drop drop
;
\
\
\ 0= ( n1 -- t/f ) true if n1 is zero
: 0= _xasm2>flagIMM h0 _cnip hA186 _cnip ;
\
\
\ <> ( x1 x2 -- flag ) flag is true if and only if x1 is not bit-for-bit the same as x2. 
: <> _xasm2>flag h5186 _cnip ;
\
\
\ 0 <> ( n1 -- t/f ) true if n1 is not zero
: 0<> _xasm2>flagIMM h0 _cnip h5186 _cnip ;
\
\
\ 0< ( n1 -- t/f ) true if n1 < 0
: 0< _xasm2>flagIMM h0 _cnip hC186 _cnip ;
\
\
\ 0> ( n1 -- t/f ) true if n1 > 0
: 0> _xasm2>flagIMM h0 _cnip h1186 _cnip ;
\
\
\ 1+ ( n1 -- n1+1 )
: 1+ _xasm2>1IMM h1 _cnip h107 _cnip ;
\
\
\ 1- ( n1 -- n1-1 )
: 1- _xasm2>1IMM h1 _cnip h10F _cnip ;
\
\
\ 2+ ( n1 -- n1+2 )
: 2+ _xasm2>1IMM h2 _cnip h107 _cnip ;
\
\
\ 2- ( n1 -- n1-2 )
: 2- _xasm2>1IMM h2 _cnip h10F _cnip ;
\
\
\ 4+ ( n1 -- n1+4 )
: 4+ _xasm2>1IMM h4 _cnip h107 _cnip ;
\
\
\ 4* ( n1 -- n1<<2 ) n1 is shifted logically left 2 bits
: 4* _xasm2>1IMM h2 _cnip h5F _cnip ; 
\
\
\ 2/ ( n1 -- n1>>1 ) n1 is shifted arithmetically right 1 bit
: 2/ _xasm2>1IMM h1 _cnip h77 _cnip ;
\
\
\ rot2 ( x1 x2 x3 -- x3 x1 x2 )
\ : rot2 rot rot ;
: rot2 2 ST@ 2 ST@ 2 ST@ 4 ST! 1 ST! 1 ST! ;
\
\
\ nip ( x1 x2 -- x2 ) delete the item x1 from the stack
: nip
	swap drop
;
\
\
\ tuck ( x1 x2 -- x2 x1 x2 )
: tuck
	swap over
;
\
\
\ >= ( n1 n2 -- t/f) true if n1 >= n2
: >=
	_xasm2>flag h3186 _cnip
;
\
\
\ <= ( n1 n2 -- t/f) true if n1 <= n2
: <=
	_xasm2>flag hE186 _cnip
;
\
\
\ 0>= ( n1 -- t/f ) true if n1 >= 0
: 0>=
	_xasm2>flagIMM h0 _cnip h3186 _cnip
;
\
\
\ W+! ( n1 addr -- ) add n1 to the word contents of address
: W+!
	dup W@ rot + swap W!
;
\
\
\ orC! ( c1 addr -- ) or c1 with the contents of address
: orC!
	dup C@ rot or swap C!
;
\
\
\ andnC! ( c1 addr -- ) and inverse of c1 with the contents of address
: andnC!
	dup C@ rot andn swap C!
;
\
\
\ between ( n1 n2 n3 -- t/f ) true if n2 <= n1 <= n3
: between
	rot2 over <= rot2 >= and
;
\
\
\ cr ( -- ) emits a carriage return
: cr
	hD emit
;
\
\
\ space ( -- ) emits a space
: space
	bl emit
;
\
\
\ spaces ( n -- ) emit n spaces
: spaces
	dup
	if
		0
		do
			space
		loop
	else
		drop
	then
;
\
\
\ bounds ( x n -- x+n x )
: bounds
	over + swap
;
\
\
\ alignl ( n1 -- n1) aligns n1 to a long (32 bit)  boundary
: alignl
	3 + 3 andn
;
\
\
\ alignw ( n1 -- n1) aligns n1 to a halfword (16 bit)  boundary
: alignw
	1+ 1 andn
;
\
\
\ C@++ ( c-addr -- c-addr+1 c1 ) fetch the character and increment the address
: C@++
	dup 1+ swap C@
;
\
\
\ todigit ( c1 -- n1 ) converts character to a number 
: todigit
	h30 -
	dup h9 >
	if
		7 - dup hA <
		if
			drop -1
	thens
\
	dup h26 >
	if
		3 - dup h27 <
		if
			drop -1
	thens
;
\
\
\ isdigit ( c1 -- t/f ) true if is it a valid digit according to base
: isdigit
	todigit 0 base W@ 1- between
;
\
\
\ isunumber ( c-addr len -- t/f ) true if the string is numeric
: isunumber
	bounds -1 rot2
	do
		i C@ h5F <>
		if
			i C@ isdigit and
		then
	loop
;
\
\
\ unumber ( c-addr len -- u1 ) convert string to an unsigned number
: unumber
	bounds 0 rot2
	do
		i C@ h5F <>
		if
			base W@ u* i C@ todigit +
		then
	loop
;
\
\
\ number ( c-addr len -- n1 ) convert string to a signed number
: number
	over C@ h2D =
	if
		1- 0 max swap 1+ swap unumber negate
	else
		unumber
	then
;
\
\
\ _xnu ( c-addr len base -- n1 ) convert string to a signed number
: _xnu
	base W@ >r base W!
	1- 0 max swap 1+ swap
	number
	r> base W!
;
\
\
\ xnumber ( c-addr len -- n1 ) convert string to a signed number
: xnumber
	over C@ h7A =
	if
		h40 _xnu
	else
		over C@ h68 =
		if
			h10 _xnu
		else
			over C@ h64 =
			if
				hA _xnu
			else
				over C@ h62 =
				if
					2 _xnu
				else
					number
	thens
;
\
\
\ isnumber ( c-addr len -- t/f ) true if the string is numeric
: isnumber
	over C@ h2D =
	if
		1- 0 max swap 1+ swap
	then
	isunumber
;
\
\
\ _xis ( c-addr len base -- t/f ) true if the string is numeric
: _xis
	base W@ >r base W!
	1- 0 max swap 1+ swap
	isnumber
	r> base W!
;
\
\
\ xisnumber ( c-addr len -- t/f ) true if the string is numeric
: xisnumber
	over C@ h7A =
	if
		h40 _xis
	else
		over C@ h68 =
		if
			h10 _xis
		else
			over C@ h64 =
			if
				hA _xis
			else
				over C@ h62 =
				if
					2 _xis
				else
					isnumber
	thens
;
\
\
\ .str ( c-addr u1 -- ) emit u1 characters at c-addr
: .str
	dup
	if
		bounds
		do
			i C@ emit
		loop
	else
		2drop
	then
;
\
\
\ npfx ( c-addr1 c-addr2 -- t/f ) -1 if c-addr2 is prefix of c-addr1, 0 otherwise
: npfx
	namelen rot namelen rot 2dup >=
	if
		min bounds
		do
			C@++ i C@ <>
			if
				drop 0 leave
			then
		loop
		0<>
	else
		2drop 2drop 0
	then
;
\
\
\ namelen ( c-addr -- c-addr+1 len ) returns c-addr+1 and the length of the name at c-addr
: namelen
	C@++ namemax and
;
\
\
\ cmove ( c-addr1 c-addr2 u -- ) If u is greater than zero, copy u consecutive characters from the data space starting
\  at c-addr1 to that starting at c-addr2, proceeding character-by-character from lower addresses to higher addresses.
: cmove
	dup 0>
	if
		bounds
		do
			C@++ i C!
		loop
		drop
	else
		3drop
	then
;
\
\
\ namecopy ( c-addr1 c-addr2 -- ) Copy the name from c-addr1 to c-addr2
: namecopy
	over namelen 1+ nip cmove
;
\
\
\ ccopy ( c-addr1 c-addr2 -- ) Copy the cstr from c-addr1 to c-addr2
: ccopy
	over C@ 1+ cmove
;
\
\
\ cappend ( c-addr1 c-addr2 -- ) addpend the cstr from c-addr1 to c-addr2
: cappend
	dup C@++ +
	rot2 over C@ over C@ +
	swap C! dup C@ swap 1+
	rot2 cmove
;
\
\
\ cappendn ( n cstr -- ) print the number n and append to cstr
: cappendn
	swap <# #s #> swap cappend
;
\
\
\ (nfcog) ( -- n1 n2 ) n1 the next valid free forth cog, n2 is 0 if the cog is valid
: (nfcog)
	-1 -1 8 0
	do
		7 i - dup cogstate C@ 4 and
		over cogio L@ h_100 = and
		if
			nip nip 0 leave
		else
			drop
		then
	loop
;
\
\
\ nfcog ( -- n ) returns the next valid free forth cog
: nfcog
	(nfcog)
	if
		5 ERR
	then
;
\
\
\ cogx ( cstr n -- ) execute cstr on cog n
: cogx
	io 2+ W@
	rot2 cogio io 2+ W!
	.cstr cr
	io 2+ W!
;
\
\
\ .strname ( c-addr -- ) c-addr point to a forth name field, print the name
: .strname
	dup
	if
		namelen .str
	else
		drop h3F emit
	then
;
\
\ .cstr ( addr -- ) emit a counted string at addr
: .cstr
	 C@++ .str
;
\
\
\ dq ( -- ) emit a counted string at the ip, and increment the ip past it and word alignw it
: dq
	r> C@++ 2dup + alignw >r .str
;
\
\
\ i ( -- n1 ) the most current loop counter
: i
	2 RS@
;
\
\
\ seti ( n1 -- ) set the most current loop counter
: seti
	2 RS!
;
\
\
\ fill ( c-addr u char -- ) fill the memory with char
: fill
	rot2 bounds
	do
		dup i C!
	loop
	drop
;
\
\
\ nfa>lfa ( addr -- addr ) go from the nfa (name field address) to the lfa (link field address)
: nfa>lfa
	2-
;
\
\
\ nfa>pfa ( addr -- addr ) go from the nfa (name field address) to the pfa (parameter field address)
: nfa>pfa
	namelen + alignw
;
\
\
\ nfa>next ( addr -- addr ) go from the current nfa to the prev nfa in the dictionary
: nfa>next
	nfa>lfa W@
;
\
\
\ lastnfa ( -- addr ) gets the last NFA
: lastnfa
	wlastnfa W@
;
\
\
\ isnamechar ( c1 -- t/f ) true if c1 is a valif name char > $20 < $7F
: isnamechar
	h21 h7E between
;
\
\
\ _forthpfa>nfa ( addr -- addr ) pfa>nfa for a forth word
: _forthpfa>nfa
	1-
	begin
		1- dup C@ isnamechar 0=
	until
;
\
\
\ _asmpfa>nfa ( addr -- addr ) pfa>nfa for an asm word
: _asmpfa>nfa
	lastnfa
	begin
		2dup nfa>pfa W@ = over C@
		h80 and 0= and
		if
			-1
		else
			 nfa>next dup 0=
		then
	until
	nip
;
\
\
\ pfa>nfa ( addr -- addr ) gets the name field address (nfa) for a parameter field address (pfa)
: pfa>nfa
	dup $C_fMask COG@ and
	if
		_forthpfa>nfa
	else
		_asmpfa>nfa
	then
;
\
\
\
\
\ _accept ( -- +n2 ) collect padsize -2 characters or until eol, convert ctl chars to space,
\ pad with 1 space at start & end. For parsing ease, and for the length byte when we make cstrs
: _accept
	padsize 2- pad 1+ over bounds 
	do
		key dup hD =
		if
			state C@ 8 and 0=
			if
				dup emit
			then
			2drop i pad 1+ - leave
		else
			dup 8 = 
			if
				drop
				state C@ 8 and 0=
				if
					8 emit space 8 emit
				then
				bl i 1- C!
				i 2- pad max seti
			else
				bl max
				state C@ 8 and 0=
				if
					dup emit
				then
				i C!
		thens
	loop
;
\
\
\ padbl ( -- ) fills this cogs pad with blanks
: padbl
	pad padsize bl fill
;
\
\ accept ( -- ) uses the pad and accepts up to padsize - 2
: accept
	padbl
	_accept
	state C@ h10 and
	if
		pad 1+ swap .str cr
	else
		drop
	then
;
\
\ parse ( c1 -- +n2 ) parse the word delimited by c1, or the end of buffer is reached, n2 is the length >in is the offset
\ in the pad of the start of the parsed word REPLACED IN VERSION 4.3 2011FEB24
: parse
	padsize >in W@ <=
	if
		0
	else
		dup _lc C!
\								\ put the delim character at the end of the pad
		0
		begin
			2dup pad>in + C@ tuck =
			if
				drop -1
			else
				h7E =
				if
\								\ process ~ddd
					dup pad>in + dup
					1+ 3 2dup
					xisnumber
					if
\								\ we have a valid number
						xnumber over C!
						over 0
						do
							dup C@ over 3 + C! 1-
						loop
						drop
						3 >in W+!
					else
						3drop
					then
				then
				1+ 0
			then
		until
	then
	nip
;
\
\
\ skipbl ( -- ) increment >in past blanks or until it equals padsize
: skipbl
	begin
		pad>in C@ bl =
		if
			>in W@ 1+ dup >in W! padsize =
		else
			-1
		then
	until
;
\
\
\ nextword ( -- ) increment >in past current counted string
: nextword
	padsize >in W@ >
	if
		pad>in C@ >in W@ + 1+ >in W!
	then
;
\
\
\ parseword ( c1 -- +n2 ) skip blanks, and parse the following word delimited by c1, update to be a counted string in
\ the pad
: parseword
	skipbl parse dup
	if
		>in W@ 1- 2dup pad + C! >in W!
	then
;
\
\
\ parsebl ( -- t/f) parse the next word in the pad delimited by blank, true if there is a word
: parsebl
	bl parseword 0<>
;
\
\
\ parsenw ( -- cstr ) parse and move to the next word, str ptr is zero if there is no next word
: parsenw
	parsebl
	if
		pad>in nextword
	else
		0
	then
;
\
\
\ find ( c-addr -- c-addr 0 | xt 2 | xt 1  |  xt -1 ) c-addr is a counted string, 0 - not found, 2 eXecute word, 
\ 1 immediate word, -1 word NOT ANSI
: find
	lastnfa over _dictsearch dup
	if
		nip dup nfa>pfa over C@ h80 and 0=
		if
			W@
		then
		swap C@ dup h40 and
		if
			h20 and
			if
				2
			else
				1
			then
		else
			drop -1
	thens
;
\
\
\ <# ( -- ) initialize the output area
: <# numpadsize
	>out W!
;
\
\
\ #> ( n1 -- caddr ) address of a counted string representing the output, NOT ANSI
: #>
	drop numpadsize >out W@ - -1 >out W+! pad>out C! pad>out
;
\
\
\ tochar ( n1 -- c1 ) convert c1 to a char
: tochar
	h3F and h30 +
	dup h39 >
	if
		7 +
	then
	dup h5D >
	if
		3 +
	then
;
\
\
\ # ( n1 -- n2 ) divide n1 by base and convert the remainder to a char and append to the output
: #
	base W@ u/mod swap tochar -1 >out W+! pad>out C!
;
\
\
\ #s ( n1 -- 0 ) execute # until the remainder is 0
: #s
	begin
		# dup 0=
	until
;
\
\ u. ( n1 -- ) prints the unsigned number on the top of the stack
: u.
	<# #s #> .cstr space
;
\
\ . ( n1 -- ) prints the signed number on the top of the stack
: .
	dup 0<
	if
		h2D emit negate
	then
	u.
;
\
\
\ cogid ( -- n1 ) return id of the current cog ( 0 - 7 )
: cogid
	-1 1 hubopr
;
\ _lockarray - 8 character array used to keep track of locks
\
\ 						\ one byte for each lock
\						\ hi 4 bits is the lockcount
\						\ lo 4 bits is the cogid
lockdict wvariable _lockarray 6 allot freedict
\
\ lock ( lock# -- )
: lock
	7 and dup _lockarray + dup C@ dup
\ 						\ ( lock# _lockarray_addr count/cog count/cog == - )
	hF and cogid =
	if
\						\ locked by this cog, increment count
\ 
		h10 + tuck swap C!
\ 						\ ( lock# count+1/cog == - )
		hF0 and 0=
		if
\						\ we locked too many times, 15 is the max
			6 ERR
		then
		drop
\ 						\ ( - == - )
	else
\ 						\ ( lock# _lockarray_addr count/cog == - )
		drop swap
\ 						\ ( _lockarray_addr lock# == - )
\		cnt COG@ tbuf L!
\						\ this will try to lock for about 20 seconds
\						\ then error out 
		-1 h1000 8 lshift 0
		do
\ 						\ ( _lockarray_addr lock# -1 == - )
			over 6 hubopf 0=
\ 						\ ( _lockarray_addr lock# -1 t/f == - )
			if
				drop 0 leave
\ 						\ ( _lockarray_addr lock# 0 == - )
			then
\ 						\ ( _lockarray_addr lock# -1 == - )
		loop
\ 						\ ( _lockarray_addr lock# 0/-1 == - )
\
		if
\			cnt COG@ tbuf L@ .
\						\ lock timeout
			7 ERR
		then
\ 						\ ( _lockarray_addr lock# == - )

		drop
\ 						\ ( _lockarray_addr == - )
		cogid h10 + swap C!
	then
;
\
\
\ unlock ( lock# -- )
: unlock
	7 and dup _lockarray + dup C@ dup
\ 						\ ( lock# _lockarray_addr count/cog count/cog == - )
	hF and cogid =
	if
\						\ locked by this cog, decrement count
\ 						\ ( lock# _lockarray_addr count/cog == - )
		h10 - dup hF0 and 0=
		if
\ 						\ ( lock# _lockarray_addr 0/cog == - )
			drop hF swap C!
\ 						\ ( - == - )
			7 hubopf drop
		else
\ 						\ ( lock# _lockarray_addr count-1/cog == - )
			swap C! drop
\ 						\ ( - == - )
		then
	else
\						\ this cog is unlocking something it did not lock
		8 ERR
	then
;
\
\ unlockall ( -- ) unlocks everything this cog has locked
: unlockall
	8 0
	do
		_lockarray i + C@ hF and cogid =
		if
			hF _lockarray i + C!
			i 7 hubopf drop
		then
	loop
;
\
: 2lock 2 lock ;
: 2unlock 2 unlock ;
\
\
\
\ checkdict ( n -- ) make sure there are at least n bytes available in the dictionary
: checkdict
	here W@ + dictend W@ >=
	if
		h9 ERR
	then
;
\
\
: (createbegin)
	lockdict herewal
	wlastnfa W@ here W@ dup 2+ wlastnfa W! swap over W! 2+
;
\
\
: (createend)
	over namecopy namelen + alignw here W! freedict
;
\
\
\ ccreate ( cstr -- ) create a dictionary entry
: ccreate
	(createbegin) swap (createend)
;
\ 
\
\ create ( -- ) skip blanks parse the next word and create a dictionary entry
: create
	bl parseword
	if
		(createbegin) pad>in (createend) nextword
	then
;
\
\
\ herewal ( -- ) align contents of here to a word boundary, 2 byte boundary
: herewal
	lockdict 2 checkdict here W@ alignw here W! freedict
;
\
\
\ allot ( n1 -- ) add n1 to here, allocates space on the data dictionary or release it
: allot
	lockdict dup checkdict here W+! freedict
;
\
\
\ w, ( x -- ) allocate 1 halfword 2 bytes in the dictionary and copy x to that location
: w,
	lockdict herewal here W@ W! 2 allot freedict
;
\
\
\ c, ( x -- ) allocate 1 byte in the dictionary and copy x to that location
: c,
	lockdict here W@ C! 1 allot freedict
;
\
\
\ herelal ( -- ) alignw contents of here to a long boundary, 4 byte boundary
: herelal
	lockdict 4 checkdict here W@ alignl here W! freedict
;
\
\
\ l, ( x -- ) allocate 1 long, 4 bytes in the dictionary and copy x to that location
: l,
	lockdict herelal here W@ L! 4 allot freedict
;
\
\
\ orlnfa ( c1 -- ) ors c1 with the nfa length of the last name field entered
: orlnfa
	lastnfa orC!
;
\
\
\ forthentry ( -- ) marks last entry as a forth word
: forthentry
	h80 orlnfa
;
\
\
\ immediate ( -- ) marks last entry as an immediate word
: immediate
	h40 orlnfa
;
\
\
\ exec ( -- ) marks last entry as an eXecute word, executes always
: exec
	h60 orlnfa
;
\
\
\ leave ( -- ) exits at the next loop or +loop, i is placed to the max loop value
: leave
	1 RS@ 2 RS!
;
\
\
\ clearkeys ( -- ) clear the input keys
: clearkeys
\ fkey? ( -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
	1 state andnC!
	begin
		0 _wkeyto W@ 0
		do
			fkey? nip or  
		loop
		0=
	until
;
\
\
\ w>l ( n1 n2 -- n1n2 ) consider only lower 16 bits of each source word
: w>l
	hFFFF and swap
	h10 lshift or
;
\
\
\ l>w ( n1n2 -- n1 n2) break into 16 bits
: l>w
	dup h10 rshift
	swap hFFFF and
;
\
\
: :
	lockdict create h3741 1 state orC!
;
\
\ _ mmcs ( -- ) print MISMATCHED CONTROL STRUCTURE(S), then clear input keys
: _mmcs
	_p?
	if
		." MISMATCHED CONTROL STRUCTURE(S)" cr
	then
	clearkeys
;
\
\
\ to prevent ; from using itself while it is defining itself it is first defined as %, then renamed
lockdict
: %
	$C_a_exit w, 1 state andnC! forthentry h3741 <>
	if
		_mmcs
	then
	freedict
; immediate
c" %" find drop pfa>nfa 1+ c" ;" C@++ rot swap cmove
freedict
\
\
: dothen
	l>w dup h1235 = swap h1239 = or
	if
		dup here W@ swap - swap W!
	else
		_mmcs
	then
;
\
\
lockdict
\
: then
	dothen
; immediate
\
\
: thens
 	begin
		dup hFFFF and dup h1235 = swap h1239 = or
		if
			dothen 0
		else
			-1
		then
	until
; immediate
\
\
: if
	$C_a_0branch w, here W@ h1235 w>l 0 w,
; immediate
\
\
: else
	$C_a_branch w, 0 w, dothen here W@ 2- h1239 w>l
; immediate
\
\
: until
	l>w h1317 =
	if
		$C_a_0branch w, here W@ - w,
	else
		_mmcs
	then
; immediate
\
\
: begin
	here W@ h1317 w>l
; immediate
\
\
: doloop
	swap l>w h2329 =
	if
		swap w, here W@ - w,
	else
		_mmcs
	then
;
\
\
: loop
	$C_a_(loop) doloop
; immediate
\
\
: +loop
	$C_a_(+loop) doloop
; immediate
\
\
: do
	$C_a_2>r w, here W@ h2329 w>l
; immediate
freedict
\
\ _ecs ( -- ) emit a colon followed by a space
: _ecs
	h3A emit space
;
\
\ _udf ( -- ) print out UNDEFINED WORD
: _udf
	." UNDEFINED WORD "
;
\
\
\ _qp ( -- cstr ) we are past the open " in a string, parse the string in the pad and return a cstr 
: _qp
	h22 parse 1- pad>in 2dup C! swap 2+ >in W+!
;
\
\
\ _sp ( n1 -- ) put n1 in the dictionary, followed by the string in the pad
: _sp
	w, _qp dup here W@ ccopy C@ 1+ allot herewal
;
\
\
\
lockdict
: ."
	$H_dq _sp
;  immediate
freedict
\
\
\ fisnumber ( c-addr len -- t/f -- ) dummy routines for indirection when float package is loaded
: fisnumber
	xisnumber
;
\
\ fnumber ( c-addr len -- n1 ) convert string to a signed number
\ dummy routines for indirection when float package is loaded
: fnumber
	xnumber
;
\
\
\ interpretpad ( -- ) interpret the contents of the pad
: interpretpad
	1 >in W!
	begin
		bl parseword
		if
			pad>in nextword find dup
			if
\
				dup -1 = 
				if
					drop compile?
					if
						w,
					else
						execute
					then
					0
				else
					2 =
					if
						execute 0
					else
						compile?
						if
							execute 0
						else
							pfa>nfa
							_p?
							if
								." IMMEDIATE WORD " .strname cr
							else
								drop
							then
							clearkeys -1
						then
					then
				then
\
\
\
			else
				drop dup C@++  fisnumber
				if
					C@++ fnumber compile?
					if
						dup 0 hFFFF between
						if
							$C_a_litw w, w,
						else
							$C_a_litl w, l,
						then
					then
					0
				else
					compile? if freedict then
					1 state andnC!
					_p?
					if
						_udf .strname cr
					then
					clearkeys
					-1
				then
			then
		else
			-1
		then
	until
;
\
\
\ interpret ( -- ) the main interpreter loop
: interpret
	accept interpretpad
;
\
\
\ _wc1 ( x -- nfa ) skip blanks parse the next word and create a constant, allocate a word, 2 bytes
: _wc1
	lockdict create $C_a_doconw w, w, forthentry lastnfa freedict
;
\
\
\ wconstant ( x -- ) skip blanks parse the next word and create a constant, allocate a word, 2 bytes
: wconstant
	 _wc1 drop
;
\
\
\ wvariable ( -- ) skip blanks parse the next word and create a variable, allocate a word, 2 bytes 
: wvariable
	lockdict create $C_a_dovarw w, 0 w, forthentry freedict
;
\
\
\ asmlabel ( x -- ) skip blanks parse the next word and create an assembler entry
: asmlabel
	lockdict create w, freedict
;
\
\
\ hex ( -- ) set the base for hexadecimal
: hex
	h10 base W!
;
\ delms ( n1 -- ) delay n1 milli-seconds for 80Mhz h68DB max
: delms
	h7FFFFFFF clkfreq h3E8 u/ u/ min 1 max
	clkfreq h3E8 u/ u* cnt COG@ +
	begin
		dup cnt COG@ - 0<
	until
	drop
;
\
\
\
\
\ >m ( n1 -- n2 ) produce a 1 bit mask n2 for position n1
: >m
	1 swap lshift
;
\
\
\ \ ( -- ) moves the parse pointer >in to the end of the line
lockdict
: \
	padsize >in W!
; immediate exec
\
\
\ _dl( c1 -- ) drop lines unitl c1 is received as the first or second character in a line, a . is emitted for each line
: _dl
	padbl
	pad 1+
	state C@ rot2
	8 state orC!
	h10 state andnC!
\ ( c1 addr -- )
	begin
		h2E emit cr
		accept
		dup C@
\ ( c1 addr char -- )
		2 ST@ =
\ ( c1 addr flag -- )
		over 1+ C@ 3 ST@ = or
	until
	drop emit cr
	state C!
;
\
\
\ { ( -- ) discard all the characters between { and }
\ open brace MUST be the first and only character on a new line, the close brace must be on another line
: {
	h7D _dl
; immediate exec
\ } ( -- )
: } ; immediate exec
\
\
\ _if xxx   ( flag -- ) if flag  is 0, drop all characters until ], [if should be the first only only chars on the line
: _if
	0=
	if
		h5D _dl
	then
;
\
\
\ [if xxx   ( flag -- ) if flag  is 0, drop all characters until ], [if should be the first only only chars on the line
: [if
	_if
; immediate exec
\
\
\ [ifdef xxx   ( -- ) if xxx is not defined drop all characters until ], [ifdef xxx should be the first only only chars on the line
: [ifdef
	parsenw find nip _if
; immediate exec
\
\
\ [ifndef xxx   ( -- ) if xxx is defined drop all characters until ], [ifndef xxx should be the first only only chars on the line
: [ifndef
	parsenw find nip 0= _if
; immediate exec
\
: ] ;	immediate exec
\
: ... ;	immediate exec
freedict
\
\
\ ' ( -- addr ) returns the execution token for the next name, if not found it returns 0
: '
parsenw dup if
	find 0=
	if _p? if _udf cr then drop 0
	then
then
;
\
\
\
\ cq ( -- addr ) returns the address of the counted string following this word and increments the IP past it
: cq
	r> dup C@++ + alignw >r
;
\
\
\ c" ( -- c-addr ) compiles the string delimited by ", runtime return the addr of the counted string ** valid only in that line
\ comiple time, caddress is not left on the stack
lockdict
: c" compile? if $H_cq _sp else _qp then ; immediate exec
freedict
\
\
\ to ensure one fast load at a time
wvariable fl_lock
wvariable fl_in
\
\
\ (flout)  ( -- ) attempt to output a character
: (flout)
	io 2+ W@ dup W@ h100 and dictend W@ fl_in W@ < and
	if
		dictend W@ dup 1+ dictend W! C@ swap W!
	else
		drop
	then
;
\
\
\ (fl) ( -- n1 ) buffer input and emit n1 is the number of characters overflowed
\
\ t0 - the end of the buffer
\ t1 - the number of characters overflowed
\ fl_in - pointer to next character for input
\ dictend - pointer to the next character for output
\ initialize
\
: (fl)
	dictend W@ 2- t0 W! here W@ h80 + dup fl_in W! dictend W!
\ 								\	process the input stream
\ 								\	( timeoutcount beginning_of_line_flag -- )
	0 t1 W! _wkeyto W@ -1
	begin
		fkey? 0=
	 	if
			drop (flout)
		else
			begin
\ 								\	check to see if the buffer is overflowed?
				fl_in W@ t0 W@ >=
				if
					drop
					1 t1 W+!
				else
					swap
					if
\ beginning of the line, comment or { ?
						dup h5C =
						if
							drop
							begin
								key hD =
							until
							-1
						else
							dup h7B =
							if
								drop 0
								begin
									1+ h1F over and h1F =
									if
										(flout)
									then
									key h7D =
								until
								drop 0 
							else
								dup h9 = over h20 = or
								if
									begin
										drop
										key
										dup h9 = over 
										h20 = or 0=
  									until
								then 
								dup fl_in W@ dup 1+ fl_in W! C! hD =
							then
						then
					else
\ process the char
						dup fl_in W@ dup 1+ fl_in W! C! hD =
					then
				then
\ next key
				(flout) fkey? 0=
			until
\ 								\	reset the timeout counter
			drop nip _wkeyto W@ swap
		then
\								\	decrease the timeout counter
		swap 1- swap over 0=
	until 2drop
\								\	output any remain chars
	dictend W@ fl_in W@ <
	if
		fl_in W@ dictend W@
		do
			i dup C@ emit dictend W!
		loop
	then
\								\	make sure we terminate any line
	cr cr
\ 								\	restore dictend
	t0 W@ 2+ dictend W!
	t1 W@
;
\
\
\ fl ( -- ) buffer the input and route to a free cog
: fl
	lockdict fl_lock W@
	if
		freedict
	else
		-1 fl_lock W! cogid nfcog dup >r iolink freedict
		(fl)
		cogid iounlink
		0 fl_lock W!
		r> over
		if
			cogreset
			cr . ." characters overflowed" cr
		else
			2drop
	thens
;
\
\ init_coghere ( -- ) This word can be replaced to the assembler optimizations, initializes the coghere wvariable
: init_coghere
	$C_varEnd coghere W!
;
\
\ this word is what the IP is set to on a reboot or a reset
\ fstart ( -- ) the start word
: fstart
\								\	set up the reset register for the cog
	io h10 lshift $H_entry 2 lshift or cogid or $C_resetDreg COG!
\
\ 								\	if the cog terminated abnormally,
\								\	the hi bit of the first word will be 0,
\								\	normally processed by onreset
	lasterr C@
\								\	set up the cogs IO
	h100 io W!
\ 								\	initialiaze the debug variable
\	$C_fMask COG@ debugcmd W!
\ 								\	zero out the rest of the cog data area
	pad $S_cdsz 4 - 0 fill
\ 								\	initialize forth variables
	hA base W! init_coghere
\								\	initiliaze the common variables
	lockdict _finit W@ 0=
	if 
		-1 _finit W!
		freedict
		0 fl_lock W!
		(version) version W! (prop) prop W!
		_lockarray 8 bounds do hF i C! loop
		c" onboot" find drop execute
	else
		freedict
	then
\								\	exists, otherwise execute onreset
	c" onreset" tbuf ccopy cogid tbuf cappendn tbuf find
	if
		execute
	else
		drop
		c" onreset"
		find drop execute
	then
\ 								\	THE MAIN LOOP
	begin
		compile? 0=
		if
			_p?
			if
				2lock prop W@ .cstr propid W@ . ." Cog" cogid . ." ok" cr 2unlock
			then
		then
		interpret 0
	until
;
\
\
