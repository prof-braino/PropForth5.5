\ therrmistor.f 2013-09-21 braino from Sal's example
\ using 10k (cheapest) thermistor
\ needs 0.1uF capacitor
\ uses 1 prop pin
\ connect thermistor to 3.3v and to pin;
\ connect capacitor to ground and pin
\ 3.3v -----/\/\/\/\/\/\----+-----||---------- gnd
\                           |
\ pin-----------------------
 
27 wconstant _therm_pin

\  _temp? ( pin# -- count)
: _temp?
dup pinlo dup pinout
1 delms  \  x1000x 100 10 1
cnt COG@ over pinin
swap >m dup waitpeq
cnt COG@ swap -
;

\ 27C =  54928


\  _10temp? ( pin# -- count) take 10 readings, return average count /256
: _10temp?
0
h10 0
do
over _temp? +
loop
nip
h100 u/mod swap h80 >= abs +
;

: therm  st? sc st?
  ."  Thermistor test "
begin  
     \ cr 
     _therm_pin _10temp? . \ 1 delms
fkey? swap drop until
;

: sample 
st? sc st?
  ."  Thermistor test "
50 0 do 
     cr \ ."  reading is " 
       _therm_pin _10temp? .
       
loop 
;

: sample 
st? sc st?
  ."  Thermistor test "
50 0 do 
     cr \ ."  reading is " 
       _therm_pin _10temp? .
       
loop 
;

variable hi 
variable lo
: @hi hi L@ ; : !hi hi L! ; : .hi @hi . ; 
: @lo lo L@ ; : !lo lo L! ; : .lo @lo . ; 



: test test


 _therm_pin _10temp? dup !hi !lo
begin  
     _therm_pin _10temp? 
     dup @hi > if dup !hi then
     dup @lo < if dup !lo then
cr . ."  hi:" .hi ."   lo:" .lo ."  Delta=" @hi @lo - .

fkey? swap drop until
;



{
24C: hi=3702 lo=3306 delta=396 
}









