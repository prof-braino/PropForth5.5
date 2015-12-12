fl

fswrite btstat.f
\ for the HC05
\ White wire - prop input, hi if connected
[ifndef hcConnect
	16 wconstant hcConnect
]
\ blue wire - prop output, hi to program device
[ifndef hcProgPin 
	17 wconstant hcProgPin
]
\ blue wire - prop input, lo when hc05 wants to send data
[ifndef hcRts
	18 wconstant hcRts
]
\ blue wire - prop output, lo when hc05 can send data
[ifndef hcCts
	19 wconstant hcCts
]
\ red wire - prop output, data
[ifndef hcRx
	20 wconstant hcRx
]
\ white wire - prop input, data 
[ifndef hcTx
	21 wconstant hcTx
]
[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
\	d_9600 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;
]

\ hcConnect? ( -- t/f) bluetooth connected
[ifndef hcConnect?
: hcConnect?
	hcConnect dup pinin px?
;
]

\ hcRts? ( -- t/f) bluetooth connected
[ifndef hcRts?
: hcRts?
	hcRts dup pinin px?
;
]

{
: hcQ
	cogid hcSerialCog iolink
	begin
		hcConnect? 0=
		if
			c" NOT CONNECTED~h0D" .concstr
			d_1000 delms
		then
	fkey?
	if
		dup h_1B =
		if
			drop -1
		else
			dup h_30 =
			if
				c" CTS LO~h0D~h0A" hcSerialCog cogx
				hcCts pinlo
			else
				dup h_31 =
				if
					c" CTS hi~h0D~h0A" hcSerialCog cogx
					hcCts pinhi
				then
			then
			drop 0
		then
	else
		drop 0
	then
	until
	cogid iounlink
;
}

hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags
hcConnect? .

hcCts pinout hcCts pinlo

hcProgPin pinhi hcProgPin pinout

c" AT+VERSION~h0D~h0A" hcSend
c" AT+ADDR?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+RNAME?~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+CLASS?~h0D~h0A" hcSend
c" AT+IAC?~h0D~h0A" hcSend
c" AT+INQM?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+CMODE?~h0D~h0A" hcSend
c" AT+BIND?~h0D~h0A" hcSend
c" AT+POLAR?~h0D~h0A" hcSend
c" AT+IPSCAN?~h0D~h0A" hcSend
c" AT+SNIFF?~h0D~h0A" hcSend
c" AT+SENM?~h0D~h0A" hcSend
c" AT+ADCN?~h0D~h0A" hcSend
c" AT+MRAD?~h0D~h0A" hcSend
c" AT+STATE?~h0D~h0A" hcSend




hcProgPin pinlo 

...

fswrite btinit.f

\ for the HC05
\ White wire - prop input, hi if connected
[ifndef hcConnect
	16 wconstant hcConnect
]
\ blue wire - prop output, hi to program device
[ifndef hcProgPin 
	17 wconstant hcProgPin
]
\ blue wire - prop input, lo when hc05 wants to send data
[ifndef hcRts
	18 wconstant hcRts
]
\ blue wire - prop output, lo when hc05 can send data
[ifndef hcCts
	19 wconstant hcCts
]
\ red wire - prop output, data
[ifndef hcRx
	20 wconstant hcRx
]
\ white wire - prop input, data 
[ifndef hcTx
	21 wconstant hcTx
]

[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
\	d_9600 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

\ hcConnect? ( -- t/f) bluetooth connected
[ifndef hcConnect?
: hcConnect?
	hcConnect dup pinin px?
;
]


[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

]


hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags
hcConnect? .


hcProgPin pinhi hcProgPin pinout

c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend
c" AT+NAME=CreativeCompanion~h0D~h0A" hcSend
c" AT+PSWD=password~h0D~h0A" hcSend
c" AT+UART=230400,0,0~h0D~h0A" hcSend
c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend


hcProgPin pinlo 

\ after the hc05 is power cycled, the baud rate will change, not like the hc06

...


fswrite boot.f
hA state orC! version W@ .cstr cr cr cr

: getfile
	." ~h0D........~h0D"
	fsread
	." ~h0D,,,,,,,,~h0D"
;

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

c" boot.f - Finding top of eeprom, " .cstr findEETOP ' fstop 2+ alignl L! forget findEETOP c" Top of eeprom at: " .cstr fstop . cr


c" boot.f - DONE PropForth Loaded~h0D~h0D" .cstr hA state andnC!

\ for the HC05
\ White wire - prop input, hi if connected
[ifndef hcConnect
	16 wconstant hcConnect
]
\ blue wire - prop output, hi to program device
[ifndef hcProgPin 
	17 wconstant hcProgPin
]
\ blue wire - prop input, lo when hc05 wants to send data
[ifndef hcRts
	18 wconstant hcRts
]
\ blue wire - prop output, lo when hc05 can send data
[ifndef hcCts
	19 wconstant hcCts
]
\ red wire - prop output, data
[ifndef hcRx
	20 wconstant hcRx
]
\ white wire - prop input, data 
[ifndef hcTx
	21 wconstant hcTx
]
[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
\	d_9600 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

[ifndef xsmDir
	d0 wconstant xsmDir
\ rising edge 2us cycletime max
	d_01 wconstant xsmStep
\ active lo
	d_02 wconstant xsmSlp
\ active lo
	d_03 wconstant xsmRst
	d_04 wconstant xsmMs3
	d_05 wconstant xsmMs2
	d_06 wconstant xsmMs1
\ active lo
	d_07 wconstant xsmEn
	d_24 wconstant xsmTemp
	d_25 wconstant xsmDTemp
]

[ifndef ysmDir
	d_08 wconstant ysmDir
\ rising edge 2us cycletime max
	d_09 wconstant ysmStep
\ active lo
	d_10 wconstant ysmSlp
\ active lo
	d_11 wconstant ysmRst
	d_12 wconstant ysmMs3
	d_13 wconstant ysmMs2
	d_14 wconstant ysmMs1
\ active lo
	d_15 wconstant ysmEn
	d_23 wconstant ysmTemp
	d_22 wconstant ysmDTemp
]

: smInit
	h_F3F3 outa COG! h_FFFF dira COG!
	10 delms h_FBFB outa COG!  
	10 delms h_FFFF outa COG!
;

: xsmOn  xsmEn pinlo ;  
: xsmOff xsmEn pinhi ;  

: ysmOn  ysmEn pinlo ;  
: ysmOff ysmEn pinhi ;  

: _xStep xsmStep pinhi xsmStep pinlo ;

: xStep xsmDir over 0> if pinhi else pinlo then abs 0 do _xStep loop ;
	 
: _yStep ysmStep pinhi ysmStep pinlo ;

: yStep ysmDir over 0> if pinhi else pinlo then abs 0 do _yStep loop ;

: _temp?
	dup pinlo dup pinout
	1 delms
	cnt COG@ over pinin
	swap >m dup waitpeq
	cnt COG@ swap -
;

: xsmTemp? 0 h10 0 do xsmTemp _temp? + loop h10 u/ ;

: ysmTemp? 0 h10 0 do ysmTemp _temp? + loop h10 u/ ;

: xsmDTemp? 0 h10 0 do xsmDTemp _temp? + loop h10 u/ ;

: ysmDTemp? 0 h10 0 do ysmDTemp _temp? + loop h10 u/ ;

: temp 
	begin
		." x: "       xsmTemp? .long space xsmDTemp? .long
		."       y: " ysmTemp? .long space ysmDTemp? .long cr
		fkey?
		if
			h1B =
		else
			drop 0
		then
	until
;	


	
	
[ifndef _ready_led
	27 wconstant _ready_led
]

: prompt
	c" CreativeCompanion-" prop W!
;

: onreset6
	fkey? and fkey? and or h1B <>
	if
		smInit
		prompt
		$S_con iodis $S_con cogreset 100 delms
		c" _ready_led dup pinout pinhi" $S_con cogx
		c" hcRx hcTx 57600 serial" $S_con cogx 100 delms
		cogid >con
	then
	c" onreset6" (forget)
;


...
