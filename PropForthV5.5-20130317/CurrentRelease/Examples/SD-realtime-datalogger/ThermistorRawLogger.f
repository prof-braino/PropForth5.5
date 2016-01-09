
{
mountusr
\ create a 50 Mbyte logfile
100_000 fcreate log

mountusr
fstat log
}



fl

 100 fwrite therm-driver.f

\ therm-driver.f 2013-11-10 braino based on Sal's example
\ just log the RAW therm data.

\ using 10k (cheapest) thermistor        cnt COG@ clkfreq +

\ needs 0.1uF capacitor
\ uses 1 prop pin
\ connect thermistor to 3.3v and to pin;
\ connect capacitor to ground and pin
\ 3.3v -----/\/\/\/\/\/\----+-----||---------- gnd
\                           |
\ pin-----------------------
 
27 wconstant _therm_pin

variable _therm_reading   \ store current reading here

\ NOTE that _temp? does NOT read the temperature or resistance from the thermistor
\ _temp? returns the number of ticks for the capacitor to discharge through the thermistor. 
\ I should change this when it works

\  _temp? ( pin# -- count)
: _temp?
         dup pinlo dup pinout
         1 delms  
         cnt COG@ over pinin
         swap >m dup waitpeq
         cnt COG@ swap -
;

: temp! 
        _therm_pin _temp? 
        _therm_reading  L!       
;

: temp@   \ ( - therm value )
        _therm_reading  L@ 
;

: therm-scan
        4 state andnC!
        c" THERM" cds W!
        begin
             temp!
        0 until
;
 
...


fl

100 fwrite therm-ui.f

variable _meter_display \ type in the number displayed on the VOM digital temperature probe

\ meter! stores the degrees C entered by the user
: meter! \ ( degrees - )
         _meter_display L!   
;

\ meter@ fetches the degrees C entered by the user and leaves it on the top of stack
: meter@ \ ( - degrees )
    _meter_display L@
;  

hDEADBEEF meter! \ initialize the flag

wvariable flag
: !flag flag W! ;
: @flag flag W@ ;

: get_METER 
            
            ." Enter the temp from the digital thermometer: " 
            interpret  
            ."  logging data for " 
            dup . ."  degrees Centigrade "  
            cr
            dup h1B = !flag
            meter!      
;

: SCAN 
      begin
           get_METER
           
      @flag until
;

...

fl

100 fwrite therm-logger.f

lockdict wvariable logBuffer 256 allot freedict

: logdata
        c"  METER-degrees-C: " logBuffer ccopy
        meter@ <# #s #> logBuffer cappend 

\ collect ten reading for each meter temperature entered
\ adjust this to control the number of sample logged 

        c"  Therm-readings: " logBuffer cappend
        10 0 do 
                  temp@ <# #s #> logBuffer cappend 
                  c"  " logBuffer cappend
        loop 

\ end each record with CR so it displays on the terminal

        c" ~h0D" logBuffer cappend  
        logBuffer                  \ return the address of this buffer
;

\ log when new meter reading is entered
: logger-body
               meter@   hDEADBEEF = 0=                  \ temperature? 
                if                                       \ if degrees is set
                logdata C@++ c" log" 7 lock sd_append 7 unlock   \ log a record
                hDEADBEEF meter!                         \ turn the logger off
                then
;

: logger
        4 state andnC!
        c" LOGGER" cds W!
        mountusr
        begin
               logger-body 
                1 delms \ is this needed?
        0 until 
;

\ user can enter ClearLog to erase the entire contents of the log file
: ClearLog
        mountusr
        7 lock 0 c" log" sd_trunc 7 unlock
;

...

fl

mountsys 
100 fwrite usrboot.f

version W@  .cstr cr
c" usrboot.f  -  initializing~h0D~h0D" .cstr
1 sd_mount

 fload therm-driver.f   
 fload therm-ui.f
 fload therm-logger.f

fread .sdcardinfo      \ display the previously recorded card info file

c" logger" nfcog cogx  \ launch logger on next free cog
c" therm-scan" nfcog cogx  \ launch therm monitor on next free cog

c" usrboot.f  -  DONE~h0D~h0D" .cstr


...


{
mountusr
fstat log
fread log
temp!
get_METER 
logger-body
}





