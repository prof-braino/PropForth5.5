fl

\ load propforth devkernel.spin or devkernel.eeprom or devkernel.binary per normal method
\ paste this entire file into the terminal window  per normal method
\ heartbeat on cog2 and cylon on cog 1 control
\ PWM driver on cog 0 

\ uses NCO differential mode to control two LED pins per counter, 
\ for total of 4 LEDs per cog. Each pair is in logical opposite state.
\ LED output pins are changed on the fly

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
variable pwm_hitimeA 1_0000_0000 pwm_hitimeA L!
variable pwm_hitimeB      250 pwm_hitimeB L!

wvariable PinAa 16 : PinAa! PinAa W! ; PinAa! \ easily recognizable initial state  
wvariable PinAb 17 : PinAb! PinAb W! ; PinAb!  \ easily recognizable initial state
wvariable PinBa 20 : PinBa! PinBa W! ; PinBa!  \ easily recognizable initial state
wvariable PinBb 21 : PinBb! PinBb W! ; PinBb!  \ easily recognizable initial state

\ change the above to non LED pins when done testing

\ pwm_set_pulse ( u -- ) n1 is an integer between 0 and 31, u is an unsigned integer between 0 and 10,000
\  u is Pulse width (% * 100) unsigned integer between 0 and 10,000
: pwm_set_pulseA 
	0 max d_10_000 min \ force input within range
        pwm_minhi 
        pwm_maxhi 
	rot d_10_000 u*/ + \ scale % to clock ticks
        pwm_hitimeA L! 
;  
: pwm_set_pulseB 
	0 max d_10_000 min \ force input within range
        pwm_minhi 
        pwm_maxhi 
	rot d_10_000 u*/ + \ scale % to clock ticks
        pwm_hitimeB L! 
;  

\ ESC? exit to terminal on escape key (terminal diagnostic)
: ESC? fkey? drop 27 = if st? cogid cogreset then ;

: enable-outs 28 0 
      do pwm_enable L@ 1 i lshift and if i dup pinlo pinout then loop
;

\ this is the key to PWM. See Prop Manual page 98,  
\ also p95 (ctra, ctrb), p73 (cnt), p111 (frwa, frqb), p180 (phsa,phsb), 
\ pwm_driver ( -- ) this cog will drive pwm target pins pA and pB, specified elsewher
: pwm_driver
        enable-outs
	1 frqa COG!   \ count by 1 clock cycle
	1 frqb COG!   \ count by 1 clock cycle
	cnt COG@ pwm_cyclecnt + \ do we need to add the interval HERE???????????????????????? 
	begin                                    \ NCOpinA $pwm_hitime cycles
             0 phsa COG!  0 phsb COG!
\                h_1000_0000            \ NCO single ended, plus  pinA
                 h_1400_0000            \ NCO differential with pinB
                 PinAb W@ 9 lshift +    \ pinb bit 14..9
                 PinAa W@          +    \ NCO, plus first pin
             ctra COG!    \ setup counter A

\                h_1000_0000            \ NCO single ended, plus  pinA
                 h_1400_0000            \ NCO differential with pinB
                 PinBb W@ 9 lshift +    \ pinb bit 14..9
                 PinBa W@          +    \ NCO single ended, plus first pin
             ctrb COG!    \ setup counter B
         pwm_hitimeA L@ negate phsa COG! \ count clocks until zero
         pwm_hitimeB L@ negate phsb COG! \ count clocks until zero
         pwm_cyclecnt  waitcnt \ this is the delay
               ESC? \ for terminal diagnostics, can be removed.
       0 until \ this cog runs forever in the background
;

\ each XXX_cog rouinte run an infinite loop in the back ground for each task.
\ each start_xxxx routine launches the background task in each cog.


: pwm_driver_cog  \  \ this driver runs in the background on a cog
	4 state andnC!  \ bit 4 -  0 - accept echos line off / 1 - accept echos line on
	c" PWM" cds W!
      pwm_minhi pwm_maxhi over - 2/ +     \ middle value
      dup pwm_hitimeA  L! pwm_hitimeB  L!
        pwm_driver
;

{
\ this starts the driver from the command line for testing 
\ pwm_start_driver ( -- ) runs 32 servo drivers on cogs 0 - 1, io pins 16-19 (any 4 of 0 - 31)
: pwm_start_driver_cog
    0 cogreset h_10 delms c" pwm_driver_cog" 0 cogx 10 delms
  \ 1 cogreset h_10 delms c" pwm_driver_cog" 1 cogx 10 delms
;
}

\ faderr ( i - +loop ) \ fade slower on dim end

\ increasing the negative limit increases dark time
: fadeoutA 10_001 -1000 do  0 RS@ i - pwm_set_pulseA  12 +loop ; \ 0 pwm_set_pulseA ;
: fadeinA  10_001 0  do        i   pwm_set_pulseA  8 +loop ; \ 10000 pwm_set_pulseA ; \ cant turn off
: fadeoutB 10_001 0  do  0 RS@ i - pwm_set_pulseB  8 +loop ; \ 0  pwm_set_pulseB ;
: fadeinB  10_001 0  do        i   pwm_set_pulseB  8 +loop ; \ 10000 pwm_set_pulseB ;

: cylonupIn  cr \ does not turn off
      23 17 do i .   \ 23 is heartbeat
               i PinAa! 
i 1- dup dup pinhi pinout 
               i 2- PinAb!  fadeinA
dup pinlo pinin 
               ESC? 
     loop  
;            

: cylonup  \ cr  \ cylonupOut 
      23 17 do  \ i .   \ 23 is heartbeat
               i 1- PinAa! 
               i  PinAb!  fadeoutA
               ESC? 
     loop  
;            

: cylondn \ cr
      -16 -22 do \ i .    \ 23 is heartbeat 
               i abs PinAa!
               i abs 1- PinAb!  fadeoutA
               ESC? 
    loop  
;            

: scan cylonup  cylondn  ;

: scan_driver_cog \ this driver runs in the background on a cog
              4 state andnC!  \ bit 4 -  0 - accept echos line off / 1 - accept echos line on
              c" scan" cds W!
                 begin
                      scan
                      ESC?
                 0 until
;

{
\ this starts the driver from the command line for testing 
: start_scan_driver_cog c" scan_driver_cog"  1 cogx ;
}

: heart fadeoutB fadeinB 750 delms ; \ 350 delms 750 delms   ;

: heartbeat 2 PinBa!  3 PinBb! \ these two are dummy pins
           23 PinBb! 
              begin
                   heart
                   ESC?
              0 until
;

: heart_driver_cog \ this driver runs in the background on a cog
              4 state andnC!  \ bit 4 -  0 - accept echos line off / 1 - accept echos line on
              c" heart" cds W!
              heartbeat
;

{
\ this starts the driver from the command line for testing 
: start_heart_driver_cog 2 cogreset h_10 delms c"   heart_driver_cog " 2 cogx ;
}

{
\ each start_xxxx routine launches the background task in each cog, for testing only.
\ each XXX_cog rounte run an infinite loop in the back ground for each task.
\ onresetN launches the routing (oneword) on that cog at reset
}

\ 0 cogreset  1 cogreset  2 cogreset 

{
: go \ for terminal testing
        pwm_start_driver_cog
        start_heart_driver_cog
        start_scan_driver_cog
;
}

: onreset0    pwm_driver_cog  ; 
: onreset1   scan_driver_cog  ;
: onreset2  heart_driver_cog  ; 

saveforth

reboot

