fl

fswrite boot.f
hA state orC! version W@ .cstr cr cr cr
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
c" boot.f - Running sdboot.f~h0D" .cstr
1 sd_mount fload sdboot.f

c" boot.f - DONE PropForth Loaded~h0D~h0D" .cstr hA state andnC!
...
