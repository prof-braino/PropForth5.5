\
\ 2012-Feb-04 Status: Alpha
\
\ Provides a high resolution long time system timer by using one cog
\ to update a 64-bit counter as rapidly as possible. The main word is
\ _tickCounter ( addr_dticks _timelock -- ) 
\
\ When this words starts it sets the default time zone,
\ Sets the default time to 2012-01-01_12:00:00 UTC,
\ and adjusts the parameters to the current clkfreq 
\
\ This word will be run on one cog at system startup.
\
\ Counts system clock cycles (ticks) since system startup as an
\ unsigned double long.
\
\ Update read cycle is approximately 1 - 2 microseconds on an
\ 80 Mhz system.
\
\ This is because we have to use a lock, to update, or to read the
\ 2 longs that make up the double counter.
\
\ The words which update the double counter, and which read the
\ double counter, are written in assembler to ensure maximum resolution.
\ 
\ This provides a range of about 7,311 years at 80 Mhz
\ 2^64 / 80,000,000 / 60 / 60 / 24 / 365
\
\ The range will vary if the clock frequency changes, the design point
\ on this was an 80 Mhz system
\
\ Time is then calculated as ticks since 1970-Jan-01_00:00:00
\ only unsigned counts are considered, so minimum date is 1970-Jan-01_00:00:00
\
\ So for the unix people, you can generate a unix time stamp easily
\
\ NOTE: UTC -> local timezone conversion can cause an underflow. 
\
\ setTimeZone ( h m -- ) - sets the time zone h and m can be positive or negative
\
\ setTime ( y m d h m s -- ) sets the UTC time
\
\ setLocalTime ( y m d h m s -- ) subtracts the time zone, then sets UTC time
\
\ getTime ( -- y m d h m s ticks -- ) gets UTC time
\
\ getLocalTime ( -- y m d h m s ticks -- ) gets local time
\ 
\ formatTime ( -- y m d h m s ticks -- cstr) formats a to a printable sortable string
\
\ getTimeStr( -- cstr) get the current UTC time as a string
\
\ getLocalTimeStr( -- cstr) get the current local time as a string
\
\ time ( -- ) print the local time
\
\ setDriftCorrection ( n1 -- ) sets the time correction to n1 ticks per day
\
\ utc ( -- ) print the utc time
\
\ timeStamp ( -- lo hi) gets a number which is the time stamp in microseconds (UTC)
\                       the number of microseconds since 1970-01-01_00:00:00
\                       print with d. or the double format words 
\
\ unixTimeStamp ( -- lo hi) gets a number which is the time stamp in seconds (UTC)
\                           the number of seconds since 1970-01-01_00:00:00
\                           print with d. or the double format words
\
\
1 wconstant build_time
\
\ Begin config parameters
\
[ifndef timeZoneHours
-7 constant timeZoneHours
]
[ifndef timeZoneMinutes
0 constant timeZoneMinutes
]
[ifndef doubleTimerCog
3 wconstant doubleTimerCog
]
\
\ End config parameters
\
\
\
\ a double long, the current number of clock ticks since boot
[ifndef _dtickCNT 
lockdict variable _dtickCNT 4 allot freedict
]
\
[ifndef _dtimeOffset 
lockdict variable _dtimeOffset 4 allot freedict 0 u>d _dtimeOffset dL!
]
\
\ These will be re-initialized by _tickCounter when is starts up
\ in case the running system is running a different clock 
\ frequency
\
[ifndef _driftCorrectionNumerator 
lockdict variable _driftCorrectionNumerator 4 allot freedict
]
\
[ifndef _dTimeZoneOffset 
lockdict variable _dTimeZoneOffset 4 allot freedict 0 u>d _dTimeZoneOffset dL!
]
\
[ifndef _dticks/400years 
lockdict variable _dticks/400years 4 allot freedict
]
[ifndef _dticks/100years 
lockdict variable _dticks/100years 4 allot freedict
]
[ifndef _dticks/leapyear 
lockdict variable _dticks/leapyear 4 allot freedict
]
\
[ifndef _dticks/year
lockdict variable _dticks/year 4 allot freedict
]
[ifndef _dticks/day 
lockdict variable _dticks/day 4 allot freedict
]
\
[ifndef _dticks/hour 
lockdict variable _dticks/hour 4 allot freedict
]
\
[ifndef _dticks/min 
lockdict variable _dticks/min 4 allot freedict
]
\
\
clkfreq u>d 
d_60 u>d du* 2dup _dticks/min dL!
d_60 u>d du* 2dup _dticks/hour dL!
d_24 u>d du* 2dup _dticks/day dL!
\
2dup d_365 u>d du* _dticks/year dL!
2dup d_366 u>d du* _dticks/leapyear dL!
\
\
\ days per 100 years = 100 * 365 + 24 leapdays = 36_524
2dup d_36_524 u>d du* _dticks/100years dL!
\
\ days per 400 years = 400 * 365 + 97 leapdays = 146_097
d_146_097 u>d du* _dticks/400years dL!
\
\
\
\ Tick / Date Time routines
\
\
\ isleap ( yyyy -- t/f)
[ifndef isleap
: isleap
	dup 3 and 0=
	if					\ divisible by 4   - yes
		dup d_100 u/mod drop 0=		\ divisible by 100 - no 
		if 
			d_400 u/mod drop 0=	\ divisible by 400 - yes
		else 
			drop -1
		then
	else 
		drop 0 
	then
;
]
\
\
\ This routine is slow, but it only gets called when the time is being set or
\ conversions, probably not worth a re-write
\
\ y>t ( yyyy -- tickslo tickshi ) year > ticks
: y>t
	d_1970 max
	dup
	d_1970 =
	if
		drop 0 u>d
	else
		dup d_1970 - d_365 u* swap
		d_1970
		do
			i isleap
			if
				1+
			then
		loop
		u>d _dticks/day dL@ du*
	then
;
\
\ This routine is also slow, and it gets called every time a timestamp is generated
\
\ _t>y ( tickslo ticksthi -- remlo remhi y)
: _t>y
	ddup 0 u>d d=
	if
		d_1970
	else
		0 rot2
		d_9281 d_1970
		do
			i isleap
			if
				_dticks/leapyear
			else
				_dticks/year
			then
			dL@ d2dup du>=
			if
				d-
			else
				ddrop rot drop i leave
			then
		loop
	then
;
\	
\
lockdict
wvariable _dpm d31 w, d59 w, d90 w, d120 w, d151 w, d181 w, d212 w, d243 w, d273 w, d304 w, d334 w, 0 _dpm W!
freedict
\
lockdict
wvariable _ldpm d31 w, d60 w, d91 w, d121 w, d152 w, d182 w, d213 w, d244 w, d274 w, d305 w, d335 w, 0 _ldpm W!
freedict
\
\ ymd>t ( yyyy mm dd -- tickslo tickshi ) ymd > ticks
: ymd>t
	1- >r 1- >r dup >r y>t r> r> r>
	rot isleap
	if
		_ldpm
	else
		_dpm
	then

	rot 2* + W@ + u>d _dticks/day dL@ du*
	d+
;
\
\ _t>ymd ( tickslo tickshi -- remlo remhi yy mm dd )
: _t>ymd
	_t>y
	dup >r
	isleap
	if
		_ldpm
	else
		_dpm
	then
	rot2
	_dticks/day dL@ du/mod d>u
	>r rot d22 + r> swap
	d12 0
	do
		2dup W@ u>=
		if
			W@ - 11 i -
			leave
		else
			2-
		then
	loop		
	1+ swap 1+
	r>
	rot2
;


\
\ ymdhms>t ( y m d h m s -- tlo thi )
: ymdhms>t
	>r >r >r
	ymd>t 
	r> u>d _dticks/hour dL@ du* d+
	r> u>d _dticks/min dL@ du* d+
	r> u>d clkfreq u>d du* d+
;

\
\ _t>ymdhms ( tickslo tickshi -- y m d h m s rem  )
: _t>ymdhms
	_t>ymd
	>r >r rot2 r> rot2 r> rot2
	_dticks/hour dL@ du/mod d>u rot2
	_dticks/min dL@ du/mod d>u rot2
	clkfreq u>d du/mod d>u rot2 d>u
;

\
\
\ the lock used to access the timecount
[ifndef _timelock
6 wconstant _timelock
]
\	
lockdict create __tickcounter forthentry
$C_a_lxasm w, h12E  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z2WiPik l, z2WyPj0 l, z8FPeB l, z20yPO4 l, z8FPmB l, z24yPO4 l, zDVPW6 l,
z1SS04Q l, z2WiPyk l, z27FPuD l, z8FPuB l, z20yPO4 l, z38yPj0 l, z8FPmB l, zCVPW7 l,
z24yPO4 l, z2WiPeF l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l,
0 l, 0 l, z1SV04Q l,
freedict

lockdict create __tickCNTat forthentry
$C_a_lxasm w, h11E  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SyLIZ l, z2WiPeB l, zDVPW6 l, z1SS04L l, z8iPRD l, z20yPb4 l, z8iPmD l, zCVPW7 l,
z1SyJQL l, z2WiPRE l, z1SV01X l,
freedict

\ _dtickCNT@ ( -- n1 n2 ) n1 - lo long of timecount n2, hi long of timecount
: _dtickCNT@
	_dtickCNT _timelock __tickCNTat _driftCorrectionNumerator dL@ _dticks/hour dL@ d*/ 
;


\
\ _dsettime ( tlo thi -- )
: _dsettime
	_dtickCNT@ d- _dtimeOffset dL!
;

\
\ _dsetLocaltime ( tlo thi -- )
: _dsetLocaltime
	_dTimeZoneOffset dL@ d- _dtickCNT@ d- _dtimeOffset dL!
;

\ setTimeZone ( h m -- ) - sets the time zone h and m can be positive or negative
: setTimeZone
	dup 0>=
	if
		u>d _dticks/min dL@ du*
	else
		abs
		u>d _dticks/min dL@ du*
		0 u>d dswap d-
	then

	rot
	dup 0>=
	if
		u>d _dticks/hour dL@ du*
	else
		abs
		u>d _dticks/hour dL@ du*
		0 u>d dswap d-
	then
	d+ _dTimeZoneOffset dL!
;
\
\ setTime ( y m d h m s -- ) sets the UTC time
: setTime
	ymdhms>t _dsettime
;
\ setLocalTime ( y m d h m s -- ) subtracts the time zone, then sets UTC time
: setLocalTime
	ymdhms>t _dsetLocaltime
;
\
\ _dgettime ( -- tlo thi) gets a 64bit (double) value which is the number of ticks since
\                         1970-01-01_00:00:00
: _dgettime
	_dtickCNT@ _dtimeOffset dL@ d+
;
\
\ _dgetLocaltime ( -- tlo thi) gets a 64bit (double) value which is the number of ticks since
\                              1970-01-01_00:00:00 + time zone
: _dgetLocaltime
	_dtickCNT@ _dtimeOffset dL@ d+ _dTimeZoneOffset dL@ d+
;

\ getTime ( -- y m d h m s ticks -- ) gets UTC time
: getTime
	_dgettime _t>ymdhms
;
\ getLocalTime ( -- y m d h m s ticks -- ) gets local time
: getLocalTime
	_dgetLocaltime _t>ymdhms
;
\
\ formatTime ( -- y m d h m s ticks -- cstr) formats a to a printable sortable string
: formatTime
	d_1000_000 clkfreq u*/ 
	<#
		# # # # # # drop h2E #C
		# # drop h3A #C # # drop h3A #C # # drop
		h5F #C # # drop h2D #C # # drop h2D #C # # # #
	#>
;
\
\ getTimeStr( -- cstr) get the current UTC time as a string
: getTimeStr
	getTime formatTime
;
\
\ getLocalTimeStr( -- cstr) get the current local time as a string
: getLocalTimeStr
	getLocalTime formatTime
;
\
\ time ( -- ) print the local time
: time 
	getLocalTimeStr .cstr cr
;
\ setDriftCorrection ( n1 -- ) sets the time correction to n1 ticks per hour
: setDriftCorrection
		i>d _dticks/hour dL@ d+ _driftCorrectionNumerator dL!
;
\
\ utc ( -- ) print the utc time
: utc 
	getTimeStr .cstr cr
;
\
\
\ timeStamp ( -- lo hi) gets a number which is the time stamp in microseconds (UTC)
\                       the number of microseconds since 1970-01-01 00:00:00
\                       print with d. or the double format words
: timeStamp
	_dgettime d_1_000_000 u>d clkfreq u>d du*/
;
\ unixTimeStamp ( -- lo hi) gets a number which is the time stamp in seconds (UTC)
\                           the number of seconds since 1970-01-01 00:00:00
\                           print with d. or the double format words
: unixTimeStamp
	timeStamp d_1_000_000 u>d du/
;
\ _tickCounter ( addr_dticks _timelock -- )
: _tickCounter
	4 state andnC!
	c" TIME COUNTER" cds W!

	clkfreq u>d 
	d_60 u>d du* 2dup _dticks/min dL!
	d_60 u>d du* 2dup _dticks/hour dL!
	d_24 u>d du* 2dup _dticks/day dL!
\
	2dup d_365 u>d du* _dticks/year dL!
	2dup d_366 u>d du* _dticks/leapyear dL!
\
\
\ days per 100 years = 100 * 365 + 24 leapdays = 36_524
	2dup d_36_524 u>d du* _dticks/100years dL!
\
\ days per 400 years = 400 * 365 + 97 leapdays = 146_097
	d_146_097 u>d du* _dticks/400years dL!
\
	timeZoneHours timeZoneMinutes setTimeZone
	0 setDriftCorrection
\
	cnt COG@ _dtickCNT L!

	__tickcounter
;

\ dow ( tlo thi -- dow ) dow - 0 - Sun, 1 -Mon ... 6 - Sat
: dow
	_dticks/day dL@ du/
	7 0 du/mod
	3drop 4 +
	dup 7 >=
	if
		7 -
	then
;

: startTickCounter
	doubleTimerCog cogreset d_100 delms
\ clear the lock explicitly 
	_timelock 7 hubopf drop
	c" _dtickCNT _timelock _tickCounter" doubleTimerCog cogx d_100 delms
	d_2012 1 1 d_12 0 0 setTime
;

startTickCounter



{
fl	
: ttest
	1000 0
	do
		getTimeStr
		7 lock
		.concstr c"  COG: " .concstr cogid .con .concr
		7 unlock
	loop
;
: test
	time cr
	1000 0
	do
		getTime 3drop 3drop drop
	loop
	time cr
;

: utt
	c" ttest" dup 1 cogx
	dup 2 cogx
	dup 3 cogx
	dup 4 cogx
	5 cogx
;

}


{
fl

\ __tickcounter ( addr_dticks _timelock-- )
\
build_BootOpt :rasm
	spopt
\
\ $C_stTOS - addr_dticks
\ $C_treg1 - _timelock
\
	mov	$C_treg2 , cnt
	mov	$C_treg3 , # 0 

	wrlong	$C_treg2 , $C_stTOS
	add	$C_stTOS , # 4
	wrlong	$C_treg3 , $C_stTOS
	sub	$C_stTOS , # 4

__mainloop
		lockset	$C_treg1 wc
	if_c	jmp	# __mainloop


		
		mov	$C_treg4 , cnt

		cmp	$C_treg4 , $C_treg2 wz wc

		wrlong	$C_treg4 , $C_stTOS
		add	$C_stTOS , # 4
		addx	$C_treg3 , # 0

		wrlong	$C_treg3 , $C_stTOS

		lockclr	$C_treg1

		sub	$C_stTOS , # 4
		mov	$C_treg2 , $C_treg4
\
\ Make sure the window for other cogs to access is wide enough to prevent deadlock
\
		nop
		nop
		nop
		nop

		nop
		nop
		nop
		nop
		

	jmp	# __mainloop


;asm __tickcounter

\ __tickCNTat ( addr_dticks _timelock -- countlo counthi )
build_BootOpt :rasm
	spopt
\
\ $C_stTOS - addr_dticks
\ $C_treg1 - _timelock
\
	mov	$C_treg2 , $C_stTOS

__mainloop
		lockset	$C_treg1 wc
 if_c	jmp	# __mainloop
	
	rdlong	$C_stTOS , $C_treg2
	add	$C_treg2 , # 4
	rdlong	$C_treg3 , $C_treg2

	lockclr $C_treg1
	spush
	mov	$C_stTOS , $C_treg3

	jexit

;asm __tickCNTat


}


