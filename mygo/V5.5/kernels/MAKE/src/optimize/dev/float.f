fl
hex


1 wconstant build_float
\
\
\ In this implementation -0 is not returned from or considerd by routines, 0 is,
\ -inf (FF80 0000)and +inf (7F80 0000) and nan (7FC0 0000) are specific values 
\ caution if importing hex data from somewhere else
\
\ converting floats to integers, -7FFFFF80 - 7FFFFF80 is the range of integer values returned,
\ if values are greater or less they are returned as -80000000 or 7FFFFFFF, nan is returned as 0
\
\ unnormalized values are not dealt with, if the exponent is < 1 (x*2^-126) the value is considered to be 0
\
\ the dynamic range of the mantissa is 24 bits, so addition or subtraction of two numbers which differ 
\ by more than 24 (0x18) in the exponent is a nop
\
\ Original ref for IEEE754 float notation
\
\ http://www.psc.edu/general/software/packages/ieee/ieee.php
\
\ The IEEE single precision floating point standard representation requires a 32 bit word, which may
\ be represented as numbered from 31 to 0, left to right. The first bit is the sign bit, S, 
\ the next eight bits are the exponent bits, 'E', and the final  23 bits are the fraction 'F':
\
\  S  EEEEEEEE  FFFFFFFFFFFFFFFFFFFFFFF
\  31 30     23 22                    0
\
\ The value V represented by the word may be determined as follows:
\
\    * If E=255 and F is nonzero, then V=NaN ("Not a number")
\    * If E=255 and F is zero and S is 1, then V=-Infinity
\    * If E=255 and F is zero and S is 0, then V=Infinity
\    * If 0<E<255 then V=(-1)**S * 2 ** (E-127) * (1.F) where "1.F" is intended to represent the binary
\                          number created by prefixing F with an implicit leading 1 and a binary point.
\    * If E=0 and F is nonzero, then V=(-1)**S * 2 ** (-126) * (0.F) These are "unnormalized" values.
\    * If E=0 and F is zero and S is 1, then V=-0
\    * If E=0 and F is zero and S is 0, then V=0 
\
\ In particular,
\
\  0 00000000 00000000000000000000000 = 0
\  1 00000000 00000000000000000000000 = -0
\
\  0 11111111 00000000000000000000000 = Infinity
\  1 11111111 00000000000000000000000 = -Infinity
\
\  0 11111111 00000100000000000000000 = NaN
\  1 11111111 00100010001001010101010 = NaN

\  0 10000000 00000000000000000000000 = +1 * 2**(128-127) * 1.0 = 2
\  0 10000001 10100000000000000000000 = +1 * 2**(129-127) * 1.101 = 6.5
\  1 10000001 10100000000000000000000 = -1 * 2**(129-127) * 1.101 = -6.5
\
\  0 00000001 00000000000000000000000 = +1 * 2**(1-127) * 1.0 = 2**(-126)
\  0 00000000 10000000000000000000000 = +1 * 2**(-126) * 0.1 = 2**(-127) 
\  0 00000000 00000000000000000000001 = +1 * 2**(-126) * 
\                                       0.00000000000000000000001 = 
\                                       2**(-149)  (Smallest positive value)
\
h80000000 dup constant _Fsmask constant _Fmsb
h7F800000 dup constant _Femask constant +inf
h00800000 constant _Ffhibit
h007FFFFF constant _Ffmask
hFF800000 constant -inf
h7FC00000 constant nan
h7FFFFFFF constant maxInt
h80000000 constant minInt
h7F07FFFF constant max+Float
h00800000 constant min+Float
h3F800000 constant _fd1
h41200000 constant _fde1
h3DCCCCCD constant _fde-1
h447A0000 constant _fde3
h4B189680 constant _fde7
\
\ rashift ( n1 n2 -- n3) \ n3 = n1 shifted right arithmetically n2 bits
[ifndef rashift
: rashift _xasm2>1 h077 _cnip ;
]
\ rev ( n1 n2 -- n3 ) n3 is n1 with the lower 32-n2 bits reversed and the upper bite cleared
[ifndef rev
: rev
	_xasm2>1 h079 _cnip
;
]
\ cappendc ( c1 cstr -- ) append c1 the cstr
[ifndef cappendc
: cappendc
	dup C@ 1+ over C! dup C@ + C!
;
]
\
\
\ fabs ( f1 -- f2 ) f2 is the absolute value of f1
: fabs
	_Fsmask invert and
;
\
\ _Fhb ( u1 -- u1 u2 ) u2 is the most significant bit set in n1 - 20 is the most significant bit 1 is the lsb (0 - no bit set)
: _Fhb
	_Fmsb h20 0
	do
		2dup and
		if
			drop h20 i - leave
		else
			1 rshift
		then
	loop
;
\
\ _Fu>me ( u1 -- u2 u3 ) unsigned u1 is converted to mantissa and exponent, 
\        u2 is the fraction with the leading 1 in bit 24 (mantissa) u3 is the exponent
: _Fu>me
	dup 0=
	if
		0
	else
		_Fhb h18 - swap over dup 0>
		if
			rshift
		else
			negate lshift
		then
		swap h96 +
	then
;
\
\ u>f ( u1 -- f1 ) convert unsigned u1 to float f1
: u>f
	_Fu>me h17 lshift swap _Ffmask and or
;
\
\ i>f ( n1 -- f1 ) convert interger n1 to float f1
: i>f
	dup 0<>
	if
		dup 0>
		if
			0
		else
			negate _Fsmask
		then
		swap u>f or
	then
;
\
maxInt i>f constant fmaxInt
minInt i>f constant fminInt
\
\ _Ff>m ( f1 -- f1 u1 ) u1 is the mantissa - the fraction with the hi bit set
: _Ff>m
	dup 0=
	if
		0
	else
		dup _Ffmask and _Ffhibit or
	then
;
\
\ _Ff>e ( f1 -- f1 u1 ) u1 exponent
: _Ff>e
	dup h17 rshift hFF and
;
\
\ _Ff>me ( f1 -- n2 n3 ) f1 is a float n2 is the mantissa, n3 is the exponent
: _Ff>me
	_Ff>m swap _Ff>e nip
;
\
\ _Ff>sm ( f1 -- f1 n2 ) f1 is a float n2 is the signed mantissa
: _Ff>sm
	_Ff>m over _Fsmask and
	if
		negate
	then
;
\
\ f> ( f1 f2 -- t/f )  true if f1 > f2 
: f>
\ process the edge stuff
	dup -inf = if  -1 else
	dup +inf = if 0 else
	dup nan = if 0 else
	over -inf = if 0 else
	over +inf = if -1 else
	over nan = if 0 else
\ otherwise normal process
		dup _Fsmask and rot dup
		_Fsmask and rot 2dup xor
		if
			>
		else
			and 0=
			if
				swap
			then
			_Ff>me rot _Ff>me rot 2dup >
			if
				2drop -1
			else
				=
				if
					2dup swap >
				else
					0
	 thens
	 nip nip
;
\
\ f>i ( f1 -- n1 ) convert float f1 to int n1, +inf > 7FFFFFFF -inf > 80000000 nan > 0,
\ 7FFFFF80 is the largest int normally returned and -7FFFFF80 is the minimum int normally returned (rounding) 
: f>i 
\ process the standard edge stuff
	dup -inf = if drop minInt else
	dup +inf = if drop maxInt else
	dup nan = if drop 0 else
	_fd1 over fabs f> if drop 0 else
\ otherwise normal process
		dup _Fsmask and
			if
				fminInt over f>
				if
					drop 0
				then
			else
				dup fmaxInt >
				if
					drop fmaxInt
				then
			then
			dup _Ff>me h96 - dup 0>
			if
				lshift
			else
				negate rshift
			then
			swap _Fsmask and
			if
				negate
	thens
;
\
\ f+ ( f1 f2 -- f3) f3 is f1 + f2
: f+
\ process edge cases
	dup nan = if 2drop nan else
	over nan = if 2drop nan else
	dup -inf = if 2drop -inf else
	dup +inf = if 2drop +inf else
	over -inf = if 2drop -inf else
	over +inf = if 2drop +inf else
\ process cases where one number is a lot larger thus the addition is a nop
		_Ff>e rot _Ff>e rot 2dup - 
		dup h17 >
		if
			3drop nip
		else
			dup h-17 <
			if
				3drop drop
			else
\ f2 f1 e1 e2 e1-e2
				dup 0<
				if
					negate swap >r nip
				else
					rot >r nip rot2 swap rot
				then
\
\  fx fy n1 - fx is the larger float, fy the smaller float, n1 the exponent  difference, top of rs is the larger exponent
\
				swap _Ff>sm nip swap rashift swap _Ff>sm nip +
\
\ n1 - the signed sum, e1 is on rs - the larger of the exponents
\
				dup 0=
				if
					r> drop
				else
\ 97 - r> 7F - + 80 +
					i>f _Ff>e h96 - r> +
					dup hFE >
					if
						drop _Fsmask and +inf or
					else
						dup 1 <
						if
							2drop 0
						else
							h17 lshift swap _Femask invert and or
	thens
;
\
\ f- ( f1 f2 -- f3 ) f3 is f1 - f2
: f-
	_Fmsb xor f+
;
\
\ _f1 ( f1 f2 -- (80000000 | 0) m2 e2 m1 e1 ) whether the result will be positive or negative, and unpack the floats
: _f1
	2dup xor _Fmsb and rot2 _Ff>me rot _Ff>me
;
\
\ f* ( f1 f2 -- f3 ) f3 is f1 *f2
: f*
\ process edge cases
	dup nan = if 2drop nan else
	over nan = if 2drop nan else
	dup -inf = if drop dup 0= if drop nan else _Fsmask and -inf xor then else
	dup +inf = if drop dup 0= if drop nan else _Fsmask and +inf xor then else
	over -inf = if nip dup 0= if drop nan else _Fsmask and -inf xor then else
	over +inf = if nip dup 0= if drop nan else _Fsmask and +inf xor then else
	dup 0= if 2drop 0 else
	over 0= if 2drop 0 else
\ process normal
		_f1 rot + h7F -
			dup hFE >
			if
				3drop _Fsmask and +inf or
			else
				dup 0<
				if
					2drop 2drop 0
				else
					>r um* h8 lshift swap h800000 + h18 rshift or
					dup 0=
					if
						r> 3drop 0
					else
						i>f _Ff>e h95 - r> + h17 lshift swap _Femask invert and or or
	thens
;
\
\ f/ ( f1 f2 -- f3 ) f3 is f1 / f2
: f/ 
\ process edge cases
	dup nan = if 2drop nan else
	over nan = if 2drop nan else
	2dup or 0= if 2drop nan else
	over 0= if drop else
	dup 0= if drop _Fsmask and +inf xor else
\ process normal
		_f1 rot - h7F + 
		dup 1 < if 2drop 2drop 0 else
		>r h8 lshift over u/mod h10 lshift rot2
		h8 lshift over u/mod h8 lshift rot2
		h8 lshift over u/mod swap _Ffmask >
		if
			1
		else
			0
		then
		+ nip + + i>f
		_Ff>e h97 swap - r> swap  - h17 lshift swap _Femask invert and or or
	thens
;
\
\ loMask ( n1 -- n2 ) n2 is the mask of the lo bits up to the right of bit n2
: loMask
	-1 h20 rot dup 1 <
	if
		3drop 0
	else
		dup h20 >
		if
			3drop -1
		else
			- rev
	thens
;
\
: hiMask
	loMask invert
;
\
\ _Ff>int ( f1 -- f1 f2 ) f2 is the integer portion of f1
: _Ff>int
	_Ff>e h96 swap - dup h17 >
	if
		drop 0
	else
		hiMask over and
	then
;
\
\ _Ff>frac ( f1 -- f1 f2 ) f2 is the fractional portion of f1
: _Ff>frac
	_Ff>e h96 swap - dup h17 >
	if
		drop dup
	else
		2dup loMask 2dup and 
		if
			and i>f _Ff>e rot - 
			h17 lshift swap _Femask invert and or
		else
			3drop 0
		then
	then
;
\
\ _f>cstr ( f1 -- ) converts f1 to a counted string in t
: _f>cstr
\ process the standard edge stuff
	tbuf h12 h30 fill hB tbuf C!
	dup -inf = if drop c" -inf" tbuf ccopy else
	dup +inf = if drop c" +inf" tbuf ccopy  else
	dup nan = if drop c" nan" tbuf ccopy else
		base W@ decimal
		tbuf hB h30 fill
		1 tbuf C! swap dup _Fsmask and
		if
			h2D
		else
			h20
		then
		tbuf 1+ C! 
		fabs _Ff>int f>i <# #s #> tbuf cappend h2E tbuf cappendc
		_Ff>frac nip fabs _fde7 f* f>i <# #s #> 
		h7 over C@ - tbuf C@ + tbuf C!
		tbuf cappend
		base W!
	thens
;
\
\ f>cstr ( f1 -- caddr ) converts f1 to a counted string, caddr is the pointer to the counted string (16 digits + 1 space)
: f>cstr
	_f>cstr h10 tbuf C! h20 tbuf cappendc tbuf
;
\
\ f. ( f1 -- ) emits f1 followed by a space
: f.
	f>cstr .cstr
;
\
\ : f2/  dup nan <> if dup 0<> if dup +inf <> if dup -inf <> if
\ _Ff>e 1- dup 1 < if 2drop 0 else 17 lshift swap _Femask invert and or thens ;
\
\ : f2*  dup nan <> if dup 0<> if dup +inf <> if dup -inf <> if
\ _Ff>e 1+ dup FE > if drop _Fsmask and +inf or else 17 lshift swap _Femask invert and or thens ;
\
\ g>cstr ( f1 -- caddr ) converts f1 to a counted string in engineering notation,
\	caddr is the pointer to the counted string (16 digits + 1 space)
: g>cstr 
	dup 0= over -inf = or over +inf = or over nan = or
	if
		f>cstr
	else
		0 swap dup fabs _fde3 f>
		if
			begin
				swap 3 + swap _fde3 f/ _fde3 over fabs f>
			until
		else
			_fd1 over fabs f>
			if
				begin
					swap 3 - swap _fde3 f* dup fabs _fd1 f>
				until
		then
	then 	
		_f>cstr hB tbuf C! h65 tbuf cappendc 
		dup 0<
		if
			negate h2D
		else
			h2B
		then
			tbuf cappendc
			base W@ decimal swap <# # # # #> tbuf cappend base W!
			h20 tbuf cappendc tbuf
		then
;
\
\ g. ( f1 -- ) emits f1 in engineering notation followed by a space
: g.
	g>cstr .cstr
;
\
\ parseCstr ( cstr1 c1 -- cstr2 cstr3 ) parse the word delimited by c1, or the end of cstr1 is reached,
\ cstr2 is the remaining string or 0 cstr3 is the parsed word, the original cstr1 is modified if cstr2 is not 0
: parseCstr
	over 0 rot2 dup C@++ bounds 
	do
		over i C@ =
		if
			rot drop dup rot2 i ibound over - 1-
			over C! over - 1- over C! C@++ +
			rot2
		then
	loop
	2drop swap
;
\
\ parseFloat ( cstr --  cstr1 cstr2 cstr3 ) cstr1 is the exponent, cstr2 in the fratcional part, cstr1 is the integer part
: parseFloat
	tbuf ccopy tbuf h2E parseCstr swap dup 0=
	if
		drop c" NO" dup
	else
		dup C@ 0=
		if
			drop c" 0" dup
		else
			h65 parseCstr swap dup 0=
			if
				drop c" 0"
			then
			dup C@ 0=
			if
				drop c" 0"
			then
			swap
		then
		
	then
	rot
;
\
\ isFloat ( cstr -- t/f )
: isFloat
	parseFloat C@++ isnumber rot C@++ isnumber rot C@++ isnumber and and
;
\
\ int>frac ( n1 -- f2 ) divide f1 by decimal 10 until it is a fraction
: int>frac
	dup 0< swap abs i>f
	begin
		_fd1 over f>
		if
			-1
		else
			_fde1  f/ 0
		then
	until
	swap
	if
		_Fsmask or
	then
;
\
\ cstr>float ( cstr -- f1 )
: cstr>float 
	dup isFloat
	if
		parseFloat
		over >r
		C@++ number rot C@++ number rot C@++ number rot
		dup 0<
		if
			swap negate swap
		then
		i>f swap
		int>frac
		r>
		C@++ bounds
		do
			i C@ h30 <>
			if
				leave
			else
				_fde1 f/	
			then
		loop
		f+
		swap dup 0=
		if
			drop
		else
			dup 0>
			if
				_fde1
			else
				_fde-1
			then
			swap abs _fd1 swap 0
			do
				over f*
			loop
			nip f*
		 then 
	else
		drop nan
	then
;
\
h3FC90FD9 constant pi/2
h40490FDA constant pi
h4096CBE3 constant 3pi/2
h40C90FDA constant 2pi
\
\ scpi ( f1 -- f2 ) f1 radians, f2 is a radian value from -pi to pi
: scpi
	2pi f/ _Ff>frac 2pi f* swap _Fsmask and
	if
		_Fsmask or 2pi swap f+
	then
	dup pi f> 
	if
		2pi swap f- _Fsmask or
	then
;
\
\ _flu ( n1 f1 f2 -- f3) n1 is the base address of a 2k word table, f1 is a value between 0.0 and 1.0
\ f2 is the interpolated float value from the table between 0.0 and 1.0
: _flu
	f* _Ff>int f>i swap _Ff>frac nip swap
\ sin table which is longer is ok with this no bug
	dup h7FE >
	if
		2drop hFFE + W@ i>f
	else
		2* rot + dup W@ swap 2+ W@ over - i>f rot f* swap i>f f+
	then
\ 65535.0 f/
	h477FFF00 f/
;
\
\ sin ( f1 -- f2 ) f1 in radians, f2 is the sin from -1.0 to +1.0
: sin
\ process the edge stuff
	dup +inf = -inf over = or over nan = or
	if
		drop nan
	else
\ normal processing
		scpi dup _Fsmask and swap fabs dup pi/2 f>
		if
			pi/2 f- pi/2 swap f-
		then
\ e000 swap pi/2 f/ 2049.0 _flu or then ;
		hE000 swap pi/2 f/ h45001000 _flu or
	then
;
\
\ cos ( f1 -- f2 ) f1 in radians, f2 is the cos from -1.0 to +1.0
: cos
	pi/2 f+ sin
;
\
\ tan ( f1 -- f2 ) f1 in radians, f2 is the tan from -1.0 to +1.0
: tan
	dup sin swap cos f/
;
\
\ : d>r 17.4532909e-003 f* ;
: d>r
	h3C8EFA34 f*
;
\ : r>d 57.2957878 f* ; 
: r>d
	h42652EE3 f*
; 
\
\ log2 ( f1 -- f2) f2 is the base2 log of f1
: log2
\ process the edge stuff
	dup _Fsmask and over 0= or
	if
		drop nan
	else
		dup +inf =
		if
			drop +inf
		else
\ normal processing
\ _Ff>me 7F - i>f C000 rot _Ffmask and i>f 0x00800000 f/ 2048.0_flu f+ thens ;
			_Ff>me
			h7F -
			i>f
			hC000 rot
			_Ffmask and
			i>f
			h4B000000 f/ h45000000
			_flu
			f+
	thens
;
\
\ exp2 ( f1 -- f2) f2 is 2 to the power of f1
: exp2
\ process the edge stuff
	dup -inf = over 0= or if drop _fd1 else
	dup nan = if drop nan else
	dup +inf = if drop +inf else
\ normal processing
		dup _Fsmask and swap fabs
\ _Ff>int f>i 1 swap lshift i>f D000 rot _Ff>frac nip 2048.0 _flu _fd1 f+ f* thens ;
		_Ff>int
		f>i
		1 swap lshift
		i>f
		hD000 rot
		_Ff>frac nip
		h45000000
		_flu
		_fd1 f+
		f*
		swap
		if
			_fd1 swap f/
		
	thens
; 
\
\ log10 ( f1 -- f2) f2 is the base10 log of f1
\ : log10 log2 0.301029996 f* ;
: log10
	log2 h3E9A2098 f*
;
\
\ ln ( f1 -- f2) f2 is the base10 log of f1
\ : ln log2 0.693147181 f* ;
: ln
	log2 h3F317214 f*
;
\
\ exp10 ( f1 -- f2) f2 is 10 to the power of f1
\ : exp10 3.321928095 f* exp2 ;
: exp10
	h40549A77 f* exp2
;
\
\ exp ( f1 -- f2) f2 is e to the power of f1 
\ : exp 1.442695041 f* exp2 ;
: exp
	h3FB8AA3A f* exp2
;
\
\ 123.8 123.8e9 123.8e-9 are valid floats
\
\ patch the adresses in interpretpad to call isfnumber and fnumber instead of isnumber and number
' fisnumber
: fisnumber over swap xisnumber if drop -1 else 1- isFloat then ;
' fisnumber swap W!
\
' fnumber
: fnumber over swap xisnumber if 1- C@++ xnumber else 1- cstr>float then ;
' fnumber swap W!
decimal
\


{

: t
	i>f
dup g.
	101325.0 f/
dup g.
	log2
dup g.
	5.255 f/
dup g.
	exp2
dup g.
	1.0 swap -
dup g.
	443300.0 f*
dup g. cr
;
}





{

fl
hex
forget build_floatTest
1 wconstant build_floatTest

: _T00 i>f swap i>f f+ f>i = ;
: _T0 >r 2dup 0 RS@ _T00 rot2 r> _T00 and and ;
: _T10 i>f f+ = ;
: _T1 >r 2dup 0 RS@ _T10 rot2 r> _T10 and and ;

: TEST_f+
-1
7FFFFF8 7FFFFFF 1 _T0 
7FFFFF8 7FFFFFF 2 _T0
7FFFFF8 7FFFFFF 4 _T0
8000000 7FFFFFF 8 _T0
7FFFFF8 7FFFFFF -1 _T0
7FFFFF8 7FFFFFF -2 _T0
7FFFFF8 7FFFFFF -4 _T0
7FFFFF0 7FFFFFF -8 _T0
0 AAAAA -AAAAA _T0
1 1001 -1000 _T0
-1 1000 -1001 _T0
A 1234A -12340 _T0
nan nan 0 _T1
nan nan 10 _T1
nan nan -10 _T1
-inf -inf 0 _T1
-inf -inf 10 _T1
-inf -inf -10 _T1
+inf +inf 0 _T1
+inf +inf 10 _T1
+inf +inf -10 _T1
+inf 7F07FFFF 7F07FFFF f+ = and
+inf 7F07FFFF 7F040000 f+ = and
-inf FF07FFFF FF07FFFF f+ = and
-inf FF07FFFF FF400000 f+ = and
;



: TEST_Fu>me
0        _Fu>me 0= swap 0= and
1        _Fu>me 7F = swap 800000 = and and
2        _Fu>me 80 = swap 800000 = and and
4        _Fu>me 81 = swap 800000 = and and
8        _Fu>me 82 = swap 800000 = and and
A        _Fu>me 82 = swap A00000 = and and
00000064 _Fu>me 85 = swap C80000 = and and
000003E8 _Fu>me 88 = swap FA0000 = and and
00002710 _Fu>me 8C = swap 9C4000 = and and
000186A0 _Fu>me 8F = swap C35000 = and and
000F4240 _Fu>me 92 = swap F42400 = and and
00989680 _Fu>me 96 = swap 989680 = and and
05F5E100 _Fu>me 99 = swap BEBC20 = and and
3B9ACA00 _Fu>me 9C = swap EE6B28 = and and
FFFFFFFF _Fu>me 9E = swap FFFFFF = and and
80000000 _Fu>me 9E = swap 800000 = and and
40000000 _Fu>me 9D = swap 800000 = and and
01000000 _Fu>me 97 = swap 800000 = and and
00800000 _Fu>me 96 = swap 800000 = and and
00400000 _Fu>me 95 = swap 800000 = and and
00200000 _Fu>me 94 = swap 800000 = and and ;

: TEST_Fhb 0 _Fhb 0= nip
1 _Fhb 1 = nip and
2 _Fhb 2 = nip and
4 _Fhb 3 = nip and
7 _Fhb 3 = nip and
60000000 _Fhb 1f = nip and 
80000000 _Fhb 20 = nip and ;

: TEST_FAILED 0 ;

: TEST_i>f
00000000 i>f  00000000 =
00000001 i>f  3F800000 = and
0000000A i>f  41200000 = and
00000064 i>f  42C80000 = and
000003E8 i>f  447A0000 = and
00002710 i>f  461C4000 = and
000186A0 i>f  47C35000 = and
000F4240 i>f  49742400 = and
00989680 i>f  4B189680 = and
05F5E100 i>f  4CBEBC20 = and
3B9ACA00 i>f  4E6E6B28 = and
FFFFFFFF i>f  BF800000 = and
FFFFFFF6 i>f  C1200000 = and
FFFFFF9C i>f  C2C80000 = and
FFFFFC18 i>f  C47A0000 = and
FFFFD8F0 i>f  C61C4000 = and
FFFE7960 i>f  C7C35000 = and
FFF0BDC0 i>f  C9742400 = and
FF676980 i>f  CB189680 = and
FA0A1F00 i>f  CCBEBC20 = and
C4653600 i>f  CE6E6B28 = and
;


: _T2 dup i>f _Ff>me rot _Fu>me rot = rot2 = and ; 
: TEST_Ff>me
00000000 _T2
00000001 _T2 and
0000000A _T2 and
00000064 _T2 and
000003E8 _T2 and
00002710 _T2 and
000186A0 _T2 and
000F4240 _T2 and
00989680 _T2 and
00F5E100 _T2 and
00FFFFFF _T2 and
;


: TEST_f>
nan	0	f> 0=
0	nan	f> 0= and
+inf	0	f> and
-inf	0	f> 0= and
+inf	10 i>f	f> and
-inf	10 i>f	f> 0= and
10 i>f	-inf	f> and
10 i>f	+inf	f> 0= and
1 i>f	0	f> and 
0 i>f	1 i>f	f> 0= and
-1 i>f	0 	f> 0= and
-1 i>f	-inf	f> and
-1 i>f	-2 i>f	f> and
10 i>f	-2 i>f	f> and
FFFFFF i>f FFFFFE i>f f> and
FFFFFE i>f FFFFFF i>f f> 0= and
FFFFFF i>f 0FFFFE i>f f> and
0FFFFE i>f FFFFFF i>f f> 0= and

-FFFFFF i>f -FFFFFE i>f f> 0= and
-FFFFFE i>f -FFFFFF i>f f> and
-FFFFFF i>f -0FFFFE i>f f> 0= and
-0FFFFE i>f -FFFFFF i>f f> and
;


: TEST_f>i
-inf		f>i	80000000	=
+inf		f>i	7fffffff	= and
nan		f>i	0		= and

1	 i>f	f>i	1		= and
-1	 i>f	f>i	-1		= and
A	 i>f	f>i	A		= and
-A	 i>f	f>i	-A		= and
DC56	 i>f	f>i	DC56		= and
-DC56	 i>f	f>i	-DC56		= and
007FFFFF i>f	f>i	007FFFFF	= and
-007FFFFF i>f	f>i	-007FFFFF	= and

7FFFFFFF i>f	f>i	7FFFFF80	= and
-7FFFFFFF i>f	f>i	-7FFFFF80	= and

;

: _T30 i>f swap i>f f* f>i = ;
: _T3 >r 2dup 0 RS@ _T30 rot2 r> _T30 and and ;
: _T40 i>f f* = ;
: _T4 >r 2dup 0 RS@ _T40 rot2 r> _T40 and and ;
: _T5 >r 2dup 0 RS@ f* = rot2 r> f* = and and ;

: TEST_f*
-1
0 0 0 _T4 
nan +inf 0 _T5
nan -inf 0 _T5
+inf +inf +inf _T5
-inf -inf +inf _T5
+inf -inf -inf _T5

nan nan 10 _T4
nan nan 1 _T4
nan nan -10 _T4
nan nan -1 _T4
nan nan 0 _T5

+inf +inf 10 _T4
-inf -inf 10 _T4
+inf -inf -10 _T4
+inf -inf -10 _T4
6 2 3 _T3
-6 -2 3 _T3
4edc2 123 456 _T3
-4edc2 123 -456 _T3
64 A A _T3 
3E8 64 A _T3 
2710 64 64 _T3 
F4240 3E8 3E8 _T3
5F5E100 2710 2710 _T3
;

: _T6 i>f swap i>f swap f/ f>i = and ;
: _T7 swap i>f swap f/ = and ;
: _T8 f/ = and ;

: TEST_f/
-1
nan 0 0 _T8
nan 0 nan _T8
nan nan 0 _T8

0 0 +inf _T8
0 0 -inf _T8
+inf 1 0 _T7
+inf 10 0 _T7
-inf -1 0 _T7
-inf -10 0 _T7



FF 7FFFFFFF 00800000 _T6
40 40000000 00FFFFFF _T6
1 i>f dup a i>f f/ a i>f f* = and 
FF i>f 800000 i>f f/ 800000 i>f f* f>i FF = and
;


: RUNTEST dup find if execute swap .cstr if ."  PASSED" else ."  ********************FAILED" then 
else .cstr ."  ********************NOT FOUND" drop then cr ;

: TEST c" TEST_Fhb" RUNTEST c" TEST_Fu>me" RUNTEST c" TEST_i>f" RUNTEST
c" TEST_Ff>me" RUNTEST c" TEST_f>" RUNTEST c" TEST_f>i" RUNTEST c" TEST_f+" RUNTEST
c" TEST_f*" RUNTEST c" TEST_f/" RUNTEST 
c" TEST_FAILED" RUNTEST
c" TEST_NAN" RUNTEST ;


}


