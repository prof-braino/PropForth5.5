package muxserial

/*
fl
\
\ structure in cog memory for the protocol driver
\

h1D8
   dup wconstant __+offset
1+ dup wconstant __serin
1+ dup wconstant __serout
1+ dup wconstant __h100
1+ dup wconstant __bshift
1+ dup wconstant __bmask
1+ dup wconstant __numchan
1+ dup wconstant __stateflags


1+ dup wconstant __lc
1+ dup wconstant __olc
1+ dup wconstant __index
1+ dup wconstant __index+numchan
1+ dup wconstant __mask

1+ dup wconstant __stTOS
1+ dup wconstant __reg1
1+ dup wconstant __reg2
1+ dup wconstant __reg3
1+ dup wconstant __reg4
1+ dup wconstant __reg5
1+ dup wconstant __reg6
1+ dup wconstant __reg7
1+ dup wconstant __reg8
1+ dup wconstant __reg9

h1C0 wconstant __bptr
h1C1 wconstant __byte
h1C2 wconstant __rdbuffer
h1CA wconstant __rdbuffer_ret
h1CB wconstant __wrbuffer
h1D7 wconstant __wrbuffer_ret




h1C0 :rasm
		jexit
__rdbuffer
		mov	__reg8 , __bptr
		shr	__bptr , # 2
		movs	__rdread , __bptr
		

		and	__reg8 , # 3
		shl	__reg8 , # 3
__rdread
		mov	__byte , 0
		shr	__byte , __reg8
		and 	__byte , # hFF
__rdbuffer_ret
		ret


__wrbuffer
		mov	__reg8 , __bptr
		shr	__bptr , # 2
		movd	__wrband , __bptr
		movd	__wrbor , __bptr

		and	__reg8 , # 3
		shl	__reg8 , # 3

		mov	__reg9 , # hFF
		shl	__reg9 , __reg8
		shl	__byte , __reg8
		and	__byte , __reg9	

__wrband
		andn	0 , __reg9
__wrbor
		or	0 , __byte

__wrbuffer_ret
		ret

;asm rwbuf

	

\ a_iobuf( -- )
build_BootOpt :rasm

		mov	__lc , # h110
		mov	__reg1 , $C_fDestInc

__zlp
		mov	0 , # 0
		add	__zlp , __reg1
		djnz	__lc , # __zlp

__mx_protocol
\
\
\
\ from the serial port to the channel buffers
\
__serin_next
		jmpret	__serfkeyq_ret , # __serfkeyq
	if_nz	jmp	# __serinexit
\
\ we have a character, split it into the op(reg2) and channel number(reg1)		
\
		cmp	__stTOS , # h21	wz
	if_z	jmpret	__seremit_ret , # __seremit
	if_z	jmp	# __serin_next

		mov	__reg2 , __stTOS
		and	__reg2 , # hE0

		mov	__reg7 , __stTOS
		and	__reg7 , # h1F

		cmp	__reg2 , # h40	wz
	if_ne	jmp	# __serin_notack
\
\ ack, set the stateflags back to ready to receive for this channel
\
		mov	__reg3 , # 1
		shl	__reg3 , __reg7
		or	__stateflags , __reg3
		jmp	# __serin_next

__serin_notack
		cmp	__reg2 , # h60	wz
\
\ not a byte we were expecting, bail
\
\	if_nz	mov	$C_treg6 , # h99		********************************
\	if_nz	jmp	# $C_a_reset

\
\ we have a byte packet, get the count(lc)
\
		jmpret	__serkey_ret , # __serkey
		mov	__lc , __stTOS
		sub	__lc , # h20
__serin_chars
\
\ get the chars, and put them in the buffer
\
		jmpret	__serkey_ret , # __serkey
		mov	__reg1 , __reg7
		jmpret	__iobufemitq_ret , # __iobufemitq
\
\ there is supposed to be room, bail
\
\	if_z	mov	$C_treg6 , # h9A		***********************************
\	if_z	jmp	# $C_a_reset
		djnz	__lc , # __serin_chars
		jmp	# __serin_next
__serinexit
\
\
\
\ big loop scanning all the channels
\
__ioin
		mov	__olc , __numchan
		mov	__index , # 0
		mov	__index+numchan , __numchan
		mov	__mask , # 1
\
\ from the buffers to the serial channel
\
__ioin_outerlp
\
\ if we are waiting for an ack, we cannot send anything
\
		test	__stateflags , __mask	wz
	if_z	jmp	# __ioin_next
\
\ check to see if there is anything in the buffer wating to go
\
		jmpret	__iobufcountq_ret , # __iobufcountq_1
	if_z	jmp	# __ioin_next
\
\ we have a count(lc) of characters ready to go
\
		mov	__lc , __stTOS
\
\ send the index to the serial channel
\
		mov	__stTOS , __index
		add	__stTOS , # h60
		jmpret	__seremit_ret , # __seremit
\
\ send the count to the serial channel
\
		mov	__stTOS , __lc
		add	__stTOS , # h20
		jmpret	__seremit_ret , # __seremit
\
\ send the chars to the serial channel
\
__ioin_innerlp
		mov	__reg1 , __index+numchan
		jmpret	__iobufkeyq_ret , # __iobufkeyq
\
\ should be space for a char there
\
\	if_z	mov	$C_treg6 , # h33		*******************************************
\	if_z	jmp	# $C_a_reset
		
		jmpret	__seremit_ret , # __seremit
		djnz	__lc , # __ioin_innerlp
\
\ mark the stateflags as waiting for an ack for this channel
\
		andn	__stateflags , __mask
__ioin_next
\
\
\
\ from the buffers to the channel
\
__iooutbuf_outerlp

		mov	__lc , __bmask
__iooutbuf_innerlp
		mov	__reg1 , __index
		jmpret	__ioemitq_ret , # __ioemitq
	if_nz	jmp	# __iobufoutskip
		
		mov	__reg1 , __index
		jmpret	__iobufkeyq_ret , # __iobufkeyq
	if_z	jmp	# __iobufoutskip

		mov	__reg1 , __index
		jmpret	__iofemitq_ret , # __iofemitq
\
\ should be good
\
\	if_nz	mov	$C_treg6 , # h9B			*************************************
\	if_nz	jmp	# $C_a_reset

		mov	__reg1 , __index
		jmpret	__iobufcountq_ret , # __iobufcountq

	if_z	mov	__stTOS , __index
	if_z	add	__stTOS , # h40
	if_z	jmpret	__seremit_ret , # __seremit
\
\ try for an echo - since echo is done at the cog level this will prevent slowing down
\
\ from the io channels to the buffers
\
		jmpret	__iobufcountq_ret , # __iobufcountq_1
		cmp	__stTOS , __bmask	wz
	if_z	jmp	# __iooutbuf_skipecho

		mov	__reg1 , __index
		jmpret	__iofkeyq_ret , # __iofkeyq
	if_nz	jmp	# __iooutbuf_skipecho
\
		jmpret	__iobufemitq_ret , # __iobufemitq_1
\
\ should be space
\
\	if_z	mov	$C_treg6 , # h44			*****************************************
\	if_z	jmp	# $C_a_reset

__iooutbuf_skipecho
		djnz	__lc , # __iooutbuf_innerlp
__iobufoutskip
\
\
\
\
\ from the io channels to the buffers
\
__iobuf_lpouter
		jmpret	__iobufcountq_ret , # __iobufcountq_1

		mov	__lc , __bmask
		sub	__lc , __stTOS	wz
	if_z	jmp	# __iobuf_endouter
\
\ the amount of space in the buffers(lc)
\
__iobuf_lpinner
		mov	__reg1 , __index
		jmpret	__iofkeyq_ret , # __iofkeyq
	if_nz	jmp	# __iobuf_endinner
\
		jmpret	__iobufemitq_ret , # __iobufemitq_1
\
\ should be space
\
\	if_z	mov	$C_treg6 , # h44			************************
\	if_z	jmp	# $C_a_reset

__iobuf_endinner
		djnz	__lc , # __iobuf_lpinner

__iobuf_endouter




		add	__index , # 1
		add	__index+numchan , # 1
		shl	__mask , # 1
		djnz	__olc , # __ioin_outerlp
	
		jmp	# __mx_protocol


\
\ enter - __stTOS -don't care
\	- __reg1  - index to io channels
\ exit  - __stTOS - char
\       - zflag    - set if the char is valid
\
\
__iofkeyq
		shl    __reg1 , # 2
		add    __reg1 , par
 		rdword __stTOS , __reg1
		test   __stTOS , # h100	wz
	if_z	wrword __h100 , __reg1
__iofkeyq_ret
		ret

\
\
\ - enter - __reg1 - buf#
\ - exit  
\ __reg6 - head
\ __reg5 - tail
\
\ __reg4 - head/tail pointer
\
__getheadtail
		mov	__reg4 , __reg1
		shl	__reg4 , # 1
		
		mov	__bptr , __reg4
		jmpret	__rdbuffer_ret , # __rdbuffer
		mov	__reg6 , __byte

		add	__reg4 , # 1

		mov	__bptr , __reg4
		jmpret	__rdbuffer_ret , # __rdbuffer
		mov	__reg5 , __byte

\		
\
\		add	__reg4 , __iobuf
\		rdbyte	__reg6 , __reg4
\		add	__reg4 , # 1
\		rdbyte	__reg5 , __reg4
__getheadtail_ret
		ret
\
\ - enter - __reg1  - buf#
\ - exit  - __stTOS - count
\         - zflag - set if count is zero
\
__iobufcountq_1
		mov	__reg1 , __index+numchan	
__iobufcountq
		jmpret	__getheadtail_ret , # __getheadtail
		mov	__stTOS , __reg6

		sub	__stTOS , __reg5
		and	__stTOS , __bmask	wz
__iobufcountq_ret
		ret
\
\ - enter - __stTOS - char
\         - __reg1 - buf#
\ - exit  - __stTOS - don't care
\         - zflag - set char is invalid - there was no space in the buffer
\ __reg6 - head
\ __reg5 - tail
\
\ __reg4 - head/tail pointer
\
__iobufemitq_1
		mov	__reg1 , __index+numchan	
__iobufemitq
		jmpret	__getheadtail_ret , # __getheadtail

		mov	__reg2 , __reg6
		add	__reg2 , # 1
		and	__reg2 , __bmask

		cmp	__reg2 , __reg5	wz
	if_z	jmp	# __iobufemitq_ret


		shl	__reg1 , __bshift
		add	__reg1 , __+offset
		add	__reg1 , __reg6
		
		mov	__bptr , __reg1
		mov	__byte , __stTOS
		jmpret	__wrbuffer_ret , # __wrbuffer

\		wrbyte	__stTOS , __reg1

		sub	__reg4 , # 1

		mov	__bptr , __reg4
		mov	__byte , __reg2
		jmpret	__wrbuffer_ret , # __wrbuffer

\		wrbyte	__reg2 , __reg4
__iobufemitq_ret
		ret

\
\ - enter - __reg1  - buf#
\ - exit  - __stTOS - char
\         - zflag - set char is invalid
\ __reg6 - head
\ __reg5 - tail
\
\ __reg4 - head/tail pointer
\
__iobufkeyq
		jmpret	__getheadtail_ret , # __getheadtail

		cmp	__reg6 , __reg5	wz
	if_z	jmp	# __iobufkeyq_ret

		shl	__reg1 , __bshift
		add	__reg1 , __+offset
		add	__reg1 , __reg5
		
		mov	__bptr , __reg1
		jmpret	__rdbuffer_ret , # __rdbuffer
		mov	__stTOS , __byte

\		rdbyte	__stTOS , __reg1

		add	__reg5 , # 1
		and	__reg5 , __bmask

		mov	__bptr , __reg4
		mov	__byte , __reg5
		jmpret	__wrbuffer_ret , # __wrbuffer

\		wrbyte	__reg5 , __reg4
__iobufkeyq_ret
		ret


\
\ - enter - __stTOS - char
\         - __reg1 - chan number
\
\ - exit  - __stTOS - don't care
\         - zflag - set if ready for a char
\
__iofemitq
		jmpret	__ioemitq_ret , # __ioemitq
	if_z	wrword	__stTOS , __reg2 

__iofemitq_ret
		ret
\
\ - enter - __stTOS - don't care
\         - __reg1 - chan number
\ - exit  - __stTOS - don't care
\         - zflag - set if ready for a char
\
__ioemitq
		shl	__reg1 , # 2
		add	__reg1 , par
		add	__reg1 , # 2
\
		rdword	__reg2 , __reg1	wz
	if_z	jmp	# __ioemitq_ret

		rdword	__reg3 , __reg2
		test	__reg3 , # h100	wz
		muxz	__reg4 , # h1FF	nr wz

__ioemitq_ret
		ret

\
\ - enter - __stTOS - don't care
\ - exit  - __stTOS - char
\
__serkey
		jmpret	__serfkeyq_ret , # __serfkeyq
	if_nz	jmp	# __serkey
__serkey_ret
		ret
\
\ enter - __stTOS - don't care
\ exit  - __stTOS - char
\       - zflag    - set if the char is valid
\
\
__serfkeyq
		rdword	__stTOS , __serin
		test	__stTOS , # h100	wz
	if_z	wrword	__h100 , __serin
__serfkeyq_ret
		ret

\
\ - enter - __stTOS - char to emit
\ - exit  - __stTOS - char to emit
\
__seremit
\
		rdword	__reg2 , __serout	wz
	if_z	jmp	# __seremit_ret
__poll
		rdword	__reg1 , __reg2
		test	__reg1 , # h100	wz
	if_z	jmp	# __poll
\
		wrword	__stTOS , __reg2
__seremit_ret
		ret

;asm a_iobuf


cr base W@ swap hex . base W! cr cr



*/


var scode string = `
fl
\
\ serial line protocol - 
\ b011X_XXXX count cc - X is chan number count is number of characters following + h20
\ b010Y_YYYY - ack Y is chan number
\


lockdict create rwbuf forthentry
$C_a_lxasm w, h1D8  h1C1  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV01X l, z2Wiwi0 l, zbyr02 l, z1Giry0 l, z1Wywb3 l, zfywb3 l, z2Wir80 l, zbirFg l,
z1WyrBy l, z1SV000 l, z2Wiwi0 l, zbyr02 l, z1Kiti0 l, z1Kitq0 l, z1Wywb3 l, zfywb3 l,
z2Wywmy l, zfiwqg l, zfirFg l, z1WirFh l, z1[i07h l, z1bi071 l, z1SV000 l,
freedict


lockdict create a_iobuf forthentry
$C_a_lxasm w, h1B9  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z2Wyv4G l, z2Wivm2 l, z2Wy000 l, z20iYi] l, z3[yv4L l, z1SypEh l, z1SL04j l, z26VvbX l,
z1Stq6l l, z1SQ04O l, z2Wivy\ l, z1WyvuW l, z2Wiwa\ l, z1WywWV l, z26Vvs0 l, z1SL04a l,
z2Wyw01 l, zfiw7f l, z1biuyb l, z1SV04O l, z26VvsW l, z1Syohe l, z2Wiv7\ l, z24yv0W l,
z1Syohe l, z2Wivqf l, z1Sykwy l, z3[yv4e l, z1SV04O l, z2WivFU l, z2WyvG0 l, z2WivVU l,
z2WyvW1 l, z1YFuy[ l, z1SQ054 l, z1Syigr l, z1SQ054 l, z2Wiv7\ l, z2WiviY l, z20yvcW l,
z1Syq6l l, z2WiviW l, z20yvbW l, z1Syq6l l, z2WivqZ l, z1SympG l, z1Syq6l l, z3[yv4y l,
z1[iuy[ l, z2Wiv7T l, z2WivqY l, z1SyoMY l, z1SL05Q l, z2WivqY l, z1SympG l, z1SQ05Q l,
z2WivqY l, z1SynEV l, z2WivqY l, z1Syigs l, z2WdviY l, z20tvc0 l, z1Stq6l l, z1Syigr l,
z26FviT l, z1SQ05P l, z2WivqY l, z1Syggb l, z1SL05P l, z1Sykwx l, z3[yv55 l, z1Syigr l,
z2Wiv7T l, z26iv7\ l, z1SQ05Z l, z2WivqY l, z1Syggb l, z1SL05Y l, z1Sykwx l, z3[yv5U l,
z20yvG1 l, z20yvO1 l, zfyvW1 l, z3[yvCn l, z1SV04O l, zfyvj2 l, z20ivqj l, z4ivi] l,
z1YVvf0 l, z4AuV] l, z1SV000 l, z2WiwF] l, zfyw81 l, z2Wir7c l, z1SysN2 l, z2WiwV1 l,
z20yw81 l, z2Wir7c l, z1SysN2 l, z2WiwN1 l, z1SV000 l, z2WivqZ l, z1Syhwh l, z2Wivie l,
z24ivid l, z1YiviT l, z1SV000 l, z2WivqZ l, z1Syhwh l, z2Wivye l, z20yvr1 l, z1WivyT l,
z26Fvyd l, z1SQ06F l, zfivqS l, z20ivqO l, z20ivqe l, z2Wir7] l, z2WirF\ l, z1SytyB l,
z24yw81 l, z2Wir7c l, z2WirFa l, z1SytyB l, z1SV000 l, z1Syhwh l, z26FwVd l, z1SQ06U l,
zfivqS l, z20ivqO l, z20ivqd l, z2Wir7] l, z1SysN2 l, z2Wivi1 l, z20ywG1 l, z1WiwNT l,
z2Wir7c l, z2WirFd l, z1SytyB l, z1SV000 l, z1SyoMY l, z4Avia l, z1SV000 l, zfyvj2 l,
z20ivqj l, z20yvj2 l, z6ivy] l, z1SQ06d l, z4iw7a l, z1YVw40 l, z1tVwFy l, z1SV000 l,
z1SypEh l, z1SL06e l, z1SV000 l, z4iviP l, z1YVvf0 l, z4AuVP l, z1SV000 l, z6ivyQ l,
z1SQ06r l, z4ivqa l, z1YVvn0 l, z1SQ06n l, z4Fvia l, z1SV000 l,
freedict



[ifndef $C_rsPtr
    hCA wconstant $C_rsPtr
]

\
\ These constants will be sent by muxserial
[ifndef _MX_BSHIFT
d_4	wconstant _MX_BSHIFT
d_16	wconstant _MX_BSIZE
d_15	wconstant _MX_BMASK
d_32	wconstant _MX_NUM_CHAN
d_128	wconstant _MX_BUF_OFFSET
]
\
\
\ 0			- _MX_NUM_CHAN * head tail
\ _MX_BUF_OFFSET	- _MX_NUM_CHAN*2 * 16 byte buffer
\ _MX_BUF_OFFSET+d_1024	- end
\
\
\
: gos
	h1D8

	_MX_BUF_OFFSET  over COG! 1+

	hD8 _p+ over COG! 1+
	hDA _p+ over COG! 1+
	h100 over COG! 1+
	_MX_BSHIFT over COG! 1+
	_MX_BMASK over COG! 1+
	_MX_NUM_CHAN over COG! 1+
	-1 over COG! 1+


\
\	
	1 7 sersetflags
	cogid iodis
\
\ set the cog to busy
	c" MX_SERIAL" cds W!
	4 state andnC!
	8 _MX_NUM_CHAN min 1- numchan C!
\
\ set up channels as input to this cog
	io _MX_NUM_CHAN 4* bounds
	do
		h100 i L!
	4 +loop

	_MX_NUM_CHAN 4 0
	do
		cogid i i 0 (ioconn)
	loop
	if _MX_NUM_CHAN > 4
	6 cogio _MX_NUM_CHAN 4* + 6 cogio 4 4* +
	do
		i dup 2+ W!
	4 +loop
	then
\
\ set up the serial io channel and connect it
	7 cogio h100 hD8 _p+ L!
	hD8 _p+ 2dup 2+ W! swap 2+ W!
\
\ send a ! then wait for a !
	h21 hDA _p+ W@ W!
\	h21 a_seremit
	begin
		hD8 _p+ C@
		h21 =
	until
	h100 hD8 _p+ W!

	rwbuf
	a_iobuf
;



`
