\ ANSI escape sequences for serial terminal interface
\ 20120704 change h_ for hex values in v5.0 - braino
\ 20101227 Line 27 "a >"  to "9 >" ; Line 67 "version" to "(version)" for propforthV4.0
\ 20101030 prof_braino original version

fl
\ ascii code for red text      " ESC[31m "
\ hex character codes            1b 5b 33 31 6d
\ forth code for ascii red text v4.0: 1b emit 5b emit 33 emit 31 emit 6d emit          
\ forth code for ascii red text v5.0: h_1B emit h_5B emit h_33 emit h_31 emit h_6D emit          

\ ascii escape sequence start with ESC

\ second char of two character is 64 to 95   (@ to _)  40h to 5Fh
\ multi char are esc + [ + (@ to ~) 64 to 126  40h to  7Eh
\ next is [   5Bh
\ m is for graphics mode colors attributes
{ : to57 csi ." 5;7f" ;  : to2010 csi ." 20;10f" ; }
\ f is for position, needs character not value           

: esc h_1B emit ;
: csi esc h_5B emit ;
: m ." m" ;    
: smallf ." f" ; 
: K ." K" ;
: semicolon ." ;" ;

\ v>c convert a value ( 0-9 ) for a digit character for emit 
: v>c h_30 + emit ;
\ .digits ( n -  ." emit as DECIMAL characters" ) for AT  convert 0-99 for emit
: .digits 
          dup h_9 > if h_0A u/mod v>c then \ greater than 9 mod decimal 10
          v>c ;
\ AT  ( x y - ) put cursor at x,y
: AT csi .digits semicolon .digits smallf ;

: home       csi ." 1;1f" ;
: clear      csi ." 2J" ; 
: preclear   csi ." 1J" ;
: postclear  csi ." 0J" ;
: cls home clear  ;
: clear-eol  csi h_0 .digits K ;
: clear-bol  csi h_1 .digits K ;
: clear-line csi h_2 .digits K ;
\ ATtributes  esc[ #;#m   = csi # ; #  m
: AToff csi h_30 emit m ; \ 0 off
: bold  csi h_31 emit m ; \ 1 bold 

\ : faint csi 32 emit m ; \  2 faint ? 
\ : italic     csi 33 emit m ; \  3 italic ? 
: underscore csi h_34 emit m ; \  4 underscore (mono) ? 

\ : sblink      csi 35 emit m ; \  5 slow blink PINK
\ : fblink      csi 36 emit m ; \  6 fast blink
: reverse    csi h_37 emit m ; \  7 reverse

\ : conceal  csi 38 emit m ; \  8 conceal
\ : crossout csi 39 emit m ; \ 9 crossed out ?
\ there are more...

\ decimal
\ hex

: black   csi 30 .digits m ; : onblack   csi 40 .digits m ; 
: red     csi 31 .digits m ; : onred     csi 41 .digits m ; 
: green   csi 32 .digits m ; : ongreen   csi 42 .digits m ; 
: yellow  csi 33 .digits m ; : onyellow  csi 43 .digits m ; 
: blue    csi 34 .digits m ; : onblue    csi 44 .digits m ; 
: magenta csi 35 .digits m ; : onmagenta csi 45 .digits m ;
: cyan    csi 36 .digits m ; : oncyan    csi 46 .digits m ; 
: white   csi 37 .digits m ; : onwhite   csi 47 .digits m ; 

\ hex
\ decimal   

cyan  onred (version) .cstr AToff st?  500 delms red oncyan
home cls clear
c" ASCII escape sequences loaded "  6 2 AT  clear .cstr cr cr  cr cr AToff 0 4 AT  (version) .cstr postclear  cr cr

