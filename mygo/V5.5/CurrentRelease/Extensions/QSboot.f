fl

fswrite btstat.f


\ for the HC06
\ green wire
[ifndef hcProgPin
	22 wconstant hcProgPin
]
\ white/orange wire
[ifndef hcRx
	26 wconstant hcRx
]
\ white/green wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

]


hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags


hcProgPin pinhi hcProgPin pinout

c" AT" hcSend
c" AT+VERSION" hcSend

hcProgPin pinlo 

...

fswrite btinit.f


\ for the HC06
\ green wire
[ifndef hcProgPin
	22 wconstant hcProgPin
]
\ white/orange wire
[ifndef hcRx
	26 wconstant hcRx
]
\ white/green wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

]

hcProgPin pinhi hcProgPin pinout

c" AT" hcSend
c" AT+VERSION" hcSend
c" AT+NAMESanciQStart" hcSend
c" AT+PIN1111" hcSend
c" AT+PN" hcSend
c" AT+BAUD9" hcSend


hcProgPin pinlo 

\ after the hc05 is power cycled, the baud rate will change, not like the hc06

...


fswrite boot.f
hA state orC! version W@ .cstr cr cr cr
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

\ white/orange wire
[ifndef hcRx
	26 wconstant hcRx
]
\ white/green wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef _ready_led
	23 wconstant _ready_led
]

c" QS__" prop W@ ccopy
: onreset6
	fkey? and fkey? and or h1B <>
	if
		$S_con iodis $S_con cogreset 100 delms
		c" _ready_led dup pinout pinhi" $S_con cogx
		c" hcRx hcTx 57600 serial" $S_con cogx 100 delms
		cogid >con
	then
	c" onreset6" (forget)
;


...

