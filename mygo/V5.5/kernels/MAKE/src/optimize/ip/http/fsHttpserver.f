fl

1 wconstant build_httpserver

\
\ HTTP CONFIG PARAMETERS BEGIN
\

[ifndef $S_ip_httpport
d_8080 wconstant $S_ip_httpport	\ port 8080
]
\
\ uncomment this to enable http debugging
\
\ 1 wconstant http_debug

\
\ HTTP CONFIG PARAMETERS END
\

\ decimal ( -- ) set the base for decimal
[ifndef decimal
: decimal
	hA base W!
;
]


: _ht_filelen
	EW@
;

: _ht_cd drop ;

: _ht_find
	_fsfind
;

: _ht_read
	_fsread
;

: _ht_readblk
\
\ read 3 bytes into t0, t1 and process
	dup t0 h3 _fsrd
	t1 C@ + 2+ 1+ t0 W@ bounds
	do
\ align to page
		fsps i fsps 1- and -
\ only get what we need
		ibound i - min
\ read the bytes
		i pad h2 ST@ _fsrd
\ emit them
		pad over .str
	+loop
	padbl
;


wvariable fspservercog
wvariable fspcog
wvariable chunkercog

wvariable reqstatus 0 reqstatus W!

lockdict wvariable reqdata d_126 allot freedict

[ifdef http_debug
wvariable http_debug 7 http_debug W!

\ debug bit definitions
\ h01 - high level word entry and exit
\ h02 - fsp code
\ h04 - chunker output


: dbglock 7 lock ;
: dbgunlock 7 unlock ;



\ _dbg_mem ( addr count -- )
\ : _dbg_mem
\	c" c~h22 " .concstr
\	bounds
\	do
\		i C@ dup h20 h7E between
\		if
\			.conemit
\		else
\			c" ~h" .concstr
\			base W@ swap hex .conbyte base W!
\		then
\	loop
\	c" ~h22" .concstr .concr
\
\ ;

\ _http_debugmsg ( cstr cstr -- )
: _http_debugmsg
	http_debug W@
	if
		dbglock
		c" COG:" .concstr cogid .con swap .concstr bl .conemit
		dup 0 d255 between
		if
			.con
		else
			.concstr
		then

\		.concr
\		c"    PAD: " .concstr pad padsize _dbg_mem
\		c"   TBUF: " .concstr tbuf d32 _dbg_mem
 		 bl .conemit .const?
\		8 0 do
\			i dup .con cogio dup .conword bl .conemit 2+ W@ .conword bl .conemit
\		loop
\		.concr
\
		dbgunlock
	else
		2drop
	then
;


]

\ ip_SOCKhttp ( n1 -- ) n1 - the socket/cog to restart as an http socket
: ip_SOCKhttp
	dup 0 $S_ip_numsock 1- between
	if
		dup ip_SOCKreset drop				\ reset the socket
		dup iodis
		dup cogreset h80 delms				\ reset the cog
		hA over cogstate orC!				\ prompts, errors off
		$S_ip_httpport over ip_SOCKlistenport W!		\ set the port
\ server connect on, noexpandcr
		h07 over ip_SOCKsendreq drop
		h13 over ip_SOCKsendreq drop

		c" httpserver" over cogx
\		drop
\	else
\		drop
	then
	drop
;

\ httpabort ( -- )
: httpabort
	-1 h01 h11 h10 cogid ip_SOCKsendmultiplereq drop	\ flush output, flush input, then disconnect
;
\ _wnfcog ( -- cog ) wait for a free cog
[ifndef _wnfcog
: _wnfcog
	h_100 0
	do
		(nfcog) 0=
		if
			leave
		then
		drop
		1 delms
	loop
	nfcog
;
\
\
\ httpserver ( -- ) monitors for http requests and responds accordingly
: httpserver
	c" HTTP SERVER" cds W!
	h4 state andnC!
	cogid 0 $S_ip_cog cogid (ioconn)
	h_100 delms
	lockdict
		_wnfcog dup fspservercog W!
		h4 over cogstate andnC!
		hA over cogstate orC!
		c" HTTP FSP SERVER" swap cogcds W!

		_wnfcog dup fspcog W!
		h4 over cogstate andnC!
		hA over cogstate orC!
		c" HTTP FSP" swap cogcds W!

		_wnfcog dup chunkercog W!
		h4 over cogstate andnC!
		hA over cogstate orC!
		c" HTTP CHUNKER" swap cogcds W!
	freedict

	begin
		0 reqstatus W!
		accept				\ get a line from the input and parse the first word
		1 reqstatus W!
		0 >in W!
		parsenw dup
		if
			h2 reqstatus W!
[ifdef http_debug
			http_debug W@
			if
				.concr
			then
			c" httpserver data received:" over _http_debugmsg
]
			c" http" tbuf ccopy
			tbuf cappend
[ifdef http_debug
			c" httpserver VERB:" tbuf _http_debugmsg
]
 			tbuf find				\ calls httpGET httpPOST etc
			if
				h3 reqstatus W!
				execute
			else					\ ignore all other requests
[ifdef http_debug
				c" httpserver invalid request:" 0 _http_debugmsg
]
				drop
				h4 reqstatus W!
				httpabort
			then
[ifdef http_debug
			http_debug W@
			if
				.concr
			then
]
		else						\ empty line ignore
			drop
		then
	0	
	until
;



: httpfsp
[ifdef http_debug
	c" httpfsp ENTER:" 0 _http_debugmsg
]
	cogid chunkercog W@ iolink

	." httpchunker~h0D"

	key _fsk _fsk _fsk

	begin
		dup hFFFFFF and h3C3F66 =
		if
			h18 rshift emit
			hA fspcog W@ cogstate orC!
			cogid fspcog W@ iolink

[ifdef http_debug
	http_debug W@ h02 and
	if
		dbglock
		c" ~h0DFSP CODE{~h0D" .concstr
		dbgunlock
	then

]
			key _fsk _fsk _fsk
			begin
				dup hFFFF and h3F3E =
				if
					dup h18 rshift
[ifdef http_debug
	http_debug W@ h02 and
	if
		dup .conemit
	then
]
					emit
					h10 rshift
[ifdef http_debug
	http_debug W@ h02 and
	if
		dup .conemit
	then
]
					emit
					-1
			
				else
					dup h18 rshift
[ifdef http_debug
	http_debug W@ h02 and
	if
		dup .conemit
	then
]
					emit
					_fsk
					0
				then
			until
			cr cr cr
[ifdef http_debug
	http_debug W@ h02 and
	if
		dbglock
		.concr .concr .concr
		c" ~h0D}FSP CODE~h0D" .concstr
		dbgunlock
	then
]
			cogid iounlink
			key _fsk _fsk _fsk
			0


[ifdef http_debug
	c" httpfsp fspcode end:" 0 _http_debugmsg
]
		else
			dup hFF and hFF =
			if
				dup h18 rshift emit
				dup h10 rshift emit
				h8 rshift emit
				-1
			else
				dup h18 rshift emit _fsk
				0
			then
		then
	until

	hFF emit
	cr
	cr
	cogid iounlink
[ifdef http_debug
	c" httpfsp EXIT:" 0 _http_debugmsg
]
;



\ httpchunker ( -- )
: httpchunker
[ifdef http_debug
	c" httpchunker ENTER:" 0 _http_debugmsg
]
	begin
		0
		pad h80 bounds
		do
			key
			dup hFF =
			if
				drop leave
			else
				i C!
				1+
			then
		loop

		base W@ hex
		over <# #s #> .cstr ." ~h0D~h0A"
		base W!
		dup 0<>
		if
			pad over bounds
			do
				i C@ emit
			loop
			." ~h0D~h0A"
		then
[ifdef http_debug
		http_debug W@ h04 and
		if
			dbglock
			c" ~h0DCHUNKER{~h0D" .concstr
			base W@ hex
			over <# #s #> .concstr c" ~h0D~h0A" .concstr
			base W!
			dup 0<>
			if
				pad over bounds
				do
					i C@ .conemit
				loop
				c" ~h0D~h0A" .concstr
			then
			c" ~h0D}CHUNKER~h0D" .concstr
			dbgunlock
		then
]

		h80 =
		if
			0
		else
			." 0~h0D~h0A~h0D~h0A"
[ifdef http_debug
			http_debug W@ h04 and
			if
				dbglock
				c" ~h0DCHUNKER{~h0D" .concstr
				c" 0~h0D~h0A~h0D~h0A" .concstr
				c" ~h0D}CHUNKER~h0D" .concstr
				dbgunlock
			then
]
			-1
		then
	until
	padbl
		
[ifdef http_debug
	c" httpchunker EXIT:" 0 _http_debugmsg
]
;


\ _httpstart ( -- url block ) any reqdata is set if there is any data following  ? in the url
: _httpstart
[ifdef http_debug
	c" _http_start ENTER:" 0 _http_debugmsg
]

	0 reqdata C!
	lockdict
	c" __fspcode" ccreate $C_a_dovarw w, forthentry
	freedict

	parsenw dup

	if
[ifdef http_debug
	c" _http_start URL:" over _http_debugmsg
]
		C@++ 1- over C!
		dup
[ifdef http_debug
	c" _http_start 111:" over _http_debugmsg
]

		C@++ bounds
		do
			i C@ h3F =
			if
				i 1- over - over
				C!
				ibound i 1+
				-
				dup reqdata C!
				dup
				if
					reqdata 1+
					i 1+ swap rot
					cmove
				else
					drop
				then
				leave
			then
		loop
		
		dup _ht_find
	else
		drop 0 0
	then
[ifdef http_debug
	c" _http_start EXIT:" 0 _http_debugmsg
]
;

\ _httpend ( --)
: _httpend
[ifdef http_debug
	c" _http_end ENTER:" 0 _http_debugmsg
]
	-1 h01 h11 h10 cogid ip_SOCKsendmultiplereq drop	\ flush output, flush input, then disconnect
	c" __fspcode" (forget)
	0 reqdata C!
[ifdef http_debug
	c" _http_end EXIT:" 0 _http_debugmsg
]
;

\ httpSEND ( cstr1 cstr2 -- ) cstr1 - contentfilename, cstr2 - headerfilename
: httpSEND
\ (cstr1 headerblock -- )
	_ht_find dup
	if
		swap

		_ht_find dup
		if
			_ht_readblk

			dup _ht_filelen
			base W@ swap decimal . ." ~h0D~h0A~h0D~h0A"
			base W!
			_ht_readblk
		else
			2drop httpabort
		then
	else
		2drop httpabort
	then
;

\ http404 ( -- )
: http404
	c" header404" c" r404.htm" httpSEND
;

\ httpGET ( -- )
: httpGET
[ifdef http_debug
	c" httpGET ENTER:" 0 _http_debugmsg
]
	_httpstart
[ifdef http_debug
	c" httpGET: ( -- url block )" 0 _http_debugmsg
]
	h11 cogid ip_SOCKsendreq drop	\ flush the input, we are not going to consider anything else

	dup
	if
		c" header200htm" numpad ccopy
		swap
		C@++ h3 - + numpad hA + h3 cmove
		numpad _ht_find dup
		if
			_ht_readblk
			numpad hA + C@ h66 =
			if
				cogid fspservercog W@ iolink
				." httpfsp~h0D"
				_ht_readblk
				hFF emit
				cr
				cr
				cogid iounlink

			else
				dup _ht_filelen
				base W@ swap decimal . ." ~h0D~h0A~h0D~h0A"
				base W!
				_ht_readblk
				then
		else
			2drop http404
		then

	else
		2drop http404
	then
	_httpend	
[ifdef http_debug
	c" httpGET EXIT:" 0 _http_debugmsg
]
;

\
\ assuming you want to start telnet
\
\
c" onboot" find drop pfa>nfa 1+ c" onb002" C@++ rot swap cmove
\
\ onboot ( n1 -- n1)
: onboot
	onb002 
\ do not execute if escape has been hit
	fkey? and fkey? and or h1B <>
	if
		c" $S_ip_numTelnet" find
		if
			1 swap 2+ W!
		then
		startTelnet
		1 ip_SOCKhttp
	then
;



