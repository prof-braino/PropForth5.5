fl
hA state orC!

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
\
\ structure in cog memory for the serial driver
\

h1C2
   dup wconstant __rxhm		\ h1C2
1+ dup wconstant __rxtm		\ h1C3
1+ dup wconstant __txhm		\ h1C4
1+ dup wconstant __txtm		\ h1C5

1+ dup wconstant __rxbyte	\ h1C6
1+ dup wconstant __h100		\ h1C7

1+ dup wconstant __bitticks/4	\ h1C8
1+ dup wconstant __bitticks	\ h1C9

1+ dup wconstant __rxmask	\ h1CA
1+ dup wconstant __txmask	\ h1CB

1+ dup wconstant __outptr	\ h1CC
\
\ rest are initiazed to zero
\

1+ dup wconstant __reg1
1+ dup wconstant __reg2
1+ dup wconstant __reg3

1+ dup wconstant __receiveTask
1+ dup wconstant __transmitTask
1+ dup wconstant __schedTask
1+ dup wconstant __rxbufInTask
1+ dup wconstant __rxbufOutTask
1+ dup wconstant __txbufInTask
1+ dup wconstant __pollTask

1+ dup wconstant __rxbufInReg
1+ dup wconstant __txbufInReg
1+ dup wconstant __txbufInBuf

1+ dup wconstant __pollReg
1+ dup wconstant __serialFlags

1+ dup wconstant __rxdata
1+ dup wconstant __rxbits
1+ dup wconstant __rxcnt
1+ dup wconstant __txdata
1+ dup wconstant __txbits
1+ dup wconstant __txcnt

1+ dup wconstant __rxh
1+ dup wconstant __rxha
1+ dup wconstant __rxhs
1+ dup wconstant __rxt
1+ dup wconstant __rxta
1+ dup wconstant __rxts
1+ dup wconstant __txh
1+ dup wconstant __txha
1+ dup wconstant __txhs
1+ dup wconstant __txt
1+ dup wconstant __txta
1+ dup wconstant __txts
1+ dup wconstant __h00

c" ~h0D~h0D\ end of struct " .cstr . cr

build_BootOpt :rasm
                        wrlong  __h100 , par
\
                        mov     __transmitTask , # __transmit
                        mov     __schedTask , # __sched
\                        
                        mov     __rxbufInTask  , # __rxbufIn
                        mov     __rxbufOutTask , # __rxbufOut
                        mov     __txbufInTask  , # __txbufIn
                        mov     __pollTask , # __poll
\
                        or      outa , __txmask
                        or      dira , __txmask
\
\
\
\ Receive
\
__receive
\
                        jmpret  __receiveTask , __transmitTask
\
                        test    __rxmask , ina  wz
              if_nz     jmp     # __receive
\
                        mov     __rxbits , # h9
\ mov 1/4 of the way into the bit slot                        
                        mov     __rxcnt , __bitticks/4
                        add     __rxcnt , cnt             
__receivebit
			add     __rxcnt , __bitticks
__receivewait
			jmpret  __receiveTask , __transmitTask
\
                        mov     __reg1 , __rxcnt
                        sub     __reg1 , cnt
                        cmps    __reg1 , # 0           wc
\
        if_nc           jmp     # __receivewait
\
                        test    __rxmask , ina      wc
                        rcr     __rxdata , # 1
\
                        djnz    __rxbits , # __receivebit
\
\
        if_nc           jmp     # __receive
\
\
                        shr     __rxdata , # h17
\ 32-9
                        and     __rxdata , # hFF
\
                        mov     __rxbyte , __rxdata
\
                        jmp     # __receive
\
\
\ Transmit
\
__transmit


__txbufOut
\
                        jmpret  __transmitTask , __schedTask
\
                        cmp     __txh , __txt   wz
              if_z      jmp     # __transmit
\              
			or	__txta , # h80

			movs	__txbufoutrd , __txta
			mov	__txdata , __txtm
__txbufoutrd
			and	__txdata , __txta
			shr	__txdata , __txts
\
                        jmpret  __transmitTask , __schedTask
\
			rol	__txtm , # 8	wc
\
			addx	__txta , # 0
			and	__txta , # h7F
\
			add	__txts , # 8
\
                        add     __txt , # 1
                        and     __txt , # h1FF        
\
                        jmpret  __transmitTask , __schedTask
\
                        or      __txdata , # h100
                        shl     __txdata , # h2
                        or      __txdata , # 1
                        mov     __txbits , # hB
\
                        jmpret  __transmitTask , __schedTask
\
                        mov     __txcnt , cnt
\
__transmitbit
			shr     __txdata , # 1 wc
                        muxc    outa , __txmask        
                        add     __txcnt , __bitticks
\
__transmitwait
\
                        jmpret  __transmitTask , __schedTask
\
                        mov     __reg1 , __txcnt
                        sub     __reg1 , cnt
                        cmps    __reg1 , # 0 wc
        if_nc           jmp     # __transmitwait
\
                        djnz    __txbits , # __transmitbit
\
                        jmp     # __transmit
\
\
\
__sched
                        jmpret  __schedTask , __receiveTask
                        jmpret  __schedTask , __rxbufInTask
                        jmpret  __schedTask , __receiveTask
                        jmpret  __schedTask , __rxbufOutTask
                        jmpret  __schedTask , __receiveTask
                        jmpret  __schedTask , __txbufInTask
                        jmpret  __schedTask , __receiveTask
                        jmpret  __schedTask , __pollTask
                        jmp     # __sched
\
\
__rxbufIn
\
                        jmpret  __rxbufInTask , __schedTask
\
                        test    __rxbyte , # h100     wz
              if_nz     jmp     # __rxbufIn

                        mov     __rxbufInReg , __rxh
                        add     __rxbufInReg , # 1
                        and     __rxbufInReg , # h1FF
\                        
                        cmp     __rxbufInReg , __rxt   wz
              if_z      jmp     # __rxbufIn
\
                        jmpret  __rxbufInTask , __schedTask
\
			movd	__rxbufinand , __rxha
			movd	__rxbufinor , __rxha
\
			mov	__reg1 , __rxbyte
			mov	__rxbyte , # h100
\
			shl	__reg1 , __rxhs
			and	__reg1 , __rxhm
__rxbufinand
			andn	__rxha , __rxhm
__rxbufinor
			or	__rxha , __reg1
\
                        jmpret  __rxbufInTask , __schedTask
\
			rol	__rxhm , # 8	wc
\
			addx	__rxha , # 0
			and	__rxha , # h7F
\
			add	__rxhs , # 8
\
                        mov     __rxh , __rxbufInReg
\
                        jmp     # __rxbufIn
\
\
__rxbufOut
\
                        jmpret  __rxbufOutTask , __schedTask
\
                        cmp     __rxh , __rxt   wz
              if_z      jmp     # __rxbufOut
\
                        cmp	__outptr , # 0	wz
              if_nz     rdword  __reg3 , __outptr
              if_nz     test    __reg3 , # h100     wz
              if_z      jmp     # __rxbufOut
\
                        jmpret  __rxbufOutTask , __schedTask
\
			movs	__rxbufoutrd , __rxta
			mov	__reg3 , __rxtm
\
__rxbufoutrd
			and	__reg3 , __rxta
			shr	__reg3 , __rxts
                        wrword  __reg3 , __outptr      
\
                        jmpret  __rxbufOutTask , __schedTask
\
			rol	__rxtm , # 8	wc
\
			addx	__rxta , # 0
			and	__rxta , # h7F
\
			add	__rxts , # 8
\
                        add     __rxt , # 1
                        and     __rxt , # h1FF        
\
                        jmp     # __rxbufOut
\
__txbufIn
\
                        jmpret  __txbufInTask , __schedTask
\
                        rdword  __txbufInBuf , par
                        test    __txbufInBuf , # h100 wz
              if_nz     jmp     # __txbufIn
\
                        jmpret  __txbufInTask , __schedTask
\
                        mov     __txbufInReg , __txh
                        add     __txbufInReg , # 1
                        and     __txbufInReg , # h1FF
\                        
                        cmp     __txbufInReg , __txt   wz
              if_z      jmp     # __txbufIn
\
                        jmpret  __txbufInTask , __schedTask
\
			or	__txha , # h80
\
			movd	__txbufinand , __txha
			movd	__txbufinor , __txha
\
			mov	__reg1 , __txbufInBuf
			shl	__reg1 , __txhs
			and	__reg1 , __txhm
__txbufinand
			andn	__txha , __txhm
__txbufinor
			or	__txha , __reg1 
\
                        jmpret  __txbufInTask , __schedTask
\
			rol	__txhm , # 8	wc
\
			addx	__txha , # 0
			and	__txha , # h7F
\
			add	__txhs , # 8
\
                        mov     __txh , __txbufInReg
\
                        jmpret  __txbufInTask , __schedTask
\
			cmp	__txbufInBuf , # h_0D	wz
\
		if_z	test	__serialFlags , # 1	wz
\
		if_nz	wrword	__h100 , par
\
		if_z	mov	__reg1 , # h0A
		if_z	wrword  __reg1 , par
\      
                        jmp     # __txbufIn
\
\                        
__poll
\
                        jmpret  __pollTask , __schedTask
                        mov     __pollReg , par
                        add     __pollReg , # h2
\
                        rdword  __outptr , __pollReg
                        jmpret  __pollTask , __schedTask
\
			add	__pollReg , # h_C2
\
			rdlong	__reg3 , __pollReg	wz
		if_z	jmp	# __nobreak

			wrlong	__h00 , __pollReg

			min	__reg3 , # h10
                        andn    outa , __txmask
			add	__reg3 , cnt
			waitcnt	__reg3 , # 0
                        or      outa , __txmask
__nobreak
\
                        jmpret  __pollTask , __schedTask
\
			add	__pollReg , # 4
\

			rdlong	__serialFlags , __pollReg
\
			jmp	# __poll
;asm _serial


hA state andnC!


