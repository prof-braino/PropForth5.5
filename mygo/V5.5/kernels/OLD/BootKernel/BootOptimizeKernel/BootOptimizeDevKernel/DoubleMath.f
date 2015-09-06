fl
\
\ fswrite DoubleMath.f
\ 100 fwrite DoubleMath.f
\
\
1 wconstant build_DoubleMath
\
[ifndef dum*
lockdict create dum* forthentry
$C_a_lxasm w, h137  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2Wi]ZB l, z1SyLI[ l, z2Wi]RB l, z1SyLI[ l, z2Wy]b0 l, z2Wy]j0 l, z1SyLIZ l, z2WyPb0 l,
z2WyPj0 l, z2WyPr0 l, z2WyQ00 l, zeyPW1 l, zkyPO1 l, z26QPO0 l, z1SJ04] l, z21iPfm l,
z39iPnn l, z39iPvo l, z38iQ4p l, zgy]O1 l, zoy]W1 l, zoy]b1 l, zny]j1 l, z1SL04U l,
z2WiPRD l, z1SyJQL l, z2WiPRE l, z1SyJQL l, z2WiPRF l, z1SyJQL l, z2WiPRG l, z1SV01X l,
0 l, 0 l, 0 l, 0 l,
freedict
]

[ifndef dum/mod
lockdict create dum/mod forthentry
$C_a_lxasm w, h13E  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPuB l, z1SyLI[ l, z2WiaBB l, z1SyLI[ l, z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l,
z1SyLIZ l, z2WyQA0 l, z2WyaG0 l, z2WyaO0 l, zgyPO1 l, zoyPW1 l, zoyPb1 l, zoyPj1 l,
zoyaG1 l, zoyaO1 l, z1SS04d l, z27FaKs l, z3DFaRF l, z2WvQ00 l, z1SS04g l, z27iaKs l,
z3CiaRF l, z2WyQ01 l, zkyQ01 l, zoyaW1 l, znyab1 l, z3[yQCV l, z2WiPSt l, z1SyJQL l,
z2WiPSu l, z1SyJQL l, z2WiPSv l, z1SyJQL l, z2WiPSw l, z1SV01X l, 0 l, 0 l,
0 l, 0 l, 0 l,
freedict
]

[ifndef d+
lockdict create d+ forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z21iPRD l, z3OiPZE l, z1SyJQL l,
z2WiPRC l, z1SV01X l,
freedict
]

[ifndef d-
lockdict create d- forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z27iPRD l, z3SiPZE l, z1SyJQL l,
z2WiPRC l, z1SV01X l,
freedict
]

[ifndef du>
lockdict create du> forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z27FPRD l, z3FFPZE l, z2WyPO0 l,
z2WXPR6 l, z1SV01X l,
freedict
]

[ifndef du<
lockdict create du< forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z27FPRD l, z3FFPZE l, z2WyPO0 l,
z2WfPR6 l, z1SV01X l,
freedict
]

[ifndef d=
lockdict create d= forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z27FPRD l, z3FFPZE l, z2WyPO0 l,
z2WdPR6 l, z1SV01X l,
freedict
]

[ifndef du>=
lockdict create du>= forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z27FPRD l, z3FFPZE l, z2WyPO0 l,
z2WZPR6 l, z1SV01X l,
freedict
]

[ifndef du<=
lockdict create du<= forthentry
$C_a_lxasm w, h11D  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiPmB l, z1SyLI[ l, z2WiPeB l, z1SyLI[ l, z1SyLIZ l, z27FPRD l, z3FFPZE l, z2WyPO0 l,
z2WhPR6 l, z1SV01X l,
freedict
]

\ du* ( u1lo u1hi u2lo u2hi -- u1*u2lo u1*u2hi ) u1 multiplied by u2
[ifndef du*
: du*
	dum* 2drop
;
]

\ du/mod ( u1lo u1hi u2lo u2hi -- remainderlo remainderhi quotientlo quotienthi) \ unsigned divide & mod  u1 divided by u2
[ifndef du/mod
: du/mod
	0 rot2 0 rot2 dum/mod
;
]

\
\
\ du/ ( u1lo u1hi u2lo u2hi -- u1/u2lo u1/u2hi) u1 divided by u2
[ifndef du/
: du/
	du/mod rot drop rot drop
;
]

\ du*/mod ( u1lo u1hi u2lo u2hi u3lo u3hi -- u4lo u4hi u5lo u5hi ) u5 = (u1*u2)/u3, u4 is the remainder.
\         Uses a 128bit intermediate result.
[ifndef du*/mod
: du*/mod
	>r >r dum* r> r> dum/mod
;
]

\
\ du*/ ( u1lo u1hi u2lo u2hi u3lo u3hi -- u4lo u4hi ) u4 = (u1*u2)/u3. Uses a 128bit intermediate result.
[ifndef du*/
: du*/
	>r >r dum* r> r> dum/mod rot drop rot drop
;
]

\
\
\ d# ( n1lo n1hi -- n2lo n2hi ) divide n1 by base and convert the remainder to a char and append to the output
[ifndef d#
: d#
	base W@ 0 du/mod rot drop rot tochar -1 >out W+! pad>out C!
;
]

\
\
\ d#s ( n1lo n1hi -- 0 ) execute # until the remainder is 0
[ifndef d#s
: d#s
	begin
		d# 2dup 0= swap 0= and
	until
	drop
;
]

\
\ du. ( n1lo n1hi -- ) prints the unsigned number on the top of the stack
[ifndef du.
: du.
	<# d#s #> .cstr space
;
]

\
\ d. ( n1lo n1hi -- ) prints the signed number on the top of the stack
[ifndef d.
: d.
	dup 0<
	if
		h2D emit negate
	then
	du.
;
]

\
\ dL! ( nlo nhi addr -- )
[ifndef dL!
: dL!
	tuck 4+ L! L!
;
]
\
\ dL@ ( addr -- nlo nhi)
[ifndef dL@
: dL@
	dup L@ swap 4+ L@
;
]

\ dswap ( n1lo n1hi n2lo n2hi -- n2lo n2hi n1lo n1hi) 
[ifndef dswap
: dswap
	 0 ST@ 3 ST@ 1 ST! 2 ST!
	 1 ST@ 4 ST@ 2 ST! 3 ST!
;
]
\ drot ( n1lo n1hi n2lo n2hi n3lo n3hi -- n2lo n2hi n3lo n3hi  n1lo n1hi) 
[ifndef drot
: drot 
	 0 ST@ 3 ST@ 6 ST@ 2 ST! 5 ST! 2 ST!
	 1 ST@ 4 ST@ 7 ST@ 3 ST! 6 ST! 3 ST!
;
]
\ d>u ( u1lo u1hi -- u1lo )
[ifndef d>u
: d>u
	drop
;
]
\ u>d ( u1lo -- u1lo u1hi )
[ifndef u>d
: u>d
	0
;
]
\ ddup ( n1lo n1hi --	n1lo nihi n1lo n1hi)
[ifndef ddup
: ddup
	2dup
;
]
\ ddrop ( n1lo n1hi --	)
[ifndef ddrop
: ddrop
	2drop
;
]

\ dover ( n1lo n1hi n2lo n2hi -- n1lo n1hi n2lo n2hi n1lo n1hi)
[ifndef dover
: dover
	3 ST@ 3 ST@
;
]

\ d2dup ( n1lo nihi n2lo n2hi -- n1lo n1hi n2lo n2hi n1lo nihi n2lo n2hi)
[ifndef d2dup
: d2dup
	dover dover
;
]

...


