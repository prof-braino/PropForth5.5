fl

fswrite 4step.f
{

Drives a 4 phase stepper motor, tested with 28byj stepper motor wth a uln2003 driver

Create a structure, either a halfstep, or full step, specify the pins, 16 17 18 & 19 in this case


\ For half stepping
     16 17 18 19 step_create_halfstep moth


\ Initialize
     moth step_init

\ Step forward
     4096 moth step

\ Step reverse
     -4096 moth step

\ Turn off drivers
     moth step_sleep

\ Turn on drivers
     moth step_active

\ Set the step speed - setting too fast a speed will cause it to skip steps (1100 for test motor)
     1100 moth step_setspeed

\ or
\ For full stepping
     16 17 18 19 step_create_fullstep motf


\ Initialize
     motf step_init

\ Step forward
     2048 motf step

\ Step reverse
     -2048 motf step

\ Turn off drivers
     motf step_sleep

\ Turn on drivers
     motf step_active

\ Set the step speed - setting too fast a speed will cause it to skip steps (550 for test motor)
     550 motf step_setspeed



step structure
00 - 04 -- current step position - steps
04 - 08 -- current step velocity - steps / sec
08 - 0C -- max step velocity - steps / sec (should be a multiple of step acceleration)
0C - 10 -- step acceleration - steps / sec / sec (min 2)
10 - 14 -- step mask
14 - 34 -- 8 longs - step values
34 - 38 -- steps to speed
38 - 39 -- step position mask
}


\ 1 wconstant step_debug

h0  wconstant _step_position
h4  wconstant _step_current_velocity
h8  wconstant _step_max_velocity
hC  wconstant _step_accel
h10 wconstant _step_mask
h14 wconstant _step_bits
h34 wconstant _steps_to_speed
h38 wconstant _step_position_mask
h39 wconstant _step_size

[ifdef step_debug
\ step_dump ( addr -- )
: step_dump
	." current_position: " dup L@ . cr
	." current_velocity: " dup _step_current_velocity + L@ . cr
	."     max_velocity: " dup _step_max_velocity + L@ . cr
	."            accel: " dup _step_accel + L@ . cr
	."   steps to speed: " dup _steps_to_speed + L@ . cr
	."    position_mask: " dup _step_position_mask + C@ . cr
	base W@ swap hex
	."             mask: " dup _step_mask + L@ .long cr
	."             bits: "
	_step_bits + h20 bounds
	do
		i L@ .long space
	4 +loop
	base W!
	cr
;

\ step_dump1 ( addr -- )
: step_dump1
	." current_position: " dup L@ . 
	." current_velocity: " dup _step_current_velocity + L@ .
	."     max_velocity: " dup _step_max_velocity + L@ .
	."            accel: " _step_accel + L@ .
;
]

\ step_sleep ( addr -- )
: step_sleep
	_step_mask + L@ outa COG@ swap andn outa COG! 
;

\ step_active( addr -- )
: step_active
	dup _step_position + L@ over _step_position_mask + C@
	and 4* over + _step_bits + L@
	swap _step_mask + L@
	outa COG@ swap andn or outa COG!
;


\ step_init ( addr -- )
: step_init
 	dup _step_mask + L@ dira COG@ or dira COG!
	step_sleep	 
;

: _step_create1
	lockdict variable _step_size allot lastnfa nfa>pfa 2+ alignl freedict
	dup _step_size 0 fill
	4 ST@ >m 4 ST! 3 ST@ >m 3 ST! 2 ST@ >m  2 ST! 1 ST@ >m 1 ST!
;

: _step_create2
	rot2 or rot or rot or over _step_mask + L!
;

: _step_create3
	_step_bits + + L!
;

\ create a step structure

\ step_create_halfstep name ( n1 n2 n3 n4 -- )
: step_create_halfstep
	_step_create1
\ pin 1
	4 ST@ over 0 _step_create3
\ pin 1 2
	4 ST@ 4 ST@ or over 4 _step_create3
\ pin 2
	3 ST@ over 8 _step_create3
\ pin 2 3
	3 ST@ 3 ST@ or over hC _step_create3
\ pin 3
	2 ST@ over h10 _step_create3
\ pin 3 4 
	2 ST@ 2 ST@ or over h14 _step_create3
\ pin 4
	1 ST@ over h18 _step_create3
\ pin 4 1
	1 ST@ 5 ST@ or over h1C _step_create3

	_step_create2

	d_700 over _step_max_velocity + L!
	d_10  over _step_accel + L!
	d_70  over _steps_to_speed + L!

	_step_position_mask + 7 swap C!
;


\ step_create_fullstep name ( n1 n2 n3 n4 -- )
: step_create_fullstep
	_step_create1
\ pin 1 2
	4 ST@ 4 ST@ or over 0 _step_create3
\ pin 2 3
	3 ST@ 3 ST@ or over 4 _step_create3
\ pin 3 4 
	2 ST@ 2 ST@ or over 8 _step_create3
\ pin 4 1
	1 ST@ 5 ST@ or over h10 _step_create3

	_step_create2

	d_500 over _step_max_velocity + L!
	d_10  over _step_accel + L!
	d_50  over _steps_to_speed + L!
	_step_position_mask + 3 swap C!
;

\ _step_time( addr -- ticks)
: _step_time
	dup _step_current_velocity + L@ dup
\ addr cv cv
	2 ST@ _step_accel + L@ +
\ cv nv
	rot _step_max_velocity + L@ min
\ cv nv
	over - 2/ +
\ av
	clkfreq swap u/
;


\ __step ( +-1 addr xx -- +-1 addr xx )
: __step
	over _step_position + dup L@ 4 ST@ + swap L!
	over dup _step_current_velocity + L@ over _step_accel + L@ +
	over _step_max_velocity + L@ min swap _step_current_velocity + L!
	over step_active
;


[ifdef step_debug
: waitcnt
	over . dup . + cr
;
]

\ step ( n addr -- )
: step
	over 0<
	if
		-1
	else
		over 0>
		if
			1
		else
			0
		then
	then
\ n addr step
	dup 0<>
	if 	
		swap rot abs
\ +-1 addr n

		over _steps_to_speed + L@ 2* over <=
		if
			over _steps_to_speed + L@ dup >r tuck  2* - >r
		else
			dup 1 =
			if
				0 >r 0 >r
			else
				dup 2/ dup >r
				swap 1 and >r
			then
			
		then
[ifdef step_debug
		st? rs?
]
		over _step_time
[ifndef step_debug
		cnt COG@ +
]
		swap		

		0
		do
[ifdef step_debug
			i .long space
			over step_dump1
]
\ +-1 addr cnt
			__step
			over _step_time
			waitcnt
		loop

		r> dup 0=
		if
			drop
		else
			2 ST@ _step_accel + dup L@ >r 0 swap L!
			0
			do
[ifdef step_debug
				i .long space
				over step_dump1
]
\ +-1 addr cnt
				__step
				over _step_time
				waitcnt
			loop
			over _step_accel + r> swap L!
		then





		r> dup 0=
		if
			drop
		else
			2 ST@ _step_accel + dup L@ negate swap L!
			0
			do
[ifdef step_debug
				i .long space
				over step_dump1
]
\ +-1 addr cnt
				__step
				over _step_time
				waitcnt
			loop
			over _step_accel + dup L@ negate swap L!
		then

	then
	drop 0 swap _step_current_velocity + L! drop
; 

: step_accel
;

: step_setspeed
;

[ifdef step_test
d_16 d_17 d_18 d_19 step_create_halfstep moth
d_16 d_17 d_18 d_19 step_create_fullstep motf


\ _tstep ( steps addr -- )
: _tstep
	cnt COG@ >r
	2dup step
	cnt COG@ r> -
\ steps addr ticks
	2 ST@ abs
	u/
	d_1000_000 clkfreq u*/
\ steps addr usec/step
	." step:: steps: " rot .
\ addr usec/step
	over 5 + C@ 3 = if ." fullstep " then
	over 5 + C@ 7 = if ." halfstep " then
	over 6 + C@ ." accel: " .
	." usec/step: " dup .
	." steps/sec: " d_1_000_000 swap u/ . cr
	step_sleep
;

\ _step_test ( addr -- )
: _step_test
	dup step_init
	
	." Hit a key to terminate tests~h0D~h0D"

	fkey? nip 0=
	if
		d_12 0
		do
			i over step_accel
			fkey? nip 0=
			if
				d_8192 over _tstep d_1000 delms
				fkey? nip 0=
				if
					d-8192 over _tstep d_1000 delms
				else
					leave
				then
			else
				leave
			then
		loop
	then
	drop
;

: step_testh
	moth _step_test
;

: step_testf
	motf _step_test
;
]
 
...



