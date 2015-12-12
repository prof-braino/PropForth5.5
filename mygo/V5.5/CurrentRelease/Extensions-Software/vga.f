fl

hex

1 wconstant  build_vga
\
\
\ 2 virtual screens -15 rows, 32 cols cannot really get any more resolution than this w one cog
\
\
\
\ a cog special register
[ifndef ctra
h1F8	wconstant ctra
]
\
\ a cog special register
[ifndef ctrb
h1F9	wconstant ctrb 
]
\
\ a cog special register
[ifndef frqa
h1FA	wconstant frqa 
]
\
\ a cog special register
[ifndef frqb
h1FB	wconstant frqb 
]
\
\ a cog special register
[ifndef phsa
h1FC	wconstant phsa 
]
\
\ a cog special register
[ifndef phsb
h1FD	wconstant phsb 
]
\
\ a cog special register
[ifndef vcfg
h1FE	wconstant vcfg 
]
\
\ a cog special register
[ifndef vscl
h1FF	wconstant vscl
]
\
\
\
\ qHzb ( n1 n2 -- n3 ) n1 - the pin, n2 - the # of msec to sample, n3 the frequency
[ifndef qHzb
: qHzb
	swap h28000000 + 1 frqb COG! ctrb COG!
	h3000 min clkfreq over h3E8 u*/ h310 - phsb COG@ swap cnt COG@ + 0 waitcnt
	phsb COG@ nip swap - h3E8 rot u*/
; 
]
\
\ 2 virtual screens -15 rows, 32 cols cannot really get any more resolution than this w one cog
\
\ Allocate space for the screen buffers for each vga buffer 15*32*2 bytes for each one h3C0 bytes
\
lockdict variable _vgabuf 0 _vgabuf L!
\
   0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\ 
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\  
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\ 
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\
\ 2nd buffer
\
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\ 
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\  
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\ 
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,   0 l,  0 l,  0 l,  0 l,
\
freedict
\
\
\ 15 rows, 32 cols cannot really get any more resolution than this w one cog
\
\ allocate space for 2 12 byte vga structures, long aligned,
\ and a 16 word color palette array, and initialize the color array
lockdict variable _vga0ptr
\
\ vga0 structure the first long is already allocated by wvariable
h_10000 _vga0ptr L!
\			\ vx and vy, vm and vf (vm = 1)
0 w,
\			\ vo
_vgabuf h_3C0 + w,
\			\ vs
0 w,
\			\ vci and va
0 w,
\			\ padding for long alignment
\
\ vga1 structure
0 w,
\			\ vx and vy
3 w,
\			\ vm and vf (vm = 3)
0 w,
\			\ vo
_vgabuf w,
\		\ vs
8 w,
\			\ vci and va (vci = 8)
0 w,
\			\ padding for long alignment
\
\ the color array
\
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00000011		11111111
\ color 0  	black			white
h_03FF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11000011		11111111
\ color 1  	red			white
h_C3FF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		11111111
\ color 2  	green			white
h_33FF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00001111		11111111
\ color 3  	blue			white
h_0FFF w,

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11111111		00000011
\ color 4  	white			black
h_FF03 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11000011		00000011
\ color 5  	red			black
h_C303 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		00000011
\ color 6  	green			black
h_3303 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00001111		00000011
\ color 7  	blue			black
h_0F03 w,

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		11111111		00001111
\ color 8  	white			blue
h_FF0F w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		01010011		11110011
\ color 9  	brown			yellow
h_53F3 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00000011		11001111
\ color A  	black			magenta
h_03CF w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		01010111		11111111
\ color B  	grey			white
h_57FF w,

\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00111111		00010111
\ color C  	cyan			dark cyan
h_3F87 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		10111011
\ color D  	green			grey green
h_33BB w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00110011		11010111
\ color E  	red			pink
h_33D7 w,
\ foreground 	RRGGBB11 background	RRGGBB11
\ 		00001111		00111111
\ color F  	blue			cyan
h_0F3F w,

freedict

h_C _vga0ptr + wconstant _vga1ptr	\ a word pointer to the structure for vga1
h_C _vga1ptr + wconstant _vgacolors	\ a pointer to 16 colors, referenced by the vga consoles

wvariable _vgaptr _vga0ptr _vgaptr W!	\ a pointer to the currenlty active vga screen

\ the structure for the vga consoles
\ 
\ : vx ;	\ a char, the horizontal position of the cursor (the column) 0 - 1F
: vy 1+ ;	\ a char, the vertical position of the cursor (the row) 0 - E
: vm 2+ ;	\ a char, the mode of the vga cursor
: vf 3 + ;	\ a char, the flag which indicates we are waiting for the second char of a 2 byte sequence to the console
\ : vo 4+ ;	\ a word, the offset into the screen buffer of the cursor
: vs 6 + ;	\ a word, a pointer to the screen buffer, F x 20 words or 3C0 bytes
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
: vc@ vci C@ 2* _vgacolors + W@ ;

\ (lb) ( struct_addr addr -- struct_addr) blank a line
: (lb) over vci C@ h_B lshift h_220 + dup w>l swap h_10 0 do 2dup L! 4+ loop 2drop ;

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

\ _vgacemit1 ( addr -- addr ) scroll the screen if necessary, and clear the line if necessary
: _vgacemit1
	dup vo@ h_3BF > if
\ roll to the beginning of the screen
		dup va C@ if
			0 vo!
		else
\ scroll the screen
			dup vs@ dup 40 + swap
			h_E0 0 do over L@ over L! 4+ swap 4+ swap loop 2drop
			h_380 vo!
		then
	then
\ clear the line if necessary
	dup vo@ h_3F and 0= if
\ clear the line
		dup vso@ (lb)
	then
;


\ _vgap ( addr c1 -- addr )
: _vgap
	over vci C@ 2* over 1 and + h_A lshift 200 + swap FE and +
	over vso@ W! dup vo@ 2+ vo!
;

\ _vgaf! ( addr c1 -- addr)
: _vgaf! over vf C! ;

\ _vgaemit ( addr c1 -- )
: _vgaemit
	over vf C@ 0=
	if
		dup h_F > if
			_vgap
			_vgacemit1
		else dup 0 = if

\ clear the screen and set the cursor to 0 0
			drop 0 vo!				\ set cursor to 0 l, 0 and offset to 0
			dup vs@ h_3C0 bounds do i (lb) h_40 +loop	\ clear the screen

		else dup 1 = if
\ next char will be the background color
			_vgaf!
		else dup 2 = if
\ next char will be the foreground color
			_vgaf!
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
				bl _vgap
				dup vo@ E and 0=
			until
		else dup h_D = if
\ carriage return (auto line feed)
			drop dup vo@ h_40 + h_3E andn vo!		\ update the offset
			_vgacemit1				\ scroll/clear if necessary
		else dup h_A = if
\ next char will be the column
			_vgaf!
		else dup h_B = if
\ next char will be the row
			_vgaf!
		else dup h_C = if
\ next char will be the color
			_vgaf!
		else dup h_E = if
\ next char will be the character to print to the screen
			_vgaf!
		else dup h_F = if
\ next char will be the cursor mode
			_vgaf!
		else
\ otherwise just put the character
			_vgap
			_vgacemit1				\ scroll/clear if necessary
		then then then then then then then then then then then then then then

	else
		over vf dup C@ swap 0 swap C!
		dup 1 = if				\ addr backcolor vf
			drop 2* 2* 3 or over vci C@ 2* _vgacolors + C!
		else dup 2 = if				\ addr forecolor vf
			drop 2* 2* 3 or over vci C@ 2* _vgacolors + 1+ C!
		else dup A = if			\ addr x
			drop h_1F and		\ addr x
			over C@ - 2*	 	\ addr delta

			over vo@ +		\ addr offset 
			vo!			\ addr
		else dup B = if			\ addr y
			drop h_1F and		\ addr y
			over vy C@ - 6 lshift	\ addr delta

			over vo@ +		\ addr offset 
			vo!			\ addr
		else dup h_C = if
			drop h_F and over vci C!
		else dup h_E = if
			drop _vgap			\ print the char
			_vgacemit1			\ scroll/clear if necessary
		else dup h_F = if
			drop 7 and over vm C!
		else
			2drop
		then then then then then then then
	then
\ align the cursor with the offset
	dup vo@ h_3E and 2/ over C!
	dup vo@ 6 rshift swap vy C!
;

\ _v0 ( c1 -- ) emit c1 to vga0
: _v0 _vga0ptr swap _vgaemit ;

\ _v1 ( c1 -- ) emit c1 to vga1
: _v1 _vga1ptr swap _vgaemit ;



lockdict create a_vga forthentry
$C_a_lxasm w, h1A4  h113  1- tuck - h9 lshift or here W@ alignl h10 lshift or l,
z1SV05l l, z3yjFy l, z30yyy l, z3mKyDJ l, z3voDJ l, z2B0rf3 l, z2BYuC3 l, z1NyoVy l,
z1NLyyy l, zy5mvN l, zyFkSN l, zZhlEu l, zZ8uhu l, z13onFN l, z13GwVN l, zy3mvF l,
zyFjvF l, z3y0yv3 l, z3yyjC3 l, z3yjFy l, z30yyy l, z2B0rf3 l, z2BYjC3 l, z1NyoVy l,
z1NLyyy l, zy5mvN l, zyFkSN l, zZhlEu l, zZ8uhu l, z13onFN l, z13GwVN l, zy3mvF l,
zyFjvF l, z30jC3 l, 0 l, 0 l, z80 l, z10G l, 0 l, 0 l,
0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l,
z2WiQ4K l, z2WiQCL l, z2WiYZG l, z2WiYeH l, z1SibT1 l, z4iQBB l, z20yPb1 l, z1WyPbF l,
z8iPmH l, z20yQ84 l, z8i]eH l, z2Wi]no l, zby]jG l, z1Wi]e5 l, z20i]fp l, z2WiQ3E l,
zbyQ0G l, z1WyQ03 l, zfyQ0O l, z1YFQ7k l, z2Wt]b0 l, z1SibT1 l, z2WiQBC l, z2WiPuD l,
zfyPr1 l, z20iQBF l, z4iPmH l, z2WyQCK l, z20iQBD l, z20iQBD l, z1KibeH l, z20yQ81 l,
z1KibmH l, z1SibT1 l, z2WiQ3E l, zfyQ0G l, z1biQ3E l, z2WiQBE l, zfyQ88 l, z2WiPuE l,
z1WyPuy l, z1biQBF l, z2WiPuE l, z1[yPuy l, zfyPrG l, z1biQBF l, z1SV055 l, z2WybT3 l,
z1SyLIZ l, z2WiaKn l, z2WiaSp l, z2WyaWF l, z2Wyb4K l, zfyb0G l, z2WyabW l, z2Wiyvr l,
z20iaD0 l, z26FaSo l, z4ianu l, zfyaj6 l, z20ians l, z8iavx l, zbyajG l, z1Kijfx l,
z20yaO2 l, z2Wdau6 l, z3vFY[y l, z3[yagv l, z24yaP0 l, z2Wyab1 l, z1SynUQ l, z20ya84 l,
z1Yya9v l, z1SL05s l, z20yaP0 l, z3[ya\s l, z2WyabB l, z1SynUN l, z2Wyab2 l, z1SynUM l,
z2WyabV l, z1SynUM l, z1SV05n l, z1fyaG1 l, z2Wiyvq l, z3vVaG0 l, z1SibD3 l, z2WyyrA l,
z3vVaG0 l, z2WyysB l, z1fyaG2 l, z3vVaG0 l, z2Wyyre l, z1fyaG2 l, z3vVaG0 l, z3[yahN l,
z1SV000 l,
freedict


: _vgainit
	4 state andnC!

	h_10000000 frqa COG!

\ hardware configuration 1  
\ *********************************************************************************** \
\ 	300000FF vcfg COG! \ vga pins 0:7
\ 	000000FF dira COG!
\
\ 	300002FF vcfg COG! \ vga pins 8:15 \ HIVE VGA pinout
\ 	0000FF00 dira COG!

	h_300004FF vcfg COG! \ vga pins 16:23 \ Demo Board VGA pinout
 	_00FF0000 dira COG!

\	300006FF vcfg COG! \ vga pins 24:31
\	h_F000000 dira COG!
\


	h_06800000 ctra COG!

	_vgaptr _vgacolors a_vga
;

: vgastart
	d_100 0
	do
		1 cogreset
		d_100 delms
		c" _vgainit" 1 cogx
		d_100 delms

\ *********************************************************************************** \
\ hardware configuration 2
\
\		h_00			\ pin 0:7 VGA pinout
\		h_08			\ Hive VGA pinout
\		h_10			\ Demo Board VGA pinout 
\		h_18			\ pin 24:31 VGA pinout


		h_10
		h_100 qHzb
		h_37 h_41 between
		if
			leave
		then
	loop
	0 _v0 0 _v1
;

\ hardware configuration 3 
\ *********************************************************************************** \


 08000000 constant kbclock       \ demo board KBD pinout (26) 26:27
 04000000 constant kbdata        \ demo board KBD pinout (27) 26:27

\ 00010000 constant kbclock         \ HIVE VGA pinout (16) 16:17
\ 00020000 constant kbdata          \ HIVE VGA pinout (17) 16:17




wvariable kbretry h_1C0 kbretry W!

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
			1 rshift hFF and
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
	dup h_F0 = if drop (kbin0) -1 else 0 then
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
	over h0D h_7D between if
		over h_0D - 2* (kbin3table) + (kbstate) W@ 7 and if 1+ then C@ dup 0= if drop else rot drop swap
		swap 
			(kbstate) W@ h18 and if h1F and then
			(kbstate) W@ h60 and if h80 or then
		swap
	thens
;






\ kbin ( -- c1) c1 - 0, no key available, else the keycode
: kbin
	(kbin3)
\ on key up, toss
	if drop 0 else
\ alt-tab - switch screens
		dup h89 = if _vgaptr W@ _vga0ptr = if _vga1ptr else _vga0ptr then _vgaptr W! drop 0 else
	thens
;

0 cogio wconstant invga0
1 cogio wconstant invga1
invga0 2+ wconstant outvga0
invga1 2+ wconstant outvga1

: _vgamon
	4 state andnC!
\ initialize variables
\ 100 dup invga0 W! invga1 W!
(kbinit)


begin
\ look for characters to be written to the vga screens	
	100 0 do
		invga0  W@ dup h_100 and if drop else _vga0ptr swap _vgaemit h_100 invga0 W! then
		invga1  W@ dup 100 and if drop else _vga1ptr swap _vgaemit h_100 invga1 W! then
	loop
\ process input characters
	_vgaptr W@ _vga1ptr = if	
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




: vgastart
	d_100 0
	do
		1 cogreset
		d_100 delms
		c" _vgainit" 1 cogx
		d_100 delms

\ *********************************************************************************** \
\ hardware configuration 2
\
\		h_00			\ pin 0:7 VGA pinout
\		h_08			\ Hive VGA pinout
\		h_10			\ Demo Board VGA pinout 
\		h_18			\ pin 24:31 VGA pinout


		h_10
		h_100 qHzb
		h_37 h_41 between
		if
			leave
		then
	loop
	0 _v0 0 _v1

	c" _vgamon" 0 cogx

	c" VGA MONITOR 0" 0 cogcds  W!	
	c" VGA MONITOR 1" 1 cogcds  W!

	2 0 ioconn
	3 1 ioconn
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

hex

\ a cog special register
[ifndef vcfg
h1FE	wconstant vcfg 
]

\ a cog special register
[ifndef vscl
h1FF	wconstant vscl
]

build_BootOpt :rasm

		jmp	# __start


__colortable
\ black / white                 fore 00 00 00 11 (03) back 11 11 11 11 (ff)
 h_03FF03FF
__colortable1
 h_0303FFFF
  
\ yellow / brown                fore 11 11 00 11 (f3) back 01 01 00 11 (53)
 h_F353F353
 h_3F35353
  
\ magenta / black               fore 10 00 10 11 (8b) back 00 00 00 11 (03)  
 h_8B038B03
 h_8B8BB303
  
\ grey / white                  fore 01 01 01 11 (57) back 11 11 11 11 (ff)  
 h_57FF57FF
 h_5757FFFF

\ cyan / dark cyan              fore 00 11 11 11 (3f) back 00 01 01 11 (17)
 h_3F173F17
 h_3F3F1717
  
\ green / grey-green            fore 00 10 00 11 (23) back 10 11 10 11 (bb)
 h_23BB23BB
 h_2323BBBB
  
\ red / pink                    fore 01 00 00 11 (43) back 11 01 01 11 (d7)  
 h_43D743D7
 h_4343D7D7
  
\ cyan / blue                   fore 00 11 11 11 (3f) back 00 00 11 11 (0f)  
 h_3F0F3F0F
 h_3F3F0F0F

\ white / black                 fore 11 11 11 11 (ff) back 00 00 00 11 (03)
 h_FF03FF03
 h_FFFF0303
  
\ black / white                 fore 00 00 00 11 (03) back 11 11 11 11 (ff)
 h_03FF03FF
 h_0303FFFF
  
\ magenta / black               fore 10 00 10 11 (8b) back 00 00 00 11 (03)  
 h_8B038B03
 h_8B8B0303
  
\ grey / white                  fore 01 01 01 11 (57) back 11 11 11 11 (ff)  
 h_57FF57FF
 h_5757FFFF

\ cyan / dark cyan              fore 00 11 11 11 (3f) back 00 01 01 11 (17)
 h_3F173F17
 h_3F3F1717
  
\ green / grey-green            fore 00 10 00 11 (23) back 10 11 10 11 (bb)
 h_23BB23BB
 h_2323BBBB
  
\ red / pink                    fore 01 00 00 11 (43) back 11 01 01 11 (d7)  
 h_43D743D7
 h_4343D7D7
  
\ cyan / blue                   fore 00 11 11 11 (3f) back 00 00 11 11 (0f)  
 h_3F0F3F0F
 h_3F3F0F0F

__hvbase
 h_03030303

__cursoraddr
 0
__screen
 0                        
__hpix
 h_200
__linevscl
 h_1010

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

__foretask
 0
__backtask
 0

__backtask
\ $C_stTOS is _vgaptr
\ $C_treg1 is _vgacolors
\ $C_treg2 is a counter form 0 - F, used for the colors
\ $C_treg3 temp register
\ $C_treg4 temp register
\ $C_treg5 color00
\ $C_treg6 color01

			mov	$C_treg5 , __colortable
			mov	$C_treg6 , __colortable1
__backtask0
			mov	__colortable , $C_treg5
__backtask1
			mov	__colortable1 , $C_treg6
			
			jmpret	__backtask , __foretask

\ $C_treg3 vx, vy, vm, vf
\ $C_treg4 temp register
\ $C_treg5 temp register
\ $C_treg6 ptr to vgastruct
			rdword	$C_treg6 , $C_stTOS

			add	$C_treg2 , # 1
			and	$C_treg2 , # h_F
			rdlong	$C_treg3 , $C_treg6

\ $C_treg3 vx, vy, vm, vf
\ $C_treg4 temp register
\ $C_treg5 temp register
\ $C_treg6 ptr to vgastruct + 4
			add	$C_treg6 , # 4
			rdlong	__cursoraddr , $C_treg6

			mov	__screen , __cursoraddr
			shr	__screen , # h_10
			and	__cursoraddr , $C_fAddrMask
			add	__cursoraddr , __screen

			mov	$C_treg5 , $C_treg3
			shr	$C_treg5 , # h_10
			and	$C_treg5 , # 3
			shl	$C_treg5 , # h_18
			test	$C_treg5 , cnt  wz
	if_z		mov	__cursoraddr , # 0

\ __cursoraddr is now the cursor position
			
			jmpret	__backtask , __foretask

\ $C_treg3 color (16 bit)
\ $C_treg4 temp register
\ $C_treg5 temp register
\ $C_treg6 temp register
			mov	$C_treg6 , $C_treg1
			mov	$C_treg4 , $C_treg2
			shl	$C_treg4 , # 1
			add	$C_treg6 , $C_treg4

			rdword	$C_treg3 , $C_treg6

			mov	$C_treg6 , # __colortable
			add	$C_treg6 , $C_treg2
			add	$C_treg6 , $C_treg2
			movd	__backtask0 , $C_treg6	
			add	$C_treg6 , # 1
			movd	__backtask1 , $C_treg6

			jmpret	__backtask , __foretask

			mov	$C_treg5 , $C_treg3
			shl	$C_treg5 , # h_10	
			or	$C_treg5 , $C_treg3

			mov	$C_treg6 , $C_treg3
			shl	$C_treg6 , # 8

			mov	$C_treg4 , $C_treg3
			and	$C_treg4 , # h_FF
			or	$C_treg6 , $C_treg4

			mov	$C_treg4 , $C_treg3
			andn	$C_treg4 , # h_FF
			shl	$C_treg4 , # h_10
			or	$C_treg6 , $C_treg4

			jmp	# __backtask0





__start
			mov	__backtask , # __backtask
			spopt
__mainloop
                        mov     __2curhv , __hvbase

                        mov     __3curscreen , __screen
\ number of vertical lines
                        mov     __4y , # F

			mov	__8colortablel16 , # __colortable
			shl	__8colortablel16 , # h_10
__Dline                        
\ number of horizontal chars
                        mov     __5x , # h_20
                        mov     vscl , __linevscl
			add	__1line , __8colortablel16
                        
__Ctile
			cmp	__3curscreen , __cursoraddr wz

                        rdword  __6tile , __3curscreen
                        shl     __6tile , # 6 
                        add     __6tile , __1line
                        
                        rdlong  __7pixels , __6tile
                        shr     __6tile , # h_10

                        movd    __Bcolor , __6tile
                        add     __3curscreen , # 2

	if_z		mov	__7pixels , $C_fLongMask
          
__Bcolor
                        waitvid __colortable , __7pixels
                        djnz    __5x , # __Ctile

\ number of horizontal chars *2                        
                        sub     __3curscreen , # h_40
                        
                        mov     __5x , # 1
                        jmpret  __Fret , # __9hsync

\ next row of pixel in character                        
                        add     __1line , # 4
                        and     __1line , # 7C wz
        if_nz           jmp     # __Dline              
        
\ number of horizontal chars *2                        
                        add     __3curscreen , # h_40
                        djnz    __4y , # __Dline
                        
                        mov    __5x , # h_B
                        jmpret  __Fret , # __Eblank_line

                        mov     __5x , # 2
                        jmpret  __Fret , # __Avsync

                        mov     __5x , # h_1F
                        jmpret  __Fret , # __Avsync

                        jmp     # __mainloop
                        
__Avsync                      
                        xor     __2curhv , # 1
__Eblank_line
                        mov     vscl , __hpix
                        waitvid __2curhv , # 0

			jmpret	__foretask , __backtask

__9hsync
                        mov     vscl , # h_A
                        waitvid __2curhv , # 0

                        mov     vscl , # h_4B
                        
                        xor     __2curhv , # 2
                        waitvid __2curhv , # 0

                        mov     vscl , # h_2B
                        xor     __2curhv , # 2
                        waitvid __2curhv , # 0

                        djnz    __5x , # __Eblank_line
__Fret
                        ret



;asm a_vga


}





