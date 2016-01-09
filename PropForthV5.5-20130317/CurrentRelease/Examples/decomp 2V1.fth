
fl

[ifdef Decompiler
forget Decompiler
]

: Decompiler   ." PropForth 5 decompiler V2.1 - Peter Jakacki 120630 " ;
hex

: is	over = if drop r> W@ execute else r> 2+ >r then ;
: >w	FFFF and ;


\ Define constants for known words with extensions etc
' exit wconstant #exit
' litw wconstant #litw
' litl wconstant #litl
' (+loop) wconstant #+loop
' (loop) wconstant #loop
' 0branch wconstant #0branch
' branch wconstant #branch
' cq wconstant #cq
' dq wconstant #dq

' _xasm2>1 wconstant #xasm21
' _xasm2>0 wconstant #xasm20
' _xasm1>1 wconstant #xasm11
' _xasm2>1IMM wconstant #xasm2I
' _xasm2>flag wconstant #xasmF
' _xasm2>flagIMM wconstant #xasmFI

' lxasm wconstant #lxasm
' doconw wconstant #doconw
' dovarw wconstant #dovarw
' dovarl wconstant #dovarl
' doconl wconstant #doconl
' 2>r wconstant #do

	wvariable indent
	wvariable wcnt
	wvariable dflgs
	
: +indent	2 indent W+! ;
: -indent	indent W@ 2- 0 max indent W! ;

: .HEAD	
	dflgs C@ 1 and 
	if 
	  dup (dumpm) dflgs C@ 4 and if W@ .word space else drop then
	  indent W@ spaces 
	else drop then
;

: nl		wcnt W@ if dflgs C@ 1 and 0= if cr indent W@ 4 max spaces then 0 wcnt W! then ;
: nc		1 wcnt W+! ;

	variable labels 1C allot	\ room for 8 longs = address+type each
: LABEL! \ ( code addr - )	 
	w>l labels 
	begin dup W@ dup 
	  if   \ code+addr labels (label)
	    2 ST@ >w =		\ address match?
	    if L! 1			\ yes, replace previous contents and exit
	    else  4+ 0			\ no, skip this entry and continue
	    then 
	  else				\ null entry found, use this one and exit
	    drop L! 1			\ 
	  then 
	until   
; 
: LABEL? \ ( addr -- code )		\ Find a label and return with it's code or 0 if none
	labels 
	begin
	  2dup W@ = 
	  if 2+ W@ nip 1  \ ( code 1 )
	  else 4+ dup L@ 0= if 2drop 0 1 else 0 then  \ ( 0 1 -OR- addr labels flg )
	  then
	until
;

: .atrs \ ( atr -- )
	dup 40 and if ."  immediate" then
	20 and if ."  exec" then
;
: .name		pfa>nfa C@++ 1F and bounds do i C@ emit loop nc ;

 variable maxref	\ maintain a pointer to the most forward reference in the word begin decompiled
			\ to determine the real end of it (ignore exits before then)
: .branch	
	dflgs C@ 2 and if ."  >" dup .word then 
	maxref W@ max maxref W! 2+ ;

: .lit		dup 9 > if ." h" then <# #s #> .cstr nc ;
: =long	alignl dup L@ space .long 4+ ;
: =word	dup W@ space  .lit 2+ ;
: =imm		=word =word ;
: =branch1	over dup W@ + LABEL!    dup W@ over + .branch ;

: .ext  \ ( adr1 pfa -- adr2 )
	#xasm21	is =word
	#xasm20	is =word
	#xasm11	is =word
	#xasm2I is =imm
	#xasmF  is =word
	#xasmFI is =imm
	#litl	is =long
	#lxasm	is =long
	dup	\ these words need a copy of the pfa
	#loop	is =branch1
	#+loop	is =branch1
	#0branch is =branch1
	#branch	is =branch1
	2drop
	;


: branch@  \ ( addr -- addr+2 branch )
	2+ dup W@ over + >w ;


: =litw	dflgs C@ 8 and if ." litw " then 2+ dup W@ .lit 2+ ;

: =begin	dup .HEAD nl ." begin " +indent nc ;
: =until	-indent ." until" nc nl 4 over LABEL! ;
: =then	dup .HEAD ." thens " -indent nc nl ;
: =else	." else "  nc over 2+ 0 swap LABEL! 1 over LABEL! ;
: =branch	branch@ 2dup > if =until  else =else then .branch ;
: =0branch	branch@ 2dup > if =until else nl ." if" nc +indent 1 over LABEL! then .branch ; 
: =do		nl ." do " 2+  +indent ;
: =loop	." loop" -indent nc nl 4+ ;
: =+loop	." +loop" -indent nc nl 4+ ;
: =cq		2+ 63 emit 22 emit space dup .cstr 22 emit dup C@ 1+ + ;
: =dq		2+ 2E emit 22 emit space dup .cstr 22 emit dup C@ 1+ + ;

  
: .LABEL \ ( addr -- )
	LABEL?
	1 is =then
	4 is =begin
	drop
;
: .code \ ( addr -- addr+ )
	dup W@ 
	\ Preprocess structures and literals
	#0branch	is =0branch
	#branch		is =branch
	#litw		is =litw 
	#do		is =do
	#loop		is =loop
	#+loop		is =+loop
	#cq		is =cq
	#dq		is =dq

	dup #exit =
	  if over 2+ maxref W@ > if drop cr ." ;" 2+ exit then then
	wcnt W@ d8 > if nl then              \ limit length of line
	\ otherwise the default is to print the name and handle any extensions
	dup .name swap 2+ swap .ext 
	;

: codeword
  	dup .HEAD 
	dup 40 bounds do i (dumpm) i 10 bounds do i COG@ .long space 4  +loop 10 +loop
;

: _decomp
    4 indent W! nc nl
    dup 
    if  \ must be non-zero otherwise the word does not exist
      dup 800 < 
      if
        codeword
      else \ ( addr -- )
        begin
	    alignw
	    \ nc
	    dup .LABEL
	    dup .HEAD
	    dup W@ swap .code 
	    wcnt W@ if space then  \ add a space after each word but not at the start of a newline
	
	    \ determine when to stop decompiling
	    swap dup #exit = 2 ST@ maxref W@ > and  \ ( addr+2 pfa flag ) end of code? 
	    over #lxasm = or swap #doconw = or  \ ( addr+2 flag ) single operation?
\	    fkey? and 1B = or	\ or if escape key hit
        until
      then
    then
    drop
;
: =dovarw	." wvariable " .name ;
: =dovarl	." variable " .name  ;
: =doconw	dup 2+ W@ .lit ."  wconstant " .name ;
: =doconl	dup 2+ alignl L@ .lit ."  constant " .name ;

: .def \ ( 1stpfa -- flg  )
	#dovarw is =dovarw
	#dovarl is =dovarl
	#doconw is =doconw
	#doconl is =doconl
	." : "
	drop dup .name
	_decomp
; 
: >decomp  \ ( addr -- ) 
    hex 0 maxref W!
    labels 20 0 fill	\ clear labels	
    6 iodis dup _decomp		\ silent listing first 
    10 delms
    6 7 ioconn
    dup >r
    cr 
    dup pfa>nfa C@ 80 and	\ Forth tag?
      if dup W@ .def		\ Yes, process as a Forth definition
      else ." ASMCODE " dup .name codeword drop then 
    r> pfa>nfa C@ .atrs 
    cr cr 
;
  
{
 To enable all addresses and references to be listed with one word per line use: -1 details
 To hide all addresses and references use: 0 details
}
: details  dflgs C! ;
	
: decompall
	' dup 0= if drop lastnfa else pfa>nfa then 
	begin
	  dup nfa>pfa >decomp
	  nfa>next dup 0=
          fkey? and dup 20 = if begin fkey? and until then
	  1B = or
 	  until
	drop
;
  
: decomp		\ use in the form "decomp name"
   '  >decomp 
    6 7 ioconn		\ restore in case of errors
    ;

\ ********************************************************



{
Usage:
decomp interpretpad

: interpretpad
    1 >in W! 
    begin bl parseword                                                           
      if pad>in nextword find dup                                                
        if dup -1 =                                                              
          if drop compile?                                                       
            if w, else  execute thens                                            
            0 else  2 = 
            if execute 0 else  compile? 
              if execute 0 else  pfa>nfa _p? 
                if ." IMMEDIATE WORD " .strname cr else  drop thens 
                clearkeys -1 thens 
              else  drop dup C@++ fisnumber 
              if C@++ fnumber compile? 
                if dup 0 hFFFF between 
                  if $C_a_litw w, w, else  $C_a_litl w, l, thens 
                  0 else  compile? 
                  if freedict thens 
                  1 state andnC! _p? 
                  if _udf .strname cr thens 
                  clearkeys -1 thens 
                else  -1 thens 
              until
            
;
}
\ ****************** END ********************

