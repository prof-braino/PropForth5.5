\ overhead test
: speedtest1
	cnt COG@

 \ put word to be timed in here

	cnt COG@
	swap - . cr 
;


\ a looptest   \ for short items, subtract ovwerhead, about 120 H 288 decimal clock cycles (per speed test 1 )
: speedtest2
	cnt COG@
	100 0 do
		2000 0 do
		loop
	loop
	cnt COG@
	swap -  dup . ." total clocks" cr
	100 u/ 2000 u/ . ." per loop" cr
;
