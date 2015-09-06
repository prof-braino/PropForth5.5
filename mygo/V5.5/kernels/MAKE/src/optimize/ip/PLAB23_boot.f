1 wconstant  build_mcsnorom

\ this is what the cogs on the subprop will do on reset
: onreset
	unlockall 4 state orC! version W@ cds W! drop
;



\ this is what the subprop will do on boot
\ 



: onboot
\	16 pinout
\	16 pinhi


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

	h80 0
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


: bootsubprop2
	4 state andnC!
	2 3 0 1 rambootnx
	c" 2 3 0 8 mcsmaster" 6 cogx
	h1000 0
	do
		1 delms
		6 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	6 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;



: bootsubprop3
	4 state andnC!
	6 7 4 5 rambootnx
	c" 6 7 4 8 mcsmaster" 3 cogx
	h1000 0
	do
		1 delms
		3 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	3 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;



: bootplab2
	c" bootsubprop2" 5 cogx

	h4000 0
	do
		1 delms
		5 cogstate C@ hA =
		if
			leave
		then
	loop
;

: bootplab3
	c" bootsubprop3" 2 cogx

	h4000 0
	do
		1 delms
		2 cogstate C@ hA =
		if
			leave
		then
	loop
;


\ bootplab2

\ bootplab3


: bootplab23
	c" bootsubprop2" 5 cogx
	c" bootsubprop3" 2 cogx

	h2000 0
	do
		1 delms
		5 cogstate C@ hA =
		2 cogstate C@ hA = and
		if
			leave
		then
	loop
;

bootplab23

5 cogstate C@ hA =
[if
	c" 2 propid W!" 6 0 rcogx
	7 1 6 0 (ioconn)
	7 6 6 1 (ioconn)
 	c" forget SUBPROP" 6 0 rcogx
]

2 cogstate C@ hA =
[if
	c" 3 propid W!" 3 0 rcogx
	7 2 3 0 (ioconn)
	7 7 3 1 (ioconn)
 	c" forget SUBPROP" 3 0 rcogx
]



forget SUBPROP



