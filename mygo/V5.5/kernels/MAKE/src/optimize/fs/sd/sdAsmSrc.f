\
hA state orC!
\
\

build_BootOpt :rasm
		spopt
		add	$C_treg1 , # __x0F
		jmp	$C_treg1

__x01
		mov	$C_treg6 , # h8
		shl	$C_stTOS , # h18
		jmp	# __x05
__x02
\ send the bits in $C_stTOS
		mov	$C_treg6 , # h20

__x05
\ hi bit to the carry flag
		rcl	$C_stTOS , # 1 wc
\ set data out accordingly
		muxc	outa , v_sd_di 

\ toggle clock
		or	outa , v_sd_clk
		andn	outa , v_sd_clk
\ loop
		djnz	$C_treg6 , # __x05
		andn	outa , v_sd_di
		spop	
		
		jmp	# __x0E


__x03
		mov	$C_treg6 , # h8
		jmp	# __x06
__x04
		mov	$C_treg6 , # h20

__x06
		spush
		mov	$C_stTOS , # 0
		or	outa , v_sd_di
__x07
\ clock high
		or	outa , v_sd_clk
\ read in bit
		test	v_sd_do , ina wc
		rcl $C_stTOS , # 1
\ clock low
		andn outa , v_sd_clk
\ loop
		djnz $C_treg6 , # __x07
		andn	outa , v_sd_di

__x0E
		jexit

__x0F
		jmp	# __x01
		jmp	# __x02
		jmp	# __x03
		jmp	# __x04
;asm a_shift

\ mem>cog ( memaddr cogaddr numlongs -- ) memaddr must be long aligned
\ cog>mem ( memaddr cogaddr numlongs -- ) memaddr must be long aligned
\           $C_stTOS  $C_treg1  $C_treg3

build_BootOpt :rasm

		spopt
		mov	$C_treg3 , $C_treg1

		spopt
__x01
		rdlong	$C_treg2 , $C_stTOS
		movd	__x02 , $C_treg1

		add	$C_treg1 , # 1
		add	$C_stTOS , # h4

__x02
		mov	$C_treg1 , $C_treg2
		djnz	$C_treg3 , # __x01

		spop
		jexit
;asm mem>cog


build_BootOpt :rasm

		spopt
		mov	$C_treg3 , $C_treg1

		spopt
		
__x01
		movs	__x02 , $C_treg1
		add	$C_treg1 , # 1
__x02
		mov	$C_treg2 , $C_treg1

		wrlong	$C_treg2 , $C_stTOS

		add	$C_stTOS , # h4

		djnz	$C_treg3 , # __x01

		spop
		jexit
;asm cog>mem

hA state andC!
