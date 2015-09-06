1 wconstantbuild_servo.f

\
\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[ifndef waitcnt
: waitcnt
	_xasm2>1 h1F1 _cnip
;
]

\ a cog special register
[ifndef ctra
h1F8	wconstant ctra 
]

\ a cog special register
[ifndef ctrb
h1F9	wconstant ctrb
]

\ a cog special register
[ifndef frqa
h1FA	wconstant frqa
]

\ a cog special register
[ifndef frqb
h1FB	wconstant frqb
]

\ a cog special register
[ifndef phsa
h1FC	wconstant phsa
]

\ a cog special register
[ifndef phsb
h1FD	wconstant phsb
]

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

\ ------__________________________________________________________________________------_____ ctrb pin n1 + 1
\ __________------___________________________________________________________________________ ctrb pin n1 + 3
\ ____________________------_________________________________________________________________ ctrb pin n1 + 5
\ ______________________________------_______________________________________________________ ctrb pin n1 + 7
\ ________________________________________------_____________________________________________ ctrb pin n1 + 9
\ __________________________________________________------___________________________________ ctrb pin n1 + 11
\ ____________________________________________________________------_________________________ ctrb pin n1 + 13
\ ______________________________________________________________________------_______________ ctrb pin n1 + 15



\
\ This constant defines the number of times per second a pulse is generated
\ for the servo motor.
\
d_50 wconstant sm_cyclefreq

\
\ The number of clock cycles in one pulse sequence of 20ms
\
clkfreq sm_cyclefreq u/ constant sm_cyclecnt

\
\ The number of cycles in 2.5ms, 1/8 of the 20 ms cycle. However an effect
\ of this is that the maximum pulse time is 2.5ms less the time it take to
\ process a cycle. Thus the absolute maximum time it for a pulse width is
\ approximately 2.39ms to 2.4ms on an 80mHz system.
\
sm_cyclecnt 8 u/ constant sm_cyclecnt/8

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
\ This variable defines which IO pins are enabled as outputs
\ by the servo driver, the default is 0 - 27 since 30 & 31 are used
\ for the serial port, and 28 & 29 for the eeprom
\
\ variable sm_enable h_0FFF_FFFF sm_enable L!
variable sm_enable h_0000_000F sm_enable L!

\
\ this array defines the pulse hi times, it is initialized 1/2 way between
\ the min and max
\
lockdict variable sm_hitime d_124 allot freedict		\ 32 longs

\
\ this array defines the minimum pulse hi time, it is initialized to the minimum
\
lockdict variable sm_minhitime d_124 allot freedict	\ 32 longs

\
\ this array defines the maximum pulse hi time, it is initialized to the maximum
\
lockdict variable sm_maxhitime d_124 allot freedict	\ 32 longs

\
\ _sm_idx ( n1 addr -- addr ) calculates the array offset for the particular servo
: _sm_idx
	swap 0 max d_31 min 4* +
;
	

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

	>r
\					( n1 n2 timen1 -- )
 	rot  <# # # #> .cstr h2D emit hF4240 clkfreq u*/ <# # # # # #> .cstr space
	r>
 	swap <# # # #> .cstr h2D emit hF4240 clkfreq u*/ <# # # # # #> .cstr space
;


\ sm_setminmax ( min max n1 -- ) sets calibration parameters for each servo
: sm_setminmax
	swap sm_maxhi min over sm_maxhitime _sm_idx L!
	swap sm_minhi max swap sm_minhitime _sm_idx L!
;

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


\ sm_calibrate ( n1 -- ) n1 - servo
: sm_calibrate
	begin
		." a - <<<<    s - <<<    d - <<    f - <    h - >    j - >>    k - >>>    l - >>>>" cr

		." Move servo to leftmost position then hit enter" cr
		_sm_cal cr
		dup sm_hitime _sm_idx L@ swap
\										\ ( left n1 -- )

		." Move servo to rightmost position then hit enter" cr
		_sm_cal cr
		dup sm_hitime _sm_idx L@ swap
\										\ ( left right n1 -- )
		dup >r sm_setminmax
		r>
\										\ ( center left-center right n1 -- )

		." 0 - Leftmost   1 - Center    2 - Rightmost     r - Recalibrate    ESC - Done" cr
		0 begin
			drop
			key
			dup h30 = if over 0 sm_setpos else 
			dup h31 = if over h1388 sm_setpos else 
			dup h32 = if over h2710 sm_setpos
			thens
			over _sm_cal2
	
			dup h1B = over 72 = or
		until
		h1B =
	until
	cr dup sm_minhitime _sm_idx L@ . dup sm_maxhitime _sm_idx L@ . . cr  
;
	
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

\ calibration for servos
\	105000 200000 0 sm_setminmax

	32 0
	do
		i sm_minhitime _sm_idx L@
		i sm_maxhitime _sm_idx L@
		over - 2/ +
 
		i sm_hitime _sm_idx L!
	loop

	1 cogreset h_10 delms c" 0 sm_servo" 1 cogx
\	1 cogreset h_10 delms c" d_16  sm_servo" 2 cogx
	10 delms
;


