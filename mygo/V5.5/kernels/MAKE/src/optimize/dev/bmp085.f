1 wconstant build_bmp085


[ifdef bmp_debug
wvariable bmp_debug 1 bmp_debug W!
]

[ifdef bmp_debug
: bmp_reset _sdah _sdao _sclh _sclo h10 0 do _scll _sclh loop _scli _sdai ;
]

\ 0 - 3
wvariable _bmpOss 3 _bmpOss W!

\ _bmps ( addr -- )
: _bmps
	_eestart hEE _eewrite swap _eewrite or
	if
		h44 ERR
	then
;

\ _bmpr ( addr -- )
: _bmpr
	_bmps _eestart hEF _eewrite
	if
		h45 ERR
	then
;

\ _bmpcrw ( c -- )
: _bmpcrw
	hF4 _bmps _eewrite _eestop
	if
		h46 ERR
	then
;

\ _bmpr16 ( addr -- u16)
: _bmpr16
	_bmpr 0 _eeread 8 lshift -1 _eeread or _eestop
;

\ _bmpr24 ( addr -- u24)
: _bmpr24
	_bmpr 0 _eeread 8 lshift 0 _eeread or 8 lshift -1 _eeread or _eestop
;

\ _bmprs16 ( addr -- n16)
: _bmprs16
	_bmpr16 dup h8000 and if hFFFF0000 or then
;

\ _bmpID ( -- chipid_version)
: _bmpID
	hD0 _bmpr16
;

: _bmpAC1
	hAA _bmprs16
;

: _bmpAC2
	hAC _bmprs16
;

: _bmpAC3
	hAE _bmprs16
;

: _bmpAC4
	hB0 _bmpr16
;

: _bmpAC5
	hB2 _bmpr16
;


: _bmpAC6
	hB4 _bmpr16
;

: _bmpB1
	hB6 _bmprs16
;

: _bmpB2
	hB8 _bmprs16
;

: _bmpMB
	hBA _bmprs16
;

: _bmpMC
	hBC _bmprs16
;

: _bmpMD
	hBE _bmprs16
;

[ifdef bmp_debug
: _bmpDump
	base W@ hex
	_bmpID dup
	."      Chip ID: 0x" 8 rshift . cr
	." Chip Version: 0x" hFF and . cr
	base W!
	."          AC1: " _bmpAC1 . cr
	."          AC2: " _bmpAC2 . cr
	."          AC3: " _bmpAC3 . cr
	."          AC4: " _bmpAC4 . cr
	."          AC5: " _bmpAC5 . cr
	."          AC6: " _bmpAC6 . cr
	."           B1: " _bmpB1 . cr
	."           B2: " _bmpB2 . cr
	."           MB: " _bmpMB . cr
	."           MC: " _bmpMC . cr
	."           MD: " _bmpMD . cr
;
] 

: _bmpUT
	h2E _bmpcrw d_5 delms hF6 _bmpr16
[ifdef bmp_debug
	bmp_debug W@
	if
		." UT: " st?
	then
]
;

: _bmpB5
\ X1 = (UT - AC6)* AC5/2exp15
	_bmpUT _bmpAC6 - _bmpAC5 h8000 */ dup
[ifdef bmp_debug
	bmp_debug W@
	if
		." X1: " st?
	then
]
\ X2 = MC * 2exp11 / (X1 + MD)
	_bmpMD + _bmpMC h800 rot */
[ifdef bmp_debug
	bmp_debug W@
	if
		." X2: " st?
	then
]
\ B5 = X1 + X2
	+
[ifdef bmp_debug
	bmp_debug W@
	if
		." B5: " st?
	then
]
;



: bmpTemp
	_bmpB5
	8 + h10 /
;


: _bmpUP
	h34 _bmpOss W@ 6 lshift + _bmpcrw
	_bmpOss W@ 0=
	if
		d_5
	else _bmpOss W@ 1 =
	if
		d_8
	else _bmpOss W@ 2 =
	if
		d_14
	else
		d_26
	thens
	delms 
	hF6 _bmpr24 8 _bmpOss W@ - rshift
[ifdef bmp_debug
	bmp_debug W@
	if
		." UP: " st?
	then
]
;

: bmpPressure
\ B6 = B5 - 4000
	_bmpB5 d_4000 -
[ifdef bmp_debug
	bmp_debug W@
	if
		." B6: " st?
	then
]
\ X1  = (B2 * (B6*B6/2exp12))/2exp11
	dup dup h_1000  */ dup  _bmpB2 h800 */
\ ( B6 B6*B6/2exp12 X1 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X1: " st?
	then
]
\ X2 = AC2*B6/2exp11
	2 ST@ _bmpAC2 h800 */
\ ( B6 B6*B6/2exp12 X1 X2 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X2: " st?
	then
]
\ X3 = X1 +x2
	+
\ ( B6 B6*B6/2exp12 X3 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X3: " st?
	then
]
\ B3 = ( ((AC1*4+X3)<<oss) +2) / 4
	_bmpAC1 4 * + _bmpOss W@ lshift 2+ 4 /
\ ( B6 B6*B6/2exp12 B3 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." B3: " st?
	then
]
\ X1 = AC3*B6/2exp13
	rot _bmpAC3 h2000 */
\ ( B6*B6/2exp12 B3 X1 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X1: " st?
	then
]
\ X2 = (B1 *(B6*B6/2exp12))/2exp16
	rot _bmpB1 h_10000 */
\ ( B3 X1 X2 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X2: " st?
	then
]
\ X3 = ((X1+X2)+2)/2exp2
	+ 2+ 4 /
\ (B3 X3 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X3: " st?
	then
]
\ B4 = AC4 * (ulong)(X3+32768) / 2exp15
	d_32_768 + _bmpAC4 h8000 */
\ (B3 B4 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." B4: " st?
	then
]
\ B7 = ((ulong)UP-B3)*(50000 >> oss)
	_bmpUP rot - d_50_000 _bmpOss W@ rshift *
\ ( B4 B7 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." B7: " st?
	then
]
\ if (B7 < 0x8000_0000) {
\	p = (B7*2)/B4
\ } else {
\	p = (B7/B4)*2
\ }
	dup h_8000_0000 and 0=
	if
		2* swap u/
	else
		swap u/ 2*
	then
\ ( p -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." p: " st?
	then
]
\ X1 = (p/2exp8)*(p/2exp8)
	dup h100 / dup *
\ ( p X1 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X1: " st?
	then
]
\ X1 = (X1 * 3038)/2exp16
	d_3038 h_1_0000 */
\ ( p X1 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X1: " st?
	then
]
\ X2 = (-7357*p)/2exp16
	over d-7357 h_1_0000 */
\ ( p X1 X2 -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." X2: " st?
	then
]
\ p = p + (X1 + X2 + 3791) / 	2exp4
	+ d_3791 + h10 / +
\ ( p -- )
[ifdef bmp_debug
	bmp_debug W@
	if
		." p: " st?
	then
]
;

