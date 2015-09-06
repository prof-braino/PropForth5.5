fl

mountsys

h100 fwrite ipserverdebug.f


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

...


