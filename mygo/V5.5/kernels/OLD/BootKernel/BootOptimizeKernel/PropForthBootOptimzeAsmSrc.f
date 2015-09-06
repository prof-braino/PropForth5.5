fl

\

\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\

\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
\ Because the unoptimized kernel is so slow, the interpreter can actully be overrun.
\ These comments at the beginning give fl a chance to execute and catch up, so nothing will be overrun.
\
\
coghere W@ wconstant build_BootOpt
\
\
hA state orC! cr cr cr
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
_bbo0
\
\ serial ( n1 n2 n3 -- ) 
\ n1 - tx pin
\ n2 - rx pin
\ n3 - baud rate
\
\ _serial ( n1 n2 n3 -- ) 
\ n1 - tx pin
\ n2 - rx pin
\ n3 - clocks/bit
\
\ h00 - h04 -- io channel for serial driver
\ h04 - h84 -- receive buffer
\ h84 - hC4 -- transmit  buffer
\ hC4 - hC8 -- long - send a break for this number of clock cycles
\ hc8 - hCC -- flags
\	h_0000_0001 - if true do not expand cr to cr lf on transmit 
\
\
\

build_BootOpt :rasm
			jmp	# __x01
\
__rxh
	0
__rxt
	0
__txh
	0
__txt
	0
\
__rxbyte
	h100
__txbyte
	h100
\
\ Uninitialized data
\
__bitticks
	0
__rxmask
	0
__txmask
	0
__x49_rxbuff
	0
__x4A_txbuff
	0
__x4C_out
	0
\
__x4D_receiveTask
	0
__x4E_transmitTask
	0
__x4F_schedTask
	0
__x50_rxbufInTask
	0
__x51_rxbufOutTask
	0
__x52_txbufInTask
	0
__x53_txbufOutTask
	0
\
__x54_rxdata
	0
__x55_rxbits
	0
__x56_rxcnt
	0
\
\
__x57_txdata
	0
__x58_txbits
	0
__x59_txcnt
	0
\
\
\
\
\ Transmit
\
__x5A_transmit
                        jmpret  __x4E_transmitTask , __x4F_schedTask
\
                        test    __txbyte , # h100 wz
        if_nz           jmp     # __x5A_transmit
\
                        mov     __x57_txdata , __txbyte
                        mov     __txbyte , # h100                       
\
                        or      __x57_txdata , # h100
                        shl     __x57_txdata , # h2
                        or      __x57_txdata , # 1
                        mov     __x58_txbits , # hB
                        mov     __x59_txcnt , cnt
\
__x63_transmitbit
			shr     __x57_txdata , # 1 wc
                        muxc    outa , __txmask        
                        add     __x59_txcnt , __bitticks
\
__x64_transmitwait
                        jmpret  __x4E_transmitTask , __x4F_schedTask
                        mov     $C_treg1 , __x59_txcnt
                        sub     $C_treg1 , cnt
                        cmps    $C_treg1 , # 0 wc
        if_nc           jmp     # __x64_transmitwait
\
                        djnz    __x58_txbits , # __x63_transmitbit
\
                        jmp     # __x5A_transmit
\
\
\
__x5B_sched
                        jmpret  __x4F_schedTask , __x4D_receiveTask
                        jmpret  __x4F_schedTask , __x50_rxbufInTask
                        jmpret  __x4F_schedTask , __x4D_receiveTask
                        jmpret  __x4F_schedTask , __x51_rxbufOutTask
                        jmpret  __x4F_schedTask , __x4D_receiveTask
                        jmpret  __x4F_schedTask , __x52_txbufInTask
                        jmpret  __x4F_schedTask , __x4D_receiveTask
                        jmpret  __x4F_schedTask , __x53_txbufOutTask
                        jmp     # __x5B_sched
\
\
__x5C_rxbufIn
                        jmpret  __x50_rxbufInTask , __x4F_schedTask
\
                        test    __rxbyte , # h100     wz
              if_nz     jmp     # __x5C_rxbufIn
\
                        mov     $C_treg1 , __rxh
                        add     $C_treg1 , # 1
                        and     $C_treg1 , # h7F
\                        
                        cmp     $C_treg1 , __rxt   wz
              if_z      jmp     # __x5C_rxbufIn
\
                        add     __rxh , __x49_rxbuff
                        wrbyte  __rxbyte , __rxh
                        mov     __rxbyte , # h100
\
                        mov     __rxh , $C_treg1
\
                        jmp     # __x5C_rxbufIn
\
__x5D_rxbufOut
                        jmpret  __x51_rxbufOutTask , __x4F_schedTask
\
                        cmp     __rxh , __rxt   wz
              if_z      jmp     # __x5D_rxbufOut
\              
                        mov     $C_treg1 , __x4C_out
                        rdword  $C_treg2 , $C_treg1         wz
              if_nz     rdword  $C_treg3 , $C_treg2
              if_nz     test    $C_treg3 , # h100     wz
              if_z      jmp     # __x5D_rxbufOut
\
                        add     __rxt , __x49_rxbuff
                        rdbyte  $C_treg3 , __rxt
                        sub     __rxt , __x49_rxbuff
                        add     __rxt , # 1
                        wrword  $C_treg3 , $C_treg2      
                        and     __rxt , # h7F        
                        jmp     # __x5D_rxbufOut
\
__x5E_txbufIn
                        jmpret  __x52_txbufInTask , __x4F_schedTask

			rdlong	$C_treg3 , $C_treg5	wz
		if_z	jmp	# __nobreak

			mov	$C_treg1 , # 0
			wrlong	$C_treg1 , $C_treg5

			min	$C_treg3 , # h10
                        andn    outa , __txmask
			add	$C_treg3 , cnt
			waitcnt	$C_treg3 , # 0
                        or      outa , __txmask



__nobreak
\
                        rdword  $C_treg3 , par
                        test    $C_treg3 , # h100 wz
              if_nz     jmp     # __x5E_txbufIn
\
                        mov     $C_treg1 , __txh
                        add     $C_treg1 , # 1
                        and     $C_treg1 , # h3F
\                        
                        cmp     $C_treg1 , __txt   wz
              if_z      jmp     # __x5E_txbufIn
\                               
                        add     __txh , __x4A_txbuff
                        wrbyte  $C_treg3 , __txh
                        mov     __txh , $C_treg1
\
			cmp	$C_treg3 , # h_0D	wz


		if_z	rdlong	$C_treg1 , $C_treg6
		if_z	test	$C_treg1 , # 1		wz

		if_nz	mov     $C_treg1 ,  # h_100
		if_z	mov	$C_treg1 , # h0A
                        wrword  $C_treg1 , par
\
\
\
\                       
                        jmp     # __x5E_txbufIn
\
\                        
__x5F_txbufOut
                        jmpret  __x53_txbufOutTask , __x4F_schedTask
\
                        cmp     __txh , __txt   wz
              if_z      jmp     # __x5F_txbufOut
\              
                        test    __txbyte , # h100     wz
              if_z      jmp     # __x5F_txbufOut
\
                        add     __txt , __x4A_txbuff
                        rdbyte  __txbyte , __txt
                        sub     __txt , __x4A_txbuff
                        add     __txt , # 1
                        and     __txt , # h3F       
\
                        jmp     # __x5F_txbufOut
\
\
__x01

			mov	$C_treg5 , par
			add	$C_treg5 , # h_C4
\
			mov	$C_treg6 , par
			add	$C_treg6 , # h_C8
\

                        mov	__bitticks , $C_stTOS
			spop
\
                        mov	__rxmask , # 1
			shl	__rxmask , $C_stTOS
			spop
\
                        mov	__txmask , # 1
			shl	__txmask , $C_stTOS
			spop
\			
                        mov     __x49_rxbuff , par
                        add     __x49_rxbuff , # h4
                        mov     __x4A_txbuff , __x49_rxbuff
                        add     __x4A_txbuff , # h80
\
                        mov     __x4C_out , par
                        add     __x4C_out , # h2
\
\
                        mov     $C_treg1 , # h100
                        wrlong  $C_treg1 , par
\
\
                        mov     __x4E_transmitTask , # __x5A_transmit
                        mov     __x4F_schedTask , # __x5B_sched
\                        
                        mov     __x50_rxbufInTask  , # __x5C_rxbufIn
                        mov     __x51_rxbufOutTask , # __x5D_rxbufOut
                        mov     __x52_txbufInTask  , # __x5E_txbufIn
                        mov     __x53_txbufOutTask , # __x5F_txbufOut
\
                        or      outa , __txmask
                        or      dira , __txmask
\
\
\ Receive
\
__x60_receive
\
                        jmpret  __x4D_receiveTask , __x4E_transmitTask
\
\                        
                        test    __rxmask , ina  wz
              if_nz     jmp     # __x60_receive
\
                        mov     __x55_rxbits , # h9
\ mov 1/4 of the way into the bit slot                        
                        mov     __x56_rxcnt , __bitticks
                        shr     __x56_rxcnt , # h2
                        add     __x56_rxcnt , cnt             
__x61_receivebit
			add     __x56_rxcnt , __bitticks
__x62_receivewait
			jmpret  __x4D_receiveTask , __x4E_transmitTask
\
                        mov     $C_treg1 , __x56_rxcnt
                        sub     $C_treg1 , cnt
                        cmps    $C_treg1 , # 0           wc
\
        if_nc           jmp     # __x62_receivewait
\
                        test    __rxmask , ina      wc
                        rcr     __x54_rxdata , # 1
\
                        djnz    __x55_rxbits , # __x61_receivebit
\
\
        if_nc           jmp     # __x60_receive
\
\
                        shr     __x54_rxdata , # h17
\ 32-9
                        and     __x54_rxdata , # hFF
\
                        mov     __rxbyte , __x54_rxdata
\
                        jmp     # __x60_receive
\
;asm _serial
\
\
\
c" : init_coghere " .cstr base W@ hex h68 emit max_coghere W@ . base W! c" coghere W! ;" .cstr cr
\
cr cr cr hA state andnC!
\
\
