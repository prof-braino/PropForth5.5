fswrite boot.f
version W@ _bmsg c" boot.f    initializing" _bmsg

\ this turns off cr ->crlf expansion in the serial driver on cog 7
\ 1 7 cogio h_C8 + L!

\ this is the 4 character string that will be the system prompt
\
: tempPROMPT c" SNET" ;

\ this is the numberic propid
\
11 wconstant tempPROPID

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
[ifndef _sd_cd
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
\						\ 192.168.23.129
[ifndef ip_addr
h_C0_A8_17_81	constant	ip_ipaddr
]

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

c" boot.f    LOADING ipserverdebug.f" _bmsg
fload ipserverdebug.f

c" boot.f    LOADING ipserver2.f" _bmsg
fload ipserver2.f


\
\ HTTP CONFIG PARAMETERS BEGIN
\

[ifndef httpport
h1F90 wconstant httpport	\ port 8080
]
\
\ uncomment this to enable http debugging
\
\ 1 wconstant http_debug

\
\ HTTP CONFIG PARAMETERS END
\


\ for debugging HTTP
\
\ 1 wconstant ip_debug
\ c" boot.f    LOADING DevKernel.f" _bmsg
\ fload DevKernel.f


c" boot.f    LOADING httpserver.f" _bmsg
fload httpserver.f


\ start the ip_server on a free cog
lockdict nfcog 4 over cogstate andnC! freedict ' _ipcog 2+ W! 

c" boot.f    STARTING ipserver" _bmsg
c" ip_server" _ipcog cogx

\
\ the delay is to allow ipserver to start up, if the ip initialization changes this may have to 
\ be adjusted
\
c" boot.f    STARTING telnet" _bmsg
h_10 delms 0 ip_SOCKtelnet

\
\ this need to be the last thing run, as it will allocates all the free cogs 
\
c" boot.f    STARTING http" _bmsg
1 ip_SOCKhttp

...

