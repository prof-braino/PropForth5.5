fl

mountsys

100 fwrite DoubleMath.f

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


\ dswap ( n1lo n1hi n2lo n2hi -- n2lo n2hi n1lo n1hi) 
[ifndef dswap
: dswap
	 0 ST@ 3 ST@ 1 ST! 2 ST!
	 1 ST@ 4 ST@ 2 ST! 3 ST!
;

\ drot ( n1lo n1hi n2lo n2hi n3lo n3hi -- n2lo n2hi n3lo n3hi  n1lo n1hi) 
[ifndef drot
: drot 
	 0 ST@ 3 ST@ 6 ST@ 2 ST! 5 ST! 2 ST!
	 1 ST@ 4 ST@ 7 ST@ 3 ST! 6 ST! 3 ST!
;
]
]
\ ddup ( n1lo n1hi --	n1lo n1hi n1lo n1hi)
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
\ dnip ( n1lo n1hi n2lo n2hi -- n2lo n2hi)
[ifndef dnip
: dnip
	rot drop
	rot drop
;
]
\ dover ( n1lo n1hi n2lo n2hi -- n1lo n1hi n2lo n2hi n1lo n1hi)
[ifndef dover
: dover
	3 ST@ 3 ST@
;
]

\ dtuck ( n1lo n1hi n2lo n2hi -- n2lo n2hi n1lo n1hi n2lo n2hi)
[ifndef dtuck
: dtuck
	dswap dover
;
]


\ d2dup ( n1lo nihi n2lo n2hi -- n1lo n1hi n2lo n2hi n1lo nihi n2lo n2hi)
[ifndef d2dup
: d2dup
	dover dover
;
]


\ dnegate( n1lo n1hi -- u1lo u1hi)
[ifndef dnegate
: dnegate
	0 0 dswap d-
;
]
\ dabs( n1lo n1hi -- u1lo u1hi)
[ifndef dabs
: dabs
	dup 0<
	if
		dnegate
	then
;
]

\ d* ( n1lo n1hi n2lo n2hi -- n1*n2lo n1*n2hi ) u1 multiplied by u2
[ifndef d*
: d*
	du*
;
]

\ d*/mod ( n1lo n1hi n2lo n2hi n3lo n3hi -- n4lo n4hi n5lo n5hi ) n5 = (n1*n2)/n3, n4 is the remainder.
\         Uses a 128bit intermediate result.
[ifndef d*/mod
: d*/mod
	dup 3 ST@ sign 5 ST@ sign
	>r
	dabs
	>r >r
	dabs dswap dabs
	dum*
	r> r>
	dum/mod
	r>
	if
		dnegate dswap dnegate dswap
	then
;
]

\ d*/ ( n1lo n1hi n2lo n2hi n3lo n3hi -- n5lo n5hi ) n5 = (n1*n2)/n3
\         Uses a 128bit intermediate result.
[ifndef d*/
: d*/
	d*/mod dnip
;
]
\ d/mod ( n1lo n1hi n2lo n2hi -- n4lo n4hi n5lo n5hi ) n5 = (n1/n2), n4 is the remainder.
[ifndef d/mod
: d/mod
	dup 3 ST@ sign
	>r
	dabs dswap dabs dswap
	du/mod
	r>
	if
		dnegate dswap dnegate dswap
	then
;
]

\ d/ ( n1lo n1hi n2lo n2hi -- n5lo n5hi ) n5 = (n1/n2)
[ifndef d/
: d/
	d/mod dnip
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
		h2D emit dabs
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
\ i>d ( d1lo -- d1lo d1hi )
[ifndef i>d
: i>d
	dup 0<
	if
		-1
	else
		0
	then
;
]

{

fl


\
\
\ dum* ( u1lo u1hi u2lo u2hi -- u1*u2LL u1*u2LM u1*u2HM  u1*u2HH) \ unsigned 64 bit * 64bit -- 128 bit result
\
\
build_BootOpt :rasm
		mov	__u2LM , $C_stTOS
		spop
		mov	__u2LL , $C_stTOS
		spop

		mov	__u2HM , # 0
		mov	__u2HH , # 0

\ treg1 - u1hi
\ stTOS - u1lo
		spopt

\ treg2 - resLL
\ treg3 - resLM
\ treg4 - resHM
\ treg5 - resHH

		mov	$C_treg2 , # 0
		mov	$C_treg3 , # 0
		mov	$C_treg4 , # 0
		mov	$C_treg5 , # 0


__x01
		shr	$C_treg1 , # 1		wz wc
		rcr	$C_stTOS , # 1		wc
	if_z	cmp	$C_stTOS , # 0		wz

	if_nc	jmp     # __x02
\
		add	$C_treg2 , __u2LL	wc
		addx	$C_treg3 , __u2LM	wc
		addx	$C_treg4 , __u2HM	wc
		addx	$C_treg5 , __u2HH
__x02
\
		shl	__u2LL , # 1		wc
		rcl	__u2LM , # 1		wc
		rcl	__u2HM , # 1		wc
		rcl	__u2HH , # 1

	if_nz	jmp     # __x01
\		
		mov	$C_stTOS , $C_treg2
		spush
		mov	$C_stTOS , $C_treg3
		spush
		mov	$C_stTOS , $C_treg4
		spush
		mov	$C_stTOS , $C_treg5

		jexit
__u2LL
 0
__u2LM
 0
__u2HM
 0
__u2HH
 0
;asm dum*


\
\
\ dum/mod ( u1LL u1LM u1HM u1HH u2lo u2hi -- remainderlo remainderhi quotientlo quotienthi )
\ unsigned divide & mod  u1 divided by u2
\
build_BootOpt :rasm
		mov	$C_treg4 , $C_stTOS
		spop
		mov	__u2lo , $C_stTOS
		spop
\ u2hi - treg4
\ u1HH - treg3
\ u1MH - treg2
\ u1ML - treg1
\ u1LL - stTOS
\

		mov	$C_treg3 , $C_stTOS
		spop
		mov	$C_treg2 , $C_stTOS
		spop
                     
		spopt

		mov	$C_treg6 , # h80
		mov	__remlo , # 0
		mov	__remhi , # 0
\
__x01
		shl	$C_stTOS , # 1		wc
		rcl	$C_treg1 , # 1		wc
		rcl	$C_treg2 , # 1		wc
		rcl	$C_treg3 , # 1		wc
\                                                
		rcl	__remlo , # 1		wc
		rcl	__remhi , # 1		wc
\
	if_c	jmp	# __x02
\        
		cmp	__remlo , __u2lo	wz wc
		cmpx	__remhi , $C_treg4	wc
	if_c	mov	$C_treg5 , # 0
	if_c	jmp	# __x03
	
__x02
		sub	__remlo , __u2lo	wz wc
		subx	__remhi , $C_treg4
		mov	$C_treg5 , # 1
__x03
		rcr	$C_treg5 , # 1		wc

		rcl	__quolo , # 1		wc
		rcl	__quohi , # 1
                                  
		djnz	$C_treg6 , # __x01
\
		mov	$C_stTOS , __remlo
		spush
		mov	$C_stTOS , __remhi
		spush
		mov	$C_stTOS , __quolo
		spush
		mov	$C_stTOS , __quohi
		jexit

__u2lo
 0

__remlo
 0
__remhi
 0

__quolo
 0
__quohi
 0
;asm dum/mod


\
\ d+ ( n1lo n1hi n2lo n2hi -- n3lo n3hi ) n3 = n1+n2
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		add	$C_stTOS , $C_treg2		wc
		addsx	$C_treg1 , $C_treg3
\
		spush
		mov	$C_stTOS , $C_treg1		
\
		jexit
;asm d+


\
\ d- ( n1lo n1hi n2lo n2hi -- n3lo n3hi ) n3 = n1-n2
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		sub	$C_stTOS , $C_treg2		wz wc
		subsx	$C_treg1 , $C_treg3
\
		spush
		mov	$C_stTOS , $C_treg1		
\
		jexit
;asm d-


\
\ du> ( n1lo n1hi n2lo n2hi -- flag )
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		cmp	$C_stTOS , $C_treg2	wz wc
		cmpx	$C_treg1 , $C_treg3	wz wc
\
		mov	$C_stTOS , # 0
	if_a	mov	$C_stTOS , $C_fLongMask
\
		jexit
;asm du>


\
\ du< ( n1lo n1hi n2lo n2hi -- flag )
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		cmp	$C_stTOS , $C_treg2	wz wc
		cmpx	$C_treg1 , $C_treg3	wz wc	
\
		mov	$C_stTOS , # 0
	if_b	mov	$C_stTOS , $C_fLongMask
\
		jexit
;asm du<

\
\ du= ( n1lo n1hi n2lo n2hi -- n3lo n3hi ) n3 = n1-n2
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		cmp	$C_stTOS , $C_treg2	wz wc
		cmpx	$C_treg1 , $C_treg3	wz wc
\
		mov	$C_stTOS , # 0
	if_e	mov	$C_stTOS , $C_fLongMask
\
		jexit
;asm d=


\
\ du>= ( n1lo n1hi n2lo n2hi -- flag )
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		cmp	$C_stTOS , $C_treg2	wz wc
		cmpx	$C_treg1 , $C_treg3	wz wc
\
		mov	$C_stTOS , # 0
	if_ae	mov	$C_stTOS , $C_fLongMask
\
		jexit
;asm du>=


\
\ du<= ( n1lo n1hi n2lo n2hi -- flag )
build_BootOpt :rasm
\ n2hi
		mov	$C_treg3 , $C_stTOS
		spop
\ n2lo
		mov	$C_treg2 , $C_stTOS
		spop
\ n1hi	
		spopt
\
\ stTOS - n1lo
\ treg1 - n1hi
\ treg2 - n2lo
\ treg3 - n2hi
\
		cmp	$C_stTOS , $C_treg2	wz wc
		cmpx	$C_treg1 , $C_treg3	wz wc	
\
		mov	$C_stTOS , # 0
	if_be	mov	$C_stTOS , $C_fLongMask
\
		jexit
;asm du<=


}

...

