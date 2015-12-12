fl
\
fsclear
\
fswrite btstat.f

\ for the HC05
\ white wire
[ifndef hcProgPin
	25 wconstant hcProgPin
]
\ red wire
[ifndef hcRx
	26 wconstant hcRx
]
\  blue wire
[ifndef hcTx
	27 wconstant hcTx
]
\
[ifndef hcBaud
\ initital baud
\	d_9600 4/ wconstant hcBaud
\ operatingbaud
	d_230_400 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]
\
[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;
]
\
hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags
\
\
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;
\
hcProgPin pinhi hcProgPin pinout
\
c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend
\
hcProgPin pinlo 
\

...

fswrite btinit.f


\ for the HC05
\ white wire
[ifndef hcProgPin
	25 wconstant hcProgPin
]
\ red wire
[ifndef hcRx
	26 wconstant hcRx
]
\  blue wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef hcBaud
\ initital baud
\	d_9600 4/ wconstant hcBaud
\ operatingbaud
	d_230_400 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]
\
[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;
]
\
hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags
\
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;
\
hcProgPin pinhi hcProgPin pinout
\
c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend
c" AT+NAME=SIGHT_848~h0D~h0A" hcSend
c" AT+PSWD=8488~h0D~h0A" hcSend
c" AT+UART=230400,0,0~h0D~h0A" hcSend
c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend
\
hcProgPin pinlo 
\

...

\
fswrite boot.f
hA state orC! version W@ .cstr cr cr cr
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
\
c" boot.f - Finding top of eeprom, " .cstr findEETOP ' fstop 2+ alignl L! forget findEETOP c" Top of eeprom at: " .cstr fstop . cr
\
\
c" boot.f - DONE PropForth Loaded~h0D~h0D" .cstr hA state andnC!
\
\
1 wconstant build_servo
\
\
\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[ifndef waitcnt
: waitcnt
	_xasm2>1 h1F1 _cnip
;
]
\
\ a cog special register
[ifndef ctra
h1F8	wconstant ctra 
]
\
\ a cog special register
[ifndef ctrb
h1F9	wconstant ctrb
]
\
\ a cog special register
[ifndef frqa
h1FA	wconstant frqa
]
\
\ a cog special register
[ifndef frqb
h1FB	wconstant frqb
]
\
\ a cog special register
[ifndef phsa
h1FC	wconstant phsa
]
\
\ a cog special register
[ifndef phsb
h1FD	wconstant phsb
]
\
\
\ Servo motors are controlled by a pulse width modulation (pwm).
\ Every 20 milliseconds a pulse of length 0.75 milliseconds 
\ to 2.25 millseconds determines the position of the servo motor.
\
\ Example1: 0.75ms
\ ---_____________________________________________________________________________---________
\
\ Example2: 1.5ms
\ ------__________________________________________________________________________------_____
\
\ Example3: 2.25ms
\ ---------_______________________________________________________________________---------__
\
\
\ Each servo motor requires calibration, so we will set the absolute minimum to 0.5 ms and the
\ absolute maximum to 2.5 ms. Depending on the servos you are using, you may want to adjust these
\ values. 
\

\
\ This driver will drive 16 servos per cog, it uses the 2 counters in a time domain multiplexed
\ mode to generate the pulses.
\
\ Each counter is set to single ended PWM/NCO mode. In this mode the counter drives an io pin.
\ The value of the pin is controlled by bit 31 of the phsa/phsb registers. These registers and
\ incremented every cycle of the system clock. For an 80 Mhz system clock this provides for
\ 12.5 ns resolution.
\
\ Without intervention the phsa/phsb registers would generate a square wave with the cycle time
\ being more than 50 seconds
\ ----------------------____________________----------------------____________________
\
\ By starting the phsa/phsb register at the appropriate place in the cycle, and by resetting
\ it to the same position every 20 ms, we generate a pwm signal on the io pin.
\
\ Since there are 2 counters we can do this with 2 pins at a time.
\
\ And since we only need intervention during the hi time of the signal, we can interleave the
\ processing so that each clock will address 8 io pins.
\
\ This is done by taking the 20ms cycle, and splitting it into 8 2.5ms sections, and driving the
\ corresponding pin hi in that portion of the cycle.
\
\ This means the absolute maximum we can set the pulse width will be 2.5ms
\
\ 0ms                 5ms                 10ms                15ms                20ms
\ ------__________________________________________________________________________------_____ ctra pin n1
\ __________------___________________________________________________________________________ ctra pin n1 + 2
\ ____________________------_________________________________________________________________ ctra pin n1 + 4
\ ______________________________------_______________________________________________________ ctra pin n1 + 6
\ ________________________________________------_____________________________________________ ctra pin n1 + 8
\ __________________________________________________------___________________________________ ctra pin n1 + 10
\ ____________________________________________________________------_________________________ ctra pin n1 + 12
\ ______________________________________________________________________------_______________ ctra pin n1 + 14
\
\ ------__________________________________________________________________________------_____ ctrb pin n1 + 1
\ __________------___________________________________________________________________________ ctrb pin n1 + 3
\ ____________________------_________________________________________________________________ ctrb pin n1 + 5
\ ______________________________------_______________________________________________________ ctrb pin n1 + 7
\ ________________________________________------_____________________________________________ ctrb pin n1 + 9
\ __________________________________________________------___________________________________ ctrb pin n1 + 11
\ ____________________________________________________________------_________________________ ctrb pin n1 + 13
\ ______________________________________________________________________------_______________ ctrb pin n1 + 15
\
\
\
\
\ This constant defines the number of times per second a pulse is generated
\ for the servo motor.
\
d_50 wconstant sm_cyclefreq
\
\
\ The number of clock cycles in one pulse sequence of 20ms
\
clkfreq sm_cyclefreq u/ constant sm_cyclecnt
\
\
\ The number of cycles in 2.5ms, 1/8 of the 20 ms cycle. However an effect
\ of this is that the maximum pulse time is 2.5ms less the time it take to
\ process a cycle. Thus the absolute maximum time it for a pulse width is
\ approximately 2.39ms to 2.4ms on an 80mHz system.
\
sm_cyclecnt 8 u/ constant sm_cyclecnt/8
\
\
\ These constants define the absolute minium and maximum lengths of time
\ for the pulse. The maximum can never be more than the time slot.
\
\ The minimum was set to 500usec and and maximum to 2500usec
\ but someone managed to turn their servo into a countinuos rotation servo
\ without intending to do so.
\ So the defaults are set to 750usec and 2250usec.
\
clkfreq d_750   d_1_000_000 u*/ constant sm_minhi
clkfreq d_2_250 d_1_000_000 u*/ sm_cyclecnt/8 min constant sm_maxhi
\
\
\ This variable defines which IO pins are enabled as outputs
\ by the servo driver, the default is 0 - 27 since 30 & 31 are used
\ for the serial port, and 28 & 29 for the eeprom
\
\ variable sm_enable h_0FFF_FFFF sm_enable L!
variable sm_enable h_0000_0060 sm_enable L!
\
\
\ this array defines the pulse hi times, it is initialized 1/2 way between
\ the min and max
\
lockdict variable sm_hitime d_124 allot freedict		\ 32 longs
\
\
\ this array defines the minimum pulse hi time, it is initialized to the minimum
\
lockdict variable sm_minhitime d_124 allot freedict	\ 32 longs
\
\
\ this array defines the maximum pulse hi time, it is initialized to the maximum
\
lockdict variable sm_maxhitime d_124 allot freedict	\ 32 longs
\
\
\ _sm_idx ( n1 addr -- addr ) calculates the array offset for the particular servo
: _sm_idx
	swap 0 max d_31 min 4* +
;
\	
\
\ sm_setpos ( n1 u -- ) n1 is an integer between 0 and 31, u is an unsigned integer between 0 and 10,000
: sm_setpos
	0 max d_10_000 min
\						\ ( n1 u -- )
	over dup sm_minhitime _sm_idx L@
\						\ ( n1 u n1 minhitime -- )
	swap sm_maxhitime _sm_idx L@ 
\						\ ( n1 u minhitime maxhitime -- )
	over -
\						\ ( n1 u minhitime range -- )
	rot d_10_000 u*/ +
\						\ ( n1 pos -- )
	swap sm_hitime _sm_idx L! 
;  
\
\
\
\
\ sm_servo ( n1 -- ) this cog will drive servos n1 to n1 + 15
: sm_servo
	4 state andnC!
	c" SERVO" cds W!
\				\ ( n1 -- )
	0 max h18 min
	dup h_10 bounds
	do
		sm_enable L@ 1 i lshift and
		if
			i dup pinlo pinout
		then
	loop
\				\ ( n1 -- )
	1 frqa COG!
	1 frqb COG!
\				\ counter set to drive pin n1, single ended nco/pwm mode
	dup h_1000_0000 +
\				\ the offset into the array defining the pulse width
	swap 4* sm_hitime +
\				\ ( ctrn1 hitimeoffset -- )
	cnt COG@ sm_cyclecnt +
\				\ ( ctrn1 hitimeoffset nextcycletime -- )
	begin
		h10 0
		do
			0 phsa COG! 0 phsb COG!
\				\ counter a set to drive pin n1,   single ended nco/pwm mode
\				\ counter b set to drive pin n1+1, single ended nco/pwm mode
\				\ ( ctrn1 hitimeoffset nextcycletime -- )
			rot dup i + dup ctra COG!
			1 + ctrb COG!
\				\ ( hitimeoffset nextcycletime ctrn1 -- )
			rot dup i 2 lshift + dup L@ negate phsa COG!
			4 + L@ negate phsb COG!
\				\ ( nextcycletime ctrn1 hitimeoffset -- )
			rot
\				\ ( hitimeoffset ctrn1 nextcycletime -- )
\				\ wait for the next 2.5ms time slot
			sm_cyclecnt/8 waitcnt
		2 +loop
	0 until
;
\
\ _pos? ( n1 n2 -- n3 n4 ) n3 usec per cycle for pin n1, n4 usec per cycle for pin n2
: _pos?
\					\ increment counter when pulse is hi for pin n1
	h_6800_0000 + ctra COG! 1 frqa COG!
\					\ increment counter when pulse is hi for pin n2
	h_6800_0000 + ctrb COG! 1 frqb COG!
\					\ zero counts, wait one cycle and get counts
	cnt COG@ 0 phsb COG! 0 phsa COG! 
	sm_cyclecnt + 0 waitcnt
	phsb COG@ phsa COG@
\					\ display number of usec pin was hi in one cycle count
	rot drop
\					( n1 n2 timen1 timen2 -- )
;

\ pos? ( n1 n2 -- ) display for pin n1 and pin n2 the number of usec hi per cycle
: pos?
	2dup
	_pos?
\
	>r
\					( n1 n2 timen1 -- )
 	rot  <# # # #> .cstr h2D emit hF4240 clkfreq u*/ <# # # # # #> .cstr space
	r>
 	swap <# # # #> .cstr h2D emit hF4240 clkfreq u*/ <# # # # # #> .cstr space
;
\
\
\ sm_setminmax ( min max n1 -- ) sets calibration parameters for each servo
: sm_setminmax
	swap sm_maxhi min over sm_maxhitime _sm_idx L!
	swap sm_minhi max swap sm_minhitime _sm_idx L!
;
\
\ _sm_cal2 ( n1 -- )
\ _sm_cal2
: _sm_cal2
	sm_enable L@ over 3 swap lshift and
	if
		dup 1+ pos?
		hD emit
	else
		drop
	then
;
\
\ _sm_cal1 ( servo key delta -- servo key )
: _sm_cal1
	rot tuck
\					\ ( key servo delta servo -- )
	sm_hitime _sm_idx dup
\					\ ( key servo delta addr addr -- )
	L@ rot + sm_minhi max sm_maxhi min swap L!
\					\ ( key servo -- )
	swap
;
\
\ _sm_cal ( n1 -- n1 ) n1 - the serv0 0 - 9
: _sm_cal
	begin
		key
		dup h61 = if h-2710 _sm_cal1 else
		dup h73 = if h-3E8 _sm_cal1 else
		dup h64 = if h-64 _sm_cal1 else
		dup h66 = if h-10 _sm_cal1 else
		dup h68 = if h10 _sm_cal1 else
		dup h6A = if h64 _sm_cal1 else
		dup h6B = if h3E8 _sm_cal1 else
		dup h6C = if h2710 _sm_cal1
		thens
		over _sm_cal2
		hD =
	until
;
\
\
\ sm_calibrate ( n1 -- ) n1 - servo
: sm_calibrate
	begin
		." a - <<<<    s - <<<    d - <<    f - <    h - >    j - >>    k - >>>    l - >>>>" cr

		." Move servo to leftmost position then hit enter" cr
		_sm_cal cr
		dup sm_hitime _sm_idx L@ swap
\										\ ( left n1 -- )
\
		." Move servo to rightmost position then hit enter" cr
		_sm_cal cr
		dup sm_hitime _sm_idx L@ swap
\										\ ( left right n1 -- )
		." Calibration parameters: " rot dup . rot dup . rot dup . cr
		dup >r sm_setminmax
		r>
\										\ ( center left-center right n1 -- )
\
		." 0 - Leftmost   1 - Center    2 - Rightmost     r - Recalibrate    ESC - Done" cr
		0 begin
			drop
			key
			dup h30 = if over 0 sm_setpos else 
			dup h31 = if over h1388 sm_setpos else 
			dup h32 = if over h2710 sm_setpos
			thens
			over _sm_cal2
\	
			dup h1B = over 72 = or
		until
		h1B =
	until
	cr dup sm_minhitime _sm_idx L@ . dup sm_maxhitime _sm_idx L@ . . cr  
;
\	
\ 
\
\
\ sm_start_servos ( -- ) runs 32 servo drivers on cogs 0 - 1, io pins 0 - 31
\ 			modify after calibrating servos
: sm_start_servos
\ initialize arrays, default calibration
\
	32 0
	do
		sm_minhi i sm_minhitime _sm_idx L!
		sm_maxhi i sm_maxhitime _sm_idx L!
	loop
\
\ calibration for servos
\	105000 200000 0 sm_setminmax

	32 0
	do
		i sm_minhitime _sm_idx L@
		i sm_maxhitime _sm_idx L@
		over - 2/ +
\ 
		i sm_hitime _sm_idx L!
	loop
\
	1 cogreset h_10 delms c" 0 sm_servo" 1 cogx
\	2 cogreset h_10 delms c" d_16  sm_servo" 2 cogx
	10 delms
;
\
\
\
1 wconstant build_sightbox
: sbv c" Sight Box Software Version 2013-JAN-15 11:58:00~h0D~h0D" ;
\
\
\
d_40 wconstant cal_time
\
fsload cal.f
\
\
\ Set the console bluetooth serial port
\
\
\
\ running pin definitions
\
\
\ bluetooth 
\
\ white wire
25 wconstant hcProgPin
\
\ red wire
26 wconstant hcRx
\
\  blue wire
27 wconstant hcTx
\
\ led on board
0 wconstant _red_led
1 wconstant _green_led
2 wconstant _yellow_led
\
4 wconstant _laser
5 wconstant _vertical_servo
6 wconstant _horizontal_servo
\
\ 8 pin connectoreon right - from rear forward
\
\ 5v   - red
\ 3.3v - nc
\ GND  - brown
\ IO-7 - nc
\ IO-6 - yellow
\ IO-5 - green
\ IO-4 - white
\ IO-3 - nc
\
\
\
\
\ RJ45 connector
\
\
\ Orange/White - GND
\ Orange       - IO-09 -- Pullup / remote red led
\ Green/White  - IO-10 -- Top switch PB
\ Green        - IO-11 -- Top switch rotate 1
\ Brown/White  - IO-12 -- Top switch rotate 2
\ Brown        - IO-13 -- Side switch PB
\ Blue/White   - IO-14 -- Side switch rotate 1
\ Blue         - IO-15 -- Side switch rotate 2
\
\
\ Bluetooth
\
\ ID: SIGHT_848
\ Pairing Code: 8488
\
\ Debug bits
\
\ bit 0 - Echo rotate and up down commands
\ bit 1 - Echo tick command
\ bit 2 - Display in port bit changes
\ bit 3 - Display XY commands
\ bit 4 - Debug information - display every 8 seconds
\
\
wvariable in_debug 0 in_debug W!
variable bootTicks
variable _in_nextTickCount
\
\ _in_monitor1 ( 0 old new diff -- cmd old new diff -- )
: _in_monitor1
	dup h2000 and if
		over h2000 and
		if
			c" sideUp" 3 ST!
		else
			c" sideDown" 3 ST!
		then
	else dup h8000 and if
		over h8000 and 0=
		if
			over h4000 and
			if
				c" sideCW" 3 ST!
			else
				c" sideCCW" 3 ST!
			then
		then
	else dup h0400 and if
		over h0400 and
		if
			c" topUp" 3 ST!
		else
			c" topDown" 3 ST!
		then
	else dup h1000 and if
		over h1000 and 0=
		if
			over h0800 and
			if
				c" topCW"  3 ST!
			else
				c" topCCW"  3 ST!
			then
		then
	thens
;
\
\ _in_monitor2 ( cmd -- )
: _in_monitor2
	dup if
		in_debug W@ 1 and
		if
			c" DEBUG: " .concstr dup .concstr .concr
		then
		.cstr cr
	else
		drop
	then
;
\
: in_monitor
	4 state andnC!
	c" IN_MONITOR" cds W!
	9 pinout 9 pinhi ina COG@ hFC00 and
	cnt COG@ _in_nextTickCount L!
	0 bootTicks L!
	begin

		bootTicks L@ cal_time > cnt COG@ or h_400_0000 and 9 px
\ (old -- )
		9 px?
		if
			ina COG@ hFC00 and
			2dup xor 0<>
			if
\ ( old new -- )

				0 rot2 2dup xor
\ ( cmd old new diff -- )
				in_debug W@ 4 and
				if
					base W@ 2 base W!
					3 ST@ .conword  bl .conemit
					2 ST@ .conword  bl .conemit
					over .conword .concr
					base W!
				then

				_in_monitor1
\ ( cmd old new diff -- )
				drop rot
				_in_monitor2
			then
\ ( old new -- )
			nip
		then
\ ( new -- )
		_in_nextTickCount L@ cnt COG@ - 0 <=
		if
			c" tick"
			in_debug W@ 2 and
			if
				c" DEBUG: " .concstr dup .concstr .concr
			then
			.cstr cr

			_in_nextTickCount L@ clkfreq 4/ + _in_nextTickCount L!	
		then
		0
	until
	drop
;
\
wvariable in_topDown
wvariable in_sideDown
wvariable in_laserCount
wvariable in_scan
wvariable in_calibrate
wvariable in_laserFlash
\
wvariable x 
wvariable y
wvariable minX 
wvariable minY
wvariable maxX 
wvariable maxY
\
wvariable _clickIncrement
\
wvariable _scaledxy
\
\
d_333 wconstant _defClickIncrement
\
\
: _dbg
	c" ~h0D~h0Din_topDown: " .concstr in_topDown W@ .con
	c" ~h0Din_sideDown: " .concstr in_sideDown W@ .con
	c" ~h0Din_laserCount: " .concstr in_laserCount W@ .con
	c" ~h0Din_scan: " .concstr in_scan W@ .con
	c" ~h0Din_calibrate: " .concstr in_calibrate W@ .con
	c" ~h0Din_laserFlash: " .concstr in_laserFlash W@ .con
	c" ~h0Dx: " .concstr x W@ .con
	c" ~h0Dy: " .concstr y W@ .con
	c" ~h0DminX: " .concstr minX W@ .con
	c" ~h0DminY: " .concstr minY W@ .con
	c" ~h0DmaxX: " .concstr maxX W@ .con
	c" ~h0DmaxY: " .concstr maxY W@ .con
	c" ~h0D_clickIncrement: " .concstr _clickIncrement W@ .con
	c" ~h0D_scaledxy: " .concstr _scaledxy W@ .con
	c" ~h0DbootTicks: " .concstr bootTicks L@ .con
	c" ~h0D_in_nextTickCount: " .concstr _in_nextTickCount L@ .con
	c" ~h0D_in_debug: " .concstr in_debug L@ .con
	c" ~h0Dcal_time: " .concstr  cal_time .con .concr .concr
;
\ limit ( x -- X )
: limit
	d_9999 min 0 max
;
\
\ _scalexy( x y -- scaleX scaleY)
: _scalexy
	limit swap limit swap
	d_2000 /mod
\ ( x ymod ydiv -- )
	rot d_2000 /mod
\ ( ymod ydiv xmod xdiv -- )
	4* cal_table +
\ ( ymod ydiv xmod caloff -- )
	rot d_24 u* +
\ ( ymod xmod caloff -- )
\	over . dup W@ . dup 4+ W@ . cr
\	2 ST@ . dup 2+ W@ . dup d_26 + W@ . cr

	dup 4+ W@ over W@ - rot d_2000 u*/ over W@ +
\ ( ymod caloff xscale -- )
	rot2
\ (xscale ymod caloff -- )
	dup 26 + W@ over 2+ W@ - rot d_2000 u*/ swap 2+ W@ +
\
	minY W@ max maxY W@ min swap
	minX W@ max maxX W@ min swap
; 
\
\
: setXY
	6 x W@ y W@
	_scaledxy W@
	if
		_scalexy
	then
	5 swap
	in_debug W@ 8 and
	if
		c" x y -> sX sY: " .concstr x W@ .con y W@ .con 2 ST@ .con dup .con .concr
	then

	sm_setpos sm_setpos
;


: setMinMaxXY
	d_5000 dup dup dup minX W! minY W!  maxX W! maxY W!
	0 cal_table d_148 bounds

	do
		i W@    minX W@ over min minX W! maxX W@ max maxX W! 
		i 2+ W@ minY W@ over min minY W! maxY W@ max maxY W!
	4 +loop
;

: cmd_proc
	4 state andnC!
	c" CMD_PROC" cds W!
	_red_led dup pinout pinhi
	_green_led dup pinout pinlo
	_yellow_led dup pinout pinlo
	_laser dup pinlo pinout
	0 in_topDown W!
	0 in_sideDown W!
	0 in_laserCount W!
	0 in_calibrate W!
	0 in_scan W!
	0 in_laserFlash W!
	_defClickIncrement _clickIncrement W!
	-1 _scaledxy W!
\
	d_5000 x W!
	d_5000 y W!
	d_102_000 d_170_000 5 sm_setminmax
	d_102_000 d_170_000 6 sm_setminmax
\
	setMinMaxXY
	d_5000 dup x W! y W! setXY
;
\
\
: topDown -1 in_topDown W! d_120 in_laserCount W! ;
: topUp 0 in_topDown W! ;
: sideDown -1 in_sideDown W! 0 in_laserCount W! ;
: sideUp 0 in_sideDown W! ;
\
: tick
	bootTicks L@ 1+ bootTicks L!
\
	in_laserCount W@ 0>
	in_laserFlash W@ dup 0= swap
	bootTicks L@ 1 and 
\
	and or and _laser px
\
	in_laserCount W@ 1- 0 max in_laserCount W!
\
	bootTicks L@ cal_time <= _green_led px
\
	in_topDown W@ in_sideDown W@ and
	if
		bootTicks L@ cal_time <=
		if
			in_calibrate W@ 0= in_scan W@ 0= and
			if
				-1 in_calibrate W!
				lockdict c" calibrate" nfcog cogx  freedict
			then
		else
			in_calibrate W@ 0= in_scan W@ 0= and
			if
				-1 in_scan W!
				lockdict c" scan" nfcog cogx  freedict
			then
		then
	then
\
	in_calibrate W@ in_scan W@ or _yellow_led px

	in_debug W@ h10 and bootTicks L@ h1F and 0= and
	if
		_dbg
	then
;
\
: dbg in_debug W! ;
\
: topCW y W@ _clickIncrement W@ + d_10000 min y W! setXY ;
: topCCW y W@ _clickIncrement W@ - 0 max y W! setXY ;
\
: sideCW x W@ _clickIncrement W@ + d_10000 min x W! setXY ;
: sideCCW x W@ _clickIncrement W@ - 0 max x W! setXY ;
\
: scan
	4 state andnC!
	c" SCAN" cds W!
	c" Scan started~h0D~h0D" .concstr
	d_240 in_laserCount W!
\
	d_5000 0 do
		i 2* x W! i y W! setXY
		d_50 delms
	d_100 +loop
\
	d_5000 0 do
		d_10000 i 2* - x W! i d_5000 + y W! setXY
		d_50 delms
	d_100 +loop
\
	d_10000 0 do
		d_10000 i - y W! setXY
		d_50 delms
	d_100 +loop
\
	d_10000 0 do
		i x W! setXY
		d_50 delms
	d_100 +loop
\
	d_5000 0 do
		d_10000 i 2* - x W! i y W! setXY
		d_50 delms
	d_100 +loop
\
	d_5000 0 do
		i 2* x W! i d_5000 + y W! setXY
		d_50 delms
	d_100 +loop
\
	d_5000 0 do
		d_10000 i - y W! setXY
		d_50 delms
	d100 +loop
\
	d_5000 0 do
		d_10000 i - x W! setXY
		d_50 delms
	d100 +loop
\
	d_5000 dup x W! y W! setXY d500 delms
\
	0 in_laserCount W!
	0 in_scan W!
	4 state orC!
	0 cds W!
	c" Scan done~h0D~h0D" .concstr
;
\
: calibrate
	4 state andnC!
	c" CALIBRATE" cds W!
	-1 in_calibrate W!
	d_50 _clickIncrement W!
	0 _scaledxy  W!
	begin
		in_topDown W@ in_sideDown W@ and 0=
	until
\
	c" Calibration started~h0D~h0D" .concstr
\
	0 cal_table d_148 bounds
\
	do
		i W@ x W! i 2+ W@ y W! setXY
		c" Original point: " .concstr x W@ .con y W@ .con .concr
		d_240 in_laserCount W!
		d_16000 0
		do
			d_100 delms
			in_sideDown W@
			if
				in_topDown W@
				if
					drop -1
					begin
						in_sideDown W@ in_topDown W@ and 0=
					until
				else
					begin
						in_sideDown W@ 0=
					until
				then
\
				leave
			then
		loop
\
		dup if
			leave
		else
			x W@ i W!
			y W@ i 2+ W!
			c" Calibrated point: " .concstr x W@ .con y W@ .con .concr
		then
	4 +loop
\
	_defClickIncrement _clickIncrement W!
	-1 _scaledxy W!
\
	0= if	
		d_5000 dup x W! y W! setXY
		d_40 in_laserCount W!
		-1 in_laserFlash W!
		c" Calibration write?~h0D~h0D" .concstr
\
		d_1000 0
		do
			d_100 delms
			in_topDown W@ in_sideDown W@ and
			if
				c" Calibration write started~h0D~h0D" .concstr
				0 in_laserFlash W!
				lockdict cogid nfcog iolink freedict
				." fsdrop~h0D~h0D"
				." fswrite cal.f~h0D~h0D"
				." lockdict wvariable cal_table -2 allot" cr
				0 cal_table d_148 bounds
				do
					." d_" i W@ . ." w, "
					1+ dup 12 >=
					if
						drop 0 cr
					then
				2 +loop
				drop
				." freedict~h0D~h0D...~h0D~h0D"
				cogid iounlink
				c" Calibration write done~h0D~h0D" .concstr
\
				d_50 in_laserCount W!
				d_5000 delms
\
				leave
			then
		loop
	then
\
	0 in_laserFlash W!
	0 in_laserCount W!
\
	0 in_calibrate W!
	4 state orC!
	0 cds W!
	c" Calibration done~h0D~h0D" .concstr
;
\
\
c" 848-" prop W@ ccopy
: onreset6
	fkey? and fkey? and or h1B <>
	if
		sm_start_servos
		c" in_monitor" 0 cogx
		c" cmd_proc" 2 cogx
		0 2 iolink
\
		$S_con iodis $S_con cogreset 100 delms
		c" hcRx hcTx 57600 serial" $S_con cogx 100 delms
		cogid >con
	then
	sbv .concstr
	c" onreset6" (forget)
;
\
\

...

\
fswrite cal.f

lockdict wvariable cal_table -2 allot
d_2950 w, d_900 w, d_4150 w, d_850 w, d_5450 w, d_750 w, d_6850 w, d_750 w, d_8250 w, d_950 w, d_9400 w, d_1150 w,
d_2800 w, d_2150 w, d_4050 w, d_2100 w, d_5350 w, d_2100 w, d_6800 w, d_2150 w, d_8200 w, d_2250 w, d_9300 w, d_2350 w,
d_2700 w, d_3600 w, d_3850 w, d_3550 w, d_5250 w, d_3550 w, d_6800 w, d_3600 w, d_8100 w, d_3650 w, d_9300 w, d_3750 w,
d_2650 w, d_4950 w, d_3800 w, d_5050 w, d_5300 w, d_5100 w, d_6700 w, d_5050 w, d_8000 w, d_5150 w, d_9250 w, d_5100 w,
d_2500 w, d_6350 w, d_3700 w, d_6500 w, d_5100 w, d_6550 w, d_6600 w, d_6600 w, d_7950 w, d_6600 w, d_9050 w, d_6550 w,
d_2450 w, d_7650 w, d_3600 w, d_7850 w, d_6250 w, d_8050 w, d_6550 w, d_7900 w, d_7900 w, d_7900 w, d_9100 w, d_7800 w,
d_6042 w, d_4367 w, freedict

...

