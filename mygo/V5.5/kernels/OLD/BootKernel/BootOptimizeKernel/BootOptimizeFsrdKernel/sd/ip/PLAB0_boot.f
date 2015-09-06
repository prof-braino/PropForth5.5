fl
\
\ This boot file is for a very specific hardware configuration which is
\ a Spinneret with a propeller chip connected.
\
\ norom and mcs are loaded, the subprop is booted and then morom and mcs are unloaded
\
\
\
fswrite boot.f
version W@ _bmsg c" boot.f    initializing" _bmsg

\ this turns off cr ->crlf expansion in the serial driver on cog 7
\ 1 7 cogio h_C8 + L!

\ this is the 4 character string that will be the system prompt
\
: tempPROMPT c" PLAB" ;

\ this is the numberic propid
\
0 wconstant tempPROPID

\
\ (forget) ( cstr -- ) wind the dictionary back to the word which follows - caution
[ifndef (forget)
: (forget)
	dup
	if
		find
		if
			pfa>nfa nfa>lfa dup here W! W@ wlastnfa W!
		else
			_p?
			if
				.cstr h3F emit cr
			then
		then
	else
		drop
	then
;
]
\
\
\ forget ( -- ) wind the dictionary back to the word which follows - caution
[ifndef forget
: forget
	parsenw (forget)
;
]

\ findEETOP ( -- n1 ) the top of the eeprom + 1
: findEETOP

\
\ search 32k block increments until we get a fail
\

	0
	h100000 h8000
	do
		i t0 2 eereadpage
		if
			leave
		else
			i h7FFE + t0 3 eereadpage
			if
				leave
			else
				drop i h8000 +
			then
			
		then
	h8000 +loop
;


c" boot.f    setting top of eeprom file system and prompt" _bmsg

findEETOP ' fstop 2+ alignl L! 


\
\ make sure not to copy in a string longer than the original string 4 bytes\
tempPROMPT 1 + C@ prop W@ 1 + C!
tempPROMPT 2 + C@ prop W@ 2 + C!
tempPROMPT 3 + C@ prop W@ 3 + C!
tempPROMPT 4 + C@ prop W@ 4 + C!

tempPROPID propid W!


forget _serial



\
\
\ SD CONFIG PARAMETERS BEGIN
\
\ definitions for io pins connecting to the sd card
\

[ifndef _sd_cs
h13 wconstant _sd_cs
]
[ifndef _sd_di
h14 wconstant _sd_di
]
[ifndef _sd_clk
h15 wconstant _sd_clk
]
[ifndef _sd_do
h10 wconstant _sd_do
]

{
\ PLAB CONFIG 
[ifndef _sd_cs
h00 wconstant _sd_cs \ DAT3 PIN2 
]
[ifndef _sd_di
h01 wconstant _sd_di	\ CMD PIN3
]
[ifndef _sd_clk
h02 wconstant _sd_clk	\ CLK PIN6
]
[ifndef _sd_do
h03 wconstant _sd_do	\ DATA0 PIN8
}

\
\
\
\ SD CONFIG PARAMETERS END
\

c" boot.f    LOADING sd_init.f" _bmsg
fsload sd_init.f

c" boot.f    LOADING sd_run.f" _bmsg
fsload sd_run.f

c" boot.f    LOADING sdfs.f" _bmsg
fsload sdfs.f

c" boot.f    SD FILE SYSTEM LOADED" _bmsg

1 sd_mount

c" boot.f    LOADING DevKernel.f" _bmsg
fload DevKernel.f




\
\ BEGIN boot and configure subprop
\

[ifndef rcogx
\ rcogx ( cstr cog channel -- ) send cstr to the cog/channel
: rcogx
	io 2+ W@
\ ( cstr cog channel oldio+2 -- )
	rot cogio
\ ( cstr channel oldio+2 cogio -- )
	rot 4* +
\ ( cstr oldio+2 chaddr -- )
	io 2+ W!
\ ( cstr oldio+2 -- )
	swap .cstr cr
	io 2+ W!
;
]

[ifndef rfsend
\ rfsend filename ( cog channel -- )
: rfsend
	4* swap cogio +
	_sd_fsp dup
	if
\ ( chaddr fname -- )
		io 2+ W@
\ ( chaddr fname oldio+2 -- )
		rot io 2+ W!
\ ( fname oldio+2 -- )
		swap
		sd_read
		io 2+ W!
	else
		2drop _fnf
	then
;
]




\
\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[ifndef term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup h6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]


1 wconstant SUBPROP

c" boot.f    LOADING norom.f" _bmsg
fload norom.f

c" boot.f    LOADING mcs.f" _bmsg
fload mcs.f



1 wconstant  build_mcsnorom

\ this is what the cogs on the subprop will do on reset
: onreset
	unlockall 4 state orC! version W@ cds W! drop
;



\ this is what the subprop will do on boot
\ 



: onboot
	8 0
	do
		i cogid <>
		if
			i cogreset
		then
	loop

\
\ drop error codes
\
	drop 0 

	h40 0
	do
		h1C 1 qHzb h90000 hA0000 between
		if
			c" h1C h1D hFF h8 mcsslave" h7 cogx h10 delms
			h10000 0
			do
				h7 cogio mcsstate@ 4 =
				if
					leave
				then
			loop
			4 0 7 4 (ioconn)
			0 0 7 0 (ioconn)
		then
	loop
;		

: bootsubprop
	4 state andnC!
	d26 d27 d24 d25 rambootnx
	c" d26 d27 d24 d8 mcsmaster" 2 cogx
	h2000 0
	do
		1 delms
		2 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	2 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;


: bootplab1
	c" bootsubprop" 3 cogx

	h2000 0
	do
		1 delms
		3 cogstate C@ hA =
		if
			leave
		then
	loop
;

bootplab1 3 cogstate C@ hA =
[if
	c" 1 propid W!" 2 0 rcogx
	c" forget build_fsrd" 2 0 rcogx
	c" : onboot ; : reboot .~h22 NO~h22 cr ;" 2 0 rcogx
	c" : onreset unlockall 4 state orC! version W@ cds W! drop ;" 2 0 rcogx
	2 0 rfsend DevKernel.f
]

forget SUBPROP

\
\ END boot and configure subprop
\

fload sdboot.f

fread .sdcardinfo






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
\ IP & TELNET CONFIG PARAMETERS BEGIN
\
\


\
\ The gateway parameter is necessary for the client protocols, to route through for internet requests.
\ These parameters may be defined in boot.f
\
\						\ 192.168.0.1
[ifndef ip_gateway
h_C0_A8_00_01	constant	ip_gateway
]
\
						\ 255.255.255.0
[ifndef ip_subnetmask
h_FF_FF_FF_00	constant	ip_subnetmask
]
\
\ The mac address is on the bottom of the spinneret board
\
\						\ 00:08:DC:16:EF:2D
[ifndef ip_machi
 h_00_08	wconstant	ip_machi
 h_DC_16_EF_2D	constant	ip_maclo
]
\						\ 192.168.0.144
[ifndef ip_addr
h_C0_A8_00_90	constant	ip_ipaddr
]

\
\						\ ports 23, 24, 25, 26, port 23 is the standard telnet port
\ h_17		wconstant	ip_telnetport
\						\ ports 2020, 2021, 2022, 2023
\ h_7E4		wconstant	ip_telnetport
[ifndef ip_telnetport
h_7E4		wconstant	ip_telnetport
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
1 wconstant _ip_light
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
h800		wconstant _sockbufsize
_sockbufsize 1-	wconstant _sockbufmask
h_55		wconstant _sockbufinit
4		wconstant _ipnumsock			\ must be 1, 2 or 4
]

\
\
\ IP & TELNET CONFIG PARAMETERS END
\




\
\
\ for debugging IP
\
\ 1 wconstant ip_debug
\ c" boot.f    LOADING DevKernel.f" _bmsg
\ fload DevKernel.f

c" boot.f    LOADING ipserver1.f" _bmsg
fload ipserver1.f

c" boot.f    LOADING ipserver2.f" _bmsg
fload ipserver2.f


\ start the ip_server on a free cog
lockdict nfcog 4 over cogstate andnC! freedict ' _ipcog 2+ W!
_ipcog cr cr . cr cr

c" boot.f    STARTING ipserver" _bmsg
c" ip_server" _ipcog cogx

\
\ the delay is to allow ipserver to start up, if the ip initialization changes this may have to 
\ be adjusted
\
c" boot.f    STARTING telnet" _bmsg
h_10 delms
0 ip_SOCKtelnet

2 0 _ipcog 1 (ioconn)
1 ip_SOCKreset drop
1 ip_telnetport + 1 ip_SOCKlistenport W!
-1 h07 h12 h03 1 ip_SOCKsendmultiplereq drop

2 1 _ipcog 2 (ioconn)
2 ip_SOCKreset drop
2 ip_telnetport + 2 ip_SOCKlistenport W!
-1 h07 h12 h03 2 ip_SOCKsendmultiplereq drop

2 2 _ipcog 3 (ioconn)
3 ip_SOCKreset drop
3 ip_telnetport + 3 ip_SOCKlistenport W!
-1 h07 h12 h03 3 ip_SOCKsendmultiplereq drop


c" boot.f    DONE" _bmsg


6 cogio W@ h1B = h100 6 cogio W! 100 delms
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
0=
[if
 	6 iounlink 6 iodis 6 cogreset 7 cogreset
]

...
