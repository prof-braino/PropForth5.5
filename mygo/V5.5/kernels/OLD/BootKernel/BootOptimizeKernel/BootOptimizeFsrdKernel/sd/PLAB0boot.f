fl
\
\ This boot file is for a very specific hardware configuration which is
\ a Spinneret with a propeller chip connected.
\
\ norom and mcs are loaded, the subprop is booted and then morom and mcs are unloaded
\
\
\
fswrite boot.f
version W@ _bmsg c" boot.f    initializing" _bmsg

\ this turns off cr ->crlf expansion in the serial driver on cog 7
\ 1 7 cogio h_C8 + L!

\ this is the 4 character string that will be the system prompt
\
: tempPROMPT c" PLAB" ;

\ this is the numberic propid
\
0 wconstant tempPROPID

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

\ findEETOP ( -- n1 ) the top of the eeprom + 1
: findEETOP

\
\ search 32k block increments until we get a fail
\

	0
	h100000 h8000
	do
		i t0 2 eereadpage
		if
			leave
		else
			i h7FFE + t0 3 eereadpage
			if
				leave
			else
				drop i h8000 +
			then
			
		then
	h8000 +loop
;


c" boot.f    setting top of eeprom file system and prompt" _bmsg

findEETOP ' fstop 2+ alignl L! 


\
\ make sure not to copy in a string longer than the original string 4 bytes\
tempPROMPT 1 + C@ prop W@ 1 + C!
tempPROMPT 2 + C@ prop W@ 2 + C!
tempPROMPT 3 + C@ prop W@ 3 + C!
tempPROMPT 4 + C@ prop W@ 4 + C!

tempPROPID propid W!


forget _serial



\
\
\ SD CONFIG PARAMETERS BEGIN
\
\ definitions for io pins connecting to the sd card
\

[ifndef _sd_cs
h13 wconstant _sd_cs
]
[ifndef _sd_di
h14 wconstant _sd_di
]
[ifndef _sd_clk
h15 wconstant _sd_clk
]
[ifndef _sd_do
h10 wconstant _sd_do
]

{
\ PLAB CONFIG 
[ifndef _sd_cs
h00 wconstant _sd_cs \ DAT3 PIN2 
]
[ifndef _sd_di
h01 wconstant _sd_di	\ CMD PIN3
]
[ifndef _sd_clk
h02 wconstant _sd_clk	\ CLK PIN6
]
[ifndef _sd_do
h03 wconstant _sd_do	\ DATA0 PIN8
}

\
\
\
\ SD CONFIG PARAMETERS END
\

c" boot.f    LOADING sd_init.f" _bmsg
fsload sd_init.f

c" boot.f    LOADING sd_run.f" _bmsg
fsload sd_run.f

c" boot.f    LOADING sdfs.f" _bmsg
fsload sdfs.f

c" boot.f    SD FILE SYSTEM LOADED" _bmsg

1 sd_mount

c" boot.f    LOADING DevKernel.f" _bmsg
fload DevKernel.f




\
\ BEGIN boot and configure subprop
\

[ifndef rcogx
\ rcogx ( cstr cog channel -- ) send cstr to the cog/channel
: rcogx
	io 2+ W@
\ ( cstr cog channel oldio+2 -- )
	rot cogio
\ ( cstr channel oldio+2 cogio -- )
	rot 4* +
\ ( cstr oldio+2 chaddr -- )
	io 2+ W!
\ ( cstr oldio+2 -- )
	swap .cstr cr
	io 2+ W!
;
]

[ifndef rfsend
\ rfsend filename ( cog channel -- )
: rfsend
	4* swap cogio +
	_sd_fsp dup
	if
\ ( chaddr fname -- )
		io 2+ W@
\ ( chaddr fname oldio+2 -- )
		rot io 2+ W!
\ ( fname oldio+2 -- )
		swap
		sd_read
		io 2+ W!
	else
		2drop _fnf
	then
;
]




\
\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[ifndef term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup h6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]


1 wconstant SUBPROP

c" boot.f    LOADING norom.f" _bmsg
fload norom.f

c" boot.f    LOADING mcs.f" _bmsg
fload mcs.f



1 wconstant  build_mcsnorom

\ this is what the cogs on the subprop will do on reset
: onreset
	unlockall 4 state orC! version W@ cds W! drop
;



\ this is what the subprop will do on boot
\ 



: onboot
	8 0
	do
		i cogid <>
		if
			i cogreset
		then
	loop

\
\ drop error codes
\
	drop 0 

	h40 0
	do
		h1C 1 qHzb h90000 hA0000 between
		if
			c" h1C h1D hFF h8 mcsslave" h7 cogx h10 delms
			h10000 0
			do
				h7 cogio mcsstate@ 4 =
				if
					leave
				then
			loop

			h5 0
			do
				i 0 h7 i (ioconn)
			loop
		then
	loop
;		

: bootsubprop
	4 state andnC!
	d26 d27 d24 d25 rambootnx
	c" d26 d27 d24 d8 mcsmaster" 2 cogx
	h2000 0
	do
		1 delms
		2 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	2 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;


: bootplab1
	c" bootsubprop" 3 cogx

	h2000 0
	do
		1 delms
		3 cogstate C@ hA =
		if
			leave
		then
	loop
;

bootplab1 3 cogstate C@ hA =
[if
	c" 1 propid W!" 2 0 rcogx
	c" forget build_fsrd" 2 0 rcogx
	c" : onboot ; : reboot .~h22 NO~h22 cr ;" 2 0 rcogx
	c" : onreset unlockall 4 state orC! version W@ cds W! drop ;" 2 0 rcogx
	2 0 rfsend DevKernel.f
]

forget SUBPROP

\
\ END boot and configure subprop
\

fload sdboot.f

fread .sdcardinfo

c" boot.f    DONE" _bmsg


...