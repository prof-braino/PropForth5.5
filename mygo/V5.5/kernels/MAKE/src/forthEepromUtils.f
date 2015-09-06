1 wconstant build_EepromUtils

c" EEpromUtils Loading 1 " .cstr

{

Read Timing

pin 28 - SDA
pin 29 - SCL


    Trigger Pin      -q    +Q: 26
   Trigger Edge   -w +W SPACE: __x0--
Trigger Frequency         eE :             891
Sample Interval -asdfg +ASDFG: 500.0 nS             40 clock cycles
         Sample     <ENTER>
         Quit         <ESC>
Sample Display  -zxcv  +ZXCV :             277 clock cycles of           2,693
                 |               |               |               |               |               |               |               |
         149.9 uS|       157.9 uS|       165.9 uS|       173.9 uS|       181.9 uS|       189.9 uS|       197.9 uS|       205.9 uS|
                 |               |               |               |               |               |               |               |
31--------------------------------------------------------------------------------------------------------------------------------
30--------------------------------------------------------------------------------------------------------------------------------
29___________________________------------___________------------______-_________________________________________-----------------_
28________________________---___--___---___---___---___---___---___--____--__________________________________--___---___---___---_
                        |     |    |     |     |     |     |     |     |
                        |     |    |     |     |     |     |     |     |
                        |D7rd |D6rd|D5rd |D4rd |D3rd |D2rd |D1rd |D0rd |ACKwrite


Write Timing

pin 28 - SDA
pin 29 - SCL


    Trigger Pin      -q    +Q: 27
   Trigger Edge   -w +W SPACE: __x0--
Trigger Frequency         eE :             891
Sample Interval -asdfg +ASDFG: 500.0 nS             40 clock cycles
         Sample     <ENTER>
         Quit         <ESC>
Sample Display  -zxcv  +ZXCV :             277 clock cycles of           2,693
                 |               |               |               |               |               |               |               |
         149.9 uS|       157.9 uS|       165.9 uS|       173.9 uS|       181.9 uS|       189.9 uS|       197.9 uS|       205.9 uS|
                 |               |               |               |               |               |               |               |
31--------------------------------------------------------------------------------------------------------------------------------
30--------------------------------------------------------------------------------------------------------------------------------
29----_________________________________________------______------___________________________________-_________________________----
28-----------____________________________________---___---___---___--____--___---___---___---___---_____________________________--
      |                                        |     |    |     |     |     |     |     |     |
      |eestart                                 |     |    |     |     |     |     |     |     |
                                               |D7wr |D6wr |D5wr |D4wr|D3wr |D2wr |D1wr |D0wr |ACKrd

}
2 .
{
\
_bbo
\
\
\ _eeread ( t/f -- c1 ) flag should be true is this is the last read
\
:asm
		jmp	# __x0C
__x02sda
		h20000000
__x03scl
		h10000000
__x04delay/2
		hD
\ this delay makes for a 400kHZ clock on an 80 Mhz prop
\
__x0Edelay/2
		mov	$C_treg6 , __x04delay/2
__x0D
		djnz	$C_treg6 , # __x0D
__x0Fdelayret
		ret
\
__x0C
		mov	$C_treg1 , $C_stTOS 
		mov	$C_stTOS , # 0
		andn	dira , __x02sda
		mov	$C_treg3 , # h8
\		
__x0B
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		test	__x02sda , ina	wc
		rcl	$C_stTOS , # 1
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		djnz	$C_treg3 , # __x0B
\
		cmp	$C_treg1 , # 0 wz
		muxnz	outa , __x02sda
		or	dira , __x02sda
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
		andn	outa , __x02sda
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		jexit
\
;asm _eeread
\
_bbo
\
\
\
\ _eewrite ( c1 -- t/f ) write c1 to the eeprom, true if there was an error
\
\
:asm
		jmp	# __x0C
__x02sda
		h20000000
__x03scl
		h10000000
__x04delay/2
		hD
\ this delay makes for a 400kHZ clock on an 80 Mhz prop
\
__x0Edelay/2
		mov	$C_treg6 , __x04delay/2
__x0D
		djnz	$C_treg6 , # __x0D
__x0Fdelayret
		ret
\
__x0C
		mov	$C_treg3 , # h8
\		
__x0B
		test	$C_stTOS , # h80	wz
		muxnz	outa , __x02sda
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
		shl	$C_stTOS , # 1
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		djnz	$C_treg3 , # __x0B
\
		andn	dira , __x02sda
		test	__x02sda , ina	wz
		muxnz	$C_stTOS , $C_fLongMask
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		or	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		jmpret	__x0Fdelayret , # __x0Edelay/2
\
		andn	outa , __x03scl
\
		jmpret	__x0Fdelayret , # __x0Edelay/2
		andn	outa , __x02sda
		or	dira , __x02sda
\
\
		jexit
\
;asm _eewrite
}
3 .
[ifndef _eeread
lockdict create _eeread forthentry
$C_a_lxasm w, h132  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV04Q l, zW0000 l, zG0000 l, zD l, z2WiQCM l, z3[yQCO l, z1SV000 l, z2WiPZB l,
z2WyPO0 l, z1[ixnK l, z2WyPj8 l, z1SyZCN l, z1XFYal l, znyPO1 l, z1bix[L l, z1SyZCN l,
z1SyZCN l, z1[ix[L l, z1SyZCN l, z3[yPnU l, z26VPW0 l, z1vix[K l, z1bixnK l, z1SyZCN l,
z1bix[L l, z1SyZCN l, z1SyZCN l, z1[ix[L l, z1[ix[K l, z1SyZCN l, z1SV01X l,
freedict
]

[ifndef _eewrite
lockdict create _eewrite forthentry
$C_a_lxasm w, h131  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV04Q l, zW0000 l, zG0000 l, zD l, z2WiQCM l, z3[yQCO l, z1SV000 l, z2WyPj8 l,
z1YVPQ0 l, z1vix[K l, z1SyZCN l, z1bix[L l, z1SyZCN l, z1SyZCN l, z1[ix[L l, zfyPO1 l,
z1SyZCN l, z3[yPnR l, z1[ixnK l, z1YFYal l, z1viPR6 l, z1SyZCN l, z1bix[L l, z1SyZCN l,
z1SyZCN l, z1[ix[L l, z1SyZCN l, z1[ix[K l, z1bixnK l, z1SV01X l,
freedict
]
4 .
\ invert ( n1 -- n2 ) bitwise invert n1
[ifndef invert
: invert
	-1 xor
;
]
\
\ lasti? ( -- t/f ) true if this is the last value of i in this loop, assume an increment of 1
[ifndef lasti?
: lasti?
	1 RS@ h2 RS@ 1+ =
;
]
\
\
\ pinin ( n1 -- ) set pin # n1 to an input
[ifndef pinin
: pinin
	>m invert dira COG@ and dira COG!
;
]
\
\
\ pinout ( n1 -- ) set pin # n1 to an output
[ifndef pinout
: pinout
	>m dira COG@ or dira COG!
;
]
\
\
\ pinlo ( n1 -- ) set pin # n1 to lo
[ifndef pinlo
: pinlo
	>m _maskoutlo
;
]
\
\
\ pinhi ( n1 -- ) set pin # n1 to hi
[ifndef pinhi
: pinhi
	>m _maskouthi
;
]
\
\
\ px ( t/f n1 -- ) set pin # n1 to h - true or l false
[ifndef px
: px
	swap
	if 
		pinhi
	else
		pinlo
	then
;
]
5 .
\
\
\ eeprom read and write routine for the prop proto board AT24CL256 eeprom on pin 28 sclk, 29 sda
\
\ _sdai ( -- ) eeprom sda in
[ifndef _sdai
: _sdai
	h1D pinin
;
]
\
\ _sdao ( -- ) eeprom sda out
[ifndef _sdao
: _sdao
	h1D pinout
;
]
\
\ _scli ( -- ) eeprom clk in
[ifndef _scli
: _scli
	h1C pinin
;
]
\
\
\ _scll ( -- ) eeprom clk out
[ifndef _sclo
: _sclo
	h1C pinout
;
]
\
\
[ifndef _sdal
\ _sdal ( -- ) eeprom sda lo
: _sdal
	h20000000 _maskoutlo
;
]
\
\
\ _sdah ( -- ) eeprom sda hi
[ifndef _sdah
: _sdah
	h20000000 _maskouthi
;
]
6 .
\
\
\ _scll ( -- ) eeprom clk lo
[ifndef _scll
: _scll
	h10000000 _maskoutlo
;
]
\
\
\ _sclh ( -- ) eeprom clk hi
[ifndef _sclh
: _sclh
	h10000000 _maskouthi
;
]
\
\
\ _sda? ( -- t/f ) read the state of the sda pin
[ifndef _sda?
: _sda?
	h20000000 _maskin
;
]
\
\
\ _eestart ( -- ) start the data transfer
[ifndef _eestart
: _eestart
	_sclh _sclo _sdah _sdao _sdal _scll
;
]
\
\
\ _eestop ( -- ) stop the data transfer
[ifndef _eestop
: _eestop
	_sclh _sdah _scll _scli _sdai
;
]
\
\
[ifndef 1lock
\ 1lock( -- ) equivalent to 1 lock
: 1lock 1 lock ;
]
\
[ifndef 1unlock
\ 1unlock( -- )  equivalent to 1 unlock
: 1unlock 1 unlock ;
]
7 .
\
\ the eereadpage and eewritePage words assume the eeprom are 64kx8 and will address up to 
\ 8 sequential eeproms
\ eereadpage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
[ifndef eereadpage 
: eereadpage
	1lock
	1 max rot dup hFF and swap dup
	h8 rshift hFF and swap h10 rshift h7 and
	1 lshift dup >r
	_eestart hA0 or _eewrite swap _eewrite or swap _eewrite or
	_eestart r> hA1 or _eewrite or
	rot2 bounds
	do
		lasti? _eeread i C!
	loop
	_eestop
	1unlock
;
]
\
\
\ the eereadpage and eewritePage words assume the eeprom are 64kx8 and will address up to 
\ 8 sequential eeproms
\ eewritepage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
[ifndef eewritepage
: eewritepage
	1lock
	1 max rot dup hFF and swap dup h8 rshift hFF and swap h10 rshift h7 and 1 lshift
	_eestart hA0 or _eewrite swap _eewrite or swap _eewrite or
	rot2 bounds
	do
		i C@ _eewrite or
	loop
	_eestop hA delms
	1unlock
;
]
8 .
\
\
\ eeemit( -- ) dumps 32k of eeprom
[ifndef eeemit
: eeemit
	h8000 0
	do
		i pad h40 eereadpage drop
		pad h40 .str
		100 delms
	h40 +loop
	padbl
;
]
\
\ eecheck( -- ) checksums 32k of eeprom
[ifndef eecheck
: eecheck
	0 h8000 0
	do
		i pad h40 eereadpage drop
		pad h40 bounds
		do
			i L@ +
		4 +loop
	h40 +loop
	padbl
	." EEPROM Sum: " . cr
;
]
9 .

\ eeload( -- ) loads 32k of eeprom
[ifndef eeload
: eeload
	." Writing EEPROM:~h0D"
	0 h8000 0
	do
		pad h40 bounds
		do
			key i C!
		loop
		i pad h40 eewritepage drop
		i h40 + dup h3FF and 0=
		if
			i h40 + .
		then
		h1FFF and 0=
		if
			cr
		then
	h40 +loop
	padbl
	eecheck
;
]
\
\
\ EW! ( n1 eeAddr -- ) write n1 to the eeprom
[ifndef EW!
: EW!
	swap t0 W! t0 2 eewritepage
	if
		hA ERR
	then
;
]
\
\
\ ibound ( -- n1 ) the upper bound of i
[ifndef ibound
: ibound
	1 RS@
;
]
10 .
\
\
\
\ saveforth( -- ) write the running image to eeprom UPDATES THE CURRENT VERSION STR
[ifndef saveforth
: saveforth
	c" wlastnfa" find
	if
		version W@ dup C@ + dup C@ 1+ swap C!
		pfa>nfa here W@ swap
		begin dup W@ over EW! 2+ dup h3F and 0= until
		do
			ibound i - h40 min dup i dup rot 
			eewritepage if hA ERR then _p? if h2E emit then
		+loop	 
	else
		drop
	then
	_p?
	if
		cr
	then
;
]
11 .
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
12 .
\
\ forgetandsaveforth ( -- ) forget this module and saveforth
: forgetandsaveforth
	c" build_EepromUtils" (forget)
	saveforth
;

c" EEpromUtils Loaded~h0D~h0D" .cstr


