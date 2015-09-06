\ HINWEIS: Admistra und Regnatix mit Standard Propforth 3.5c nicht VGA

fl

hex

: build_hiresvga ;


\ works with VGA_HiRes_Text driver, provides 2 screens, each 32x128 chars
\
\ the row colors which are applied are words in the form
\
\ BACKGROUND FOREGROUND
\ RRGGBB00   RRGGBB00
\ 00001100   11111100
\
1 cogd 	    wconstant (rowcolor)	\ 64 words, provides the row color for each line
1 cogd 80 + wconstant (vgasync)		\ a long, set to 0, will be set to -1 the next vertical synch time
1 cogd 84 + wconstant (vgafont)		\ a word which points to the font used for the driver

1 cogd 86 + wconstant (vga0ptr)		\ a word pointer to the structure for vga0
1 cogd 96 + wconstant (vga1ptr)		\ a word pointer to the structure for vga1
1 cogd A6 + wconstant (vgacolors)	\ a pointer to 16 colors, referenced by tge vga consonles
\ 1 cogd C6 + wconstant freespace	\ 2A bytes free space


\ the structure for the vga consoles
\ 
\ : vx ;	\ a char, the horizontal position of the cursor (the column) 0 - 7F
: vy 1+ ;	\ a char, the vertical position of the cursor (the row) 0 - 1F
: vm 2+ ;	\ a char, the mode of the vga cursor
: vf 3 + ;	\ a char, the flag which indicates we are waiting for the second char of a 2 byte sequence to the console
\ : vo 4+ ;	\ a word, the offset into the screen buffer of the cursor
: vs 6 + ;	\ a word, a pointer to the screen buffer, 20 x 80 bytes or 1000 bytes
: vyo 8 + ;	\ a char, y offset (row offset) to apply to the cursor, 0 for vga0, 20 for vga1
: vci 9 + ;	\ a char, the current index of the color being used
: va A + ;	\ a char, if 0 autoscroll is on
\ : vfree B + ; 5 bytes free per structure
\
\ vo ( struct_addr -- n1)
: vo@ 4+ W@ ;		\ gets the current offset of the cursor into the screen buffer
\ vo! ( struct_addr n1 -- struct_addr )
: vo! over 4+ W! ;	\ stores the offset

\ vs@ ( struct_addr -- addr) 
: vs@ 6 + W@ ;			\ gets the screen buffer pointer
\ vso@ ( struct_addr -- addr )
: vso@ dup vs@ swap vo@ + ;	\ gets the pointer to the character pointed at the cursor
\ vc@ ( struct_addr -- currentcolor)
: vc@ vci C@ 2* (vgacolors) + W@ ;

\ (lb) ( addr -- ) blank a line
: (lb) 20202020 swap 20 0 do 2dup L! 4+ loop 2drop ;

\ 00 - clear the screen and home the cursor
\ 01 nn - set the current backgorund color 00RR GGBB
\ 02 nn - set the current foregraound color 00RR GGBB
\ 03 - set autoscroll on
\ 04 - set autoscroll off
\ 08 - backspace
\ 09 - tab every 8 spaces
\ 0D - carriage return and line feed
\ 0A nn - set cursor to column nn (00 - 7F)
\ 0B nn - set cursor to row nn (00 - 1F)
\ 0C nn - set current line color to nn (00 - 0F) last color set is the current color
\ 0E nn - echo nn to the screen
\ 0F nn - set cursor mode to nn ( 0 - 7)
\ 0 - cursor off
\ 1 - block cursor on
\ 2 - block cursor on, blink slow
\ 3 - block cursor on, blink fast
\ 4 - cursor off
\ 5 - underscore cursor on
\ 6 - underscore cursor on, blink slow
\ 7 - underscore cursor on, blink fast
 

\ (vgaemit1) ( addr -- addr ) scroll the screen if necessary, and clear the line if necessary
: (vgaemit1)
	dup vo@ 1000 and if
\ roll to the beginning of the screen
		dup va C@ if
			0 vo!
		else
\ scroll the screen
			dup vs@ dup 80 + swap
			3e0 0 do over L@ over L! 4+ swap 4+ swap loop 2drop
			f80 vo!
\ scroll the line colors
			dup vyo C@ 2* (rowcolor) + 3E bounds
			do i dup 2+ W@ swap W! loop
		then
	then
\ clear the line if necessary
	dup vo@ 7f and 0= if
\ clear the line
		dup vso@ (lb)
	then
;

\ (vgap) ( addr c1 -- addr )
: (vgap) over vso@ C! dup vo@ 1+ vo! ;

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
			dup vs@ 1000 bounds do i (lb) 80 +loop	\ clear the screen

			dup vc@ over vyo C@ 2* (rowcolor) + 40 bounds	\ set the colors to the current color
			do dup i W! 2 +loop drop
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
			drop dup vo@ 1- 0 max vo!		\ back up the offset to the previos character
			bl over vso@ C!				\ write a blank to the current position
		else dup 9 = if
\ tab every 8 characters
			drop begin
				bl (vgap)
				dup vo@ 7 and 0=
			until
		else dup D = if
\ carriage return (auto line feed)
			drop dup vo@ 80 + 7f andn vo!		\ update the offset
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
			drop 2* 2* over vci C@ 2* (vgacolors) + 1+ C!
			
\		else dup 1 = if				\ addr forecolor vf  \ was bug v3.4 Patch20100912
		else dup 2 = if				\ addr forecolor vf

			drop 2* 2* over vci C@ 2* (vgacolors) + C!
		else dup A = if			\ addr x
			drop 7f and		\ addr x
			over C@ -	 	\ addr delta

			over vo@ +		\ addr offset 
			vo!			\ addr
		else dup B = if				\ addr y
			drop 1f and over vyo C@ +	\ addr y
			over vy C@ - 7 lshift	 	\ addr delta

			over vo@ +		\ addr offset 
			vo!			\ addr
		else dup C = if
			drop F and over vci C!
			dup vci C@ 2* (vgacolors) + W@	\ addr color
			over vy C@ 2* (rowcolor) + W!	\ addr
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
	dup vo@ 7f and over C!
	dup vo@ 7 rshift over vyo C@ + swap vy C!
;

\ (v0) ( c1 -- ) emit c1 to vga0
: (v0) (vga0ptr) swap (vgaemit) ;

\ (v1) ( c1 -- ) emit c1 to vga1
: (v1) (vga1ptr) swap (vgaemit) ;





\ 08000000 constant kbclock       \ demo board VGA pinout
\ 04000000 constant kbdata        \ demo board VGA pinout

00010000 constant kbclock         \ HIVE VGA pinout
00020000 constant kbdata          \ HIVE VGA pinout

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







\ which vga terminal is connected to the keyboard
wvariable vgakb


\ kbin ( -- c1) c1 - 0, no key available, else the keycode
: kbin
	(kbin3)
\ on key up, toss
	if drop 0 else
\ alt-tab - switch screens
		dup 89 = if vgakb W@ 0= vgakb W! drop 0 else
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
\ set the screen pointers
6000 (vga0ptr) vs W!
7000 (vga1ptr) vs W!

\ initialize the default colors
0 (vga0ptr) vci C! 4 (vga1ptr) vci C!

\ the y cursor offset for vga screen 1
20 (vga1ptr) vyo C!

\ clear the screens and home the cursors
(vga0ptr) 0 (vgaemit) (vga1ptr) 0 (vgaemit)

\ set the cursor modes
7  (vga0ptr) vm C! 2 (vga1ptr) vm C!

\ initialize variables
100 dup invga0 W! invga1 W!
(kbinit)
0 vgakb W!


begin
\ look for characters to be written to the vga screens	
	100 0 do
		invga0 W@ dup 100 and if drop else (vga0ptr) swap (vgaemit) 100 invga0 W! then
		invga1 W@ dup 100 and if drop else (vga1ptr) swap (vgaemit) 100 invga1 W! then
	loop
\ process input characters
	vgakb W@ if	
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

: _onboot onboot ;

: onboot _onboot (cog+) cog+ ;

: onreset0 cogid 0= if  3 >vga0 4 >vga1 50 delms 5 >con vgamon then ;

: _onreset onreset ;

: onreset _onreset
\ reconnect the cog to the vga consoles if it was previously connected
cogid cogvga0 W@ = if cogid >vga0 then 
cogid cogvga1 W@ = if cogid >vga1 then
;


{


fl

\ vt1 ( -- ) print out characters from 0 - 7f
: vt1
\ clear screen
	0 emit 
\ 16 lines of characters
	10 0 do
\ characters from 0 - 10 are control characters, so an E character first 
		10 0 do
			e emit i emit
		loop
		80 10 do
			i emit
		loop
	loop
;

\ vt2 ( -- ) cursor positioning
: vt2
\ clear screen
	0 emit 
	40 0 do
\ set cursor to 2i, 2
		a emit i 2* emit b emit i emit
\ output a character
		21  i + emit
\ set the line color
		c emit i emit
	loop
;

\ vt3 ( -- ) tabs
: vt3
\ set the default color to color 0 and clear the screen
	c emit 0 emit 0 emit
	60 0 do
		9 emit 21 i + emit 
	loop
;

\ vt4 ( -- ) cursor modes
: vt4
\ set the cursor to mid screen, and go though cursor modes
	B 2 do
		a emit 40 emit b emit 10 emit i .
		F emit i emit
		1 delsec
	loop
;

\ vt5 ( -- ) backspace
: vt5
\ set the cursor to 20, 2 and backspace to the beginning of the line
	a emit 20 emit b emit 2 emit
	20 0 do
		8 emit
	loop
;

\ vt6 ( -- ) carriage returns
: vt6
\ clear screen
	0 emit 
	30 0 do
		i . d emit
	loop
;

\ vt0 ( -- ) run through screen stuff
: vt0
vt1 4 delsec
vt2 4 delsec
vt3 4 delsec
vt4
vt5 4 delsec
vt6 4 delsec
;

\ vt ( -- )
: vt
\ set screen to no scroll
	3 emit vt0
\ set screen to scroll
	4 emit vt0
;


}