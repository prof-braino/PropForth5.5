fl

{
fl
\
\ a_cha ( char flinW@ memend -- flin )
\
build_BootOpt :rasm
		mov	$C_treg6 , $C_stTOS
		spop
		spopt

\ treg6 - memend
\ treg1 - flin
\ stTOS - char
\
__bol
		cmp	$C_stTOS , # h5C	wz
	if_ne	jmp	# __not5C
__5Cloop1
		jmpret	__key_ret , # __key

		cmp	$C_stTOS , # h0D	wz
	if_ne	jmp	#  __5Cloop1

		jmpret	__key_ret , # __key
		jmp	# __bol
__not5C


		cmp	$C_stTOS , # h7B	wz
	if_ne	jmp	# __not7B
__7Bloop1
		jmpret	__key_ret , # __key

		cmp	$C_stTOS , # h7D	wz
	if_ne	jmp	#  __7Bloop1

		jmpret	__key_ret , # __key
\		jmp	# __donebol
__not7B

__sploop
		cmp	$C_stTOS , # h20	wz
	if_ne	cmp	$C_stTOS , # h09	wz
	if_ne	jmp	# __notsp
__sploop1
		jmpret	__key_ret , # __key

		cmp	$C_stTOS , # h20	wz
	if_ne	cmp	$C_stTOS , # h09	wz
	if_e	jmp	# __sploop1

\		jmp	# __donebol
__notsp
		

__donebol
		jmp	# __pchar
__cloop
		jmpret	__key_ret , # __key

__pchar
		cmp	$C_stTOS , # h0D	wz
		wrbyte	$C_stTOS , $C_treg1
		add	$C_treg1 , # 1
		cmp	$C_treg1 , $C_treg6	wc
 if_c_and_nz	jmp	# __cloop

		mov	$C_stTOS , $C_treg1

		jexit

__h100
	h100

__key
		rdword	$C_stTOS , par
		test	$C_stTOS , # h100	wz
	if_nz	jmp	# __key
		
		wrword	__h100 , par
__key_ret
		ret

;asm a_cha
	
fl

\
\ a_flout ( flin addrdictend -- )
\
build_BootOpt :rasm
\ io 2+ W@ dup W@ h100 and dictend W@ fl_in W@ < and
\ if
\	dictend W@ dup 1+ dictend W! C@ swap W!
\ else
\	drop
\ then
\
\ treg6 - loop counter
\ treg5 - io ptr
\ treg4 - dictend
\ treg1 - addrdictend
\ stTOS - flin
\
	mov	$C_treg6 , # h20
	spopt

	mov	$C_treg3 , $C_stTOS

	rdword	$C_treg4 , $C_treg1
	sub	$C_treg3 , $C_treg4	wc wz

 if_be	jmp	# __exit

	max	$C_treg6 , $C_treg3

	mov	$C_treg2 , par
	add	$C_treg2 , # 2
	rdword	$C_treg5 , $C_treg2

__outlp
	rdword	$C_treg2 , $C_treg5
	test	$C_treg2 , # h100	wz
 if_z	jmp	# __notready

	rdbyte	$C_stTOS , $C_treg4
	add	$C_treg4 , # 1
	wrword	$C_stTOS , $C_treg5
__notready
	djnz	$C_treg6 , # __outlp
__done
	wrword	$C_treg4 , $C_treg1
__exit
	spop
	jexit
;asm a_flout
}



lockdict create a_cha forthentry
$C_a_lxasm w, h139  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WiQBB l, z1SyLI[ l, z1SyLIZ l, z26VPPS l, z1SL04T l, z1Sya4n l, z26VPOD l, z1SL04O l,
z1Sya4n l, z1SV04M l, z26VPPu l, z1SL04Z l, z1Sya4n l, z26VPPw l, z1SL04V l, z1Sya4n l,
z26VPOW l, z26LPO9 l, z1SL04d l, z1Sya4n l, z26VPOW l, z26LPO9 l, z1SQ04] l, z1SV04f l,
z1Sya4n l, z26VPOD l, zFPRC l, z20yPW1 l, z25FPZH l, z1SK04e l, z2WiPRC l, z1SV01X l,
z40 l, z4iPVj l, z1YVPS0 l, z1SL04n l, z4F]Vj l, z1SV000 l,
freedict



lockdict create a_flout forthentry
$C_a_lxasm w, h127  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2WyQ8W l, z1SyLIZ l, z2WiPmB l, z4iPuC l, z27iPmF l, z1SU04\ l, z1CiQBE l, z2WiPij l,
z20yPb2 l, z4iQ3D l, z4iPeG l, z1YVPf0 l, z1SQ04Z l, ziPRF l, z20yPr1 l, z4FPRG l,
z3[yQCT l, z4FPuC l, z1SyLI[ l, z1SV01X l,
freedict

\
\
\ fl ( -- ) buffer the input and route to a free cog
: fl
	lockdict fl_lock W@
	if
		freedict
	else
		-1 fl_lock W! cogid nfcog dup >r iolink freedict

\
\ dictend - pointer to the next character for output
\ initialize
\
		0 dictend W@ 2- here W@ h80 + dup dictend W!

\ ( num_overflow bufend bufstart -- )
		_wkeyto W@ 0
		do
			2dup <=
			if
				fkey? nip
				if
					0 seti
					rot 1+ rot2
				else
					dup dictend a_flout
				then
			else
				fkey?
				if
					0 seti
					swap 2 ST@ a_cha
				else
					drop dup dictend a_flout
				then
			then
		loop
		begin
			dup dictend a_flout
			dup dictend W@ <=
		until
		cr cr
		drop 2+ dictend W!
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
