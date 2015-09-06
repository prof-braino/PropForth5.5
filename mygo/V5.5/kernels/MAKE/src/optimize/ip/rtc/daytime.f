
1 wconstant build_daytime

\
\ decimal ( -- ) set the base for decimal
[ifndef decimal
: decimal
	hA base W!
;
]
\
\
\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
[ifndef 2*
: 2* _xasm2>1IMM h0001 _cnip h05F _cnip ; 
]
\


lockdict wvariable ip_daytimeresult hE allot freedict

\ ip_SOCKdaytime ( n1 -- ) use socket/cog n1 to execute a daytime request
: ip_SOCKdaytime
	dup ip_SOCKtelnet
	dup ip_SOCKreset drop				\ reset the socket
	dup cogreset h80 delms				\ reset the cog
	hA over cogstate orC!				\ prompts, errors off

	0 ip_daytimeresult W!				\ return buffer initialize
	c" _ip_daytimerequest" swap cogx	\ execute the request
	h100000 0
	do
		ip_daytimeresult W@
		if
			leave
		then
	loop
	ip_daytimeresult W@ h7 =
	if						\ valid return
		." SUCCESS "
		ip_daytimeresult 2+ W@
		3 + 7 u/mod drop				\ convert the first number to day of week
		ip_daytimeresult 2+ dup 2+ swap h6 cmove	\ yy mm dd into positions 1 , 2 & 3
		ip_daytimeresult h8 + W!			\ dow position 4, hh mm ss 5, 6 & 7
		c" setdatetime_utc" find			\ search for the rtc routine
		if
			>r
			ip_daytimeresult 2+ hE bounds
			do
				i W@
			2 +loop
			r> 
			." RTC: " c" datetime" find if execute else drop then
			execute
			." RTC NOW: "  c" datetime" find if execute else drop then
		else
			drop
		then
	else
		." FAILURE"
	then
	cr

\	8 0
\	do
\		i 2* ip_daytimeresult + W@ .
\	loop
\	cr
;



: _ip_daytimerequest
	cogid 0 $S_ip_cog cogid (ioconn)
	cogid ip_SOCKreset
	if
		0 cogid ip_SOCKlistenport W!		\ listen port disabled
		hD cogid ip_SOCKdestport W!		\ destination port 13
		h_45_19_60_0D cogid ip_SOCKdestipaddr L!	\ 69.25.96.13
		-1 h0D h09 cogid ip_SOCKsendmultiplereq	\ defer disconnect on, client connect once on
		drop

		0 h10000 0				\ will wait about 4 seconds for a connect
		do
			cogid ip_SOCKstatus@ _ip_connected and
			if
				1-
				leave
			then
		loop
	else
		0					\ socket reset failed
	then

	if						\ receive the characters
		padbl
		pad 1+
		h100000 0
		do
			fkey?
			if
				dup h30 h39 between 0=	\ only keep numbers
				if
					drop bl
				then
				over C!
				1+
			else
				drop
			then
			cogid ip_SOCKstatus@
			_ip_connected and 0=
			if
				leave
			then
		loop
		drop


		base W@ decimal
		0 >in W!
		0
		h7 0
		do
			parsenw dup
			if
				C@++ number
				i 1+ 2* ip_daytimeresult + W!
				1+
			else
				drop leave
			then
		loop
		dup 0=
		if
			drop -1
		then
		ip_daytimeresult W!
		base W!
	else						\ no sucessful connection
		cogid ip_SOCKreset drop
		-1 ip_daytimeresult W!
	then

	padbl
	cogid iodis
;


	
