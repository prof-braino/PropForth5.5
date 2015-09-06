fl

\ fswrite snet.f


\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[ifndef term
: term over cognchan min
	." Hit CTL-F to exit comterm" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup h6 = if drop 1 else emit 0 then until
	cogid iounlink ;
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
\ forget ( -- ) wind the dictionary back to the word which follows - caution
[ifndef forget
: forget
	parsenw (forget)
;
]

{
\
\ version for Eeprom Development System
\
\ _snet ( -- ) load the serial driver, and start it on cog 4, then forget the code
: _snet
	c" serial.f" _fsload
	4 cogreset
	h10 delms
	c" hD hC hE100 serial" 4 cogx
	h100 delms
	c" _serial" (forget)
	1 4 sersetflags 
;
}

\
\ version for Standard Development System
\
\ _snet ( -- ) load the serial driver, and start it on cog 4
: _snet
	4 cogreset
	h10 delms
	c" hD hC hE100 serial" 4 cogx
	h100 delms
	1 4 sersetflags 
;


\ snet ( -- ) reset the spinnret board, start a serial driver, and connect a terminal
: snet _snet hE dup pinlo dup pinout 1 delms dup pinhi pinin h10 delms h4 0 term ;

\ resnet ( -- ) start a serial driver and connect a terminal to the spinneret board
: resnet _snet h10 delms h4 0 term ;


...
