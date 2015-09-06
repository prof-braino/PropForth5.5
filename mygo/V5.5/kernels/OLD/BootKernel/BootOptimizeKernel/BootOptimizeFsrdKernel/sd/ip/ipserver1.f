fl


mountsys

\
\
h100 fwrite ipserver1.f
\

\
\ a tcpip server for the spinneret
\ by default 4 sockets are started up as telnet
\ set the config parameters
\ load this file + part 2, do a saveforth, reboot, telnet away
\ Status: Alpha 2011-Feb-19
\
\
\
1 wconstant build_ipserver

[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
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

\
\
\ IP & TELNET CONFIG PARAMETERS BEGIN
\
\


\
\ The gateway parameter is necessary for the client protocols, to route through for internet requests.
\ These parameters may be defined in boot.f
\
\						\ 192.168.0.1
\ h_C0_A8_00_01	constant	ip_gateway
\						\ 192.168.23.1
[ifndef ip_gateway
h_C0_A8_17_01	constant	ip_gateway
]
\
						\ 255.255.255.0
[ifndef ip_subnetmask
h_FF_FF_FF_00	constant	ip_subnetmask
]
\
\ The mac address is on the bottom of the spinneret board
\
\						\ 00:0c:29:8b:00:70
[ifndef ip_machi
 h_00_0C	wconstant	ip_machi
 h_29_8B_00_70	constant	ip_maclo
]
\						\ 00:08:DC:16:EF:2D
\ h_00_08		wconstant	ip_machi
\ h_DC_16_EF_2D	constant	ip_maclo

\						\ 192.168.0.129
\ h_C0_A8_00_81	constant	ip_ipaddr
\						\ 192.168.23.129
[ifndef ip_ipaddr
h_C0_A8_17_81	constant	ip_ipaddr
]
\						\ 192.168.0.144
\ h_C0_A8_00_90	constant	ip_ipaddr

\
\						\ ports 23, 24, 25, 26, port 23 is the standard telnet port
\ h_17		wconstant	ip_telnetport
\						\ ports 2020, 2021, 2022, 2023
\ h_7E4		wconstant	ip_telnetport
\						\ ports 3020, 3021, 3022, 3023
[ifndef ip_telnetport
h_BCC		wconstant	ip_telnetport
]
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
h400	1-	wconstant	_ip_txbuffersize
]
\						\ uncomment this if debug is needed
\ 1 wconstant ip_debug

\
\						\ drive the led connected to pin 23
\ 
\
\ 1 wconstant _ip_light
\
\
\ This defines the cog which will be used to run the ip service
\ This constant may be reset during the boot process
\
\
[ifndef _ipcog
-1 wconstant _ipcog
]

\ h2000 		wconstant _sockbufsize
\ _sockbufsize 1-	wconstant _sockbufmask
\ h_03		wconstant _sockbufinit
\ 1		wconstant _ipnumsock			\ must be 1, 2 or 4

\ h1000		wconstant _sockbufsize
\ _sockbufsize 1-	wconstant _sockbufmask
\ h_0A		wconstant _sockbufinit
\ 2		wconstant _ipnumsock			\ must be 1, 2 or 4

\ h800 		wconstant _sockbufsize
\ _sockbufsize 1-	wconstant _sockbufmask
\ h_55		wconstant _sockbufinit
\ 4		wconstant _ipnumsock			\ must be 1, 2 or 4

[ifndef _sockbufsize
h1000		wconstant _sockbufsize
_sockbufsize 1-	wconstant _sockbufmask
h_0A		wconstant _sockbufinit
2		wconstant _ipnumsock			\ must be 1, 2 or 4
]

\
\
\ IP & TELNET CONFIG PARAMETERS END
\




[ifdef ip_debug
\ a variable used for turning on and off debugging
wvariable ip_debug 1 ip_debug W!
]


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

\ ip_SOCKtelnet ( n1 -- ) n1 - the socket/cog to restart as a telnet socket
: ip_SOCKtelnet
	dup 0 _ipnumsock 1- between
	if
		_ipcog over dup 0 (ioconn)
\							\ reset the socket
		dup ip_SOCKreset drop
\							\ reset the cog
		dup cogreset h80 delms
\							\ set the port
		dup ip_telnetport + over ip_SOCKlistenport W!
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

		i _sockbufsize u* h4000 + dup _ip_socketdata 2+ W!
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
\ non assembler routines
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
	_sockbufinit	_ip_rmsr	_ip_wrbyte
	_sockbufinit	_ip_tmsr	_ip_wrbyte
	ip_gateway	_ip_gar		_ip_wrlong
	ip_subnetmask	_ip_subr	_ip_wrlong
	ip_machi	_ip_shar	_ip_wrword
	ip_maclo	_ip_shar 2+	_ip_wrlong
	ip_ipaddr	_ip_sipr 	_ip_wrlong
;

...


