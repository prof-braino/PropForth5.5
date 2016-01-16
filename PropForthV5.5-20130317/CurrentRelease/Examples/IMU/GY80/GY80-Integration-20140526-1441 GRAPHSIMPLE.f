fl
{
GY-80 Simple with Graph.

Postion the graph on the display by editing these values
around line 400 below

\ wvariable upperLeftColumn 1 upperLeftColumn W!
\ wvariable upperLeftRow    1 upperLeftRow    W!

Make the graph larger or smaller by eidting the axislength

\ 15  wconstant axisLength 

NOTE if using the SD kernel, 
the code will not load in one paste operation

See the fl n the comments below, 
Paste lines 1 - 300 first,
then  
paste lines 300 to 600
then 
paste line 600 to end


}
 

\ begin BMP085 driver

1 wconstant build_bmp085

wvariable BMP_temp_C
variable BMP_pressure_hPa  \ this is a LONG

wvariable _bmpOss 3 _bmpOss W!

\ _bmps   ( addr -- ) \ module address write - xEE - SEND
: _bmps   _eestart hEE _eewrite swap _eewrite or if h44 ERR then ;
\ _bmpr   ( addr -- ) \ module address read - xEF - RECEIVE
: _bmpr   _bmps _eestart hEF _eewrite if h45 ERR then ;
\ _bmpcrw ( c -- )  \  xF4 is  control register
: _bmpcrw hF4 _bmps _eewrite _eestop if h46 ERR then ;
\ _bmpr16 ( addr -- u16) 
: _bmpr16 _bmpr 0 _eeread 8 lshift -1 _eeread or _eestop ;
\ _bmpr24 ( addr -- u24)
: _bmpr24 _bmpr 0 _eeread 8 lshift 0 _eeread or 8 lshift -1 _eeread or _eestop ;
\ _bmprs16 ( addr -- n16)
: _bmprs16 _bmpr16 dup h8000 and if hFFFF0000 or then ;
\ _bmpID   ( -- chipid_version)
: _bmpID  hD0 _bmpr16 ;
: _bmpAC1 hAA _bmprs16 ;
: _bmpAC2 hAC _bmprs16 ;
: _bmpAC3 hAE _bmprs16 ;
: _bmpAC4 hB0 _bmpr16 ;
: _bmpAC5 hB2 _bmpr16 ;
: _bmpAC6 hB4 _bmpr16 ;
: _bmpB1  hB6 _bmprs16 ;
: _bmpB2  hB8 _bmprs16 ;
: _bmpMB  hBA _bmprs16 ;
: _bmpMC  hBC _bmprs16 ;
: _bmpMD  hBE _bmprs16 ;

: _bmpUT h2E _bmpcrw d_5 delms hF6 _bmpr16 ;

: _bmpB5
        \ X1 = (UT - AC6)* AC5/2exp15
	_bmpUT _bmpAC6 - _bmpAC5 h8000 */ dup
        \ X2 = MC * 2exp11 / (X1 + MD)
	_bmpMD + _bmpMC h800 rot */
        \ B5 = X1 + X2
	+
;

: bmpTemp _bmpB5 8 + h10 / ;

: _bmpUP
	h34 _bmpOss W@ 6 lshift + _bmpcrw
	_bmpOss W@ 0=
	if d_5 	else 
        _bmpOss W@ 1 =
	if d_8 	else 
        _bmpOss W@ 2 =
	if d_14 else d_26
	thens
	delms 
	hF6 _bmpr24 8 _bmpOss W@ - rshift
;

: bmpPressure
\ B6 = B5 - 4000
	_bmpB5 d_4000 -
\ X1  = (B2 * (B6*B6/2exp12))/2exp11
	dup dup h_1000  */ dup  _bmpB2 h800 */
\ ( B6 B6*B6/2exp12 X1 -- )
\ X2 = AC2*B6/2exp11
	2 ST@ _bmpAC2 h800 */
\ ( B6 B6*B6/2exp12 X1 X2 -- )
\ X3 = X1 +x2
	+
\ ( B6 B6*B6/2exp12 X3 -- )
\ B3 = ( ((AC1*4+X3)<<oss) +2) / 4
	_bmpAC1 4 * + _bmpOss W@ lshift 2+ 4 /
\ ( B6 B6*B6/2exp12 B3 -- )
\ X1 = AC3*B6/2exp13
	rot _bmpAC3 h2000 */
\ ( B6*B6/2exp12 B3 X1 -- )
\ X2 = (B1 *(B6*B6/2exp12))/2exp16
	rot _bmpB1 h_10000 */
\ ( B3 X1 X2 -- )
\ X3 = ((X1+X2)+2)/2exp2
	+ 2+ 4 /
\ (B3 X3 -- )
\ B4 = AC4 * (ulong)(X3+32768) / 2exp15
	d_32_768 + _bmpAC4 h8000 */
\ (B3 B4 -- )
\ B7 = ((ulong)UP-B3)*(50000 >> oss)
	_bmpUP rot - d_50_000 _bmpOss W@ rshift *

	dup h_8000_0000 and 0=
	if 2* swap u/
	else swap u/ 2*
	then
\ ( p -- )
\ X1 = (p/2exp8)*(p/2exp8)
	dup h100 / dup *
\ ( p X1 -- )
\ X1 = (X1 * 3038)/2exp16
	d_3038 h_1_0000 */
\ ( p X1 -- )
\ X2 = (-7357*p)/2exp16
	over d-7357 h_1_0000 */
\ ( p X1 X2 -- )
\ p = p + (X1 + X2 + 3791) / 	2exp4
	+ d_3791 + h10 / +
\ ( p -- )
;

: BMP085
         bmpTemp BMP_temp_C W!
         bmpPressure BMP_pressure_hPa L!
;


\ end  BMP085 driver

1 wconstant build_ADXL345

wvariable ADXL.XYZDATA 4 allot

\ _ADXLs ( addr -- )  ALT ADDRESS pin ground (ADXL Pin 12 from datasheet) 
: _ADXLs
	_eestart hA6 _eewrite swap _eewrite or \ grounding  0xA6 for a write
	if h44 ERR then ;

\ _ADXLr   ( addr -- )  \  ALT ADDRESS pin (Pin 12)
: _ADXLr
	_ADXLs _eestart hA7 _eewrite \ grounding 0xA7 for a read 
	if h45 ERR then ;

\ _ADXLr8 ( addr - U8 )  register read
: _ADXLr8 
          _ADXLr -1 _eeread _eestop 
;

: ADXL.DEVID          h00   ;
: ADXL.DATAX0         h32   ;
: ADXL.POWER_CT       h2D   ;

: @ADXL.DEVID         
             ADXL.DEVID _ADXLr8     
;

\ !POWER_CT ( flags - )  sets flags to configure ADXL 
: !POWER_CT       ADXL.POWER_CT      _ADXLs _eewrite _eestop  ;

: ADXL.initialize 
               b0000_1000 !POWER_CT  
               \ stay awake, measure, awake      
;


\ ADXLrXYZ! ( - ) read current XYZ and store in array ADXL.XYZDATA
: ADXLrXYZ!
             ADXL.DATAX0 
             _ADXLr
           
             0 _eeread  0 _eeread 8 lshift or ADXL.XYZDATA W!
             0 _eeread  0 _eeread 8 lshift or ADXL.XYZDATA 2+ W!
            0 _eeread  -1 _eeread 8 lshift or ADXL.XYZDATA 4+ W!
             _eestop 
;

1 wconstant build_HMC5883L

wvariable HMC5883L.XYZDATA 4 allot

\ _HMCs ( addr -- )
: _HMCs _eestart h3C _eewrite swap _eewrite or if h3C ERR then ;
\ _HMCr ( addr -- )
: _HMCr _HMCs _eestart h3D _eewrite if h3D ERR 	then ;
\ _HMCr24 ( addr -- u24)
: _HMCr24 _HMCr 0 _eeread 8 lshift 0 _eeread or 8 lshift -1 _eeread or _eestop ;
\ _HMCr16 ( addr -- u16)
: _HMCr16 _HMCr 0 _eeread 8 lshift -1 _eeread or _eestop ;
\ _HMCr8 ( addr -- u8)
 : _HMCr8 _HMCr -1  _eeread  _eestop ;
\ _HMCID ( -- chipid_version)
: .HMCID
    ." HMC5883L ID: " 
	h0A _HMCr 0 _eeread  emit 0 _eeread emit -1 _eeread  emit _eestop  space cr 
;
	
: _HMC_dump   decimal   13 0 do cr i  . i _HMCr8 . loop ; 
: _HMC_ConfA h00 _HMCs _eewrite _eestop if h46 ERR then ;
: _HMC_ConfB h01 _HMCs _eewrite _eestop if h46 ERR then ;
: _HMC_mode  h02 _HMCs _eewrite _eestop if h46 ERR then ;
: HMC_Fast_sample h78 _HMC_ConfA ;
: HMC_Continuous_mode  h00 _HMC_mode ;
: HMC.Initialize 
                 HMC_Fast_sample
                 HMC_Continuous_mode
 ;

\ _HMCrXZY ( addr -- Xu16 Zu16 Yu16)
: HMCrXZY! 	
       h03 _HMCr \ starting with X hi
           0 _eeread 8 lshift 0 _eeread or HMC5883L.XYZDATA W! 
           0 _eeread 8 lshift 0 _eeread or HMC5883L.XYZDATA 2+ W!
           0 _eeread 8 lshift -1 _eeread or HMC5883L.XYZDATA 4+ W!
           _eestop 
;

\ 20140511 the mag is no working

: dump_HMC
           ." HMC mag "
        h03 _HMCr \ starting with X hi
          
           0 _eeread 8 lshift 0 _eeread or 
           0 _eeread 8 lshift 0 _eeread or 
           0 _eeread 8 lshift -1 _eeread or
           _eestop 

."  z="  . cr  ."  y="   . cr  ."  x="  . cr 
;


1 wconstant build_L3G4200D

wvariable L3G4200D.DATA 8 allot

\ _L3Gs ( addr -- )
: _L3Gs  _eestart hD2 _eewrite swap _eewrite or \ [SDO = VDD]
\	 _eestart hD0 _eewrite swap _eewrite or \ [SDO = GND]
	if h44 ERR then ;
\ _L3Gr ( addr -- )
: _L3Gr _L3Gs _eestart hD3 _eewrite  \ [SDO = VDD]
\	_L3Gs _eestart hD1 _eewrite \ [SDO = GND]
	if h45 ERR then ;
 \   _L3Gcrw ( c -- )
 \ : _L3Gcrw hF4 _L3Gs _eewrite _eestop if h46 ERR then ;
\ _L3Gw8      ( u8 Addr -- ) \ write one byte
: _L3Gw8        _L3Gs _eewrite or _eestop ;
: _L3Gr8        _L3Gr -1 _eeread _eestop ;
: _L3Gr88       _L3Gr 0 _eeread -1 _eeread _eestop ;
\ _L3Gr16    ( addr -- u16) \ int is Hi Lo
: _L3Gr16int    _L3Gr 0 _eeread 8 lshift -1 _eeread or _eestop ;
\ _L3Gr16xyz ( addr -- u16 ) \ xyz are lo hi
: _L3Gr16xyz _L3Gr 0 _eeread -1 _eeread 8 lshift or _eestop ;
\ _L3G.ID ( -- chipid_version:11010011 hD3  d211)
: _L3G.ID h0F _L3Gr8 ;
\ : L3G.WHO_AM_I      h0F    ; \ readonly = xD3 
: L3G.CTRL_REG1     h20   ; \ default = x07
: L3G.CTRL_REG2     h21   ; \ default = x0 
: L3G.CTRL_REG3     h22   ; \ default = x0
: L3G.CTRL_REG4     h23   ; \ default = x0
: L3G.CTRL_REG5     h24   ; \ default = x0
: L3G.OUT_TEMP      h26    ; \ readonly
: L3G.STATUS_REG    h27    ; \ readonly
: L3G.OUT_X_L       h28    ; \ readonly
: L3G.OUT_X_H       h29    ; \ readonly
: L3G.OUT_Y_L       h2A    ; \ readonly
: L3G.OUT_Y_H       h2B    ; \ readonly
: L3G.OUT_Z_L       h2C    ; \ readonly
: L3G.OUT_Z_H       h2D    ; \ readonly

: autoINC h80 or ;

: @L3G.xyz16 L3G.OUT_TEMP autoINC
\             hA6 
             _L3Gr 
             0 _eeread                    \ temperature 
             0 _eeread                    \ status    
             0 _eeread 0 _eeread 8 lshift or \ x
             0 _eeread 0 _eeread 8 lshift or \ y
             0 _eeread 0 _eeread 8 lshift or \ z
             0 _eeread  drop \ FIFO ctl
            -1 _eeread \ FIFO src
\ If FIFO, not used, remove last two
;

: L3G.data!
             L3G.OUT_TEMP autoINC
\             hA6 
             _L3Gr 
     0 _eeread                       L3G4200D.DATA     C! \ temperature 
     0 _eeread                       L3G4200D.DATA 1+  C! \ status    
     0 _eeread 0 _eeread 8 lshift or L3G4200D.DATA 2+  W! \ x
     0 _eeread 0 _eeread 8 lshift or L3G4200D.DATA 4+  W! \ y
     0 _eeread 0 _eeread 8 lshift or L3G4200D.DATA 6 + W! \ z
     0 _eeread                       L3G4200D.DATA 8 + C!  \ FIFO ctl
    -1 _eeread                       L3G4200D.DATA 9 + C! \ FIFO src
\ If FIFO, not used, remove last two
;

{
====================================
Load in several sections of 300 lines
Section 2
===================================
}

\  fl



: !L3G8 _L3Gw8 ; \  MAYBE!!!!!!!

: !L3G.CTRL_REG1     h20 !L3G8   ; \ default = x07
: !L3G.CTRL_REG2     h21 !L3G8  ; \ default = x0 
: !L3G.CTRL_REG3     h22 !L3G8  ; \ default = x0
: !L3G.CTRL_REG4     h23 !L3G8  ; \ default = x0
: !L3G.CTRL_REG5     h24 !L3G8  ; \ default = x0

: L3G.initialize

  b0000_1111 !L3G.CTRL_REG1 \ min speed, power on
  b0010_0111 !L3G.CTRL_REG2 \ normal 200Hz  0.1
  b0000_0000 !L3G.CTRL_REG3 \ idsable interupts (default)
  b0000_0000 !L3G.CTRL_REG4 \ continuous, LSB lowest, CHECK FULL SCALE
  b0000_0000 !L3G.CTRL_REG5 \ boot, no FIFO, no HiPass, def INT 
;

: (signed)  dup h8000 and if hFFFF0000 or then  ;

\ do.GY80 does the AXDL driver in a background cog
: do.GY80
        4 state andnC!
        c" GY80-driver" cds W! \ text displayed by cog?
        ADXL.initialize   \ ADXL345
     \  BMP085
        HMC.Initialize    \  MMC5883L
        L3G.initialize \  L3G4200D  
        begin
            ADXLrXYZ!
            BMP085
            HMCrXZY!     \  MMC5883L
            L3G.data! \ L3G4200D  
        0 until
        \ 
;

: start.GY80
            c" do.GY80 " nfcog cogx
;


: csi h_1B emit h_5B emit ;
: m ." m" ;    
: smallf ." f" ; 
: K ." K" ;
: semicolon ." ;" ;
: v>c h_30 + emit ;
: .digits dup h_9 > if h_0A u/mod v>c then  v>c ;

\ AT  ( x y - ) put cursor at x,y (column , row)
: AT csi .digits semicolon .digits smallf ;
: home       csi ." 1;1f" ;
: clear      csi ." 2J" ; 
: cls home clear  ;

: @ADXL.X ADXL.XYZDATA    W@ (signed) ;
: @ADXL.Y ADXL.XYZDATA 2+ W@ (signed) ;
: @ADXL.Z ADXL.XYZDATA 4+ W@ (signed) ;


: .ADXL
     cr ." ADXL.X=" @ADXL.X . 3 spaces
     cr ." ADXL.Y=" @ADXL.Y . 3 spaces
     cr ." ADXL.Z=" @ADXL.Z . 3 spaces
;

: T2   \ ADXL.initialize  \ start.GY80  
      begin  
            2 11 AT .ADXL fkey? if h1B = else drop 0 then 
      until 
;

wvariable upperLeftColumn 1 upperLeftColumn W!
wvariable upperLeftRow    1 upperLeftRow    W!

\ 15  wconstant axisLength \ minicom

8  wconstant axisLength \ samsung captivate glide phone

\ dont change the label size, it gets icky
4  wconstant labelLength 

axisLength 2- wconstant magnitude 

: @centerColumn
               labelLength axisLength  2*  + 
               upperLeftColumn W@  + 1+      
; 

: @centerRow
           labelLength axisLength    + 
           upperLeftRow  W@  +     
; 

\ axis labels

: .Y+ @centerColumn  axisLength 1+ 2* + @centerRow AT ." +Y+" ;
: .Y- @centerColumn  axisLength 2+ 2* - @centerRow AT ." -Y-" ;

: .Z+ @centerColumn 1- @centerRow axisLength 2+  - AT ." +Z+" ;
: .Z- @centerColumn 1- @centerRow axisLength 2+  + AT ." -Z-" ;

: .X+ @centerColumn axisLength 1+  2* + @centerRow axisLength 1+  - AT ." +X+"  ;
: .X- @centerColumn axisLength 2+  2* - @centerRow axisLength 1+  + AT ." -X-"  ;

\ graph axis lines

: .axisY+ axisLength 1+ 1 do @centerColumn i 2* + 1- @centerRow     AT ." --" loop .Y+ ;
: .axisY- axisLength 1+ 1 do @centerColumn i 2* - @centerRow     AT ." --" loop .Y- ;
: .axisZ+ axisLength 1+ 1 do @centerColumn        @centerRow i - AT ." |" loop .Z+ ;
: .axisZ- axisLength 1+ 1 do @centerColumn        @centerRow i + AT ." |" loop .Z- ;
: .axisX- axisLength 1+ 1 do @centerColumn i 2* - @centerRow i + AT ." /" loop .X- ;
: .axisX+ axisLength 1+ 1 do @centerColumn i 2* + @centerRow i - AT ." /" loop .X+ ;

: .arrows \ ( C R  gyro - )
          dup >r 
          1000 > if   2dup 1- AT ." >>>" 1+ AT ." <<<" 
                   r> drop 
              else 
              r>
          -1000 < if   2dup 1- AT ." <<<" 1+ AT ." >>>" 
              else 2dup 1- AT ." ===" 1+ AT ." ===" 
              thens
;

\ pitch is Y
: gyroY+ @centerColumn  axisLength 1+ 2* + @centerRow  ;
: gyroY- @centerColumn  axisLength 2+ 2* - @centerRow  ;

\ yaw is Z
: gyroZ-  @centerColumn 1- @centerRow axisLength 2+  +  ;
: gyroZ+  @centerColumn 1- @centerRow axisLength 2+  -  ;

\ roll is X
: gyroX+ @centerColumn axisLength 1+  2* + @centerRow axisLength 1+  - ;
: gyroX- @centerColumn axisLength 2+  2* - @centerRow axisLength 1+  + ;

: .accYdata+ > if  ." >" else space then ;
\ .accYdata- \  ( data len - )
: .accYdata-  < if  space else ." <" then ;

: .accY
        ADXL.XYZDATA 2+ W@ (signed) 
        dup 4 rshift (signed)  \ scale the data to axis len positive
                  axisLength 2 do   \ was 2+ 2
                  @centerColumn i 2* + @centerRow 1+ AT  dup i .accYdata+ 
                  loop drop
        dup 4 rshift (signed)  \ scale the data to axis len neg
        negate         
                  axisLength   2 do \ was 2+ 1+ 2
                  @centerColumn i 2* - @centerRow 1- AT dup i .accYdata- 
                  loop drop
        drop
;

\ .accZdata+  ( data len - )
: .accZdata+  > if  ." ^" else space then ;
\ .accZdata-  ( data len - )
: .accZdata-  < if  space else ." v" then ;

: .accZ
        ADXL.XYZDATA 4+ W@ (signed) 
        dup 4 rshift  (signed) \ scale the data to axis len positive
        axisLength  2   \  was 2+ 2
        do 
           @centerColumn 1+ @centerRow  i - AT dup i .accZdata+ 
        loop drop
        dup 4 rshift (signed)  \ scale the data to axis len neg
        negate
        axisLength  2 
        do 
            @centerColumn 1- @centerRow  i + AT dup i .accZdata-  
        loop drop
        drop   
;

\ .accXdata+  ( data len - )
: .accXdata+  > if  ." 7" else space then ;
\ .accXdata-  ( data len - )
: .accXdata-  < if  space else ." L" then ;

: .accX
        ADXL.XYZDATA    W@  (signed) 
        dup 4 rshift (signed)  \ scale the data to axis len positive
        axisLength  2 
        do 
             @centerColumn i 2* + 1+ @centerRow i - AT  dup i .accXdata+  
        loop drop
        dup 4 rshift (signed)  \ scale the data to axis len neg
        negate
        axisLength  2 
        do 
             @centerColumn i 2* - 1- @centerRow i + AT dup i .accXdata- 
        loop drop
   drop
;

{

===========================
load as another section? 

===========================

}

\  fl

: .HMCrXZY 	
       h00 _HMC_mode \ continuous mode
       HMC.Initialize  


  4 4 AT   h02 _HMCr 0 _eeread ." mode:" . 3 spaces \ starting with mode
  7 5 AT   0 _eeread 8 lshift 0 _eeread or ." X:" (signed) . 3 spaces
  7 6 AT   0 _eeread 8 lshift 0 _eeread or ." Z:" (signed) . 3 spaces 
  7 7 AT   0 _eeread 8 lshift 0 _eeread or ." Y:" (signed) . 3 spaces 
  2 8 AT  -1 _eeread  ." Status:" .  3 spaces 
             _eestop 
;

: HMC.test  
     cls
     0 
     begin  
          1+ dup 9 3 AT . 2 spaces 
          .HMCrXZY  
          fkey? if h1B = else drop 0 then 
     until 
;

: @magY HMC5883L.XYZDATA 4+ W@ (signed) ;
: @magZ HMC5883L.XYZDATA 2+ W@ (signed) ;
: @magX HMC5883L.XYZDATA    W@ (signed) ;

: .HMC
       home
       @magX . 
       @magY .
       @magZ .
;

: T3
       begin
       .HMC 
             fkey? if h1B = else drop 0 then 
      until 
      
 30 30 AT st?
;



: .magDATA+ > if ." @" else space then ; 
: .magDATA- < if space else ." @" then ; 

: .magY 
   @magY 4 rshift (signed) 
   axisLength 2 do @centerColumn i 2* + @centerRow 1- AT dup i .magDATA+ loop
   negate
   axisLength 2 do @centerColumn i 2* - @centerRow 1+ AT dup i .magDATA- loop
   drop
;

: .magZ 
   @magZ 4 rshift (signed) 
   axisLength 2 do @centerColumn 1- @centerRow i - AT dup i .magDATA+ loop
   negate
   axisLength 2 do @centerColumn 1+ @centerRow i + AT dup i .magDATA- loop
   drop
;

{

SKIP THIS ONE?

====================================
Load in several sections of 300 lines
Section 3
===================================
}

\  fl


: .magX 
   @magX 4 rshift (signed) 
   axisLength 2 do @centerColumn i 2* + 1- @centerRow i - AT dup i .magDATA+ loop
   negate
   axisLength 2 do @centerColumn i 2* - 1+ @centerRow i + AT dup i .magDATA- loop
   drop
;

: .L3G4200D
            ." L3G " 
            L3G4200D.DATA     C@ (signed) . ." C " cr
            L3G4200D.DATA 1+  C@ (signed) . ." stat "  cr
            L3G4200D.DATA 2+  W@ (signed) . ." x    " cr
            L3G4200D.DATA 4+  W@ (signed) . ." y    " cr
            L3G4200D.DATA 6 + W@ (signed) . ." z    " cr
            L3G4200D.DATA 8 + C@ (signed) . ." odd   " cr
            L3G4200D.DATA 9 + C@ (signed) .  ." fifo   "  cr
;

: @GX L3G4200D.DATA 2+  W@  (signed) ;
: @GY L3G4200D.DATA 4+  W@  (signed) ;
: @GZ L3G4200D.DATA 6 + W@  (signed) ; 

: .pitch gyroY+   @GY .arrows gyroY-   @GY .arrows ;
: .yaw  gyroZ+  @GZ .arrows gyroZ-  @GZ .arrows ;
: .roll  gyroX+ @GX .arrows gyroX- @GX .arrows ;

{
====================================
Load in several sections of 300 lines
Section 4
===================================
}

\  fl


1 wconstant build_bmp085alt

lockdict variable _bmp085_pd

50 l, 200 l, 450 l, 800 l, 1300 l, 1900 l, 2600 l,
3450 l, 4400 l, 5450 l, 6600 l, 7850 l, 9200 l, 10650 l, 12200 l,
13800 l, 15500 l, 17250 l, 19100 l, 21000 l, 22950 l, 24950 l, 27000 l,
29100 l, 31200 l, 33350 l, 35500 l, 37700 l, 39900 l, 42100 l, 44300 l,
46500 l, 48650 l, 50800 l, 52950 l, 55050 l, 57100 l, 59150 l, 61150 l,
63100 l, 65000 l, 66850 l, 68650 l, 70400 l, 72100 l, 73750 l, 75350 l,
76900 l, 78400 l, 79850 l, 81250 l, 82550 l, 83800 l, 84950 l, 86100 l,
87200 l, 88250 l, 89200 l, 90100 l, 90950 l, 91750 l, 92500 l, 93200 l, 
0 _bmp085_pd L!
freedict

lockdict variable _bmp085_ba
4163 l, 16664 l, 37532 l, 66817 l, 108797 l, 159398 l, 218746 l,
291271 l, 372934 l, 463951 l, 564567 l, 675061 l, 795745 l, 926976 l, 
1069149 l, 1218024 l, 1378638 l, 1546690 l, 1727453 l, 1916563 l, 
2114453 l, 2321604 l, 2538542 l, 2765855 l, 2998584 l, 3242776 l, 
3493304 l, 3756614 l, 4027402 l, 4306160 l, 4593432 l, 4889824 l, 
5188935 l, 5498100 l, 5818108 l, 6141992 l, 6469855 l, 6810264 l, 
7155538 l, 7505850 l, 7861387 l, 8222344 l, 8588928 l, 8961357 l, 
9339860 l, 9724684 l, 10116085 l, 10514337 l, 10919730 l, 11332568 l, 
11753174 l, 12165573 l, 12584525 l, 12991907 l, 13423155 l,
13861085 l, 14305678 l, 14733582 l, 15164787 l, 15598560 l, 
16033955 l, 16469768 l, 16904486 l,
0 _bmp085_ba L!
freedict

lockdict variable _bmp085_a
83271 l, 83337 l, 83471 l, 83672 l, 83959 l, 84334 l, 84782 l,
85323 l, 85961 l, 86682 l, 87492 l, 88394 l, 89396 l, 90503 l, 
91724 l, 93046 l, 94478 l, 96029 l, 97709 l, 99531 l, 101482 l, 
103575 l, 105823 l, 108244 l, 110823 l, 113577 l, 116524 l, 
119686 l, 123085 l, 126708 l, 130578 l, 134723 l, 139121 l, 
143797 l, 148840 l, 154230 l, 159933 l, 166053 l, 172636 l, 
179647 l, 187124 l, 195111 l, 203657 l, 212816 l, 222649 l, 
233226 l, 244625 l, 256936 l, 270261 l, 284715 l, 300433 l, 
317229 l, 335161 l, 354245 l, 374998 l, 398118 l, 423421 l, 
450425 l, 479117 l, 510320 l, 544243 l, 581085 l, 621024 l, 
0 _bmp085_a L!
freedict

\ bmpAlt ( base press -- alt)
: bmpAlt
	- dup
	_bmp085_pd  d_252 + L@ -
	_bmp085_a d_252 + L@ d_1000 */
	_bmp085_ba d_252 + L@ +
	swap
\ alt diff
	d_63 0
	do
		dup
		_bmp085_pd i 4* + dup L@ swap 4+ L@
		between
		if
			nip
\ diff
			_bmp085_pd i 4* + L@ -
			_bmp085_a i 1+ 4* + L@ d_1000 u*/ 
			_bmp085_ba i 4* + L@ +
			0 leave
		then
	loop
	drop
;

{
====================================
Load in several sections of 300 lines
Section 5
===================================
}

\  fl




[ifdef bmpAlt_test
: bmpAlt_test
	101325 0
	do 
	    i . ." : "
		dup dup i - dup . bmpAlt . cr
	20 +loop
;   
]

\ hg>hpa ( n1 -- n2)
: hg>hpa
	d_3_386_388_16 d_10_000_000 u*/
;

\ hpa>hg ( n1 -- n2)
: hpa>hg
	d_2_952_998_751 d_1_000_000_000 u*/
	d_100 u/mod swap d_49 > if 1+ then
;

{
=======================================
}
: @BMP085
          BMP_temp_C W@
          BMP_pressure_hPa L@
;

: .BMP085
         
         @BMP085 swap
          ." BMP: " .
          ." C  and " . ." hPa "  
;

{
           \ 101325 bmpPressure bmpAlt 
           \ get it from memory like the logger will
}             

: Altitude 
             101325 BMP_pressure_hPa L@ bmpAlt 
;

variable prevAlt

\ also in simple diagnostic ? 
: .alt Altitude dup  .  dup prevAlt L@ - .  prevAlt L! ;
  
: GY-80
       5 cogreset 100 delms
       sc
       cls
\       axisLength dup 3 * swap 2 * 1- AT sc
       start.GY80
       .axisY+ .axisY- .axisZ- .axisZ+ .axisX+ .axisX-
       0 
       begin
             1+ dup home  .
             \ display data
            .accY  .accZ  .accX 
            .magY  .magZ .magX
            .pitch .yaw .roll

             1 2  AT .L3G4200D
\ axisLength dup 3 * swap 2 *  
@centerColumn 5 +  @centerRow 3 + 
AT .BMP085 .alt 5 spaces
             fkey? if h1B = else drop 0 then 
      until 
      
 30 30 AT st?
;

{
\       start.GY80 
}


