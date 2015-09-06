1 wconstant build_mathext

lockdict create mul16 forthentry
$C_a_lxasm w, h120  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z1WiP[O l, z1WiPSO l, z1SyZvP l, z1SV01X l, zFyy l, zfyPWG l, z2WyPjG l,
zcyPO1 l, z21fPRC l, zkyPO1 l, z3[yPnS l, z1SV000 l,
freedict

lockdict create div16 forthentry
$C_a_lxasm w, h123  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z1WiP[S l, z1Sy[KT l, z2WiPZB l, zbyPOG l, z1SyJQL l, z2WiPRC l, z1WiPSS l,
z1SV01X l, zFyy l, zfyPWF l, z2WyPjG l, z3XiPRC l, znyPO1 l, z3[yPnV l, z1SV000 l,

freedict


lockdict create sqrt forthentry
$C_a_lxasm w, h124  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1Sy[SM l, z2WiPRD l, z1SV01X l, z2WyPW0 l, z2WyPb0 l, z2WyPjG l, zgyPO1 l, znyPW1 l,
zgyPO1 l, znyPW1 l, zfyPb2 l, z1byPb1 l, z3XiPZD l, zbyPb2 l, znyPb1 l, z3[yPnP l,
z1SV000 l,
freedict


{
\ limited precision fast math routines

fl

\ mul16 ( n1 n2 -- n3) 
build_BootOpt :rasm
		spopt
		and	$C_treg1 , __FFFF
		and	$C_stTOS , __FFFF
		jmpret	__mul16_ret , # __mul16
		jexit
	
__FFFF
hFFFF
__mul16
		shl	$C_treg1 , # d16
		mov	$C_treg3 , # d16
		shr	$C_stTOS , # 1		wc
__loopmul16
	if_c	add	$C_stTOS , $C_treg1	wc
		rcr	$C_stTOS , # 1		wc
		djnz	$C_treg3 , # __loopmul16
__mul16_ret
		ret


;asm mul16

\ div16 ( n1 n2 -- n3) 
build_BootOpt :rasm
		spopt
		and	$C_treg1 , __FFFF
		jmpret	__div16_ret , # __div16

		mov	$C_treg1 , $C_stTOS
		shr	$C_stTOS , # d16
		spush
		mov	$C_stTOS , $C_treg1
		and	$C_stTOS , __FFFF
		jexit
	
__FFFF
hFFFF
__div16
		shl	$C_treg1 , # d15
		mov	$C_treg3 , # d16
__loopdiv16
		cmpsub	$C_stTOS , $C_treg1	wr wc
		rcl	$C_stTOS , # 1
		djnz	$C_treg3 , # __loopdiv16
__div16_ret
		ret

;asm div16


build_BootOpt :rasm

\ sqrt ( n1 -- n2) 
		jmpret	__sqrt_ret , # __sqrt
		mov	$C_stTOS , $C_treg2
		jexit
	
__sqrt
		mov	$C_treg1 , # 0
		mov	$C_treg2 , # 0
		mov	$C_treg3 , # d16
__loopsqrt
		shl	$C_stTOS , # 1		wc
		rcl	$C_treg1 , # 1
		shl	$C_stTOS , # 1		wc
		rcl	$C_treg1 , # 1
		shl	$C_treg2 , # 2
		or	$C_treg2 , # 1
		cmpsub	$C_treg1 , $C_treg2 	wr wc
		shr	$C_treg2 , # 2
		rcl	$C_treg2 , # 1
		djnz	$C_treg3 , # __loopsqrt
__sqrt_ret
		ret


;asm sqrt


}





