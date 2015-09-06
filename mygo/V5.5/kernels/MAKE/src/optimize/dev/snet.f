\ sersetflags ( n2 n1 -- O ) for the serial driver running on cog n1, set the flags to n2
[ifndef sersetflags
: sersetflags
	cogio hC8 + L!
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
\
\ _snet ( -- ) load the serial driver, and start it on cog 4
[ifndef _snet
: _snet
	4 cogreset
	h10 delms
	c" hD hC hE100 serial" 4 cogx
	h100 delms
	1 4 sersetflags 
	1 7 sersetflags 
;
]
\
\
\ snet ( -- ) reset the spinnret board, start a serial driver, and connect a terminal
[ifndef snet
: snet
	_snet hE dup pinlo dup pinout 1 delms dup pinhi pinin
	h10 delms h4 0 term 0 7 sersetflags
;
]
\
\ resnet ( -- ) start a serial driver and connect a terminal to the spinneret board
[ifndef resnet
: resnet
	_snet h10 delms h4 0 term 0 7 sersetflags
;
]
\
\
\ nsnet ( n1 -- ) start a serial driver, send n1 characters
[ifndef nsnet
: nsnet
	h10 delms
	cogid 0 4 0 (iolink)
	0
	do
		key emit
	loop
	cogid iounlink
;
]

