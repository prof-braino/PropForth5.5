hA state orC!
1 wconstant build_IP


lockdict create a__ip_rddr forthentry
$C_a_lxasm w, h124  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV04S l, zDv0 l, zDyy l, z5v0 l, z4S0 l, z5j0 l, z5n0 l, z1G0 l, 
z5r0 l, z1SyJQL l, z2Wix[M l, z2WixnK l, z2Wix[N l, z2WyPRy l, z1WiPVl l, z2Wix[O l, 
z1SV01X l, 
freedict




lockdict create a__ip_wridm forthentry
$C_a_lxasm w, h12C  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV04S l, zDv0 l, zDyy l, z5v0 l, z4S0 l, z5j0 l, z5n0 l, z1G0 l, 
z5r0 l, z2WiPZB l, zbyPW8 l, z1WyPZy l, z1biP[P l, z2WixZC l, z2WixnL l, z1[iP[Q l, 
z2WixZC l, z1WyPRy l, z1biPSR l, z2WixZB l, z1[iPSQ l, z2WixZB l, z1SyLI[ l, z2Wix[O l, 
z1SV01X l, 
freedict




lockdict create a__ip_wrdr forthentry
$C_a_lxasm w, h125  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV04S l, zDv0 l, zDyy l, z5v0 l, z4S0 l, z5j0 l, z5n0 l, z1G0 l, 
z5r0 l, z1WyPRy l, z1biPSM l, z2WixZB l, z2WixnL l, z1[iPSQ l, z2WixZB l, z1SyLI[ l, 
z2Wix[O l, z1SV01X l, 
freedict




lockdict create a__ip_fkeyq forthentry
$C_a_lxasm w, h123  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z2WiPeB l, z4iPmD l, z2WiPRE l, z1SyJQL l, z1YVPS0 l, z1riPR6 l, z1SL01X l, 
z26VPjD l, z20tPWQ l, z4dPuC l, z1YQPv0 l, z2WoPn0 l, z2WtPjA l, z4FPmD l, z1SV01X l, 

freedict




lockdict create a__ip_emitq forthentry
$C_a_lxasm w, h11B  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z20yPO2 l, z6iPZB l, z1rdPR6 l, z1SQ01Z l, z4iPRC l, z1YyPS0 l, z1viPR6 l, z1SV01X l, 

freedict




lockdict create a__ip_emit forthentry
$C_a_lxasm w, h120  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z20yPO2 l, z6iPZB l, z1SL04P l, z1SyLI[ l, z1SyLI[ l, z1SV01X l, z4iPRC l, z1YyPS0 l, 
z1SQ04P l, z1SyLI[ l, z4FPRC l, z1SyLI[ l, z1SV01X l, 
freedict


\
\ a tcpip server for the spinneret
\ or similar configurations
\ Status: Release 2012JUN-14
\
\
\
c" IP Loading 1 " .cstr
\						\ uncomment this if debug is needed
\ 1 wconstant ip_debug
\
\
\ IP & TELNET CONFIG PARAMETERS BEGIN
\
\


\
\
\ This set of constants may be redefined in the spin file
\
\ If true, pulse the led on IO23 when the ip service is running
[ifndef $S_ip_light
-1 wconstant $S_ip_light
]
\
\ This defines the cog which will be used to run the ip service
[ifndef $S_ip_cog
5 wconstant $S_ip_cog
]
\
\ These constants configure the number of ip channels and the
\ buffer allocation in the W5100
\
\ h2000		wconstant $S_ip_sockbufsize
\ h1FFF		wconstant $S_ip_sockbufmask
\ h_03		wconstant $S_ip_sockbufinit
\ 1		wconstant $S_ip_numsock

\ h1000		wconstant $S_ip_sockbufsize
\ hFFF		wconstant $S_ip_sockbufmask
\ h_0A		wconstant $S_ip_sockbufinit
\ 2		wconstant $S_ip_numsock

[ifndef $S_ip_sockbufsize
h800 		wconstant $S_ip_sockbufsize
]
[ifndef $S_ip_sockbufmask
h7FF		wconstant $S_ip_sockbufmask
]
[ifndef $S_ip_sockbufinit
h_55		wconstant $S_ip_sockbufinit
]
[ifndef $S_ip_numsock
4		wconstant $S_ip_numsock
]
\
\
\ The number of telnet sockets to start
\
[ifndef $S_ip_numTelnet
$S_ip_numsock	wconstant $S_ip_numTelnet
]
\
\
\ port 23 is the standard telnet port
\ up to 4 consecutive ports will be used
\ int this case 3020 - 3024
\
[ifndef $S_ip_telnetport
d_3020		wconstant	$S_ip_telnetport
]
\
\ The gateway parameter is necessary for the client protocols, to route through for internet requests.
\
\						\ 192.168.0.1
[ifndef $S_ip_gatewayhi
h_C0_A8	wconstant	$S_ip_gatewayhi
]
[ifndef $S_ip_gatewaylo
h_00_01	wconstant	$S_ip_gatewaylo
]
\
						\ 255.255.255.0
[ifndef $S_ip_subnetmaskhi
h_FF_FF	wconstant	$S_ip_subnetmaskhi
]
[ifndef $S_ip_subnetmasklo
h_FF_00	wconstant	$S_ip_subnetmasklo
]
\
\ The mac address is on the bottom of the spinneret board
\
\						\ 00:0c:29:8b:00:70
[ifndef $S_ip_machi
h_00_0C	wconstant	$S_ip_machi
]
[ifndef $S_ip_macmid
h_29_8B	wconstant	$S_ip_macmid
]
[ifndef $S_ip_maclo
h_00_70	wconstant	$S_ip_maclo
]
\						\ 192.168.0.129
[ifndef $S_ip_addrhi
h_C0_A8	wconstant	$S_ip_addrhi
]
[ifndef $S_ip_addrlo
h_00_81	wconstant	$S_ip_addrlo
]
2 .
\
\
\ The followinf constants cannot be changed in the spin file.
\ Normally they are only changed during debugging 
\
\
\ Reasonable values are between 2 - 32, the response of the output to a telnet session will change with this
\
\						\ the number of loops with no characters sent to the
\						\ socket before the buffer is sent
[ifndef ip_txlooplimit
h8		wconstant	ip_txlooplimit
]

\						\ the number of characters buffered by the socket
\						\ before it is sent
\						\ 16 - 1024 are reasonable values
\						\ 1 is the minimum value
\						\ the size should not exceed the buffer size defined by
\						\ _sockbufsize
\						\ because of how the comparison is done, the value is the
\						\ buffer size - 1 
[ifndef _ip_txbuffersize
h400 1-		wconstant	_ip_txbuffersize
]

\
\
\ IP & TELNET CONFIG PARAMETERS END
\


[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]

[ifndef $C_a_doconl
    h52 wconstant $C_a_doconl
]

\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[ifndef variable
: variable lockdict create $C_a_dovarl w, 0 l, forthentry freedict ;
]

\ constant ( x -- ) skip blanks parse the next word and create a constant, allocate a long, 4 bytes
[ifndef constant
: constant lockdict create $C_a_doconl w, l, forthentry freedict ;
]

\
\
\ pinout ( n1 -- ) set pin # n1 to an output
[ifndef pinout
: pinout
	>m dira COG@ or dira COG!
;
]
\
\
\ pinlo ( n1 -- ) set pin # n1 to lo
[ifndef pinlo
: pinlo
	>m _maskoutlo
;
]
\
\
\ pinhi ( n1 -- ) set pin # n1 to hi
[ifndef pinhi
: pinhi
	>m _maskouthi
;
]
\
\
\ px ( t/f n1 -- ) set pin # n1 to h - true or l false
[ifndef px
: px
	swap
	if 
		pinhi
	else
		pinlo
	then
;
]

\
\
\ orW! ( w1 addr -- ) or w1 with the contents of address
[ifndef orW!
: orW!
	dup W@ rot or swap W!
;
]
\
\
\ andnW! ( w1 addr -- ) and inverse of w1 with the contents of address
[ifndef andW!
: andnW!
	dup W@ rot andn swap W!
;


[ifdef ip_debug
\ a variable used for turning on and off debugging
wvariable ip_debug 1 ip_debug W!
]

3 .

\ the base address of the socket structures
0			wconstant	_ip_socketbase
' _ip_socketbase 2+	wconstant	_ip_socketbaseaddr

\
\ These variables in the structure should only be written by the cog running the _ip_ipserver
\ They can be read by any cog
\
\ the current socket structure pointer
0			wconstant	_ip_socketdata
' _ip_socketdata 2+	wconstant	_ip_socketdataaddr

\ io channels which the sockets connect to
io 			wconstant	_ip_sockio
' _ip_sockio 2+ 	wconstant 	_ip_sockioaddr

\ the base address for the socket registers (word)
\ this is assumed to be the first word in the structure by _ip_initsocketdata
: _ip_sbase		_ip_socketdata W@ ;

\ the base address for the w5100 transmit buffers (word)
\ this is assumed to be the second word in the structure by _ip_initsocketdata
: _ip_txbuf		_ip_socketdata h2 + W@ ;

\ the base address for the w5100 receive buffers (word)
\ this is assumed to be the third word in the structure by _ip_initsocketdata
: _ip_rxbuf		_ip_socketdata h4 + W@ ;

\ the count of characters that have been written to the socket, but not yet sent (word)
: _ip_txcount		_ip_socketdata h6 + ;

\ the offset to write the next character to the socket (word)
: _ip_txoffset		_ip_socketdata h8 + ;

\ the number of times we have been through without a character going out to the w5100, sort of a timeout counter (char)
: _ip_txloop		_ip_socketdata hA + ;

\
\ free char at hB
\

\ the number of characters received in the last packet received from the w5100 (word)
: _ip_rxcount		_ip_socketdata hC + ;

\ the offset of the characters in the last packet received from the w5100 (word)
: _ip_rxoffset		_ip_socketdata hE + ;

\ used for debugging, the last socket status and interrupts (char)
[ifdef ip_debug
: _ip_lastsocketstatus	_ip_socketdata h10 + ;
]
\
\ a request send to the socket
: _ip_sockreq		_ip_socketdata h11 + ;
\
\ 
\ These structure members may be updated by any cog
\
\ if _ip_listenport is not 0, start listening on this port (word)
: _ip_listenport	_ip_socketdata h12 + ;

\  the ip address of the remote client (long)
: _ip_destipaddr		_ip_socketdata h14 + ;

\ the socket on the remote client (word)
: _ip_destport		_ip_socketdata h18 + ;	

\ socket state, whether or not we have connected etc (word)
: _ip_sockstatus		_ip_socketdata h1A + ;

4 .

h1C		wconstant	_ip_socketdatasize

\
\ constants for _ip_socket status word
1 wconstant _ip_initialized
h2 wconstant _ip_connected
h4 wconstant _ip_deferdiscon
h8 wconstant _ip_telnetprotocol
h10 wconstant _ip_serverconnectonce
h30 wconstant _ip_serverconnect
h40 wconstant _ip_clientconnectonce
hC0 wconstant _ip_clientconnect
h100 wconstant _ip_noexpandcr


\ 00 00 - ready for command, only write this when it is ready, once the command has been accepted it is set back to ready
\ 01 01 					disconnect/reset the socket
\ 02 02 - _ip_telnetprotocol		off	raw bytes in and out
\ 03 03 - _ip_telnetprotocol		on	watch for the telnet commands and process them
\ 04 04 - _ip_serverconnectonce		off	run as a server, but only allow one connection, then go idle
\ 05 05 - _ip_serverconnectonce		on
\ 06 06 - _ip_serverconnect		off	run as a server, after a disconnect accept another connection
\ 07 07 - _ip_serverconnect		on
\ 08 08 - _ip_clientconnectonce		off	run as a client, after a disconnect go idle
\ 09 09 - _ip_clientconnectonce		on
\ 10 0A - _ip_clientconnect		off	run as a client, after a disconnect attempt another connection
\ 11 0B - _ip_clientconnect		on
\ 12 0C - _ip_deferdiscon		off	do not process disconnect if we have more chars to read from the socket
\ 13 0D - _ip_deferdiscon		on
\ 14 0E						do a hard close on the socket, and reset
\ 15 0F - NOP
\ 16 10 - OUTPUT FLUSH				send all characters to the socket
\ 17 11 - INPUT FLUSH				drop all the characters received from the socket
\ 18 12 - _ip_noexpandcr		off	expand cr to crlf when writing to the w5100
\ 19 13 - _ip_noexpandcr		on	do not expand cr to crlf when writing to the w5100
\
\ -1 -1 - end of command sequence, required at the end of a multiple command sequence

\
\ These words should be used by other cogs to interface
\

\ ip_SOCKstruct ( n1 -- addr ) returns the address of the structure for the socket n1 
: ip_SOCKstruct 3 and _ip_socketdatasize u* _ip_socketbase + ;

\ ip_SOCKsendreq ( n1 n2 -- t/f) send command n1 to socket n2, true if successful
: ip_SOCKsendreq
\						\ check for a valid socket
	2dup 0 h3 between
\						\ check to make sure we have a valid command
	swap 0 h13 between and
	if
\						\ assume failure
		0 rot2
\						\ address of _ip_sockreq
		ip_SOCKstruct h11 +
		h400 0
\						\ 1024 tries 1 msec delay				
		do
			dup C@ 0=
			if
\						\ _ip_sockreq ready for a command
				2dup C!
				rot drop -1 rot2 
				leave
			then 
			1 delms
		loop
		2drop
	else
\						\ invalid command 
		2drop 0
	then
;

\ ip_SOCKsendmultiplereq ( -1 cmd1 ... cmdn socket -- t/f ) send commands to socket until -1 is encounterd
: ip_SOCKsendmultiplereq
	-1 >r
	begin
		over -1 =
		if
			-1
		else
			2dup ip_SOCKsendreq
			r> and >r
			nip
			0
		then
	until
	2drop
	r>
;

\ ip_SOCKlistenport ( n1 -- addr ) address of the listen port for socket n1
: ip_SOCKlistenport ip_SOCKstruct h12 + ;	

\ ip_SOCKdestipaddr ( n1 -- addr ) address of the destination ip address for socket n1
: ip_SOCKdestipaddr ip_SOCKstruct h14 + ;	

\ ip_SOCKdestport ( n1 -- addr ) address of the destination port for socket n1
: ip_SOCKdestport ip_SOCKstruct h18 + ;	

\ ip_SOCKstatus@ ( n1 -- n2 ) the status word for socket n1
: ip_SOCKstatus@ ip_SOCKstruct h1A + W@ ;	

\ ip_SOCKreset ( n1 -- t/f) reset socket n1, true if successful
: ip_SOCKreset
\ telnet protocol off, server connect once off, server connect off
\ client connect once off, client connect off, defer disconnect off, noexpandcr off,  reset
	>r -1 h0F h0F h0E h12 h0C h0A h08 h06 h04 h02 r> dup >r ip_SOCKsendmultiplereq r> swap
	if
		ip_SOCKstatus@ 0=
	else
		drop
		0
	then
;
5 .

\ ip_SOCKtelnet ( n1 -- ) n1 - the socket/cog to restart as a telnet socket
: ip_SOCKtelnet
	dup 0 $S_ip_numsock 1- between
	if
		$S_ip_cog over dup 0
		(ioconn)
\							\ reset the socket
		dup ip_SOCKreset drop
\							\ reset the cog
		dup cogreset h80 delms
\							\ set the port
		dup $S_ip_telnetport + over ip_SOCKlistenport W!
\ 							\ telnet protocol on, noexpandcr off, server connect on
		>r -1 h07 h12 h03 r> ip_SOCKsendmultiplereq

\		drop
\	else
\		drop
	then
	drop
;




\
\ we will use the current cog's pad less the first 4 bytes, which are used for the 4th io channel
\ for the socket structures, the pad is 128 bytes, so 124/4 and it must be long aligned,
\ thus 28 max (1C hex)

\ _ip_currsocket ( n1 -- ) sets the pointers to point to the current socket's variables
: _ip_currsocket
\ update the socket address
	h3 and dup 4* io + _ip_sockioaddr W!
\ the structure address
	_ip_socketdatasize u* _ip_socketbase +
	_ip_socketdataaddr W!
;

: _ip_initsocketdata
\ since we have 4 io channels, socket data should start 16 bytes in, this means 116 bytes are of the pad is available
\ so the max size for the socket structure should be 29 bytes or h1D
	io h10 + _ip_socketbaseaddr W!
	io _ip_socketdatasize 4* h10 + 0  fill
	h4 0
	do
		i _ip_currsocket
		i h8 lshift h400 + _ip_socketdata W!

		i $S_ip_sockbufsize u* h4000 + dup _ip_socketdata 2+ W!
		h2000 + _ip_socketdata 4+ W!
	loop
;

\
\ See wiznet manual for descriptions of these registers
\ 
\ common mode registers
h1  wconstant _ip_gar	\ gateway address register (long)
h5  wconstant _ip_subr	\ subnet mask register (long)
h9  wconstant _ip_shar	\ source hardware address register (word + long)
hF  wconstant _ip_sipr	\ source ip address address register (long)
h1A wconstant _ip_rmsr	\ receive memory size (byte)
h1B wconstant _ip_tmsr	\ transmit memory size (byte)

\ socket registers
\		 		\ socket mode register (byte)
: _ip_smr	_ip_sbase ;
\				\ socket command register (byte)
: _ip_scr	_ip_sbase 1+ ;
\				\ socket interrupt register (byte)
: _ip_sir	_ip_sbase 2+ ;
\				\ socket status register (byte)
: _ip_ssr	_ip_sbase h3 + ;
\				\ socket source port register (word)
: _ip_sport _ip_sbase 4+ ;
\				\ socket destination hardware address register (word + long)
: _ip_sdhar _ip_sbase h6 + ;
\				\ socket destination ip address register (long)
: _ip_sdipr _ip_sbase hC + ;
\				\ socket destination ip port register (word)
: _ip_sdport _ip_sbase h10 + ;
\				\ socket transmit free size register (word)
: _ip_stx_fsr _ip_sbase h20 + ;
\				\ socket transmit read pointer register (word)
: _ip_stx_rd _ip_sbase h22 + ;
\				\ socket transmit write pointer register (word)
: _ip_stx_wr _ip_sbase h24 + ;
\				\ socket receive size register register (word)
: _ip_srx_rsr _ip_sbase h26 + ;
\				\ socket receive read pointer register (word)
: _ip_srx_rd _ip_sbase h28 + ;

6 .

\ socket sr (status) constants
\ socksr values
0  wconstant _ip_sr_closed
h13 wconstant _ip_sr_init
h14 wconstant _ip_sr_listen
h17 wconstant _ip_sr_sock_established
h1C wconstant _ip_sr_close_wait
\ h22 wconstant _ip_sr_udp
\ h32 wconstant _ip_sr_ipraw
\ h42 wconstant _ip_sr_ipmacraw

\ socket ir (interrupt) constants
1  wconstant _ip_ircon
h2  wconstant _ip_irdiscon
h4  wconstant _ip_irrecv
h8  wconstant _ip_irtimeout
h10 wconstant _ip_irsend_ok

\ sock sc (command) constants
1  wconstant _ip_sc_open
h2  wconstant _ip_sc_listen
h4  wconstant _ip_sc_connect
h8  wconstant _ip_sc_discon
h10 wconstant _ip_sc_close
h20 wconstant _ip_sc_send
\ h21 wconstant _ip_sc_sendmac
h22 wconstant _ip_sc_sendkeep
h40 wconstant _ip_sc_recv


\ _ip_wrmr ( c1 -- ) write the mode register
: _ip_wrmr
	hDFFF dira COG!
	hFF and h5C00 or dup outa COG!
	h1400 andn outa COG!
	h5C00 outa COG!
;

{
\
\ non assembler routines, here for reference and debugging
\
\ a__ip_rddr ( -- c1 ) read the indirect bus data register
: a__ip_rddr
	hDF00 dira COG!
	h5F00 dup outa COG!
	h1800 andn outa COG!
	ina COG@
	h5C00 outa COG!
	hFF and
;

\ a__ip_wridm ( n1 -- ) n1 - a 16 bit value to write to the indirect bus address registers
: a__ip_wridm
	hDFFF dira COG!
	dup h8 rshift hFF and
	h5D00 or dup outa COG! h1400 andn outa COG!
	hFF and
	h5E00 or dup outa COG! h1400 andn outa COG!
	h5C00 outa COG!
;

\ a__ip_wrdr ( c1 -- ) write the indirect bus data register
: a__ip_wrdr
	hDFFF dira COG!
	hFF and h5F00 or dup outa COG!
	h1400 andn outa COG!
	h5C00 outa COG!
;

\ _ip_emit? ( -- t/f) true if the io channel is ready for a char
: _ip_emit?
	_ip_sockio 2+ W@ dup
	if
		W@ h100 and 0<>
	else
		drop
		-1
	then
;

\ _ip_femit? (c1 -- t/f) true if the output emitted a char to the io channel, a fast non blocking emit
: _ip_femit?
	_ip_sockio 2+ W@ dup
	if
		dup W@ h100 and
		if
			swap hFF and swap W!
			-1
		else
			2drop
			0
		then
	else
		2drop
		-1
	then
;

\ _ip_emit ( c1 -- ) emit the char on the stack to the io channel
: _ip_emit
	begin
		dup _ip_femit?
	until
	drop
;


\ _ip_fkey? ( -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
: _ip_fkey?
	_ip_sockio W@ dup h100 and
	if
		0
	else
		h100
 		over hD =
		if
			_ip_sockstatus W@ _ip_noexpandcr and 0=
			if
				drop hA
			then
		then
		_ip_sockio W!
		-1
	then
;

}

7 .

\ _ip_rdbyte ( n1 -- n2) n1 - the register to read, n2 the data read
: _ip_rdbyte
	a__ip_wridm
	a__ip_rddr
;

\ _ip_rdword ( n1 -- n2 )  n2 - the word read from registers n1 & n1+1 
: _ip_rdword
	a__ip_wridm
	a__ip_rddr
	h8 lshift a__ip_rddr or
; 

\ _ip_rdlong ( n1 -- n2 )  n2 - the long read from registers n1, n1+1, n1+2, n1+3
: _ip_rdlong
	_ip_rdbyte
	h8 lshift a__ip_rddr or
	h8 lshift a__ip_rddr or
	h8 lshift a__ip_rddr or
; 

\ _ip_wrbyte ( n1 n2 --) n1 - the data to write, n2 - the register
: _ip_wrbyte
	a__ip_wridm
	a__ip_wrdr
;

\ _ip_wrword ( n1 n2 -- ) write the word n1 to registers n2 & n2+1 
: _ip_wrword
	over h8 rshift swap
	a__ip_wridm
	a__ip_wrdr
	a__ip_wrdr
; 

\ _ip_wrlong ( n1 n2 -- ) write the long n1 to registers n2, n2+1, n2+2, n2+3
: _ip_wrlong
	over h18 rshift swap 
	a__ip_wridm
	a__ip_wrdr
	dup h10 rshift a__ip_wrdr
	dup h8 rshift a__ip_wrdr
	a__ip_wrdr
; 

\ _ip_sXXX! ( n1 -- ) n1 - value
: _ip_smr! _ip_smr _ip_wrbyte ;
: _ip_scr! _ip_scr _ip_wrbyte ;
: _ip_sir! _ip_sir _ip_wrbyte ;
: _ip_ssr! _ip_ssr _ip_wrbyte ;
: _ip_sport! _ip_sport _ip_wrword ;
: _ip_sdipr! _ip_sdipr _ip_wrlong ;
: _ip_sdport! _ip_sdport _ip_wrword ;
: _ip_stx_wr! _ip_stx_wr _ip_wrword ;
: _ip_srx_rd! _ip_srx_rd _ip_wrword ;

\ _ip_sXXX@ ( -- n2 ) n1 - value
: _ip_smr@ _ip_smr _ip_rdbyte ;
: _ip_scr@ _ip_scr _ip_rdbyte ;
: _ip_sir@ _ip_sir _ip_rdbyte ;
: _ip_ssr@ _ip_ssr _ip_rdbyte ;
: _ip_sport@ _ip_sport _ip_rdword ;
: _ip_sdipr@ _ip_sdipr _ip_rdlong ;
: _ip_sdport@ _ip_sdport _ip_rdword ;
: _ip_stx_fsr@ _ip_stx_fsr _ip_rdword ;
: _ip_stx_rd@ _ip_stx_rd _ip_rdword ;
: _ip_stx_wr@ _ip_stx_wr _ip_rdword ;
: _ip_srx_rsr@ _ip_srx_rsr _ip_rdword ;
: _ip_srx_rd@ _ip_srx_rd _ip_rdword ;


: _ip_emit? _ip_sockio a__ip_emitq ;
: _ip_emit _ip_sockio a__ip_emit ;
: _ip_fkey? _ip_sockio _ip_socketdata a__ip_fkeyq ;


\ _ip_init ( -- ) reset the w5100, set to use indirect bus interface mode, address auto-increment
: _ip_init
	_ip_initsocketdata
	h1C00 outa COG!
	hDF00 dira COG!
	1 delms		\ pulse reset lo
	h5C00 outa COG!
	h3 _ip_wrmr	\ auto increment, indirect bus interface mode, see wiznet manual
	0 _ip_currsocket
;

\ ip_init ( -- ) initialize the ip parameters
: ip_init
	_ip_init
	$S_ip_sockbufinit	_ip_rmsr	_ip_wrbyte
	$S_ip_sockbufinit	_ip_tmsr	_ip_wrbyte

	$S_ip_gatewayhi $S_ip_gatewaylo w>l		_ip_gar		_ip_wrlong

	$S_ip_subnetmaskhi $S_ip_subnetmasklo w>l	_ip_subr	_ip_wrlong

	$S_ip_machi		_ip_shar	_ip_wrword

	$S_ip_macmid $S_ip_maclo w>l			_ip_shar 2+	_ip_wrlong
	$S_ip_addrhi $S_ip_addrlo w>l			_ip_sipr 	_ip_wrlong
;




[ifdef ip_debug

: 7lock 7 lock ;
: 7unlock 7 unlock ;

variable _ip_lastcnt


: _ip_sockstat1
	_ip_sir@ dup 0<> if
		hex
		c" INTERRUPTS: " .concstr dup .conbyte 
		dup 1  and if c"  CON     " .concstr then
		dup h2  and if c"  DISCON  " .concstr then
		dup h4  and if c"  RECV    " .concstr then
		dup h8  and if c"  TIMEOUT " .concstr then
		    h10 and if c"  SEND_OK " .concstr then
		decimal
	else
		c"                         " .concstr
		drop
	then
;

: _ip_sockstat2
	hex
	_ip_ssr@ c"  STATUS: " .concstr dup .conbyte
	dup 0= if   c"  SOCK_CLOSED     " .concstr else
	dup h13 = if c"  SOCK_INIT       " .concstr else
	dup h14 = if c"  SOCK_LISTEN     " .concstr else
	dup h17 = if c"  SOCK_ESTABLISHED" .concstr else
	dup h1C = if c"  SOCK_CLOSE_WAIT " .concstr else
	dup h22 = if c"  SOCK_UDP        " .concstr else
	dup h32 = if c"  SOCK_IPRAW      " .concstr else
	dup h42 = if c"  SOCK_MACRAW     " .concstr else
	dup h5F = if c"  SOCK_PPOE       " .concstr else
	dup h15 = if c"  SOCK_SYNSENT    " .concstr else
	dup h16 = if c"  SOCK_SYNRECV    " .concstr else
	dup h18 = if c"  SOCK_FIN_WAIT   " .concstr else
	dup h1A = if c"  SOCK_CLOSING    " .concstr else
	dup h1B = if c"  SOCK_TIME_WAIT  " .concstr else
	dup h1D = if c"  SOCK_LAST_ACK   " .concstr else
	dup h11 = if c"  SOCK_ARP        " .concstr else
	dup h21 = if c"  SOCK_ARP        " .concstr else
	dup h31 = if c"  SOCK_ARP        " .concstr else
		    c"                  " .concstr
	thens
	drop
	
	c"  SMR: " .concstr _ip_smr@  .conbyte
	c"    SCR: " .concstr _ip_scr@ .conbyte
	c"  SPORT: " .concstr _ip_sport@ .conword 
	c"    SDIPR: " .concstr _ip_sdipr@ dup h18 rshift hFF and .conbyte h2E .conemit 
		dup h10 rshift hFF and .conbyte  h2E .conemit dup h8 rshift hFF and .conbyte  h2E .conemit hFF and .conbyte
	c"  SDPORT: " .concstr _ip_sdport@ .conword .concr
	c"  TX_FSR: " .concstr _ip_stx_fsr@ .conword
	c"            TX_RD: " .concstr _ip_stx_rd@ .conword
	c"              TX_WR: " .concstr _ip_stx_wr@ .conword .concr
	c"  RX_RSR: " .concstr _ip_srx_rsr@ .conword
	c"            RX_RD: " .concstr _ip_srx_rd@ .conword .concr
	c"   RXoff: " .concstr _ip_rxoffset W@ .conword
	c"          RXcount: " .concstr _ip_rxcount W@ .conword .concr
	c"   TXoff: " .concstr _ip_txoffset W@ .conword
	c"          TXcount: " .concstr _ip_txcount W@ .conword
	c"         sockstatus: " .concstr _ip_sockstatus W@ .conword
	c"             TXLoop: " .concstr _ip_txloop C@ .conbyte
	.concr

	decimal

	c" SETTINGS:~h0D" .concstr
	c"     listenport: " .concstr _ip_listenport W@ .conword .concr
	c"       destsport: " .concstr _ip_destport W@ .conword .concr
	c"     destipaddr: " .concstr _ip_destipaddr L@
		dup h18 rshift	hFF and .conbyte h2E .conemit
		dup h10 rshift	hFF and .conbyte h2E .conemit
		dup  h8 rshift	hFF and .conbyte h2E .conemit
				hFF and .conbyte .concr
;

\ debugging info for current socket to the console
: _ip_socketstatus
	7lock
	.concr

	_ip_lastcnt dup

	L@ cnt COG@
	tuck
	dup .conlong bl .conemit
	swap -
\ ( addr newcount cntdiff -- )
	h3E8 um* clkfreq um/mod nip
	.conlong bl .conemit
	swap L!
	.const? base W@ _ip_sockstat1 _ip_sockstat2 .concr base W!
	7unlock
;

\ ip_socketstatus ( -- ) debugging info out if the _ip_sir or _ip_ssr registers have changed
: ip_socketstatus
	_ip_sir@ _ip_ssr@ xor _ip_lastsocketstatus
	2dup C@ <> rot2 C!
	if
\				\ information displayed only if _ip_sir or _ip_ssr registers have changed
		_ip_socketstatus
	then
;
]

8 .

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
	$S_ip_sockbufmask and _ip_txbuf + _ip_wrbyte
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
		_ip_rxoffset W@ $S_ip_sockbufmask and _ip_rxbuf +
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

	0 $S_ip_sockbufsize _ip_txoffset W@ $S_ip_sockbufmask and - h100 min

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
		$S_ip_sockbufmask and _ip_txbuf +
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

9 .

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

10 .

\ _ip_si ( -- cnt )
: _ip_si

	0 $S_ip_sockbufsize _ip_rxoffset W@ $S_ip_sockbufmask and - h100 min _ip_rxcount W@ min
\ ( sendcount maxcount -- )
	dup 0>
	if
\							\ is the io channel is ready to accept a character
		_ip_emit?
		if
\							\ and there is a character ready from the socket
\							\ address of the next byte to be read
			_ip_rxoffset W@ $S_ip_sockbufmask and _ip_rxbuf +
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

11 .

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

12 .

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
	$S_ip_numsock 1- numchan C!
\				 	\ number of io channels
	4 state andnC!
	c" IP SERVER" cds W!
	begin
		$S_ip_numsock 0
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

			$S_ip_light
			if
				cnt COG@ h800000 and 0= h17 dup pinout px
			then
 			drop
		loop
		0
	until 
;


: lecho h18 state orC! 2 cogid ip_SOCKsendreq drop ;

: cecho h18 state andnC! 3 cogid ip_SOCKsendreq drop ;

: startIp
	c" ip_server" $S_ip_cog cogx
;

: startTelnet
	startIp h_10 delms
	$S_ip_numTelnet 0 >
	if
		$S_ip_numTelnet 0
		do
			i ip_SOCKtelnet
		loop
	then
;

c" IP Loaded~h0D" .cstr







hA state andnC!
