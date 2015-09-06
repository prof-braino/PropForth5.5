\
\
\ serial ( n1 n2 n3 -- ) 
\ n1 - tx pin
\ n2 - rx pin
\ n3 - baud rate / 4 - the actual baud rate will be 4 * this number
\
\ _serial ( n1 n2 n3 -- )
\ n1 - tx pin
\ n2 - rx pin
\ n3 - clocks/bit
\
\ h00 - h04 -- io channel
\ h04 - h84 -- the receive buffer
\ h84 - hC4 -- the transmit buffer
\ hC4 - breaklength (long), if this long is not zero the driver will transmit a break breaklength cycles,
\		the minmum length is 16 cycles, at 80 Mhz this is 200 nanoSeconds
\ hC8 - flags (long)
\	h_0000_0001 	- if this bit is 0, CR is transmitted as CR LF
\			- if this bit is 1, CR is transmitted as CR
\
lockdict create _serial forthentry
$C_a_lxasm w, h1B8  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z8Fryj l, z2WytCj l, z2WytLG l, z2WytTP l, z2Wyt\k l, z2Wyth6 l, z2Wytp] l, z1bixaB l,
z1bixqB l, z1Sit7H l, z1YFsNl l, z1SL04S l, z2Wyub9 l, z2Wiuq8 l, z20iuqk l, z20iuq9 l,
z1Sit7H l, z2WisiU l, z24isik l, z31Vsb0 l, z1SJ04Z l, z1XFsNl l, zjyuW1 l, z3[yufY l,
z1SJ04S l, zbyuWN l, z1WyuZy l, z2WirqS l, z1SV04S l, z1SitFI l, z26Fw7e l, z1SQ04j l,
z1bywY0 l, z1Gi]qf l, z2Wiuy5 l, z1Wiuyf l, zbiuyg l, z1SitFI l, z\yrb8 l, z38ywW0 l,
z1WywXy l, z20ywb8 l, z20ywO1 l, z1WywVy l, z1SitFI l, z1byuv0 l, zfyur2 l, z1byur1 l,
z2Wyv0B l, z1SitFI l, z2WivFk l, zcyur1 l, z1jixaB l, z20ivF9 l, z1SitFI l, z2WisiX l,
z24isik l, z31Vsb0 l, z1SJ059 l, z3[yv56 l, z1SV04j l, z1SitNG l, z1SitNJ l, z1SitNG l,
z1SitNK l, z1SitNG l, z1SitNL l, z1SitNG l, z1SitNM l, z1SV05G l, z1SitVI l, z1YVrn0 l,
z1SL05P l, z2WityY l, z20ytr1 l, z1Wytyy l, z26Fty\ l, z1SQ05P l, z1SitVI l, z1Kig7Z l,
z1KigFZ l, z2Wisi6 l, z2Wyrn0 l, zfisi[ l, z1Wisi2 l, z1[ivV2 l, z1bivVD l, z1SitVI l,
z\yrG8 l, z38yvO0 l, z1WyvPy l, z20yvW8 l, z2WivNN l, z1SV05P l, z1SitaI l, z26FvN\ l,
z1SQ05k l, z26VsW0 l, z4\syC l, z1YLsv0 l, z1SQ05k l, z1SitaI l, z1GiiV] l, z2Wisy3 l,
z1Wisy] l, zbisya l, z4FsyC l, z1SitaI l, z\yrO8 l, z38yvj0 l, z1Wyvky l, z20yvr8 l,
z20yvb1 l, z1Wyviy l, z1SV05k l, z1SitiI l, z4iuFj l, z1YVuC0 l, z1SL066 l, z1SitiI l,
z2Wiu7b l, z20yu01 l, z1Wyu7y l, z26Fu7e l, z1SQ066 l, z1SitiI l, z1bywA0 l, z1Kilyc l,
z1Kim7c l, z2WisiP l, zfisid l, z1Wisi4 l, z1[iwF4 l, z1biwFD l, z1SitiI l, z\yrW8 l,
z38yw80 l, z1Wyw9y l, z20ywG8 l, z2Wiw7O l, z1SitiI l, z26Vu8D l, z1YQuO1 l, z45ryj l,
z2WtsbA l, z4Asij l, z1SV066 l, z1SitqI l, z2WiuNj l, z20yuG2 l, z4isaQ l, z1SitqI l,
z20yuJ2 l, zAisyQ l, z1SQ06n l, z8FwqQ l, z18ysrG l, z1[ixaB l, z20isyk l, z3rysr0 l,
z1bixaB l, z1SitqI l, z20yuG4 l, z8iuVQ l, z1SV06] l,
freedict
\
\
: serial
	4*
	clkfreq swap u/ dup 2/ 2/
\
\ serial structure
\
\
\ init 1st 4 members to hFF
\
	hFF h1C2 
	2dup COG!
	1+ 2dup COG!
	1+ 2dup COG!
	1+ tuck COG!
\
\ next 2 members to h100
\
	1+ h100 swap 2dup COG!
	1+ tuck COG!
\
\ bittick/4, bitticks
\
	1+ tuck COG!
	1+ tuck COG!
\
\ rxmask txmask
\
	1+ swap >m over COG!
	1+ swap >m over COG!
\ rest of structure to 0
	1+ h1F0 swap
	do
		0 i COG!
	loop
\
	c" SERIAL" numpad ccopy numpad cds W!
	4 state andnC!
	0 io hC4 + L!
	0 io hC8 + L!
	_serial
;
