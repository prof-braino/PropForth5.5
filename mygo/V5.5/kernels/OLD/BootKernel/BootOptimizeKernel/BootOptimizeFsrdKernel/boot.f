fl

fswrite boot.f
version W@ _bmsg c" boot.f    initializing" _bmsg

\ this turns off cr ->crlf expansion in the serial driver on cog 7
\ 1 7 cogio h_C8 + L!

\ this is the 4 character string that will be the system prompt
\
: tempPROMPT c" PROT" ;

\ this is the numberic propid
\
33 wconstant tempPROPID

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


c" boot.f    LOADING DevKernel.f" _bmsg


fsload DevKernel.f


c" boot.f    DONE - PROPFORTH LOADED" _bmsg


...