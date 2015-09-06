fl

\
\
coghere W@ wconstant build_BootOpt
\
\
wvariable max_coghere coghere W@ max_coghere W!
\
: _bbo0 coghere W@ max_coghere W@ max max_coghere W! ;
: _bbo1 build_BootOpt coghere W! ;
: _bbo _bbo0 _bbo1 ;
\
\
$V_lc 1+ $V_pad -	wconstant _vpadsize
_vpadsize 2-		wconstant _vpadsize-2
_vpadsize 4 u/		wconstant _vpadlongs
$V_state 2-		wconstant _vstate-2
$V_state $V_pad 1+ -	wconstant _vstate-vpad+1
\
\
\ um* ( u1 u2 -- u1*u2L u1*u2H ) \ unsigned 32bit * 32bit -- 64bit result
\
\
_bbo1
\
:asm
		spopt
		mov	$C_treg2 , # 0
		mov	$C_treg3 , # 0
		mov	$C_treg4 , # 0
__x01
		shr	$C_stTOS , # 1			wz wc 
	if_nc	jmp     # __x02
\
		add	$C_treg4 , $C_treg1		wc
		addx	$C_treg2 , $C_treg3 
__x02
\
		shl	$C_treg1 , # 1			wc
		rcl	$C_treg3 , # 1
	if_nz	jmp     # __x01
\		
		mov	$C_stTOS , $C_treg4
		spush
		mov	$C_stTOS , $C_treg2
		jexit
;asm um*
\
_bbo
\
\
\ um/mod ( u1lo u1hi u2 -- remainder quotient ) \ unsigned divide & mod  u1 divided by u2
\
:asm
		spopt
		mov	$C_treg6 , $C_stTOS                     
		spop
		mov	$C_treg3 , # h40
		mov	$C_treg2 , # 0
\
__x01
		shl	$C_stTOS , # 1			wc
		rcl	$C_treg6 , # 1			wc
\                                                
		rcl	$C_treg2 , # 1			wc
\
\
	if_c	sub	$C_treg2 , $C_treg1                        
	if_nc	cmpsub	$C_treg2 , $C_treg1		wc wr
\
\
		rcl	$C_treg4 , # 1                                               
		djnz	$C_treg3 , # __x01
\
		mov	$C_stTOS , $C_treg2
		spush
		mov	$C_stTOS , $C_treg4
		jexit
;asm um/mod
\
_bbo
\
\ cstr= ( cstr1 cstr2 -- t/f ) case sensitive compare
\
\
:asm
		spopt
		rdbyte	$C_treg2 , $C_treg1
		add	$C_treg2 , # 1
		sub	$C_stTOS , # 1
__x01
		rdbyte	$C_treg3 , $C_treg1
		add	$C_treg1 , # 1
		add	$C_stTOS , # 1
		rdbyte	$C_treg4 , $C_stTOS
		cmp	$C_treg3 , $C_treg4		wz
	if_z	djnz	$C_treg2 , # __x01
\
		muxz	$C_stTOS , $C_fLongMask
		jexit
;asm cstr=
\
_bbo
\
\
\ name= ( cstr1 cstr2 -- t/f ) case sensitive compare
\
:asm
		spopt
		rdbyte	$C_treg2 , $C_treg1
		and	$C_treg2 , # h1F
		add	$C_treg1 , # 1
\
		rdbyte	$C_treg4 , $C_stTOS
		and	$C_treg4 , # h1F
		mov	$C_treg3 , $C_treg2
		add	$C_treg2 , # 1
\		
		jmp	# __x02
\		
__x01
		rdbyte	$C_treg3 , $C_treg1
		add	$C_treg1 , # 1
		add	$C_stTOS , # 1
		rdbyte	$C_treg4 , $C_stTOS
__x02
		cmp	$C_treg3 , $C_treg4		wz
	if_z	djnz	$C_treg2 , # __x01
\
		muxz	$C_stTOS , $C_fLongMask
		jexit
;asm name=
\
_bbo
\
\ _dictsearch ( nfa cstr -- n1) nfa - addr to start searching in the dictionary, cstr - the counted string to find
\	n1 - nfa if found, 0 if not found, a fast assembler routine
\
:asm
		spopt
		mov	$C_treg5 , $C_treg1
__x03
		mov	$C_treg6 , $C_stTOS
\
		rdbyte	$C_treg2 , $C_treg1
		and	$C_treg2 , # h1F
		add	$C_treg1 , # 1
\
		rdbyte	$C_treg4 , $C_stTOS
		and	$C_treg4 , # h1F
		mov	$C_treg3 , $C_treg2
		add	$C_treg2 , # 1
\		
		jmp	# __x02
\		
__x01
		rdbyte	$C_treg3 , $C_treg1
		add	$C_treg1 , # 1
		add	$C_stTOS , # 1
		rdbyte	$C_treg4 , $C_stTOS
__x02
		cmp	$C_treg3 , $C_treg4		wz
	if_z	djnz	$C_treg2 , # __x01
\		
		mov	$C_stTOS , $C_treg6
	if_z	jexit
\
		sub	$C_treg6 , # h2
		rdword	$C_stTOS , $C_treg6		wz
	if_z	jexit
		mov	$C_treg1 , $C_treg5
		jmp	# __x03			
\
;asm _dictsearch
\
_bbo
\
\
\ padbl ( -- ) 
\
:asm
		mov	$C_treg5 , par
		add	$C_treg5 , # $V_pad
\
		mov	$C_treg3 , # _vpadlongs
__x01
		wrlong	__x0F , $C_treg5
		add	$C_treg5 , # h4
		djnz	$C_treg3 , # __x01
\		
		jexit
\
__x0F
	h20202020
;asm padbl
\
_bbo
\
\
\ _accept ( -- n1) 
\
\
:asm
\
\ $C_treg2 - pad start
\ $C_treg3 - loop count
\ $C_stTOS - pad ptr
\`$C_treg6 - (io+2)
\
		spush
\
\ output pointer
\
		mov	$C_treg2 , par
		add	$C_treg2 , # h2
		rdword	$C_treg6 , $C_treg2
\
\ if state has no echo bit on, offset DF 
\
		add	$C_treg2 , # _vstate-2
		rdbyte	$C_treg1 , $C_treg2
		test	$C_treg1 , # h8	wz
	if_nz	mov	$C_treg6 , # 0
\
\ point to pad + 1
\
		sub	$C_treg2 , # _vstate-vpad+1
\
		mov	$C_stTOS , $C_treg2
		mov	$C_treg3 , # _vpadsize-2
\
\
\ read a character into $C_treg4
\
__x01
		rdword	$C_treg4 , par
		test	$C_treg4 , # h100	wz
	if_nz	jmp	# __x01
		mov	$C_treg1 , # h100
		wrword	$C_treg1 , par
\
\ cr, we are done
\
		cmp	$C_treg4 , # hD wz
	if_z	mov	$C_treg3 , # 1
	if_z	jmp	# __x04
\
\ bs?
\
		cmp	$C_treg4 , # h8 wz
	if_z	jmp	# __x03
\
\
\ normal char	
\
		min	$C_treg4 , # h20
\
		wrbyte	$C_treg4 , $C_stTOS
		add	$C_stTOS , # 1
		jmp	# __x04
\
\
\ $C_treg2 - pad start
\ $C_treg3 - loop count
\ $C_treg4 - char
\ $C_stTOS - pad ptr
\`$C_treg6 - (io+2)
\
\ process backspace
\
__x03
\
		jmpret	__x0F , # __x0E
		mov	$C_treg4 , # h20
		jmpret	__x0F , # __x0E
\
		sub	$C_stTOS , # 1
		min	$C_stTOS , $C_treg2
		wrbyte	$C_treg4 , $C_stTOS
\
		add	$C_treg3 , # h2
		max	$C_treg3 , # _vpadsize-2
\
		mov	$C_treg4 , # h8
\
__x04
		jmpret	__x0F , # __x0E
\
		djnz	$C_treg3 , # __x01
\
		sub	$C_stTOS , $C_treg2
		jexit
\
\
\
\ emit char in $C_treg4, $C_treg6 is ptr to io channel 
\
__x0E
		cmp	$C_treg6 , # 0 	wz
	if_z	jmp	# __x0F
__x06
		rdword	$C_treg1 , $C_treg6
		test	$C_treg1 , # h100	wz
	if_z	jmp	# __x06
\
		wrword	$C_treg4 , $C_treg6
__x0F
		ret
;asm _accept
\
_bbo
\
\
\ : t accept cr pad padsize bounds do i L@ .long space 4 +loop cr ;
\
\
\ .str ( c-addr u1 -- ) emit u1 characters at c-addr
\
:asm
		spopt
\
		cmp	$C_treg1 , # 0	wz
	if_nz	mov	$C_treg6 , par
	if_nz	add	$C_treg6 , # h2
	if_nz	rdword	$C_treg2 , $C_treg6	wz 
\
	if_z	jmp	# __x01
__x03
		rdbyte	$C_treg4 , $C_stTOS
		add	$C_stTOS , # 1
__x02
		rdword	$C_treg3 , $C_treg2
		test	$C_treg3 , # h100	wz
	if_z	jmp	# __x02
\
		wrword	$C_treg4 , $C_treg2
		djnz	$C_treg1 , # __x03
\
__x01
		spop
		jexit
;asm .str
\
_bbo
\
\
\ _fkey? ( ioaddr -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
\
:asm
		rdword	$C_treg1 , $C_stTOS
		test	$C_treg1 , # h100	wz
		muxz	$C_treg2 , $C_fLongMask
\				
	if_nz	jmp	# __x01
\
		mov	$C_treg3 , # h100
		wrword	$C_treg3 , $C_stTOS
\
__x01
		mov	$C_stTOS , $C_treg1
		spush
		mov	$C_stTOS , $C_treg2
		jexit
;asm _fkey?
\
_bbo
\
\
\ fkey? ( -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
\
:asm
		spush
		rdword	$C_stTOS , par
		test	$C_stTOS , # h100	wz
		muxz	$C_treg1 , $C_fLongMask
\				
	if_nz	jmp	# __x01
\
		mov	$C_treg3 , # h100
		wrword	$C_treg3 , par
\
__x01
		spush
		mov	$C_stTOS , $C_treg1 
		jexit
;asm fkey?
\
_bbo
\
\
\ key ( -- c1 )
\
:asm
		spush
__x01
		rdword	$C_stTOS , par
		test	$C_stTOS , # h100	wz
	if_nz	jmp	# __x01
		mov	$C_treg1 , # h100
		wrword	$C_treg1 , par
		jexit
;asm key
\
_bbo
\
\
\ _femit? (c1 ioaddr -- t/f) true if the output emitted a char, a fast non blocking emit
\
:asm
		spopt
		and	$C_stTOS , # hFF
		mov	$C_treg2 , $C_treg1
		add	$C_treg2 , # h2
\		
		rdword	$C_treg3 , $C_treg2 	wz
		muxz	$C_treg4 , $C_fLongMask
	if_z	jmp	# __x01
\
		rdword	$C_treg2 , $C_treg3
		test	$C_treg2 , # h100	wz
		muxnz	$C_treg4 , $C_fLongMask
	if_nz	wrword	$C_stTOS , $C_treg3
__x01
		mov	$C_stTOS , $C_treg4		
		jexit
;asm _femit?
\
_bbo
\
\
\ femit? (c1 -- t/f) true if the output emitted a char, a fast non blocking emit
\
:asm
		and	$C_stTOS , # hFF
		mov	$C_treg2 , par
		add	$C_treg2 , # h2
\		
		rdword	$C_treg3 , $C_treg2	wz
		muxz	$C_treg4 , $C_fLongMask
	if_z	jmp	# __x01
\
		rdword	$C_treg2 , $C_treg3
		test	$C_treg2 , # h100	wz
		muxnz	$C_treg4 , $C_fLongMask
	if_nz	wrword	$C_stTOS , $C_treg3
__x01
		mov	$C_stTOS , $C_treg4		
		jexit
;asm femit?

\
_bbo
\
\
\ emit ( c1 -- )
\
:asm
		spopt
		and	$C_treg1 , # hFF
		mov	$C_treg2 , par
		add	$C_treg2 , # h2
\		
		rdword	$C_treg3 , $C_treg2	wz
	if_z	jmp	# __x02
__x01
		rdword	$C_treg2 , $C_treg3
		test	$C_treg2 , # h100	wz
	if_z	jmp	# __x01
\
		wrword	$C_treg1 , $C_treg3
__x02
		jexit
;asm emit
\
\
_bbo
\
\ skipbl ( -- )
:asm
\ >in
		mov	$C_treg1 , par
		add	$C_treg1 , # $V_>in
		rdword	$C_treg2 , $C_treg1
		cmp	$C_treg2 , # _vpadsize		wz wc
	if_ae	jmp	# __x02
\
\
\ num characters left in pad
		mov	$C_treg3 , # _vpadsize
		sub	$C_treg3 , $C_treg2
\ pad>in
		add	$C_treg2 , # $V_pad
		add	$C_treg2 , par
\
__x01
			rdbyte	$C_treg5 , $C_treg2
			cmp	$C_treg5 , # h20 	wz
		if_e	add	$C_treg2 , # 1
\
	if_e	djnz	$C_treg3 , # __x01
\	
\
\
\ recalculate >in
	sub	$C_treg2 , # $V_pad
	sub	$C_treg2 , par
	wrword	$C_treg2 , $C_treg1
__x02
	jexit
\	
;asm skipbl
\
\
{

Read Timing

pin 28 - SDA
pin 29 - SCL


    Trigger Pin      -q    +Q: 26
   Trigger Edge   -w +W SPACE: __x0--
Trigger Frequency         eE :             891
Sample Interval -asdfg +ASDFG: 500.0 nS             40 clock cycles
         Sample     <ENTER>
         Quit         <ESC>
Sample Display  -zxcv  +ZXCV :             277 clock cycles of           2,693
                 |               |               |               |               |               |               |               |
         149.9 uS|       157.9 uS|       165.9 uS|       173.9 uS|       181.9 uS|       189.9 uS|       197.9 uS|       205.9 uS|
                 |               |               |               |               |               |               |               |
31--------------------------------------------------------------------------------------------------------------------------------
30--------------------------------------------------------------------------------------------------------------------------------
29___________________________------------___________------------______-_________________________________________-----------------_
28________________________---___--___---___---___---___---___---___--____--__________________________________--___---___---___---_
                        |     |    |     |     |     |     |     |     |
                        |     |    |     |     |     |     |     |     |
                        |D7rd |D6rd|D5rd |D4rd |D3rd |D2rd |D1rd |D0rd |ACKwrite


Write Timing

pin 28 - SDA
pin 29 - SCL


    Trigger Pin      -q    +Q: 27
   Trigger Edge   -w +W SPACE: __x0--
Trigger Frequency         eE :             891
Sample Interval -asdfg +ASDFG: 500.0 nS             40 clock cycles
         Sample     <ENTER>
         Quit         <ESC>
Sample Display  -zxcv  +ZXCV :             277 clock cycles of           2,693
                 |               |               |               |               |               |               |               |
         149.9 uS|       157.9 uS|       165.9 uS|       173.9 uS|       181.9 uS|       189.9 uS|       197.9 uS|       205.9 uS|
                 |               |               |               |               |               |               |               |
31--------------------------------------------------------------------------------------------------------------------------------
30--------------------------------------------------------------------------------------------------------------------------------
29----_________________________________________------______------___________________________________-_________________________----
28-----------____________________________________---___---___---___--____--___---___---___---___---_____________________________--            |                                         |     |     |     |    |     |     |     |     |
      |eestart                                 |     |    |     |     |     |     |     |     |
                                               |D7wr |D6wr |D5wr |D4wr|D3wr |D2wr |D1wr |D0wr |ACKrd

}
\
_bbo
\
\
\ _eeread ( t/f -- c1 ) flag should be true is this is the last read
\
:asm
		jmp	# __x0C
__x02sda
		h20000000
__x03scl
		h10000000
__x04delay/2
		hD
\ this delay makes for a 400kHZ clock on an 80 Mhz prop
\
__x0Edelay/2
		mov	$C_treg6 , __x04delay/2
__x0D
		djnz	$C_treg6 , # __x0D
__x0Fdelayret
		ret
\
__x0C
		mov	$C_treg1 , $C_stTOS 
		mov	$C_stTOS , # 0
		andn	dira , __x02sda
		mov	$C_treg3 , # h8
\		
__x0B
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		test	__x02sda , ina	wc
		rcl	$C_stTOS , # 1
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		djnz	$C_treg3 , # __x0B
\
		cmp	$C_treg1 , # 0 wz
		muxnz	outa , __x02sda
		or	dira , __x02sda
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
		andn	outa , __x02sda
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		jexit
\
;asm _eeread
\
_bbo
\
\
\
\ _eewrite ( c1 -- t/f ) write c1 to the eeprom, true if there was an error
\
\
:asm
		jmp	# __x0C
__x02sda
		h20000000
__x03scl
		h10000000
__x04delay/2
		hD
\ this delay makes for a 400kHZ clock on an 80 Mhz prop
\
__x0Edelay/2
		mov	$C_treg6 , __x04delay/2
__x0D
		djnz	$C_treg6 , # __x0D
__x0Fdelayret
		ret
\
__x0C
		mov	$C_treg3 , # h8
\		
__x0B
		test	$C_stTOS , # h80	wz
		muxnz	outa , __x02sda
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
		shl	$C_stTOS , # 1
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		djnz	$C_treg3 , # __x0B
\
		andn	dira , __x02sda
		test	__x02sda , ina	wz
		muxnz	$C_stTOS , $C_fLongMask
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		andn	outa , __x02sda
		or	dira , __x02sda
\
\
		jexit
\
;asm _eewrite
\
\
\
\
\
_bbo
\
\ a_cha ( char flinW@ memend -- flin )
\
:asm
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
\
\
_bbo
\	
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
\
\
_bbo
\
