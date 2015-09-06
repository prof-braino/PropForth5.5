fl

hA state orC!


build_BootOpt :rasm
		jmp	# __x0C
__x01v_df00
	hDF00
__x02v_dfff
	hDFFF
__x03v_5f00
	h5F00
__x04v_4700
	h4700
__x05v_5c00
	h5C00
__x06v_5d00
	h5D00
__x07v_1400
	h1400
__x08v_5e00
	h5E00

__x0C
	spush

	mov	outa , __x03v_5f00
	mov	dira , __x01v_df00

	mov	outa , __x04v_4700

	mov	$C_stTOS , # hFF 
	and	$C_stTOS , ina

	mov	outa , __x05v_5c00

	jexit

;asm a__ip_rddr


build_BootOpt :rasm
		jmp	# __x0C
__x01v_df00
	hDF00
__x02v_dfff
	hDFFF
__x03v_5f00
	h5F00
__x04v_4700
	h4700
__x05v_5c00
	h5C00
__x06v_5d00
	h5D00
__x07v_1400
	h1400
__x08v_5e00
	h5E00

__x0C
	mov	$C_treg1 , $C_stTOS
	shr	$C_treg1 , # h8
	and	$C_treg1 , # hFF

	or	$C_treg1 , __x06v_5d00
	mov	outa , $C_treg1

	mov	dira , __x02v_dfff

	andn	$C_treg1 , __x07v_1400
	mov	outa , $C_treg1

	and	$C_stTOS , # hFF
	or	$C_stTOS , __x08v_5e00
	mov	outa , $C_stTOS

	andn	$C_stTOS , __x07v_1400
	mov	outa , $C_stTOS

	spop
	mov	outa , __x05v_5c00

	jexit

;asm a__ip_wridm



build_BootOpt :rasm
		jmp	# __x0C
__x01v_df00
	hDF00
__x02v_dfff
	hDFFF
__x03v_5f00
	h5F00
__x04v_4700
	h4700
__x05v_5c00
	h5C00
__x06v_5d00
	h5D00
__x07v_1400
	h1400
__x08v_5e00
	h5E00

__x0C
	and	$C_stTOS , # hFF
	or	$C_stTOS , __x03v_5f00

	mov	outa , $C_stTOS
	mov	dira , __x02v_dfff

	andn	$C_stTOS , __x07v_1400
	mov	outa , $C_stTOS

	spop

	mov	outa , __x05v_5c00

	jexit

;asm a__ip_wrdr

build_BootOpt :rasm
\
\ _treg1 - pointer to the current socket structure
\ _treg2 - pointer to the current io channel
\ _treg3 - current io word read
\
	spopt
	mov	$C_treg2 , $C_stTOS

	rdword	$C_treg3 , $C_treg2
	mov	$C_stTOS , $C_treg3		
	spush

	test	$C_stTOS , # h100 wz
	muxz	$C_stTOS , $C_fLongMask

 if_nz	jexit

	cmp	$C_treg3 , # h_D wz
\
\ h_1A is the offset of _ip_sockstatus
\
 if_z	add	$C_treg1 , # h_1A
 if_z	rdword	$C_treg4 , $C_treg1
\
\ h_100 - is the expandcr flag bit 
\
 if_z	test	$C_treg4 , # h_100 wz
 
 if_nz	mov	$C_treg3 , # h_100
 if_z	mov	$C_treg3 , # h_0A
 	wrword	$C_treg3 , $C_treg2

	jexit

;asm a__ip_fkeyq


build_BootOpt :rasm
	add	$C_stTOS , # h2

	rdword	$C_treg1 , $C_stTOS	wz
 if_z	muxz	$C_stTOS , $C_fLongMask
 if_z	jnext

	rdword	$C_stTOS , $C_treg1
	and	$C_stTOS , # h100 wz
	muxnz	$C_stTOS , $C_fLongMask
	jexit
;asm a__ip_emitq


build_BootOpt :rasm
	add	$C_stTOS , # h2

	rdword	$C_treg1 , $C_stTOS	wz
 if_nz	jmp	# __x0F
	spop
	spop
 	jexit
__x0F
	rdword	$C_stTOS , $C_treg1
	and	$C_stTOS , # h100 wz
 if_z	jmp	# __x0F
	spop
	wrword	$C_stTOS , $C_treg1
	spop
	jexit
;asm a__ip_emit


hA state orC!
