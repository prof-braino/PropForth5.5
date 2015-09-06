1 wconstant build_ds1302

d_16 wconstant ce
d_17 wconstant io
d_18 wconstant ck


\ wr8 ( addr -- )
: wr8
	io pinlo io pinout
	h8 0
	do
		ck pinlo
		dup 1 and
		if
			io pinhi
		else
			io pinlo
		then
		ck pinhi
		1 rshift
	loop
	drop
	io pinin
	io pinlo
;

\ rd8 ( -- data )
: rd8
	0 h8 0
	do
		1 rshift
		ck pinlo
		io px?
		if
			h80 or
		then
		ck pinhi
	loop
;

: _st
	ck pinlo ck pinout
	ce pinhi ce pinout
;

: _end
	ck pinlo 
	ce pinlo 
	ck pinin
	ce pinin
;
 
\ wr ( data addr -- )
: wr
	_st
	wr8 wr8
	_end
;

\ rd ( addr -- data )
: rd
	_st
	wr8
	rd8
	_end
;

: wpoff
	0 h8E wr
;

: wpon
	h80 h8E wr
;


\ rdclk ( -- n1 - n8)
: rdclk
	_st
	hBF
	wr8
	h8 0
	do
		rd8
	loop
	_end
\ ." ~h0Drdclk: " base W@ hex st? base W!
;

\ wrclk ( n8 - n1 -- )
: wrclk
\ ." ~h0Dwrclk: " base W@ hex st? base W!
	_st
	hBE
	wr8
	h8 0
	do
		wr8
	loop
	_end
;

\
\ bcd> ( n1 -- n2 ) convert bcd byte n1 to hex byte n2
[ifndef bcd>
: bcd>
	dup hF and
	swap hF0 and
	1 rshift dup
	h2 rshift + +
;
]

\
\ >bcd ( n1 -- n2 ) convert hex byte n1 to bcd byte n2
[ifndef >bcd
: >bcd
	hA u/mod h4 lshift +
;
]


\ rdlong ( addr -- n2 )
: rdlong

	0 swap 
	7 and 6 min 8 u* hC1 + 8 bounds
	_st
	do
		8 rshift i
		rd
		h18 lshift
		or
	2 +loop
	_end
;


\ wrlong ( n addr -- )
: wrlong
	7 and 6 min 8 u* hC0 + 8 bounds
	_st
	do
		dup hFF and i
		wr
		8 rshift
	2 +loop
	_end
	drop
;	

\ 0 - 1 - datestamp of ds1302 set
\ 2 - 3 - datestamp of ds1302 read
\ 4 	- ds1302 drift correction - ticks / hour
\ 5     - time drift correction - ticks / hour
\ 6     - spare long




\ _ds1302_write ( tlo thi -- )
: _ds1302_write
	ddup dow 1+ >r
	_t>ymdhms drop
\ 0 -1 y m d h m s
	5 ST@ d_2000 - >bcd 6 ST!
	4 ST@ >bcd 4 ST!
	3 ST@ >bcd 3 ST!
	2 ST@ >bcd 2 ST!
	1 ST@ >bcd 1 ST!
	>bcd
	r> 5 ST!
	wrclk
;
 

: _ds1302_setRTC
	wpoff
	0 -1

\ wait for a seconds transition
	0 0 
	begin
		ddrop
		_dgettime ddup clkfreq u>d du/mod ddrop drop
		clkfreq d_1000 u/ <
	until

	ddup
	0 wrlong 1 wrlong

	ddup dow 1+ >r
	_t>ymdhms drop
\ 0 -1 y m d h m s

	5 ST@ d_2000 - >bcd 6 ST!
	4 ST@ >bcd 4 ST!
	3 ST@ >bcd 3 ST!
	2 ST@ >bcd 2 ST!
	1 ST@ >bcd 1 ST!
	>bcd
	r> 5 ST!
	wrclk
	0 4 wrlong
	wpon
;

\ _ds1302_rawtime ( -- y M d h m s)
: _ds1302_rawtime
	rdclk
	drop nip
\ s m h d M y
	bcd> d_2000 +
	5 ST@ bcd> swap
\ s m h d M s y
	5 ST!
\ y m h d M s
	swap bcd> 4 ST@ bcd> swap
\ y m h d s m M
	4 ST! swap
\ y M h d m s
	rot bcd> 3 ST@ bcd> swap
\ y M h m s h d
	3 ST! rot2
\ y M d h m s
;



\ _ds1302_time ( -- tlo thi)
: _ds1302_time
\ loop until there is a seconds transition
	_ds1302_rawtime 0 0 0 0 0 0
	begin
		3drop 3drop
		_ds1302_rawtime
		6 ST@ over
		<>
	until
	>r >r >r >r >r >r
	3drop 3drop
	r> r> r> r> r> r>
\ the second should just have ticked
	ymdhms>t
	ddup
\ rtcraw rtcraw
	1 rdlong 0 rdlong
	d-
\ rtcraw elapsed
	4 rdlong i>d
\ rtc correction
	_dticks/hour dL@
	d*/
\ rtc correction
	d+
;

: _ds1302_setTimeFromRtc
	_ds1302_time
	ddup _dsettime
	wpoff
	2 wrlong 3 wrlong
	5 rdlong setDriftCorrection
	wpon
; 


: _ds1302_correctRTC
	_ds1302_time
	_dgettime
	dswap dtuck d-
	dswap 1 rdlong 0 rdlong
	d-
	_dticks/hour dL@ d/
	d/ drop
	4 rdlong +
	wpoff
	4 wrlong
	_dgettime 0 wrlong 1 wrlong
	wpon
;

\ _ds1302_correctLocalTime ( y m d h m s -- )
: _ds1302_correctLocalTime
	ymdhms>t _dTimeZoneOffset dL@ d-
	_dgettime
	dtuck d-
	dswap 3 rdlong 2 rdlong
	d-
	_dticks/hour dL@ d/
	d/
	_driftCorrectionNumerator dL@ 
	_dticks/hour dL@
	d- 
	d+
	drop
	wpoff
	dup 5 wrlong
	_dgettime 2 wrlong 3 wrlong
	wpon 
	setDriftCorrection
;


\ _ds1302_setLocalTime ( y m d h m s -- )
: _ds1302_setLocalTime
	ymdhms>t _dTimeZoneOffset dL@ d-
	ddup _dsettime
	wpoff
	2 wrlong 3 wrlong
	0 5 wrlong
	wpon 
;




: dmp
	base W@ hex
."    BCD encoded~h0D~h0D"

	rdclk
	8 0
	do
		hFF and .byte space
	loop
	cr cr

."    h81 ZXXXYYYY Z-hold      XXXYYYY   sec: " h81 rd .byte cr	
."    h83  XXXYYYY             XXXYYYY   min: " h83 rd .byte cr	
."    h85 ZXXXYYYY Z-1-12 0-24 XXXYYYY    hr: " h85 rd .byte cr	
."    h87   XXYYYY              XXYYYY   day: " h87 rd .byte cr	
."    h89    XYYYY               XYYYY month: " h89 rd .byte cr	
."    h8B      YYY                 YYY   dow: " h8B rd .byte cr	
."    h8D XXXXYYYY            XXXXYYYY  year: " h8D rd .byte cr	
."    h8F Z        Z-write protect          : " h8F rd .byte cr cr
."    h91 hAxyab x-1 diode y-2diode ab: 1-2kohm 2-4kohm 3 8kohm: " h91 rd .byte cr cr 	
	base W!
	1 rdlong 0 rdlong _t>ymdhms formatTime ."               DS1302 set/corrected: " .cstr cr
	3 rdlong 2 rdlong _t>ymdhms formatTime ."         TIME COUNTER set/corrected: " .cstr cr
	4 rdlong                               ."       DS1302 correction ticks/hour: " . cr
	5 rdlong                               ." TIME COUNTER correction ticks/hour: " . cr 
	6 rdlong                               ."                             long-6: " . cr


." _ds1302_rawtime: " _ds1302_rawtime 5 ST@ . 4 ST@ . 3 ST@ . 2 ST@ . over . dup . 0 formatTime .cstr cr cr

."    _ds1302_time: " _ds1302_time _t>ymdhms formatTime .cstr cr cr 


;

