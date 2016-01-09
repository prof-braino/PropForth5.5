fl

1 wconstant build_PWM

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
\ pulse width modulation (pwm). Drivers 2 pwm targets per cog, it uses the 2 counters one per target
\ Each counter is set to single ended PWM/NCO mode. In this mode the counter drives an io pin.
\ The value of the pin is controlled by bit 31 of the phsa/phsb registers. These registers and
\ incremented every cycle of the system clock. For an 80 Mhz system clock this provides for
\ 12.5 ns resolution.
\
\ Without intervention the phsa/phsb registers would generate a square wave with the cycle time
\ being more than 50 seconds
\ ----------------------____________________----------------------____________________
\ Since there are 2 counters we can do this with 2 pins at a time.

\ minimum persistance is about 20 times per second, (50 ms cycle period); some folks can see flicker. 
\ frequency 50 times per second (20 ms period) few if any can detect flicker
\ This constant defines the number of times per second a pulse is generated
\ for the servo motor.
d_50 wconstant pwm_cyclefreq

\ The number of clock cycles in one pulse sequence of 20ms
clkfreq pwm_cyclefreq u/ constant pwm_cyclecnt

\ These constants define the absolute minium and maximum lengths of time
\ for the pulse. The maximum can never be more than the time slot.
\
\ The minimum was set to 0 usec (0 cycles) and and maximum to 20,000 usec (1_600_000 cylces)

clkfreq d_000    d_1_000_000 u*/ constant pwm_minhi
clkfreq d_20_000 d_1_000_000 u*/ constant pwm_maxhi

\ This variable defines which IO pins are enabled as outputs
\ by the servo driver, the default is 0 - 27 since 30 & 31 are used
\ for the serial port, and 28 & 29 for the eeprom
\
\ variable pwm_enable h_0FFF_FFFF pwm_enable L!
\ Quickstart is pins 16-23
variable pwm_enable h_000FF_0000 pwm_enable L!

\ array defines the pulse hi times, initialized 1/2 way between the min and max
lockdict variable pwm_hitime d_124 allot freedict		\ 32 longs so ANY pins will work

\ array defines the minimum pulse hi time, initialized to the minimum (default is 0)
lockdict variable pwm_minhitime d_124 allot freedict	\  32 longs so ANY pins will work

\ array defines the maximum pulse hi time, initialized to the maximum (1_600_000 cycles)
lockdict variable pwm_maxhitime d_124 allot freedict	\  32 longs so ANY pins will work

\ _pwm_idx ( n1 addr -- addr ) calculates the array offset for the particular servo
: _pwm_idx
	swap 0 max d_31 min 4* +
;
	

\ pwm_set_pulse ( n1 u -- ) n1 is an integer between 0 and 31, u is an unsigned integer between 0 and 10,000
: pwm_set_pulse
	0 max d_10_000 min
	over dup pwm_minhitime _pwm_idx L@
	swap pwm_maxhitime _pwm_idx L@ 
	over -
	rot d_10_000 u*/ +
	swap pwm_hitime _pwm_idx L! 
;  

\ pwm_driver ( n1 -- ) this cog will drive pwm targets n1 to n1 + 1
: pwm_driver
	4 state andnC!
	c" PWM" cds W!
	0 max h18 min
	dup h_10 bounds
	do
		pwm_enable L@ 1 i lshift and
		if
			i dup pinlo pinout
		then
	loop
	1 frqa COG!
	1 frqb COG!
	dup h_1000_0000 +
	swap 4* pwm_hitime +
	cnt COG@ pwm_cyclecnt +
	begin
		h2 0 \ only 2 as we want 100 duty cycle for full brightness
		do
			0 phsa COG! 0 phsb COG!
			rot dup i + dup ctra COG!
                                    1 + ctrb COG!
			rot dup i 2 lshift + dup L@ negate phsa COG!
                                             4 + L@ negate phsb COG!
			rot
			pwm_cyclecnt waitcnt
		2 +loop
	0 until
;

\ pwm_setminmax ( min max n1 -- ) sets calibration parameters for each servo
: pwm_setminmax
	swap pwm_maxhi min over pwm_maxhitime _pwm_idx L!
	swap pwm_minhi max swap pwm_minhitime _pwm_idx L!
;

\ pwm_start_driver ( -- ) runs 32 servo drivers on cogs 0 - 1, io pins 16-19 (any 4 of 0 - 31)
: pwm_start_driver
	32 0 do
		pwm_minhi i pwm_minhitime _pwm_idx L!
		pwm_maxhi i pwm_maxhitime _pwm_idx L!
	loop
	32 0 do
		i pwm_minhitime _pwm_idx L@
		i pwm_maxhitime _pwm_idx L@
		over - 2/ +
		i pwm_hitime _pwm_idx L!
	loop
	0 cogreset h_10 delms c" d_18 pwm_driver" 0 cogx
	1 cogreset h_10 delms c" d_16  pwm_driver" 1 cogx
	10 delms
;

\ ESC? exit to terminal on escape key (terminal diagnostic)
: ESC? fkey? drop 27 = if st? cogid cogreset then ;

: fadeout 10_000 0 do dup  0 RS@ i - pwm_set_pulse loop drop ;
: fadein  10_000 0 do dup   i pwm_set_pulse loop drop ;

\ pwm_set_pulse

\ : test 20 16 do i . cr i fadein i fadeout ESC? loop ;            
wvariable rand_seed \ need a better random
: rand cnt COG@ dup 8 rshift xor rand_seed W@ xor 7919 * 257 + 24 rshift dup rand_seed W! ;
\ : test begin rand . ESC? cr 0 until ;
: rnd rand ;
: rnd4 rnd 5 255 */ ; 
: rnd10k rnd 39 * ; 
\ : rndT rnd 2 * ; 
\ : test16 begin rnd4 16 + . rnd10k . cr ESC? 0 until ;

: flicker rnd4 16 + rnd10k st? pwm_set_pulse rnd delms ;
: go begin flicker ESC? 0 until ;
: do_flicker	
            4 state andnC!
            c" flicker" cds W!
            begin
                 flicker 
                 ESC?
            0 until 
;

\ : onreset0 	d_18 pwm_driver ;
\ : onreset1      d_16  pwm_driver ; 
: onreset2 113 delms pwm_start_driver 117 delms do_flicker ; 
\ : onreset6 pwm_start_driver 100 delms go ;
  \ pwm_start_driver go

saveforth
reboot





