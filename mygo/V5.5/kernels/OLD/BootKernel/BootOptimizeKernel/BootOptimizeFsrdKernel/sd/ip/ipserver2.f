fl

mountsys

h100 fwrite ipserver2.f



\
\ _ip_dosend ( -- ) if there are any characters written to the w5100 send them out
: _ip_dosend
	_ip_txcount W@ 0>
	if
[ifdef ip_debug
		ip_debug W@ h2 and if _ip_socketstatus then
]

		_ip_txoffset W@ _ip_stx_wr!
		0 _ip_txcount W!
		_ip_sc_send _ip_scr!
	then
;
 
\ _ip_sockemit ( c1 -- ) c1 - the character to write to the socket, if we have written 1024 characters, do a send
: _ip_sockemit
\						\ increment _ip_txcount
	1 _ip_txcount W+!
\						\ _ip_txoffset, and increment _ip_txoffset
	_ip_txoffset W@ 1 _ip_txoffset W+!
\						\ write the char to the w5100
	_sockbufmask and _ip_txbuf + _ip_wrbyte
\						\  we have xxx characters
	_ip_txcount W@ _ip_txbuffersize >
	if
\						\ send the characters out
		_ip_dosend
	then
;

\ _ip_sockcstr ( caddr -- )  caddr - address of a cstr to write to the socket
: _ip_sockcstr
	dup C@ swap 1+ swap bounds
	do
		i C@ _ip_sockemit
	loop
;

\ _ip_sockcr ( -- )	write CR LF to the socket 
: _ip_sockcr
	hD _ip_sockemit hA _ip_sockemit

;

\ _ip_iacresp ( c1 c2 -- ) respond to the telnet control sequence
: _ip_iacresp
	hFF _ip_sockemit
	_ip_sockemit
	_ip_sockemit
;

\ _ip_sockfkey ( -- c1 t/f ) get a character from the current socket
: _ip_sockfkey
\							\ is there a character ready
	_ip_rxcount W@ 0>
	if
\							\ address of the next byte to be read
		_ip_rxoffset W@ _sockbufmask and _ip_rxbuf +
\							\ read the byte, true on the stack
		_ip_rdbyte -1
\							\ increment _ip_rxoffset
		1 _ip_rxoffset W+!
\							\ decrement _ip_rxcount			
		-1 _ip_rxcount W+!
		_ip_rxcount W@ 0=
		if
\							\ no more characters, to a recv command to the socket, see wiznet manual
			_ip_rxoffset W@ _ip_srx_rd!
			_ip_sc_recv _ip_scr!
		then
	else
		0 0 
	then
;

\ _ip_sockkey ( -- c1 ) c1 - 0 returned if there is no available character from the socket
: _ip_sockkey
	_ip_sockfkey 
	drop
;


\ _ip_k ( -- cnt )
: _ip_k

	0 _sockbufsize _ip_txoffset W@ _sockbufmask and - h100 min

	_ip_fkey?
	if
[ifdef ip_debug
		ip_debug W@ h4 and
		if
			7lock
			c" ~h0D001 " .concstr
			dup .conemit
			c"  _ip_txoffset _ip_txcount: " .concstr
			_ip_txoffset W@ .con _ip_stx_wr@ .con _ip_txcount W@ .con
			.const?
			7unlock
		then
]
		_ip_txoffset W@
		_sockbufmask and _ip_txbuf +
		_ip_wrbyte
		swap 1+ swap 1- 0
		do
			_ip_fkey?
			if
[ifdef ip_debug
				ip_debug W@ h4 and
				if
					7lock
					c" ~h0D002 " .concstr
					dup .conemit
					c"  " .concstr
					.const?
					7unlock
				then
]
				a__ip_wrdr
				1+
			else
				drop leave
			then
		loop
		dup _ip_txcount W+!
		dup _ip_txoffset W+!
[ifdef ip_debug
		ip_debug W@ h4 and
		if
			7lock
			c" ~h0D001 " .concstr
			dup .conemit
			c"  _ip_txoffset _ip_txcount: " .concstr
			_ip_txoffset W@ .con _ip_stx_wr@ .con _ip_txcount W@ .con
			.const?
			7unlock
		then
]
	else
		2drop
	then
;

\ _ip_keytosock ( -- ) get the characters coming from the io channel and send them to the socket
: _ip_keytosock

	_ip_k
	if
		_ip_k
	else
		0
	then

	if
		0 _ip_txloop C!
		_ip_txcount W@ _ip_txbuffersize >
		if
\						\ send the characters out
			_ip_dosend
		then
	else
		_ip_txloop dup C@ 1+ dup rot C!
		ip_txlooplimit >
		if
\							\ we have gone through this loop xx times, no new chars, do a send
			_ip_dosend
			0 _ip_txloop C!
		then
	then
;

\ _ip_keydrop ( -- ) get the characters coming from the io channel and throw them away
: _ip_keydrop
	h100 0
\							\ process up to 256 characters
	do
		_ip_fkey?
		0=
		if
			leave
		then
		drop
	loop
;

\ _ip_sockclose ( -- ) this is a hard close, see wiznet manual
: _ip_sockclose
	_ip_sc_close _ip_scr!
	_ip_initialized _ip_connected or
	_ip_sockstatus andnW!
;

\ _ip_sockdiscon ( -- )
: _ip_sockdiscon
	_ip_sockstatus W@ _ip_connected and
	if
\							\ we are connected, do a disconnect
		_ip_sc_discon _ip_scr!
	else
\							\ not connected, just close
		_ip_sockclose
	then
;

\ ( c -- flag )
: _ip_telnetin_1
	dup hFF = over h4 = or over 0= or
	if
		dup 0=
		if
			drop
			0
		else
\							\ sent by teraterm after a CR if transmit mode is CR instead of CR+LF
			dup hFF =
			if
				drop
\ FF - IAC
\ FE - DONT
\ FD - DO
\ FC - WONT
\ FB - WILL
\ 01 - Echo
\ 03 - Supress goahead

				_ip_sockkey 8 lshift _ip_sockkey or
\ 7lock c" IAC RECEIVED " .concstr dup base W@ swap hex .conword base W! 7unlock

\ WILL Supress goahed -> DO Supress goahead
				dup hFB03 = if drop hFD03 else
\ DO Supress goahead -> WILL Supress goahead 
				dup hFD03 = if drop hFB03 else
\ DO Echo -> WILL Echo
\				dup hFD01 = if drop hFC01 else
				dup hFD01 = if drop hFB01 else
\ DONT and WONT for everything else
				dup hFF00 and hFC00 = if hFF and hFE00 or else
				dup hFF00 and hFE00 = if hFF and hFC00 or else
				drop 0
				then then then then then
\ 7lock dup base W@ swap hex .conword .concr base W! 7unlock
				dup
				if
					dup hFF and swap h8 rshift  _ip_iacresp
				then
				0
			else
				dup h4 =	\ diconnect on a CTL-D
				if
					drop
					_ip_sockcr _ip_sockcr
					c" DISCONNECT" _ip_sockcstr
					_ip_sockcr _ip_sockcr
					_ip_dosend
					_ip_sockdiscon
					-1
				then
			then
		then
	else
		_ip_emit 0
	then
;

	

\ _ip_telnetin ( -- ) process any characters we have received and deal with the telnet protocol
: _ip_telnetin
	h100 0 do
\							\ keys from the io channel, since the cog echos chars for input
		_ip_keytosock
\							\ is the io channel is ready to accept a character
		_ip_emit?
		if
\							\ and there is a character ready from the socket
			_ip_sockfkey
			if
				_ip_telnetin_1
				if
					leave
				then
\							\ FF followed by 2 bytes is a telnet control sequence, process
			else
				drop
				leave
			then
		else
			leave
		then
	loop
;


\ _ip_si ( -- cnt )
: _ip_si

	0 _sockbufsize _ip_rxoffset W@ _sockbufmask and - h100 min _ip_rxcount W@ min
\ ( sendcount maxcount -- )
	dup 0>
	if
\							\ is the io channel is ready to accept a character
		_ip_emit?
		if
\							\ and there is a character ready from the socket
\							\ address of the next byte to be read
			_ip_rxoffset W@ _sockbufmask and _ip_rxbuf +
			a__ip_wridm
			0
			do
				_ip_emit?
				if
					a__ip_rddr
\ dup h80 and if  base W@ swap hex h7lock .con .concr 7unlock base W! else _ip_emit then
					_ip_emit
					1+
				else
					leave
				then
			loop
		else
			drop
		then
\							\ increment _ip_rxoffset
		dup _ip_rxoffset W+!
\							\ decrement _ip_rxcount			
		dup negate _ip_rxcount W+!

		_ip_rxcount W@ 0=
		if
\							\ no more characters, to a recv command to the socket, see wiznet manual
			_ip_rxoffset W@ _ip_srx_rd!
			_ip_sc_recv _ip_scr!
[ifdef ip_debug
			ip_debug W@ h100 and if _ip_socketstatus then
]
		then
	else
		drop
	then
;

: _ip_sockin
	_ip_si

\ dup 0<> if 7lock dup .con .concr 7unlock then
	if
		_ip_si
\ dup 0<> if 7lock dup .con .concr 7unlock then
		drop
	then	
;


\ _ip_int ( n1 -- n1 ) n1 - the socket number
: _ip_int
\						\ send interrupt
	dup _ip_irsend_ok and
	if
		_ip_irsend_ok _ip_sir!
	else
\						\ timeout
		dup _ip_irtimeout and
		if
			_ip_irtimeout _ip_sir!
			_ip_sockclose
		else
\						\ disconnect request from the other side
			dup _ip_irdiscon and
			if
				_ip_irdiscon _ip_sir!
				_ip_sockclose
			then
		then
	then
;

\ _ip_server ( n1 -- ) n1 - the socket number 0 - 3
: _ip_server

[ifdef ip_debug
	ip_debug W@ h10 and if d_222_000_000 _ip_socketstatus drop then
]

	_ip_sockstatus W@ _ip_initialized and 0=
	if
\									\ not initialized
\									\ throw away any chars from the cog
		_ip_keydrop

[ifdef ip_debug
		ip_debug W@ h10 and if d_222_111_000 _ip_socketstatus drop then
]
		_ip_listenport W@
		if
\									\ we have a listen port, we are a server
[ifdef ip_debug
			ip_debug W@ h10 and if d_222_222_000 _ip_socketstatus drop then
]
			_ip_sockstatus W@ _ip_serverconnect and
			if
\									\ reset the connect once bit
[ifdef ip_debug
				ip_debug W@ h10 and if d_222_333_000 _ip_socketstatus drop then
]
				_ip_serverconnectonce _ip_sockstatus andnW!
\									\ connect the socket io to the cog
\									\ set mode register to tcp, no delayed ack
				b_0010_0001 _ip_smr!
\									\ set port
				_ip_listenport W@ _ip_sport!
\									\ open command, make sure status is at init
				_ip_sc_open _ip_scr!
 				_ip_ssr@ _ip_sr_init <> 
				if
					_ip_sockclose
				then
\									\ issue a listen command, check status
				_ip_sc_listen _ip_scr!

				_ip_ssr@ _ip_sr_listen <> 
				if
					_ip_sockclose
				then

				_ip_initialized _ip_sockstatus orW!
[ifdef ip_debug
				ip_debug W@ h10 and if d_222_333_999 _ip_socketstatus drop then
]
			then
[ifdef ip_debug
			ip_debug W@ h10 and if d_222_222_999 _ip_socketstatus drop then
]
		else
\										\ use as a client
[ifdef ip_debug
			ip_debug W@ h10 and if d_222_444_000 _ip_socketstatus drop then
]
			_ip_destport W@ 0<> _ip_destipaddr L@ 0<> and
			if
[ifdef ip_debug
				ip_debug W@ h10 and if d_222_555_000 _ip_socketstatus drop then
]
				_ip_sockstatus W@ _ip_clientconnect and
				if
\										\ reset the connect once bit
[ifdef ip_debug
					ip_debug W@ h10 and if d_222_666_000 _ip_socketstatus drop then
]
					_ip_clientconnectonce _ip_sockstatus andnW!
\										\ connect the socket io to the cog
\										\ set mode register to tcp, no delayed ack
					b_0010_0001 _ip_smr!

					_ip_destport W@ _ip_sdport!
					_ip_destipaddr L@ _ip_sdipr!

					_ip_sc_connect _ip_scr!				
					_ip_initialized _ip_sockstatus orW!
				then
			then
		then
		_ip_sir@
\								\ process timeout, discon, and send_ok interrupts
		_ip_int
		drop
[ifdef ip_debug
		ip_debug W@ h10 and if d_222_111_999 _ip_socketstatus drop then
]
	else
[ifdef ip_debug
		ip_debug W@ h10 and if d_222_777_000 _ip_socketstatus drop then
]
\								\ we are initialized
		_ip_sockstatus W@ _ip_connected and 0=
		if
\								\ we are not connected
\								\ throw away any chars from the cog
			_ip_keydrop
\								\ not connected, check for a remote connection request
			_ip_sir@ dup _ip_ircon and
			if
				0 _ip_rxcount W!
				0 _ip_txcount W!

				_ip_stx_wr@ _ip_txoffset W!

				_ip_sockstatus W@ _ip_telnetprotocol and
				if
\								\ send a control sequence saying will echo
\					1 hFC _ip_iacresp
					1 hFB _ip_iacresp
\								\ send a control sequence saying will suppress go ahead
					h3 hFB _ip_iacresp

					_ip_dosend

					_ip_sockcr
					version W@ _ip_sockcstr
					_ip_sockcr
				then

				_ip_ircon _ip_sir!
				_ip_connected _ip_sockstatus orW!
				_ip_sdport@ _ip_destport W!
				_ip_sdipr@ _ip_destipaddr L!
			else
\								\ process timeout, discon, and send_ok interrupts
				_ip_int
			then
			drop
		else
\								\ we are connected
			_ip_sockstatus W@ _ip_telnetprotocol and
			if
\								\ process chars we have received
				_ip_telnetin
			else
				_ip_sockin
			then
\								\ keys from the io channel to the socket	
			_ip_keytosock
			_ip_sir@
\								\ if there are unread characters still in the socket
\								\ suppress another read interrupt	
			_ip_rxcount W@ 0>
			if
				_ip_irrecv andn
				_ip_sockstatus W@ _ip_deferdiscon and
				if
\								\ supress the disconnect interrupt as we have more to read
					_ip_irdiscon andn
				then
[ifdef ip_debug
			else
				ip_debug W@ h8 and if _ip_socketstatus then

]
			then

\								\ process only one interrupt per pass
			dup _ip_irrecv and
			if
\								\ receive interrupt
				_ip_irrecv _ip_sir!
				_ip_srx_rsr@ _ip_rxcount W!
				_ip_srx_rd@ _ip_rxoffset W!
			else
\								\ process timeout, discon, and send_ok interrupts
				_ip_int
			then
			drop
		then
[ifdef ip_debug
		ip_debug W@ h10 and if d_222_000_999 _ip_socketstatus drop then
]
	then
;


\ _ip_processsockreq ( c1 -- )
: _ip_processsockreq
	dup 1 = if
		_ip_sockdiscon
	else dup h2 = if
		_ip_telnetprotocol _ip_sockstatus andnW!
	else dup h3 = if
		_ip_telnetprotocol _ip_sockstatus orW!
	else dup h4 = if
		_ip_serverconnectonce _ip_sockstatus andnW!
	else dup h5 = if
		_ip_serverconnectonce _ip_sockstatus orW!
	else dup h6 = if
		_ip_serverconnect _ip_sockstatus andnW!
	else dup h7 = if
		_ip_serverconnect _ip_sockstatus orW!
	else dup h8 = if
		_ip_clientconnectonce _ip_sockstatus andnW!
	else dup h9 = if
		_ip_clientconnectonce _ip_sockstatus orW!
	else dup hA = if
		_ip_clientconnect _ip_sockstatus andnW!
	else dup hB = if
		_ip_clientconnect _ip_sockstatus orW!
	else dup hC = if
		_ip_deferdiscon _ip_sockstatus andnW!
	else dup hD = if
		_ip_deferdiscon _ip_sockstatus orW!
	else dup hE = if
		_ip_sockclose
	else dup h10 = if
		_ip_dosend
	else dup h11 = if
		_ip_rxcount W@ dup
		if
\						\ flush any characters we have not yet accepted from the socket
			_ip_rxoffset W+!
			0 _ip_rxcount W!
			_ip_rxoffset W@ _ip_srx_rd!
			_ip_sc_recv _ip_scr!
		else
			drop
		then
	else dup h12 = if
		_ip_noexpandcr _ip_sockstatus andnW!
	else dup h13 = if
		_ip_noexpandcr _ip_sockstatus orW!
	thens

	drop

	0 _ip_sockreq C!
;


\ ip_server (  -- )
: ip_server
\
	ip_init
\					\ 1 to n channels
	_ipnumsock
\				 	\ number of io channels
	1- h5 lshift h10 or state C!
	4 state andnC!
	c" IP SERVER" cds W!
	begin
		_ipnumsock 0
		do
			i dup _ip_currsocket
			_ip_sockreq C@ dup
			if
				_ip_processsockreq
			else
				drop
			then
[ifdef ip_debug
			ip_debug W@ 1 and if ip_socketstatus then
			ip_debug W@ h80 and if _ip_socketstatus then
]
			_ip_server
[ifdef _ip_light
			cnt COG@ h800000 and 0= h17 dup pinout px
] 
			drop
		loop
		0
	until 
;


: lecho h18 state orC! 2 cogid ip_SOCKsendreq drop ;

: cecho h18 state andnC! 3 cogid ip_SOCKsendreq drop ;

{

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




}





...

