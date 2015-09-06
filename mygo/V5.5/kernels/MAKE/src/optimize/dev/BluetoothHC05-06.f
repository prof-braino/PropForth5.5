

fl

\ for the HC06

\ green wire
27 wconstant hcProgPin

\ white/orange wire
26 wconstant hcRx

\ white/green wire
25 wconstant hcTx

9600 4/ wconstant hcBaud

0 wconstant hcSerialCog

hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms


: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

hcProgPin pinhi hcProgPin pinout

c" AT" hcSend
c" AT+VERSION" hcSend
c" AT+NAMESanciHC06-1" hcSend
c" AT+PIN1111" hcSend
c" AT+PN" hcSend
c" AT+BAUD9" hcSend

hcProgPin pinlo 

1000 delms

hcSerialCog cogreset 100 delms
230400 4/ wconstant hcBaud
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms

hcProgPin pinhi hcProgPin pinout

c" AT" hcSend
c" AT+VERSION" hcSend
c" AT+NAMESanciHC06-2" hcSend
c" AT+PIN1111" hcSend
c" AT+PN" hcSend
\ c" AT+BAUD4" hcSend \ sets back to 9600 baud

hcProgPin pinlo



fl

\ for the HC05

\ green wire
27 wconstant hcProgPin

\ white/orange wire
26 wconstant hcRx

\ white/green wire
25 wconstant hcTx

9600 4/ wconstant hcBaud

0 wconstant hcSerialCog

hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags


: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

hcProgPin pinhi hcProgPin pinout

c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend
c" AT+NAME=SanciHc05-1~h0D~h0A" hcSend
c" AT+PSWD=1111~h0D~h0A" hcSend
c" AT+UART=230400,0,0~h0D~h0A" hcSend
c" AT+VERSION~h0D~h0A" hcSend
c" AT+ROLE?~h0D~h0A" hcSend
c" AT+UART?~h0D~h0A" hcSend
c" AT+NAME?~h0D~h0A" hcSend
c" AT+PSWD?~h0D~h0A" hcSend

hcProgPin pinlo 

\ after the hc05 is power cycled, the baud rate will change, not like the hc06














