fl
\
fswrite boot.f
version W@ _bmsg c" boot.f    initializing" _bmsg

\ this turns off cr ->crlf expansion in the serial driver on cog 7
\ 1 7 cogio h_C8 + L!

\ this is the 4 character string that will be the system prompt
\
: tempPROMPT c" SNET" ;

\ this is the numberic propid
\
11 wconstant tempPROPID

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

fload sdboot.f

fread .sdcardinfo

c" boot.f    DONE" _bmsg


...