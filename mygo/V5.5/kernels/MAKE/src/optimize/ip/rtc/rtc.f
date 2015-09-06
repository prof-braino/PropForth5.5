\ code to interface to the spinneret rtc chip, and date time routines	
\
\ Status: Beta 2011-Mar-02

1 wconstant build_rtc


\
\ CONFIG PARAMETERS BEGIN
\

[ifndef timezone
variable timezone d-8 timezone L!	\ our current timezone
\ variable timezone -8 timezone L!	\ Vancouver timezone
\ variable timezone -6 timezone L!	\ Chicago  timezone
]

\
\ CONFIG PARAMETERS END
\

\
\ abs ( n1 -- abs_n1 ) absolute value of n1
[ifndef abs
: abs
	_xasm1>1 h151 _cnip
;
]


\ rev ( n1 n2 -- n3 ) n3 is n1 with the lower 32-n2 bits reversed and the upper bite cleared
[ifndef rev
: rev
	_xasm2>1 h079 _cnip
;
]

\
\ revb ( n1 -- n2 ) n2 is the lower 8 bits of n1 reveresed
[ifndef revb
: revb
	h18 rev
;
]

\
\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[ifndef u*/mod
: u*/mod
	rot2 um* rot um/mod
;
]

\
\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[ifndef u*/
: u*/
	rot2 um* rot um/mod nip
;
]

\
\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[ifndef C#
: #C
	-1 >out W+! pad>out C!
;
]

\
\ bcd> ( n1 -- n2 ) convert bcd byte n1 to hex byte n2
[ifndef bcd>
: bcd>
	dup hF and
	swap hF0 and
	1 rshift dup
	h2 rshift + +
;
]

\
\ >bcd ( n1 -- n2 ) convert hex byte n1 to bcd byte n2
[ifndef >bcd
: >bcd
	hA u/mod h4 lshift +
;
]

\
\ routines to r/w the rtc, it is an eeprom with a device code of 6
\
\ r0 - mode register 
\ r2 - date & time
\ r6 - the correction register
\

\
\ _rtcw ( c1 -- )
: _rtcw
	_eewrite
	if
		h87 ERR
	then
;

\
\ _rtcs ( c1 -- )
: _rtcs
	_eestart
	h60 or
	_rtcw
;

\
\ _rtc_r0 ( -- c1 ) read rtc reg 0
\ : _rtc_r0 1 _rtcs -1 _eeread _eestop ;

\ _rtc_w0 ( c1 -- ) write rtc reg0
: _rtc_w0
	0 _rtcs _rtcw
	_eestop
;

\
\ _rtc_r2 ( -- n1 n2 n3 n4 n5 n6 n7 ) read 7 bytes from rtc reg 2
\ n1 - year		(00 - 99)
\ n2 - month		(01 - 12)
\ n3 - day		(01 - 31)
\ n4 - day of week 	(00 - 06)
\ n5 - hour		(00 - 23)
\ n6 - minute		(00 - 59)
\ n7 - second		(00 - 59)
: _rtc_r2 5 _rtcs 6 0 do 0 _eeread revb bcd> loop -1 _eeread revb bcd> _eestop ;

\ _rtcflip7 ( n7 n6 n5 n4 n3 n2 n1 -- n1 n2 n3 n4 n5 n6 n7 ) flip the top 7 items on the stack
: _rtcflip7 
	rot >r rot >r rot >r rot >r rot >r
	swap
	r> r> r> r> r>
	rot >r rot >r rot >r
	swap
	r> r> r>
	swap rot
;

\
\ _rtc_w2 ( -- n1 n2 n3 n4 n5 n6 n7 ) write 7 bytes to rtc reg 2
\ n1 - year		(00 - 99)
\ n2 - month		(01 - 12)
\ n3 - day		(01 - 31)
\ n4 - day of week 	(00 - 06)
\ n5 - hour		(00 - 23)
\ n6 - minute		(00 - 59)
\ n7 - second		(00 - 59)
: _rtc_w2
	_rtcflip7
	h4 _rtcs
	h7 0
	do
		>bcd revb _rtcw
	loop
	_eestop
;

\ _rtc_r6 ( -- c1 ) read rtc reg 6
: _rtc_r6
	hD _rtcs
	-1 _eeread
	_eestop ;

\ _rtc_w6 ( c1 -- ) write rtc reg 6
: _rtc_w6
	hC _rtcs
	_rtcw _eestop
;

\ : _rtc_r7 hF _rtcs  -1 _eeread _eestop ;
\ : _rtc_r7 hE _rtcs _rtcw _eestop ;


\ isleap ( yyyy -- t/f)
: isleap
	dup h3 and 0=
	if					\ divisible by 4   - yes
		dup h64 u/mod drop 0=		\ divisible by 100 - no 
		if 
			h190 u/mod drop 0=	\ divisible by 400 - yes
		else 
			drop -1
		then
	else 
		drop 0 
	then ;

\ prevdate ( yyyy mm dd -- yyyy mm dd ) subtracts 1 day
: prevdate
	1- dup 0 <=
	if				\ previous month
		drop 1- dup 0 <=	
		if			\ previous year
			drop 1- hC h1F
	else
		dup h2 = 
		if			\ february
			over isleap
			if		\ leap
				h1D
			else		\ no leap
				h1C
			then
		else
			dup h4 = over h6 = or over h9 = or over hB = or
			if
				h1E		\ apr, june sept nov have 30 days
			else
				h1F		\ otherwise 31
			then
		then
	then
then
;

\ nextdate ( yyyy mm dd -- yyyy mm dd ) adds 1 day
: nextdate
	over h2 =
	if				\ february
		rot dup isleap >r rot2
		dup r>
		if
			h1D		\ 29th is the last day
		else
			h1C		\ 28th is th last day
		then
		=
		if 
			drop 1+ 1 	\ next month, 1st
		else
			1+		\ next day 
		then
	else
		over dup h4 = over h6 = or over h9 = or swap hB = or
		if
			h1E		\ 30th is the last day
		else
			h1F		\ 31st is the last day
		then
		over =
		if
			drop 1+ dup hC >	\ was it december
			if
				drop
				1+ 1 1	\ happy new year
			else
				1	\ 1st of the next month
			then
	else
		1+			\ next day
	then
then
;



\ _rtc_utc-localfixup (  n1 n2 n3 n4 n5 n6 n7  -- n1 n2 n3 n4 n5 n6 n7 ) fix if we have crossed a date boundary
\ n1 - year		(00 - 99)
\ n2 - month		(01 - 12)
\ n3 - day		(01 - 31)
\ n4 - day of week 	(00 - 06)
\ n5- minute		(00 - 59)
\ n6 - second		(00 - 59)
\ n7 - hour		(00 - 23)
: _rtc_utc-localfixup
	dup 0 h17 between 0=	\ is it a different day?
	if			
		dup 0<
		if			\ it is the previous day
			h18 +		\ fix the hour
			>r >r >r	\ mm ss hh to the return stack
			1-		\ adjust the day of week
			dup 0<
			if		\ adjust for day of week wraparound
				drop h6
			then
			 >r		\ day of week to return stack
			prevdate
		else			\ it is the next day
			h18 -		\ fix the hour
			>r >r >r	\ hh mm ss to the return stack
			1+		\ adjust the day of week
			dup h6 >
			if		\ adjust for day of week wraparound
				drop 0
			then
			>r		\ day of week to return stack
			nextdate
		then 
		r> r> r> r>		\ day of week m ss hh back to stack
	then
;




\ utc>local (  n1 n2 n3 n4 n5 n6 n7  -- n1 n2 n3 n4 n5 n6 n7 ) adjust utc to local time
\ n1 - year		(00 - 99)
\ n2 - month		(01 - 12)
\ n3 - day		(01 - 31)
\ n4 - day of week 	(00 - 06)
\ n5 - hour		(00 - 23)
\ n6 - minute		(00 - 59)
\ n7 - second		(00 - 59)
: utc>local 
	rot >bcd h3F and bcd>	\ mask off the AM/PM flag
	timezone L@ +		\ adjust according to timezone
	_rtc_utc-localfixup	\ fix if we have crossed a date boundary
	rot2
;

\ local>utc (  n1 n2 n3 n4 n5 n6 n7  -- n1 n2 n3 n4 n5 n6 n7 ) adjust utc to local time
\ n1 - year		(00 - 99)
\ n2 - month		(01 - 12)
\ n3 - day		(01 - 31)
\ n4 - day of week 	(00 - 06)
\ n5 - hour		(00 - 23)
\ n6 - minute		(00 - 59)
\ n7 - second		(00 - 59)
: local>utc 
	rot >bcd h3F and bcd>	\ mask off the AM/PM flag
	timezone L@ -		\ adjust according to timezone
	_rtc_utc-localfixup	\ fix if we have crossed a date boundary
	rot2
;

\ _rtc_dow ( n1 -- )
: _rtc_dow c" SUNMONTUEWEDTHUFRISAT" 1+ swap 1+ 7 min 1 max 3 u* +
	1- dup C@ #C 1- dup C@ #C 1- C@ #C ;

\ _rtc_mon ( n1 -- )
: _rtc_mon c" JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC" 1+ swap hC min 1 max 3 u* +
	1- dup C@ #C 1- dup C@ #C 1- C@ #C ;

\ _rtc_datestr ( yyyy mm dd -- )
: _rtc_datestr  # #  h2D #C drop _rtc_mon h2D #C # # # # drop ;

\ _rtc_timestr ( hh mm ss -- )
: _rtc_timestr # # drop h3A #C # # drop h3A #C dup h28 > if h28 - then # # drop ;





\ datestr ( yyyy mm dd -- cstr )
: datestr <# _rtc_datestr 0 #> ;

\ timestr ( hh mm ss -- cstr )
: timestr <# _rtc_timestr 0 #> ;

\ datetimestr ( yy mm dd dow hh mm ss -- cstr )
: datetimestr <# _rtc_timestr bl #C _rtc_dow bl #C rot h7D0 + rot2 _rtc_datestr 0 #> ;

\ rtcreset ( -- )
: rtcreset
	hC0 _rtc_w0
;

\ datetime ( -- )
: datetime
	_rtc_r2 utc>local
	datetimestr
	.cstr cr
;

\ setdatetime_utc ( yy mm dd dow hh mm ss -- )
: setdatetime_utc
	rtcreset 
	_rtc_w2
	;

\ setdatetime ( yy mm dd dow hh mm ss -- )
: setdatetime
	local>utc setdatetime_utc
	;

\ rtccorrect ( n1 -- ) n1 - decimal 100 * number of second / day to correct
: rtccorrect
	dup 0 >= 
	if
		hD + h67D min
		h3F h67D u*/
	else
		abs hD + h698 min
		h40 h698 u*/
		h80 swap -
	then
	revb
	_rtc_w6
;


\ rtccorrect? ( -- n1 ) n1 - decimal 100 * number of second / day to correct
: rtccorrect?
	_rtc_r6 revb
	h7F and
	dup h3F and
	swap h40 and 
	if
		h40 swap - h698 h40 u*/ negate
	else
		h67D h3F u*/
	then
;




