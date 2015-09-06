\ Low Res VGA . f for HIVE Bellatrix hardware 
\ HINWEIS: Admistra und Regnatix mit Standard Propforth 3.5c nicht VGA
\ 20101017 includes alternate hardware configurations
\ search for the asterisks ************************* 
\ to find the sections to edit


fl

hex

: build_loresvga ;

\ 15 rows, 32 cols cannot really get any more resolution than this w one cog

\ allocate space for 2 12 byte vga structures, long aligned,
\ and a 16 word color palette array, and initialize the color array
lockdict variable (vga0ptr)

\ vga0 structure the first long is already allocated by wvariable
10000 (vga0ptr) L!	\ vx and vy, vm and vf (vm = 1)
0 w,			\ vo
8000 3C0 - w,		\ VS
0 w,			\ vci and va
0 w,			\ padding for long alignement

\ vga1 structure
0 w,			\ vx and vy
3 w,			\ vm and vf (vm = 3)
0 w,			\ vo
8000 3C0 2* - w,	\ vs
8 w,			\ vci and va (vci = 8)
0 w,			\ padding for long alignement`

\ the color array

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00000011		11111111
\ color 0  	black			white
03FF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11000011		11111111
\ color 1  	red			white
c3FF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		11111111
\ color 2  	green			white
33FF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00001111		11111111
\ color 3  	blue			white
0FFF w,

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11111111		00000011
\ color 4  	white			black
FF03 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11000011		00000011
\ color 5  	red			black
c303 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		00000011
\ color 6  	green			black
3303 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00001111		00000011
\ color 7  	blue			black
0F03 w,

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11111111		00001111
\ color 8  	white			blue
FF0F w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		01010011		11110011
\ color 9  	brown			yellow
53F3 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00000011		11001111
\ color A  	black			magenta
03CF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		01010111		11111111
\ color B  	grey			white
57FF w,

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00111111		00010111
\ color C  	cyan			dark cyan
3F87 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		10111011
\ color D  	green			grey green
33BB w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		11010111
\ color E  	red			pink
33D7 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00001111		00111111
\ color F  	blue			cyan
0F3F w,

freedict

C (vga0ptr) + wconstant (vga1ptr)	\ a word pointer to the structure for vga1
C (vga1ptr) + wconstant (vgacolors)	\ a pointer to 16 colors, referenced by the vga consoles

wvariable (vgaptr) (vga0ptr) (vgaptr) W!	\ a pointer to the currenlty active vga screen

\ the structure for the vga consoles
\ 
\ : vx ;	\ a char, the horizontal position of the cursor (the column) 0 - 1F
: vy 1+ ;	\ a char, the vertical position of the cursor (the row) 0 - E
: vm 2+ ;	\ a char, the mode of the vga cursor
: vf 3 + ;	\ a char, the flag which indicates we are waiting for the second char of a 2 byte sequence to the console
\ : vo 4+ ;	\ a word, the offset into the screen buffer of the cursor
: vs 6 + ;	\ a word, a pointer to the screen buffer, E x 20 words or 3E0 bytes
: vci 8 + ;	\ a char, the current index of the color being used
: va 9 + ;	\ a char, if 0 autoscroll is on
\
\ vo ( struct_addr -- n1)
: vo@ 4+ W@ ;		\ gets the current offset of the cursor into the screen buffer
\ vo! ( struct_addr n1 -- struct_addr )
: vo! over 4+ W! ;	\ stores the offset
\
\ vs@ ( struct_addr -- addr) 
: vs@ 6 + W@ ;			\ gets the screen buffer pointer
\ vso@ ( struct_addr -- addr )
: vso@ dup vs@ swap vo@ + ;	\ gets the pointer to the character pointed at the cursor
\ vc@ ( struct_addr -- currentcolor)
: vc@ vci C@ 2* (vgacolors) + W@ ;

\ (lb) ( struct_addr addr -- struct_addr) blank a line
: (lb) over vci C@ b lshift 220 + dup w>l swap 10 0 do 2dup L! 4+ loop 2drop ;

\ 00 - clear the screen and home the cursor
\ 01 nn - set the current background color 00RR GGBB
\ 02 nn - set the current foreground color 00RR GGBB
\ 03 - set autoscroll on
\ 04 - set autoscroll off
\ 08 - backspace
\ 09 - tab every 8 spaces
\ 0D - carriage return and line feed
\ 0A nn - set cursor to column nn (00 - 1F)
\ 0B nn - set cursor to row nn (00 - 0E)
\ 0C nn - set current line color to nn (00 - 0F) last color set is the current color
\ 0E nn - echo nn to the screen
\ 0F nn - set cursor mode to nn ( 0 - 7)
\ 0 - cursor off
\ 1 - block cursor on, blink fast
\ 2 - block cursor on, blink slow
\ 3 - block cursor on, blink fast / slow

\ (vgaemit1) ( addr -- addr ) scroll the screen if necessary, and clear the line if necessary
: (vgaemit1)
	dup vo@ 3BF > if
\ roll to the beginning of the screen
		dup va C@ if
			0 vo!
		else
\ scroll the screen
			dup vs@ dup 40 + swap
			E0 0 do over L@ over L! 4+ swap 4+ swap loop 2drop
			380 vo!
		then
	then
\ clear the line if necessary
	dup vo@ 3f and 0= if
\ clear the line
		dup vso@ (lb)
	then
;


\ (vgap) ( addr c1 -- addr )
: (vgap)
	over vci C@ 2* over 1 and + a lshift 200 + swap FE and +
	over vso@ W! dup vo@ 2+ vo!
;

\ (vgaf!) ( addr c1 -- addr)
: (vgaf!) over vf C! ;

\ (vgaemit) ( addr c1 -- )
: (vgaemit)
	over vf C@ 0=
	if
		dup F > if
			(vgap)
			(vgaemit1)
		else dup 0 = if

\ clear the screen and set the cursor to 0 0
			drop 0 vo!				\ set cursor to 0,0 and offset to 0
			dup vs@ 3C0 bounds do i (lb) 40 +loop	\ clear the screen

		else dup 1 = if
\ next char will be the background color
			(vgaf!)
		else dup 2 = if
\ next char will be the foreground color
			(vgaf!)
		else dup 3 = if
\ autoscroll on
			drop 0 over va C!
		else dup 4 = if
\ autoscroll off
			drop -1 over va C!
		else dup 8 = if
\ backspace
			drop dup vo@ 2- 0 max vo!		\ back up the offset to the previos character
			bl over vso@ C!				\ write a blank to the current position
		else dup 9 = if
\ tab every 8 characters
			drop begin
				bl (vgap)
				dup vo@ E and 0=
			until
		else dup D = if
\ carriage return (auto line feed)
			drop dup vo@ 40 + 3E andn vo!		\ update the offset
			(vgaemit1)				\ scroll/clear if necessary
		else dup A = if
\ next char will be the column
			(vgaf!)
		else dup B = if
\ next char will be the row
			(vgaf!)
		else dup C = if
\ next char will be the color
			(vgaf!)
		else dup E = if
\ next char will be the character to print to the screen
			(vgaf!)
		else dup F = if
\ next char will be the cursor mode
			(vgaf!)
		else
\ otherwise just put the character
			(vgap)
			(vgaemit1)				\ scroll/clear if necessary
		then then then then then then then then then then then then then then

	else
		over vf dup C@ swap 0 swap C!
		dup 1 = if				\ addr backcolor vf
			drop 2* 2* 3 or over vci C@ 2* (vgacolors) + C!
		else dup 2 = if				\ addr forecolor vf
			drop 2* 2* 3 or over vci C@ 2* (vgacolors) + 1+ C!
		else dup A = if			\ addr x
			drop 1f and		\ addr x
			over C@ - 2*	 	\ addr delta

			over vo@ +		\ addr offset 
			vo!			\ addr
		else dup B = if			\ addr y
			drop 1f and		\ addr y
			over vy C@ - 6 lshift	\ addr delta

			over vo@ +		\ addr offset 
			vo!			\ addr
		else dup C = if
			drop F and over vci C!
		else dup E = if
			drop (vgap)			\ print the char
			(vgaemit1)			\ scroll/clear if necessary
		else dup F = if
			drop 7 and over vm C!
		else
			2drop
		then then then then then then then
	then
\ align the cursor with the offset
	dup vo@ 3E and 2/ over C!
	dup vo@ 6 rshift swap vy C!
;

\ (v0) ( c1 -- ) emit c1 to vga0
: (v0) (vga0ptr) swap (vgaemit) ;

\ (v1) ( c1 -- ) emit c1 to vga1
: (v1) (vga1ptr) swap (vgaemit) ;

{
1AF wconstant c_mainloop
181 wconstant c_backtask1
180 wconstant c_backtask0
17E wconstant c_backtask
17D wconstant v_backtask
17C wconstant v_foretask
173 wconstant v_linevscl
172 wconstant v_hpix
171 wconstant v_screen
170 wconstant v_cursoraddr
16F wconstant v_hvbase
150 wconstant v_colortable1
14F wconstant v_colortable
}

1AD asmlabel a_vgamainloop

lockdict variable def_vga 01DF l, 014F l,
03FF03FF l,
0303FFFF l,
F353F353 l,
F3F35353 l,
8B038B03 l,
8B8B0303 l,
57FF57FF l,
5757FFFF l,
3F173F17 l,
3F3F1717 l,
23BB23BB l,
2323BBBB l,
43D743D7 l,
4343D7D7 l,
3F0F3F0F l,
3F3F0F0F l,
FF03FF03 l,
FFFF0303 l,
03FF03FF l,
0303FFFF l,
8B038B03 l,
8B8B0303 l,
57FF57FF l,
5757FFFF l,
3F173F17 l,
3F3F1717 l,
23BB23BB l,
2323BBBB l,
43D743D7 l,
4343D7D7 l,
3F0F3F0F l,
3F3F0F0F l,
03030303 l,
0 l,
0 l,
00000200 l,
00001010 l,
0 l,
0 l,
0 l,
0 l,
0 l,
0 l,
0 l,
0 l,
0 l,
0 l,
A0BE1B4F l,
A0BE1D50 l,
A0BE9F0D l,
A0BEA10E l,
5CBEFB7C l,
04BE1D08 l,
80FE1401 l,
60FE140F l,
08BE170E l,
80FE1C04 l,
08BEE10E l,
A0BEE370 l,
28FEE210 l,
60BEE102 l,
80BEE171 l,
A0BE1B0B l,
28FE1A10 l,
60FE1A03 l,
2CFE1A18 l,
623E1BF1 l,
A0EAE000 l,
5CBEFB7C l,
A0BE1D09 l,
A0BE190A l,
2CFE1801 l,
80BE1D0C l,
04BE170E l,
A0FE1D4F l,
80BE1D0A l,
80BE1D0A l,
54BF010E l,
80FE1C01 l,
54BF030E l,
5CBEFB7C l,
A0BE1B0B l,
2CFE1A10 l,
68BE1B0B l,
A0BE1D0B l,
2CFE1C08 l,
A0BE190B l,
60FE18FF l,
68BE1D0C l,
A0BE190B l,
64FE18FF l,
2CFE1810 l,
68BE1D0C l,
5C7C0180 l,
A0FEFB7E l,
5CFDF0F0 l,
A0BEEB6F l,
A0BEED71 l,
A0FEEE0F l,
A0FEF74F l,
2CFEF610 l,
A0FEF020 l,
A0BFFF73 l,
80BEE97B l,
863EED70 l,
04BEF376 l,
2CFEF206 l,
80BEF374 l,
08BEF579 l,
28FEF210 l,
54BF8179 l,
80FEEC02 l,
A0AAF503 l,
FC3E9F7A l,
E4FEF1B7 l,
84FEEC40 l,
A0FEF001 l,
5CFFBDD5 l,
80FEE804 l,
62FEE87C l,
5C5401B4 l,
80FEEC40 l,
E4FEEFB4 l,
A0FEF00B l,
5CFFBDD2 l,
A0FEF002 l,
5CFFBDD1 l,
A0FEF01F l,
5CFFBDD1 l,
5C7C01AF l,
6CFEEA01 l,
A0BFFF72 l,
FC7EEA00 l,
5CBEF97D l,
A0FFFE0A l,
FC7EEA00 l,
A0FFFE4B l,
6CFEEA02 l,
FC7EEA00 l,
A0FFFE2B l,
6CFEEA02 l,
FC7EEA00 l,
E4FEF1D2 l,
5C7C0000 l,

freedict

\ *********************************************************************************** \
\ hardware configuration selection 1 of 3 - VGA
\ remove comment to use pin group 

: vgainit
def_vga lasm

10000000 frqa COG!

\ 300000FF vcfg COG! \ vga pins 0:7
\ 000000FF dira COG!
\

300002FF vcfg COG! \ vga pins 8:15 \ HIVE VGA pinout
0000FF00 dira COG!

\
\ 300004FF vcfg COG! \ vga pins 16:23 \ Demo Board VGA pinout
\ 00FF0000 dira COG!
\
\ 300006FF vcfg COG! \ vga pins 24:31
\ FF000000 dira COG!
\
\ End of hardware configuration 1  
\ Lines 450, 484, 788
\ *********************************************************************************** \


06800000 ctra COG!
787F dup dictend W! memend W!

0 (v0) 0 (v1)
(vgaptr) (vgacolors) a_vgamainloop
;

\ *********************************************************************************** \
\ hardware configuration selection 2 of 3 - Keyboard
\ remove comment to use pin group 

\ 08000000 constant kbclock       \ demo board KBD pinout (26) 26:27
\ 04000000 constant kbdata        \ demo board KBD pinout (27) 26:27

00010000 constant kbclock         \ HIVE VGA pinout (16) 16:17
00020000 constant kbdata          \ HIVE VGA pinout (17) 16:17

\ End of hardware configuration 2  
\ Lines 450, 484, 788
\ *********************************************************************************** \


wvariable kbretry 1c0 kbretry W!

\ (kbclocklo) ( -- ) set the open collector clock output to be lo, tells the keyboard we are not ready for data
: (kbclocklo)
	kbclock _maskoutlo
	dira COG@ kbclock or dira COG!
;

\ (kbclockhi) ( -- ) set the open collector clock output to be hi (set as input), tells the keyboard we are ready 
\ for data, keyboard will pull clock line lo if there are scancodes to send
: (kbclockhi)
	dira COG@ kbclock andn dira COG!
;

\ (kbbitin) ( n1 -- n1) get a keyboard bit
: (kbbitin) 
	kbclock dup waitpeq 
	1 rshift
	kbclock dup waitpne
	kbdata _maskin if 400 else 0 then or
;

\ (kbin0) ( -- n1 ) n1 - 0 no keyscan code, otherwise scan code
: (kbin0)
\ set kbclock hi, the keyboard will pull it lo if there are scancodes to send
	(kbclockhi)
\ wait for clock to go lo kbretry times
	0 kbretry W@ 0 do
		kbclock _maskin
		if else
\ there is a keycode, we already got the start bit so we need another 10 bits
			(kbbitin) (kbbitin) (kbbitin) (kbbitin) (kbbitin)
			(kbbitin) (kbbitin) (kbbitin) (kbbitin) (kbbitin)
\ kbclock set to lo, tells the keyboard we are not ready for data
			(kbclocklo)
\ and out the stop parity and start bits
			1 rshift ff and
			leave 
		then
	loop
\ kbclock set to lo, tells the keyboard we are not ready for data
	(kbclocklo)
;

\ (kbin1) ( -- n1 n2) n1 - 0 no keyscan code, scan code, n1 - 0 key down, -1 key up
: (kbin1)
	(kbin0)
\ dup 0<> if st? then
	dup F0 = if drop (kbin0) -1 else 0 then
;


\ (kbin2) ( -- n1 n2) n1 - 0 no keyscan code, otherwise translated scan code, n1 - 0 key down, -1 key up
\ 0xE0 0xXX -> 0x80 or  0xXX
\ 0xE1 0xXX 0xYY -> 0xFF
: (kbin2)
	(kbin1)
	over E0 = if 2drop (kbin1) swap 80 or swap else
	over E1 = if 2drop (kbin1) 2drop (kbin1) swap drop FF swap then then
;

\ 0x01 - leftshift
\ 0x02 - rightshift
\ 0x04 - capslock

\ 0x08 - lefttcttl
\ 0x10 - rightctrl

\ 0x20 - leftalt
\ 0x40 - rightalt

wvariable (kbstate)


: (kbinit) 0 (kbstate) W! (kbclocklo) ;

\ translation table for kbin3, from (kb2in) scan code 0x0D - 0x7D,
\ first byte is ascii code, 2nd byte is ascii code with shift key pressed
\ ascii code 0 means there is no translated value

lockdict
wvariable (kbin3table)

\ store the first 2 values in the word defined
0909 (kbin3table) W!
\ 9 c, 9 c,  \ (kbin2) 0D

60 c, 7E c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 0E
0 c, 0 c,  \ (kbin2) 11
0 c, 0 c, 0 c, 0 c,  \ (kbin2) 12
0 c, 0 c,  \ (kbin2) 14
71 c, 51 c,  \ (kbin2) 15
31 c, 21 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 16
7A c, 5A c,  \ (kbin2) 1A
73 c, 53 c,  \ (kbin2) 1B
61 c, 41 c,  \ (kbin2) 1C
77 c, 57 c,  \ (kbin2) 1D
32 c, 40 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 1E

63 c, 48 c,  \ (kbin2) 21
78 c, 58 c,  \ (kbin2) 22
64 c, 44 c,  \ (kbin2) 23
65 c, 45 c,  \ (kbin2) 24
34 c, 24 c,  \ (kbin2) 25
33 c, 23 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 26
20 c, 20 c,  \ (kbin2) 29
76 c, 56 c,  \ (kbin2) 2A
66 c, 46 c,  \ (kbin2) 2B
74 c, 54 c,  \ (kbin2) 2C
72 c, 52 c,  \ (kbin2) 2D
35 c, 25 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 2E

6E c, 4E c,  \ (kbin2) 31
62 c, 42 c,  \ (kbin2) 32
68 c, 46 c,  \ (kbin2) 33
67 c, 47 c,  \ (kbin2) 34
79 c, 59 c,  \ (kbin2) 35
36 c, 5E c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 36
6D c, 4D c,  \ (kbin2) 3A
6A c, 4A c,  \ (kbin2) 3B
75 c, 55 c,  \ (kbin2) 3C
37 c, 26 c,  \ (kbin2) 3D
38 c, 2A c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 3E

2C c, 3C c,  \ (kbin2) 41
6B c, 4B c,  \ (kbin2) 42
69 c, 49 c,  \ (kbin2) 43
6F c, 4F c,  \ (kbin2) 44
30 c, 29 c,  \ (kbin2) 45
39 c, 28 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 46
2E c, 3E c,  \ (kbin2) 49
2F c, 3F c,  \ (kbin2) 4A
6C c, 4C c,  \ (kbin2) 4B
3B c, 3A c,  \ (kbin2) 4C
70 c, 50 c,  \ (kbin2) 4D
2D c, 5F c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 4E

27 c, 22 c, 0 c, 0 c,  \ (kbin2) 52
5B c, 7B c,  \ (kbin2) 54
3D c, 2B c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 55
0 c, 0 c,  \ (kbin2) 58
0 c, 0 c,  \ (kbin2) 59
0D c, 0D c,  \ (kbin2) 5A
5D c, 7D c, 0 c, 0 c,  \ (kbin2) 5B
5C c, 7C c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 5D

8 c, 8 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 66
31 c, 31 c, 0 c, 0 c,  \ (kbin2) 69
34 c, 34 c,  \ (kbin2) 6B
37 c, 37 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ (kbin2) 6C

30 c, 30 c,  \ (kbin2) 70
2E c, 2E c,  \ (kbin2) 71
32 c, 32 c,  \ (kbin2) 72
35 c, 35 c,  \ (kbin2) 73
36 c, 36 c,  \ (kbin2) 74
38 c, 38 c,  \ (kbin2) 75
1B c, 1B c,  \ (kbin2) 76
0 c, 0 c,  \ (kbin2) 77
0 c, 0 c,  \ (kbin2) 78
2B c, 2B c,  \ (kbin2) 79
33 c, 33 c,  \ (kbin2) 7A
2D c, 2D c,  \ (kbin2) 7B
2A c, 2A c,  \ (kbin2) 7C
39 c, 39 c,  \ (kbin2) 7D

freedict


\ 0x01 - leftshift
\ 0x02 - rightshift
\ 0x04 - capslock

\ 0x08 - lefttcttl
\ 0x10 - rightctrl

\ 0x20 - leftalt
\ 0x40 - rightalt

\ (setkbstate) ( n1 n2 n3 -- 0 0 ) n1 - scan code, n2 - not 0 turn off bit, 0 turn on bit, n3 - mask
: (setkbstate) rot drop swap (kbstate) W@ rot2 if andn else or then (kbstate) W! 0 dup ;

\ (kbin3) ( -- n1 n2) n1 - 0 no keyscan code, otherwise translated to ascii scan code, n1 - 0 key down, -1 key up
\ ALT-a swap monitors
: (kbin3)
	(kbin2)
\ left alt
	over 11 = if 20 (setkbstate) else
\ left shift
	over 12 = if 01 (setkbstate) else
\ left ctrl
	over 14 = if 08 (setkbstate) else
\ right alt
	over 91 = if 40 (setkbstate) else
\ right shift
	over 59 = if 02 (setkbstate) else
\ right ctrl
	over 94 = if 10 (setkbstate) else
\ code in table, ready for translation
	over 0d 7d between if
		over 0d - 2* (kbin3table) + (kbstate) W@ 7 and if 1+ then C@ dup 0= if drop else rot drop swap
		swap 
			(kbstate) W@ 18 and if 1f and then
			(kbstate) W@ 60 and if 80 or then
		swap
	thens
;






\ kbin ( -- c1) c1 - 0, no key available, else the keycode
: kbin
	(kbin3)
\ on key up, toss
	if drop 0 else
\ alt-tab - switch screens
		dup 89 = if (vgaptr) W@ (vga0ptr) = if (vga1ptr) else (vga0ptr) then (vgaptr) W! drop 0 else
	thens
;

\ the cog connected to vga0
wvariable cogvga0

\ data to vga0, a cogs emitptr points to invga0 when it is connected
wvariable invga0

\ data from vga0, points to a cogs inbyte when it is connected
wvariable outvga0

\ >vga0 ( n1 -- ) connect vga0 to the forth cog
: >vga0 cogvga0 W@ disio invga0 over cogemitptr W! dup coginbyte outvga0 W! cogvga0 W! ;

\ the cog connected to vga1
wvariable cogvga1

\ data to vga1, a cogs emitptr points to invga1 when it is connected
wvariable invga1

\ data from vga1, points to a cogs inbyte when it is connected
wvariable outvga1


\ >vga1 ( n1 -- ) connect vga1 to the forth cog
: >vga1 cogvga1 W@ disio invga1 over cogemitptr W! dup coginbyte outvga1 W! cogvga1 W! ;

: vgamon
\ initialize variables
100 dup invga0 W! invga1 W!
(kbinit)


begin
\ look for characters to be written to the vga screens	
	100 0 do
		invga0 W@ dup 100 and if drop else (vga0ptr) swap (vgaemit) 100 invga0 W! then
		invga1 W@ dup 100 and if drop else (vga1ptr) swap (vgaemit) 100 invga1 W! then
	loop
\ process input characters
	(vgaptr) W@ (vga1ptr) = if	
		outvga1 W@ W@ 100 and if
			kbin dup if 
				outvga1 W@ W!
			else
				drop
			then
		then
	else
		outvga0 W@ W@ 100 and if
			kbin dup if
				outvga0 W@ W!
			else
				drop
			then
		then
	then

0 until
;

\ qHzb ( n1 n2 -- n3 ) n1 - the pin, n2 - the # of msec to sample, n3 the frequency
: qHzb
 swap 28000000 + 1 frqb COG! ctrb COG!
 3000 min clkfreq over 3e8 */ 310 - phsb COG@ swap cnt COG@ + 0 waitcnt
 phsb COG@ nip swap - 3e8 rot */ ; 

: _onboot onboot ;

\ *********************************************************************************** \
\ hardware configuration selection 3 of 3 - VGA Vsync
\ modify code to use pin group 

\ and there is a watchdog routine on startup, 
\ so change the 10 to the vsync pin, for the Hive 
\ as it is monitoring for a signal between 55 and 65 hz

\ : onboot _onboot begin 1 cogreset 00 100 qHzb   \ pin 0:7 VGA pinout
\ : onboot _onboot begin 1 cogreset 08 100 qHzb   \ Hive VGA pinout
\ : onboot _onboot begin 1 cogreset 10 100 qHzb   \ Demo Board VGA pinout 
\ : onboot _onboot begin 1 cogreset 18 100 qHzb   \ pin 24:31 VGA pinout

\ Modify this line -------- HERE  ||
: onboot _onboot begin 1 cogreset 08 100 qHzb 37 41 between until 
0 cogreset
lockdict 2 _scog W! (cog+) (cog+) (cog+) 5 cogreset 2 >vga0 3 >vga1 5 >con freedict ;

\ End of hardware configuration 3  
\ Lines 450, 484, 788
\ *********************************************************************************** \


: onreset0 onreset vgamon ;

: onreset1 onreset vgainit ;

: _onreset onreset ;


: onreset _onreset
\ reconnect the cog to the vga consoles if it was previously connected
cogid cogvga0 W@ = if cogid >vga0 then 
cogid cogvga1 W@ = if cogid >vga1 then
;


{


\ order of pins used by vga driver
\
\ VSYNC
\ HSYNC
\ BLUE1
\ BLUE0
\ GREEN1
\ GREEN0
\ RED1
\ RED0

The intended value for the horizontal frequency of VGA
is exactly double the value used in the NTSC-M video system.
The formula for the VGA horizontal frequency is thus
(60 ÷ 1001) × 525 kHz = 4500 ÷ 143 kHz ˜ 31.4686 kHz.

All other frequencies used by the VGA card are derived from this value by
integer multiplication or division. Since the exactness of quartz oscillators
is limited, real cards will have slightly higher or lower frequency.

For most common VGA mode 640×480 "60 Hz" non-interlaced the horizontal timings are:

Parameter			Value	Unit
Pixel clock frequency		25.175	MHz[9]
Horizontal pixels		640	
Horizontal sync polarity	Negative	
Total time for each line	31.77	µs
Front porch (A)			0.94	µs
Sync pulse length (B)		3.77	µs
Back porch (C)			1.89	µs
Active video (D)		25.17	µs

(Total horizontal sync time 6.60 µs)

The vertical timings are:
Parameter			Value	Unit
Vertical lines			480	
Vertical sync polarity		Negative	
Vertical frequency		59.94	Hz
Front porch (E)			0.35	ms
Sync pulse length (F)		0.06	ms
Back porch (G)			1.02	ms
Active video (H)		15.25	ms

(Total vertical sync time 1.43 ms)


fl


:asm


v_colortable
\ black / white                 fore 00 00 00 11 (03) back 11 11 11 11 (ff)
 03FF03FF
v_colortable1
 0303FFFF
  
\ yellow / brown                fore 11 11 00 11 (f3) back 01 01 00 11 (53)
 f353f353
 f3f35353
  
\ magenta / black               fore 10 00 10 11 (8b) back 00 00 00 11 (03)  
 8b038b03
 8b8b0303
  
\ grey / white                  fore 01 01 01 11 (57) back 11 11 11 11 (ff)  
 57ff57ff
 5757ffff

\ cyan / dark cyan              fore 00 11 11 11 (3f) back 00 01 01 11 (17)
 3f173f17
 3f3f1717
  
\ green / grey-green            fore 00 10 00 11 (23) back 10 11 10 11 (bb)
 23bb23bb
 2323bbbb
  
\ red / pink                    fore 01 00 00 11 (43) back 11 01 01 11 (d7)  
 43d743d7
 4343d7d7
  
\ cyan / blue                   fore 00 11 11 11 (3f) back 00 00 11 11 (0f)  
 3f0f3f0f
 3f3f0f0f

\ white / black                 fore 11 11 11 11 (ff) back 00 00 00 11 (03)
 ff03ff03
 ffff0303
  
\ black / white                 fore 00 00 00 11 (03) back 11 11 11 11 (ff)
 03ff03ff
 0303ffff
  
\ magenta / black               fore 10 00 10 11 (8b) back 00 00 00 11 (03)  
 8b038b03
 8b8b0303
  
\ grey / white                  fore 01 01 01 11 (57) back 11 11 11 11 (ff)  
 57ff57ff
 5757ffff

\ cyan / dark cyan              fore 00 11 11 11 (3f) back 00 01 01 11 (17)
 3f173f17
 3f3f1717
  
\ green / grey-green            fore 00 10 00 11 (23) back 10 11 10 11 (bb)
 23bb23bb
 2323bbbb
  
\ red / pink                    fore 01 00 00 11 (43) back 11 01 01 11 (d7)  
 43d743d7
 4343d7d7
  
\ cyan / blue                   fore 00 11 11 11 (3f) back 00 00 11 11 (0f)  
 3f0f3f0f
 3f3f0f0f

v_hvbase
 03030303

v_cursoraddr
 0
v_screen
 0                        
v_hpix
 200
v_linevscl
 1010

__1line
 0
__2curhv
 0
__3curscreen
 0
__4y
 0
__5x
 0
__6tile
 0
__7pixels
 0
__8colortablel16
 0

v_foretask
 0
v_backtask
 0

c_backtask
\ _sttos is (vgaptr)
\ _treg1 is (vgacolors)
\ _treg2 is a counter form 0 - F, used for the colors
\ _treg3 temp register
\ _treg4 temp register
\ _treg5 color00
\ _treg6 color01

			mov	_treg5 , v_colortable
			mov	_treg6 , v_colortable1
c_backtask0
			mov	v_colortable , _treg5
c_backtask1
			mov	v_colortable1 , _treg6
			
			jmpret	v_backtask , v_foretask

\ _treg3 vx, vy, vm, vf
\ _treg4 temp register
\ _treg5 temp register
\ _treg6 ptr to vgastruct
			rdword	_treg6 , _sttos

			add	_treg2 , # 1
			and	_treg2 , # f
			rdlong	_treg3 , _treg6

\ _treg3 vx, vy, vm, vf
\ _treg4 temp register
\ _treg5 temp register
\ _treg6 ptr to vgastruct + 4
			add	_treg6 , # 4
			rdlong	v_cursoraddr , _treg6

			mov	v_screen , v_cursoraddr
			shr	v_screen , # 10
			and	v_cursoraddr , _faddrmask
			add	v_cursoraddr , v_screen

			mov	_treg5 , _treg3
			shr	_treg5 , # 10
			and	_treg5 , # 3
			shl	_treg5 , # 18
			test	_treg5 , cnt  wz
	if_z		mov	v_cursoraddr , # 0

\ v_cursoraddr is now the cursor position
			
			jmpret	v_backtask , v_foretask

\ _treg3 color (16 bit)
\ _treg4 temp register
\ _treg5 temp register
\ _treg6 temp register
			mov	_treg6 , _treg1
			mov	_treg4 , _treg2
			shl	_treg4 , # 1
			add	_treg6 , _treg4

			rdword	_treg3 , _treg6

			mov	_treg6 , # v_colortable
			add	_treg6 , _treg2
			add	_treg6 , _treg2
			movd	c_backtask0 , _treg6	
			add	_treg6 , # 1
			movd	c_backtask1 , _treg6

			jmpret	v_backtask , v_foretask

			mov	_treg5 , _treg3
			shl	_treg5 , # 10	
			or	_treg5 , _treg3

			mov	_treg6 , _treg3
			shl	_treg6 , # 8

			mov	_treg4 , _treg3
			and	_treg4 , # FF
			or	_treg6 , _treg4

			mov	_treg4 , _treg3
			andn	_treg4 , # FF
			shl	_treg4 , # 10
			or	_treg6 , _treg4

			jmp	# c_backtask0





a_vgamainloop
			mov	v_backtask , # c_backtask
			spopt
c_mainloop
                        mov     __2curhv , v_hvbase

                        mov     __3curscreen , v_screen
\ number of vertical lines
                        mov     __4y , # F

			mov	__8colortablel16 , # v_colortable
			shl	__8colortablel16 , # 10
__Dline                        
\ number of horizontal chars
                        mov     __5x , # 20
                        mov     vscl , v_linevscl
			add	__1line , __8colortablel16
                        
__Ctile
			cmp	__3curscreen , v_cursoraddr wz

                        rdword  __6tile , __3curscreen
                        shl     __6tile , # 6
                        add     __6tile , __1line
                        
                        rdlong  __7pixels , __6tile
                        shr     __6tile , # 10

                        movd    __Bcolor , __6tile
                        add     __3curscreen , # 2

	if_z		mov	__7pixels , _flongmask
          
__Bcolor
                        waitvid v_colortable , __7pixels
                        djnz    __5x , # __Ctile

\ number of horizontal chars *2                        
                        sub     __3curscreen , # 40
                        
                        mov     __5x , # 1
                        jmpret  __Fret , # __9hsync

\ next row of pixel in character                        
                        add     __1line , # 4
                        and     __1line , # 7C wz
        if_nz           jmp     # __Dline              
        
\ number of horizontal chars *2                        
                        add     __3curscreen , # 40
                        djnz    __4y , # __Dline
                        
                        mov    __5x , # B
                        jmpret  __Fret , # __Eblank_line

                        mov     __5x , # 2
                        jmpret  __Fret , # __Avsync

                        mov     __5x , # 1F
                        jmpret  __Fret , # __Avsync

                        jmp     # c_mainloop
                        
__Avsync                      
                        xor     __2curhv , # 1
__Eblank_line
                        mov     vscl , v_hpix
                        waitvid __2curhv , # 0

			jmpret	v_foretask , v_backtask

__9hsync
                        mov     vscl , # A
                        waitvid __2curhv , # 0

                        mov     vscl , # 4B
                        
                        xor     __2curhv , # 2
                        waitvid __2curhv , # 0

                        mov     vscl , # 2B
                        xor     __2curhv , # 2
                        waitvid __2curhv , # 0

                        djnz    __5x , # __Eblank_line
__Fret
                        ret



;asm


}

\ end of LOWRESVGA.F





