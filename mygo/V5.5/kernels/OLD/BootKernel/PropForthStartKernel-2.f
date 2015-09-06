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
\ serial ( n1 n2 n3 -- ) 
\ n1 - tx pin
\ n2 - rx pin
\ n3 - baud rate / 4 - the actual baud rate will be 4 * this number
\
\ _serial ( n1 n2 n3 -- )
\ n1 - tx pin
\ n2 - rx pin
\ n3 - clocks/bit
\
\ h00 - h04 -- io channel
\ h04 - h84 -- the receive buffer
\ h84 - hC4 -- the transmit buffer
\ hC4 - breaklength (long), if this long is not zero the driver will transmit a break breaklength cycles,
\		the minmum length is 16 cycles, at 80 Mhz this is 200 nanoSeconds
\ hC8 - flags (long)
\	h_0000_0001 	- if this bit is 0, CR is transmitted as CR LF
\			- if this bit is 1, CR is transmitted as CR
\
lockdict create _serial forthentry
$C_a_lxasm w, h1B8  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z8Fryj l, z2WytCj l, z2WytLG l, z2WytTP l, z2Wyt\k l, z2Wyth6 l, z2Wytp] l, z1bixaB l,
z1bixqB l, z1Sit7H l, z1YFsNl l, z1SL04S l, z2Wyub9 l, z2Wiuq8 l, z20iuqk l, z20iuq9 l,
z1Sit7H l, z2WisiU l, z24isik l, z31Vsb0 l, z1SJ04Z l, z1XFsNl l, zjyuW1 l, z3[yufY l,
z1SJ04S l, zbyuWN l, z1WyuZy l, z2WirqS l, z1SV04S l, z1SitFI l, z26Fw7e l, z1SQ04j l,
z1bywY0 l, z1Gi]qf l, z2Wiuy5 l, z1Wiuyf l, zbiuyg l, z1SitFI l, z\yrb8 l, z38ywW0 l,
z1WywXy l, z20ywb8 l, z20ywO1 l, z1WywVy l, z1SitFI l, z1byuv0 l, zfyur2 l, z1byur1 l,
z2Wyv0B l, z1SitFI l, z2WivFk l, zcyur1 l, z1jixaB l, z20ivF9 l, z1SitFI l, z2WisiX l,
z24isik l, z31Vsb0 l, z1SJ059 l, z3[yv56 l, z1SV04j l, z1SitNG l, z1SitNJ l, z1SitNG l,
z1SitNK l, z1SitNG l, z1SitNL l, z1SitNG l, z1SitNM l, z1SV05G l, z1SitVI l, z1YVrn0 l,
z1SL05P l, z2WityY l, z20ytr1 l, z1Wytyy l, z26Fty\ l, z1SQ05P l, z1SitVI l, z1Kig7Z l,
z1KigFZ l, z2Wisi6 l, z2Wyrn0 l, zfisi[ l, z1Wisi2 l, z1[ivV2 l, z1bivVD l, z1SitVI l,
z\yrG8 l, z38yvO0 l, z1WyvPy l, z20yvW8 l, z2WivNN l, z1SV05P l, z1SitaI l, z26FvN\ l,
z1SQ05k l, z26VsW0 l, z4\syC l, z1YLsv0 l, z1SQ05k l, z1SitaI l, z1GiiV] l, z2Wisy3 l,
z1Wisy] l, zbisya l, z4FsyC l, z1SitaI l, z\yrO8 l, z38yvj0 l, z1Wyvky l, z20yvr8 l,
z20yvb1 l, z1Wyviy l, z1SV05k l, z1SitiI l, z4iuFj l, z1YVuC0 l, z1SL066 l, z1SitiI l,
z2Wiu7b l, z20yu01 l, z1Wyu7y l, z26Fu7e l, z1SQ066 l, z1SitiI l, z1bywA0 l, z1Kilyc l,
z1Kim7c l, z2WisiP l, zfisid l, z1Wisi4 l, z1[iwF4 l, z1biwFD l, z1SitiI l, z\yrW8 l,
z38yw80 l, z1Wyw9y l, z20ywG8 l, z2Wiw7O l, z1SitiI l, z26Vu8D l, z1YQuO1 l, z45ryj l,
z2WtsbA l, z4Asij l, z1SV066 l, z1SitqI l, z2WiuNj l, z20yuG2 l, z4isaQ l, z1SitqI l,
z20yuJ2 l, zAisyQ l, z1SQ06n l, z8FwqQ l, z18ysrG l, z1[ixaB l, z20isyk l, z3rysr0 l,
z1bixaB l, z1SitqI l, z20yuG4 l, z8iuVQ l, z1SV06] l,
freedict
\
\
: serial
	4*
	clkfreq swap u/ dup 2/ 2/
\
\ serial structure
\
\
\ init 1st 4 members to hFF
\
	hFF h1C2 
	2dup COG!
	1+ 2dup COG!
	1+ 2dup COG!
	1+ tuck COG!
\
\ next 2 members to h100
\
	1+ h100 swap 2dup COG!
	1+ tuck COG!
\
\ bittick/4, bitticks
\
	1+ tuck COG!
	1+ tuck COG!
\
\ rxmask txmask
\
	1+ swap >m over COG!
	1+ swap >m over COG!
\ rest of structure to 0
	1+ h1F0 swap
	do
		0 i COG!
	loop
\
	c" SERIAL" numpad ccopy numpad cds W!
	4 state andnC!
	0 io hC4 + L!
	0 io hC8 + L!
	_serial
;
\
\
\ initcon ( -- ) initialize the default serial console on this cog
: initcon
	$S_txpin $S_rxpin $S_baud serial
\	h1E h1F hE100 serial
;
\
\
\
\
\ THE DEFAULT INITIALIZATION WORDS, onboot and on reset must exist
\ onboot ( n1 -- n1 ) n1 - reset error code 
: onboot
	$S_con iodis
	$S_con cogreset
	h10 delms
	c" initcon" $S_con cogx
	h100 delms
	cogid >con
	8 0
	do
		i cogid <>
		i $S_con <> and
		if
			i cogreset
		then
	loop
;
\
\ onreset ( n -- )
\ 01 - stack overflow
\ 02 - return stack overflow
\ 03 - stack underflow
\ 04 - return stack underflow
\ 05 - no more free forth cogs
\ 06 - lock overflow, tried to lock more than 15 times
\ 07 - lock timeout
\ 08 - tried to unlock something did not have locked
\ 09 - out of dictionary memory
\ 0A - eeprom write error
\
\
\ onreset ( n1 -- ) n1 - reset error code
: onreset
	unlockall 4 state orC! version W@ cds W! drop
;
\
\
\ These must be defined at the end for a rebuild
\
\ lockdict ( -- ) lock the forth dictionary
: lockdict 0 lock ;
\
\
\ freedict ( -- ) free the forth dictionary
: freedict 0 unlock ;
\
\
\
\ u* ( u1 u2 -- u1*u2) u1*u2 must be a valid 32 bit unsigned number
: u*
	0
	h20 0
	do
		over 1 and
		if
			2 ST@ +
		then
		2 ST@ 1 lshift 2 ST!
		h1 ST@ 1 rshift h1 ST!
	loop
	nip
	nip
;
\
\
\ u>= ( u1 u2 -- t/f ) \ flag is true if and only if u1 is greater or equal to than u2
: u>= _xasm2>flag h310E _cnip ;
\
\ u/mod ( u1 u2 -- remainder quotient) both remainder and quotient are 32 bit unsigned numbers
: u/mod
	1
	h1F 0
	do
		over 0<
		if
			leave
		else	
			swap 1 lshift swap
			1 lshift
		then
	loop
\
	0
	h20 0
	do
		3 ST@ 3 ST@
		u>=
		if
			3 ST@ 3 ST@ - 3 ST!
			over +
		then
		swap 1 rshift swap
		rot 1 rshift rot2
		over 0=
		if
			leave
		then
	loop
	nip nip
;
\
\
\ u/ ( u1 u2 -- u1/u2) u1 divided by u2
: u/
	u/mod nip
;
\
\ cstr= ( cstr1 cstr2 -- t/f ) case sensitive compare
: cstr=
	over C@ over C@ =
	if
		-1 rot
		1+
		rot C@++ bounds
		do
			dup C@ i C@ <>
			if
				nip 0 swap leave
			then
			1+
		loop
		drop
	else
		2drop 0
	then
;
\
\ name= ( cstr1 cstr2 -- t/f ) case sensitive compare
: name=
	over C@ h1F and over C@ h1F and =
	if
		-1 rot
		1+
		rot C@++ h1F and bounds
		do
			dup C@ i C@ <>
			if
				nip 0 swap leave
			then
			1+
		loop
		drop
	else
		2drop 0
	then
;
\
\ _dictsearch ( nfa cstr -- n1) nfa - addr to start searching in the dictionary, cstr - the counted string to find
\	n1 - nfa if found, 0 if not found, a fast assembler routine
: _dictsearch
	swap
	begin
		2dup name=
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
