fl

 \ 20160115 Prof_Braino ESC - tested with ebay HW20A (generic hobby king 20A esc)
\ PWM 1 to 2 ms to control standard hobby esc - 1ms = stop; 1.5ms = mid; 2ms = max

1 wconstant build_ESC.f

\ summary - using Quickstart, load propforth devkernel as normal
\ boot propforth and paste this file into terminal, from fl to end
\ connect ESC to esc_pin (pin 11, sm_enable bit must be 1)
\ boot propforth, touch button 1 fo 1ms. Power on ESC (normal mode)
\ -or- bootpropforth, touch button 2 for 2ms (calibration mode)
\ see line 456 for other button assignments



\ ESC BEC 20A - Brushless DC electronic speed controller from SERVO
\ Same servo pulse scheme, can run 16 BEC from one cog (8 per timer * 2 timers A&B)
\ 1000 us pulse is STOP 2000 us pulse is max
\ below 1281 motor will stop, 1282 is lowest to re-start motor turning. use 1290-1300
\ 1282 draws 0.020 A
\ Speed doesnot increase above 1940. Draws 0.82 A
\ at Startup, must deliver 1000 us (zero throttle) as safety.

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
\ ESC motors are controlled by a pulse width modulation (pwm).
\ Every 20 milliseconds a pulse of length 0.75 milliseconds 
\ to 2.25 millseconds determines the position of the ESC motor.
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
\ Each ESC motor requires calibration, so we will set the absolute minimum to 0.5 ms and the
\ absolute maximum to 2.5 ms. Depending on the ESCs you are using, you may want to adjust these
\ values. 
\

\
\ This driver will drive 16 ESCs per cog, it uses the 2 counters in a time domain multiplexed
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

d_11 wconstant esc_pin

\
\ This constant defines the number of times per second a pulse is generated
\ for the ESC motor.
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
\ but someone managed to turn their ESC into a countinuos rotation ESC
\ without intending to do so.
\ So the defaults are set to 750usec and 2250usec.
\ clockspeed times microsesonds divided by million makes
\ number of clock ticks in d microseconds
\ clkfreq d_750   d_1_000_000 u*/ constant sm_minhiticks  \ 60_000
\ clkfreq d_2_250 d_1_000_000 u*/ sm_cyclecnt/8 min constant sm_maxhiticks \ 180_000
clkfreq d_1_000   d_1_000_000 u*/ constant sm_minhiticks  \ 60_000
clkfreq d_2_000   d_1_000_000 u*/ sm_cyclecnt/8 min constant sm_maxhiticks \ 180_000

\
\ This variable defines which IO pins are enabled as outputs
\ by the ESC driver, the default is 0 - 27 since 30 & 31 are used
\ for the serial port, and 28 & 29 for the eeprom
\
\ variable sm_enable h_0FFF_FFFF sm_enable L!
\ variable sm_enable h_00FF_0000 sm_enable L!
variable sm_enable h_0000_FF00 sm_enable L!

\
\ this array defines the pulse hi times, it is initialized 1/2 way between
\ the min and max
\ TIME is microseconds (usec)


lockdict variable sm_hi_ticks d_124 allot freedict		\ 32 longs

\
\ this array defines the minimum pulse hi time, it is initialized to the minimum
\
lockdict variable sm_minhi_ticks_array d_124 allot freedict	\ 32 longs

\
\ this array defines the maximum pulse hi time, it is initialized to the maximum
\
lockdict variable sm_maxhi_ticks_array d_124 allot freedict	\ 32 longs

\
\ _sm_idx ( n1 addr -- addr ) calculates the array offset for the particular ESC
: _sm_idx
	swap 0 max d_31 min 4* +
;
	

\ sm_setpos ( n1 u -- ) n1 is an integer between 0 and 31, u is an unsigned integer between 0 and 10,000
: sm_setpos
	0 max d_10_000 min
\						\ ( n1 u -- )
	over dup sm_minhi_ticks_array _sm_idx L@
\						\ ( n1 u n1 minhi_ticks -- )
	swap sm_maxhi_ticks_array _sm_idx L@ 
\						\ ( n1 u minhi_ticks maxhi_ticks -- )
	over -
\						\ ( n1 u minhi_ticks range -- )
	rot d_10_000 u*/ +
\						\ ( n1 pos -- )
	swap sm_hi_ticks _sm_idx L! 
;  



\
\ sm_ESC ( n1 -- ) this cog will drive ESCs n1 to n1 + 15
: sm_ESC
	4 state andnC!
	c" ESC" cds W!
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
	swap 4* sm_hi_ticks +
\				\ ( ctrn1 hi_ticksoffset -- )
	cnt COG@ sm_cyclecnt +
\				\ ( ctrn1 hi_ticksoffset nextcycletime -- )
	begin
		h10 0
		do
			0 phsa COG! 0 phsb COG!
\				\ counter a set to drive pin n1,   single ended nco/pwm mode
\				\ counter b set to drive pin n1+1, single ended nco/pwm mode
\				\ ( ctrn1 hi_ticksoffset nextcycletime -- )
			rot dup i + dup ctra COG!
			1 + ctrb COG!
\				\ ( hi_ticksoffset nextcycletime ctrn1 -- )
			rot dup i 2 lshift + dup L@ negate phsa COG!
			4 + L@ negate phsb COG!
\				\ ( nextcycletime ctrn1 hi_ticksoffset -- )
			rot
\				\ ( hi_ticksoffset ctrn1 nextcycletime -- )
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

: .ticks2usec \ (ticks - ) prints ticks on stack as usec
             d_1_000_000 clkfreq u*/ <# # # # # #> .cstr space ."  uS "
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


\ sm_setminmax ( min max n1 -- ) sets calibration parameters for each ESC
: sm_setminmax
	swap sm_maxhiticks min over sm_maxhi_ticks_array _sm_idx L!
	swap sm_minhiticks max swap sm_minhi_ticks_array _sm_idx L!
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

\ _sm_cal1 ( ESC key delta -- ESC key )
: _sm_cal1
	rot tuck
\					\ ( key ESC delta ESC -- )
	sm_hi_ticks _sm_idx dup
\					\ ( key ESC delta addr addr -- )
	L@ rot + sm_minhiticks max sm_maxhiticks min swap L!
\					\ ( key ESC -- )
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


\ sm_calibrate ( n1 -- ) n1 - ESC
: sm_calibrate
	begin
		." a - <<<<    s - <<<    d - <<    f - <    h - >    j - >>    k - >>>    l - >>>>" cr

		." Move ESC to leftmost position then hit enter" cr
		_sm_cal cr
		dup sm_hi_ticks _sm_idx L@ swap
\										\ ( left n1 -- )

		." Move ESC to rightmost position then hit enter" cr
		_sm_cal cr
		dup sm_hi_ticks _sm_idx L@ swap
\										\ ( left right n1 -- )
		dup >r sm_setminmax
		r>
\										\ ( center left-center right n1 -- )

		." 0 - Leftmost   1 - Center    2 - Rightmost     r-Recalibrate    Escape-Done" cr
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
	cr dup sm_minhi_ticks_array _sm_idx L@ . dup sm_maxhi_ticks_array _sm_idx L@ . . cr  
;

\ sm_start_ESCs ( -- ) runs 32 ESC drivers on cogs 0 - 1, io pins 0 - 31
\ 			modify after calibrating ESCs
: sm_start_ESCs
\ initialize arrays, default calibration
	32 0
	do
           sm_minhiticks i sm_minhi_ticks_array _sm_idx L!
           sm_maxhiticks i sm_maxhi_ticks_array _sm_idx L!
	loop
\ calibration for ESCs
	32 0
	do
   i sm_minhi_ticks_array _sm_idx L@ i sm_maxhi_ticks_array _sm_idx L@ over - 2/ + \ START safe in middle
\  clkfreq d_1_000 d_1_000_000 u*/ \ 1 microsecond of ticks to start ESC - no 
		i sm_hi_ticks _sm_idx L!
	loop

8 sm_ESC \ this starts the driver on THIS cog
\ MUST CONTAIN ESC_PIN
\	0 cogreset h_10 delms c" 0 sm_ESC" 0 cogx 
\	0 cogreset h_10 delms c" D_8 sm_ESC" 0 cogx 
\	2 cogreset h_10 delms c" d_16  sm_ESC" 2 cogx
\	2 cogreset h_10 delms c" d_16  sm_ESC" 2 cogx
	10 delms
;

 \ ESC? exit to terminal on escape key (terminal diagnostic)
: ESC? fkey? drop 27 = if st? cogid cogreset then ;

: showsetting  esc_pin  sm_hi_ticks _sm_idx L@ .ticks2usec ;
: setmax2000 clkfreq d_2_000 d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;
: setmin1000 clkfreq d_1_000 d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;
: setmid1500 clkfreq d_1_500 d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;
: set1750    clkfreq d_1_750 d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;
: set1300    clkfreq d_1_300 d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;
: setzero0   clkfreq d_0_000 d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;
: powermessage cr ." POWER ON ESC and press key" ;

\ : any  clkfreq swap d_1_000_000 u*/ esc_pin  sm_hi_ticks _sm_idx L! showsetting ;

: drivermsg ." start ESC/BEC driver " ; \ sm_start_ESCs 

\ : tmp esc_pin sm_hi_ticks _sm_idx L@ sm_minhiticks do 0 RS@ i 1+ st? - . ESC? loop ;
\ maximum is = sm_maxhiticks
\ current is = esc_pin sm_hi_ticks _sm_idx L@
\ minimum is = sm_minhiticks

: rampdown \ from current to minimun
      esc_pin sm_hi_ticks _sm_idx L@
      sm_minhiticks
      do
         0 RS@ i 1+ - sm_minhiticks +
         esc_pin sm_hi_ticks _sm_idx L!                   
         ESC?
      loop
;

\ : tmp 10 0 do i . loop ;
: rampup \ from current to max
      sm_maxhiticks
      esc_pin sm_hi_ticks _sm_idx L@  
      do
         i 
         esc_pin sm_hi_ticks _sm_idx L!                   
         ESC?
      loop   
;

{
: test
       drivermsg sm_start_ESCs 
 cr ." before powering ESC, set to min 1000 " key drop setmin1000 showsetting
       powermessage key drop showsetting
 cr ." at safe tone, set to MID "  key drop setmid1500 showsetting
\ cr ." ramp down to mid to stop " key drop rampdown
\ cr ." ramp up   to MZ MAX "      key drop rampup
 cr ." at start tone, set to MAX " key drop setmax2000 showsetting
 cr ." press key to run att MID "  key drop setmid1500 showsetting
 cr ." press key to set to min stop " key drop setmin1000 showsetting
 cr ." press key to set to zero  "    key drop setzero0  showsetting
;      
}

\ 20160115 buttons for ESC

\ P2 - Set ESC PWMM to 2ms (motor speed max) 
\ P1 - Set ESC PWMM to 1ms (motor speed min/zero) 
\ P0 - all LEDS off - ESCpulse to zero (error state)

\ P3- set motor speed 1.30ms (30%)
\ P4-  set motor speed ramp down to 1.00ms 
\ P5- set motor speed 1.50ms (50%)
\ P6-  set motor speed ramp up to 2.00ms 
\ P7- set motor speed 1.75ms (75%)

\ ESC as several separate tasks:
\ Task 1 - monitor button pads
\ Task 2 - process buttons
\ Task 3 - control LED states
\ Task 4 - ESC driver

\ Task 6 - support user terminal (default PF kernel)
\ Task 7 - manage serial comms for terminal (default PF kernel)

\ Task 1 - monitor button pads
\ charge the buttons so we can detect a touch per quickstart touch demo
\ listen to buttons
\ if button is detected , start timer 
\ if button is not detected, zero timer
\ if time exceeds 1 second, [change state]: (a) turn on 1 second (b) trigger routine.

\ Task 2 - debounce buttons
\ Task 2 - process buttons
\ if button is detected, display button states
\ if button is not detected, display porodomo timer.

\ Task 3 - control LED states
\ Button 7 - idle - heartbeat LED 7
\ Button 1 - start - count down 23 minutes
\ Button 2 - two minute warning - count down final 120 seconds
\ Buttons 3,4,5,6 - alarms - flash attention FF->00 F0->0F CC->33 AA->55  (300 ms)
\ Button 0 - rest - cylon - 5 minutes

\ Task 4 - manage porodomo timer
\ Button 7 - idle - heartbeat LED 7
\ Button 1 - start - count down 23 minutes
\ Button 2 - two minute warning - count down final 120 seconds
\ Buttons 3,4,5,6 - alarms - flash attention FF->00 F0->0F CC->33 AA->55  (300 ms)
\ Button 0 - rest - cylon - 5 minutes

\ fl

1 wconstant build_buttons

wvariable ButtonFlag     128 ButtonFlag W! \ word (2 bytes)
wvariable PrevButtonState \ word (2 bytes)
variable TimerStart       \ long (4 bytes)

\ ESC? exit to terminal on escape key (terminal diagnostic)
: ESC? fkey? drop 27 = if st? cogid cogreset then ;

: LEDalloff  h00 16 lshift outa COG! ;
\ LEDon ( LEDpin - )
: LEDon   LEDalloff    dup pinout pinhi  ;
\ : LEDoff dup pinlo pinin ESC? ;

\ sleep should also set ESC to 0ms
: sleep 0 ButtonFlag W! LEDalloff  ;

\ =================================================================================================


\ Button0-P16-1-0.00ms 
: Button0-P16-1-set0000us   16 LEDon setzero0 ;
\ Button1-P17-2-1.00ms 
: Button1-P17-2-set1000us   17 LEDon setmin1000 ;
\ Button2-P18-4-2.00ms 
: Button2-P18-4-set2000us   18 LEDon setmax2000 ;
\ Button3-P19-8-1.30ms 
: Button3-P19-8-set1300us   19 LEDon set1300 ;
\ Button4-P20-16-ramp dowm
: Button4-P20-16-rampdowm   20 LEDon rampdown ;
\ Button5-P21-32-set1.5ms
: Button5-P21-32-set1500us  21 LEDon setmid1500 ;
\ Button6-P22-64-ramp up
: Button6-P22-64-rampup     22 LEDon rampup ;
\ Button7-P23-128-set1.75ms
: Button7-P23-128-set1750us 23 LEDon set1750 ;

\ ============================================================================
\ cog 1 - charge buttons 
\ ===============================================================
\ Task 1 - charge button pads
: charge-buttons                \ ( - )  no stack parameters
	4 state andnC!
	c" charge-buttons" cds W!
  begin                       \ start by charging the button pins 0-7
       h_FF outa COG!         \ prep first 8 pins Hi (1's) 3.3V
       h_FF dira COG!         \ make first 8 pins outputs  (1's)
                              \ so now pins are "Charged"
       h_FF invert dira COG!  \ make first 8 pins inputs
                              \ if pad is touched, it will discharge to low 
       11 delms \ 25 50 100 10  let it stay in this state for some milliseconds (delay for milliseconds)
                \ long enough to be seen, not long enough to flicker
  0 until       \ do this forever
;   

  \  c"  charge-buttons  "   1 cogx \ launch in cog 1 for testing
\ ============================================================================
\ cog 1 - charge buttons 
\ ===============================================================
\ cog 2 - debounce buttons 
\ ===============================================================


: button-actions 
     ButtonFlag W@ 
               dup 128 = if Button7-P23-128-set1750us then 
               dup 64  = if Button6-P22-64-rampup     then 
               dup 32  = if Button5-P21-32-set1500us  then 
               dup 16  = if Button4-P20-16-rampdowm   then 
               dup 8   = if Button3-P19-8-set1300us   then  
               dup 4   = if Button2-P18-4-set2000us   then  
               dup 2   = if Button1-P17-2-set1000us   then  
               dup 1   = if Button0-P16-1-set0000us   then  
               drop
; \  c"  button-actions " 3 cogx \ launch in cog 3 for testing


: StartDebounceTimer cnt COG@ TimerStart L! ; \ debounce timer
: DEBOUNCE? cnt COG@ TimerStart L@ - abs clkfreq 4 rshift > ; \ true if greater than 1 second

\  The ButtonFlag is how we know which mode to operate.
\  doButtons  ( buttonflags - ) \ to filter multiple button presses, only allow 1 button
: doButtons 
           dup 1   = if dup ButtonFlag W! \  16 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 2   = if dup ButtonFlag W! \  17 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 4   = if dup ButtonFlag W! \  18 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 8   = if dup ButtonFlag W! \  19 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 16  = if dup ButtonFlag W! \  20 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 32  = if dup ButtonFlag W! \  21 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 64  = if dup ButtonFlag W! \  22 dup LEDon 1000 delms LEDoff 
                     then                 \  diagnostic for testing
           dup 128 = if dup ButtonFlag W! \  23 dup LEDon 1000 delms LEDoff 
                     then
\ drop is done in calling routing
 button-actions 
;

\ CheckButtons ( buttonflags - ) \ (stack has current button states)
: CheckButtons 
  dup 0 <>                     \ if button presses are detected....    
  if ."  buttons pressed     " \ note: msg to console only on colsole cog   
     dup PrevButtonState W@ = 
     if                        \ if button presses same as last time...
        DEBOUNCE?              \ has it been a second yet?
        if doButtons  then  
     else PrevButtonState W! StartDebounceTimer 0 then    \ button is different, save buttonstates, restart timer
  else ." no buttons pressed " \ note: msg to console only on colsole cog
  then
  drop
;
  
: debounce-buttons      \  from demo-LED \ ( - ) takes no stack parametes  
    4 state andnC!
    c" debounce-buttons" cds W!
    16                             \ pin 16 is first of 8 LEDS
    8 0 do dup pinout 1+ loop drop \ set them to output
    begin
         ina COG@                  \ get the current pins states
         invert                    \ This makes them off till touched, 
         h_FF and                  \ filter for only buttons pins 0-7
         CheckButtons
   0 until                        \ do this forever   
; 

\  c"  debounce-buttons "    2 cogx \ launch in cog 2 for testing
\ ===============================================================
\ cog2 is debounce buttons
\ ===============================================================

\      drivermsg sm_start_ESCs 

 : onreset0 onreset sm_start_ESCs   ; \ do esc
 : onreset1 onreset charge-buttons   ; \ listen to button pads 
 : onreset2 onreset debounce-buttons   ; \ do something for a button

\ 0 cogreset 1 cogreset    2 cogreset 

saveforth
reboot

