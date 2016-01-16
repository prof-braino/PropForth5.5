fl

mountsys

\ 100 fwrite usrboot.f
100 fwrite graphboot.f
version W@  .cstr cr

c" graphboot.f  -  initializing~h0D~h0D" .cstr

1 sd_mount

\ Begin config parameters
\ chicago is UTC -5
[ifndef timeZoneHours
-5 constant timeZoneHours
]
[ifndef timeZoneMinutes
0 constant timeZoneMinutes
]
[ifndef doubleTimerCog
0 wconstant doubleTimerCog
]

[ifndef loggerCog
nfcog wconstant loggerCog   \ 1 wconstant loggerCog
]

\ End config parameters

\ start all
 fload ADXL345-driver.f  \ ok
 fload HMC5883-driver.f  \ ok
 
 fload L3G4-driver.f   

 fload BMP085-driver.f  
 fload BMP085-N-display.f

 fload BMP085altimeter-support.f   \ last one

fload GY80-Background.f \ ok

fload ANSI.f             \ ok

 fload ADXL345-N-display.f   \ ok
 fload HMC5883-N-display.f   \ ok

 fload L3G4-N-display.f

  fload Graph-display.f   \ ok

 fload  ADXL345-G-display.f    \  ok

 fload  HMC5883-G-display.f  \ ok
 fload  L3G4-G-display.f

\ fload DoubleMath.f
\ fload time.f

fload GY80-main-loop
\ end all

\ GY-80

{
recordsize number of bytes in each record, less than 512
}

\ fl

clkfreq 4/ constant logperiod
256 wconstant recordsize
recordsize d_60 d_60 d_24 u* u* u* d_512 u/ 1+ constant logfileNumBlocks

lockdict wvariable logBuffer recordsize 2- allot freedict
lockdict wvariable logFileName d13 allot freedict
wvariable lastDay -1 lastDay W!

variable rec_count 

: #rec_count 
             rec_count L@  dup
             1+ rec_count L! 
             <# #s #>
             logBuffer cappend
;


\ fl

: <signed> dup
         h8000 and if
         c" -" logBuffer cappend 
         hFFFF0000 or 
         negate
         then
;

\ fl

{
: logdata
[ifdef time
getLocalTime formatTime logBuffer ccopy
]

\   c"  CNT REGISTER: " logBuffer cappend
\   base W@ hex cnt COG@ <# #s #> logBuffer cappend base W!
\   c"  timeStamp: " logBuffer cappend
\   base W@ decimal timeStamp <# d#s #> logBuffer cappend base W!
\   c"  unixTimeStamp: " logBuffer cappend
\   base W@ decimal unixTimeStamp <# d#s #> logBuffer cappend base W!

\ time - 20 + 6 = 26 bytes
\ BMP temp - 5 bytes

[ifndef time
c" notimestamp" logBuffer ccopy
]

#rec_count 

[ifdef build_bmp085
c" -BMP:" logBuffer cappend
BMP_temp_C W@ <# # h2E #C # #  #> logBuffer cappend 
\ BMP pressure - 5 bytes
c" c " logBuffer cappend
\ BMP_pressure_hPa L@ <# # # drop  h2E #C # # # # #> logBuffer cappend 
BMP_pressure_hPa L@ <# # # h2E #C # # # # #> logBuffer cappend 
c" mB " logBuffer cappend
]

[ifdef build_L3G4200D-N
c" L3G-" logBuffer cappend
L3G4200D.DATA     C@ <# #s #> logBuffer cappend
c" c X" logBuffer cappend
L3G4200D.DATA 2+  W@  <# # # # # #  #> logBuffer cappend
c"  Y" logBuffer cappend
L3G4200D.DATA 4+  W@  <# # # # # # #> logBuffer cappend
c"  Z" logBuffer cappend
L3G4200D.DATA 6 + W@  <# # # # # # #> logBuffer cappend
]

[ifdef build_HMC5883-N-display
c"  HMC" logBuffer cappend
@mag 
 <# # # # # # h78 #C h20 #C #> logBuffer cappend
 <# # # # # # h79 #C h20 #C #> logBuffer cappend
 <# # # # # # h7A #C h20 #C #> logBuffer cappend
]

[ifdef build_ADXL345-N-display
c"  ADXL" logBuffer cappend
@ADXL 
\ negate \ (signed)
 <# # # # # # h78 #C h20 #C #> logBuffer cappend
\ negate \ (signed)
 <# # # # # # h79 #C h20 #C #> logBuffer cappend
\ negate \ (signed)
 <# # # # # # h7A #C h20 #C #> logBuffer cappend
]
[ifdef AveTemp
c"  AveTemp " logBuffer cappend
AveTemp <# # h2E #C # #  #>  logBuffer cappend
c" c" logBuffer cappend
] 

	c" ~h0D" logBuffer cappend
	logBuffer
;

}
: ClearLog
	mountusr
	7 lock 0 logFileName sd_trunc 7 unlock
;

: logdata
[ifdef time
getLocalTime formatTime logBuffer ccopy
]

[ifndef time
c" notimestamp" logBuffer ccopy
]

#rec_count 

c" , " logBuffer cappend

[ifdef build_ADXL345-N-display
\ c"  ADXL" logBuffer cappend
@ADXL 
\  <# # # # # # h78 #C h20 #C #> logBuffer cappend
\  <# # # # # # h79 #C h20 #C #> logBuffer cappend
\  <# # # # # # h7A #C h20 #C #> logBuffer cappend
<signed> <# h20 #C h2C #C # # # # # #> logBuffer cappend
<signed> <# h20 #C h2C #C # # # # # #> logBuffer cappend
<signed> <# h20 #C h2C #C # # # # # #> logBuffer cappend
]

[ifdef build_L3G4200D-N
\ c" L3G-" logBuffer cappend
L3G4200D.DATA 2+  W@ <signed> <# # # # # # #> logBuffer cappend
\ c"  Y" logBuffer cappend
c" , " logBuffer cappend
L3G4200D.DATA 4+  W@ <signed> <# # # # # # #> logBuffer cappend
\ c"  Z" logBuffer cappend
c" , " logBuffer cappend
L3G4200D.DATA 6 + W@ <signed> <# # # # # # #> logBuffer cappend
c" , " logBuffer cappend
L3G4200D.DATA     C@ <# #s #> logBuffer cappend
\ c" c X" logBuffer cappend
c" , " logBuffer cappend
]

[ifdef build_bmp085
\ c" -BMP:" logBuffer cappend
BMP_temp_C W@ <# # h2E #C # #  #> logBuffer cappend 
\ c" c " logBuffer cappend
\ BMP_pressure_hPa L@ <# # # drop  h2E #C # # # # #> logBuffer cappend 
c" , " logBuffer cappend
BMP_pressure_hPa L@ <# # # h2E #C # # # # #> logBuffer cappend 
\ c" mB " logBuffer cappend
c" , " logBuffer cappend
]


[ifdef build_HMC5883-N-display
\ c"  HMC" logBuffer cappend
@mag 
\  <# # # # # # h78 #C h20 #C #> logBuffer cappend
\ <# # # # # # h79 #C h20 #C #> logBuffer cappend
\ <# # # # # # h7A #C h20 #C #> logBuffer cappend
<signed> <# h20 #C h2C #C # # # # #  #> logBuffer cappend
<signed> <# h20 #C h2C #C # # # # #  #> logBuffer cappend
<signed> <# h20 #C h2C #C # # # # #  #> logBuffer cappend

]

[ifdef Altitude
Altitude <signed> <# h20 #C h2C #C # # # # #  #> logBuffer cappend
]

[ifdef AveTemp
c"  AveTemp " logBuffer cappend
AveTemp <# # h2E #C # #  #>  logBuffer cappend
c" c " logBuffer cappend
] 

[ifdef Altitude
c" , alt " logBuffer cappend
Altitude  <#  # # # # # # #  #> logBuffer cappend
c" mm above sealevel" logBuffer cappend

]

	c" ~h0D" logBuffer cappend
	logBuffer
;



: createLogfile
[ifdef time
_dgetLocaltime dow 
]
[ifndef time
1
]
 
 dup lastDay W@ =
 if
  drop
 else
  lastDay W!
  
[ifdef time
c" IMU" logFileName ccopy 
getTime 2drop 2drop <# # # drop h2D #C # # drop h2D #C # # # # #> logFileName cappend 
]
[ifndef time
c" IMUnoTIMExxxx" logFileName ccopy 
]

    logFileName logfileNumBlocks sd_createfile drop
  
  0 rec_count L!
  
  ClearLog
  
 then
;

\ log very second - log continuously
: logger
	4 state andnC!
	c" GY80-LOGGER" cds W!
	mountusr

\    start.GY80 10 delms

	cnt COG@ clkfreq +
	begin
		createLogfile
  logperiod waitcnt
		logdata C@++ logFileName 7 lock sd_append 7 unlock
	0 until 
;

: menu
cr ." 2014 06 08 12 00 00 setLocalTime "
cr ." fload logboot.f"
cr ." GY-80 "
cr
;


: startLogger
	-1 lastDay W!
	loggerCog cogreset 10 delms
c" logger" loggerCog cogx
\ c" logger" nfcog cogx

;

\ start.GY80 10 delms
startLogger  10 delms

fread .sdcardinfo

cog?

c" graphboot.f  -  DONE~h0D~h0D" .cstr

...


\ fload graphboot.f

\  GY-80

\ mountusr ls
\ fread IMUnoTIMExxxx
