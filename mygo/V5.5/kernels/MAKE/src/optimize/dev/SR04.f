1 wconstant build_sr04
[ifndef _sr04_trig
	d_22 wconstant _sr04_trig
]
[ifndef _sr04_echo
	d_23 wconstant _sr04_echo
]

variable _sr04_distance

: _sr04_measure
	c" MEASURE" cds W!
	4 state andnC!

	_sr04_trig pinlo _sr04_trig pinout
	_sr04_echo >m
	_sr04_trig >m
	begin
		dup _maskouthi dup dup drop _maskoutlo

		over dup dup dup

		waitpeq
		cnt COG@
		rot2

		waitpne
		cnt COG@ swap -
		d_170_000 clkfreq */


		_sr04_distance L!
		
		100 delms
	0 until
;

[ifdef sr04_test
: sr04_test
	begin
		_sr04_distance L@ . cr
		fkey? nip
	until
;
]

c" _sr04_measure" 0 cogx


