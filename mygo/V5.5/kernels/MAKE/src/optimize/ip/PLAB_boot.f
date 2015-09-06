fl

\
\ This boot file is for a very specific hardware configuration which is
\ a Spinneret with a propeller chip connected.
\
\ norom and mcs are loaded, the subprop is booted and then morom and mcs are unloaded
\
\
\


fswrite boot.f
hA state orC!
version W@ .cstr cr cr cr
c" PLAB" prop W@ ccopy
\
\
\ (forget) ( cstr -- ) wind the dictionary back to the word which follows - caution
[ifndef (forget)
: (forget)
	dup
	if
		find
		if
			pfa>nfa nfa>lfa dup here W! W@ wlastnfa W!
		else
			_p?
			if
				.cstr h3F emit cr
			then
		then
	else
		drop
	then
;
]
\
\
\ forget ( -- ) wind the dictionary back to the word which follows - caution
[ifndef forget
: forget
	parsenw (forget)
;
]
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
c" boot.f - Finding top of eeprom, " .cstr findEETOP ' fstop 2+ alignl L! forget _serial c" Top of eeprom at: " .cstr fstop . cr

c" boot.f - Loading sdcommon.f~h0D" .cstr
fsload sdcommon.f
c" boot.f - Loading sdinit.f~h0D" .cstr
fsload sdinit.f
c" boot.f - Initializing SD card~h0D" .cstr
sd_init
forget build_sdinit
c" boot.f - Loading sdrun.f~h0D" .cstr
fsload sdrun.f
c" boot.f - Loading sdfs.f~h0D" .cstr
fsload sdfs.f

hA 4 cogstate orC!
hA 5 cogstate orC!

1 sd_mount

c" boot.f    LOADING DevKernel.f~h0D" .cstr
fload DevKernel.f

c" boot.f    LOADING term.f~h0D" .cstr
fload term.f

\
\ BEGIN boot and configure subprop
\

1 wconstant SUBPROP

c" boot.f    LOADING norom.f~h0D" .cstr
fload norom.f

c" boot.f    LOADING mcs.f~h0D" .cstr
fload mcs.f



1 wconstant  build_mcsnorom

\ this is what the cogs on the subprop will do on reset
: onreset
	unlockall 4 state orC! version W@ cds W! drop
;



\ this is what the subprop will do on boot
\ 



: onboot
	8 0
	do
		i cogid <>
		if
			i cogreset
		then
	loop

\
\ drop error codes
\
	drop 0 

	h40 0
	do
		h1C 1 qHzb h90000 hA0000 between
		if
			c" h1C h1D hFF h8 mcsslave" h7 cogx h10 delms
			h10000 0
			do
				h7 cogio mcsstate@ 4 =
				if
					leave
				then
			loop
			4 0 7 4 (ioconn)
			0 0 7 0 (ioconn)
		then
	loop
;		

: bootsubprop
	4 state andnC!
	d26 d27 d24 d25 rambootnx
	c" d26 d27 d24 d8 mcsmaster" 2 cogx
	h2000 0
	do
		1 delms
		2 cogstate C@ 4 and 0=
		if
			leave
		then
	loop

	2 cogstate C@ 4 and 0=
	if
		c" SUBPROP CLOCK" tbuf ccopy
		tbuf cds W!
		hA state C!
	else
		4 state orC!
	then
;


: bootplab1
	c" bootsubprop" 3 cogx

	h2000 0
	do
		1 delms
		3 cogstate C@ hA =
		if
			leave
		then
	loop
;

c" boot.f    BOOTING Subprop 1~h0D" .cstr


bootplab1 3 cogstate C@ hA =
[if
	c" 1 propid W!" 2 0 rcogx
	c" forget build_fsrd" 2 0 rcogx
	c" : onboot ; : reboot .~h22 NO~h22 cr ;" 2 0 rcogx
	c" : onreset unlockall 4 state orC! version W@ cds W! drop ;" 2 0 rcogx
	2 0 rfsend DevKernel.f
]

forget SUBPROP

\
\ END boot and configure subprop
\

c" boot.f - Running sdboot.f~h0D" .cstr
fload sdboot.f

fread .sdcardinfo



c" boot.f - Loading ipconfig.f~h0D" .cstr
fload ipconfig.f

c" boot.f - Loading ip.f~h0D" .cstr

c" boot.f - Setting IP configuration~h0D" .cstr
\
\ IP & TELNET CONFIG PARAMETERS BEGIN
\ since cog 5 will be busy on boot
\
4 ' $S_ip_cog 2+ W!
1 ' $S_ip_numTelnet 2+ W!
\
\
\ IP & TELNET CONFIG PARAMETERS END
\

fload ip.f

h8000 memend W! h8000 dictend W!

c" boot.f - Starting telnetServer~h0D" .cstr
startTelnet




2 0 $S_ip_cog 1 (ioconn)
1 ip_SOCKreset drop
1 $S_ip_telnetport + 1 ip_SOCKlistenport W!
-1 h07 h12 h03 1 ip_SOCKsendmultiplereq drop

2 1 $S_ip_cog 2 (ioconn)
2 ip_SOCKreset drop
2 $S_ip_telnetport + 2 ip_SOCKlistenport W!
-1 h07 h12 h03 2 ip_SOCKsendmultiplereq drop

2 2 $S_ip_cog 3 (ioconn)
3 ip_SOCKreset drop
3 $S_ip_telnetport + 3 ip_SOCKlistenport W!
-1 h07 h12 h03 3 ip_SOCKsendmultiplereq drop

c" boot.f    BOOTING Subprops 2 & 3~h0D" .cstr

2 4 rfsend serial.f
2 4 rfsend term.f
: mcs?  ." FRAME COUNT: " cogio dup h34 + L@ . ." ERROR COUNT: " h38 + L@ . cr ;
c" : mcs?  .~h22 FRAME COUNT: ~h22 cogio dup h34 + L@ . .~h22 ERROR COUNT: ~h22 h38 + L@ . cr ; " 2 4 rcogx

c" 1 wconstant SUBPROP" 2 4 rcogx

2 4 rfsend norom.f
2 4 rfsend mcs.f


2 4 rfsend PLAB23_boot.f

100 delms

c" c~h22 c~h7Eh22 3 4 57600 serial~h7Eh22 5 cogx c~h7Eh22 1 0 57600 serial~h7Eh22 6 cogx ~h22 3 0 rcogx" 2 0 rcogx
c" c~h22 1 5 sersetflags 1 6 sersetflags 31 pinhi 5 pinhi 2 pinhi 5 pinout 2 pinout 31 pinout~h22 3 0 rcogx" 2 0 rcogx
c" c~h22 5 pinlo 2 pinlo 100 delms 5 pinhi 2 pinhi 5 pinin 2 pinin 3000 delms ~h22 3 0 rcogx" 2 0 rcogx


c" c~h22 c~h7Eh22 1 0 57600 serial~h7Eh22 5 cogx ~h22 6 0 rcogx" 2 0 rcogx
c" c~h22 1 5 sersetflags 31 pinhi 2 pinhi 2 pinout 31 pinout~h22 6 0 rcogx" 2 0 rcogx
c" c~h22 2 pinlo 100 delms 2 pinhi 2 pinin 3000 delms ~h22 6 0 rcogx" 2 0 rcogx

3000 delms



h8000 memend W!
h8000 dictend W!

c" boot.f - Logging boot timeh0D" .cstr

fload rtc.f

: logdate
	_rtc_r2 utc>local datetimestr pad ccopy c" ~h0D" pad cappend
	pad C@++ c" bootlog" sd_append
	padbl
;

logdate

forget build_rtc


c" boot.f - DONE PropForth Loaded~h0D~h0D" .cstr


6 cogio W@ h1B = h100 6 cogio W! 100 delms
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
6 cogio W@ h1B = h100 6 cogio W! 100 delms or
0=
[if
\ this must all be on one line - we should be running on cog 5
	6 iounlink 6 iodis 6 cogreset 7 cogreset cogid 0 2 cogid (ioconn) hA state andnC! ]


...
