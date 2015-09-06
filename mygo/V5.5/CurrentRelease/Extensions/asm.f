fl

\ Copyright (c) 2010 Sal Sanci


1 wconstant build_asm


[ifndef $C_IP
    hC8 wconstant $C_IP
]

[ifndef $C_a_(+loop)
    h82 wconstant $C_a_(+loop)
]

[ifndef $C_a_(loop)
    h80 wconstant $C_a_(loop)
]

[ifndef $C_a_0branch
    h8D wconstant $C_a_0branch
]

[ifndef $C_a_2>r
    h79 wconstant $C_a_2>r
]

[ifndef $C_a__xasm1>1
    h1C wconstant $C_a__xasm1>1
]

[ifndef $C_a__xasm2>0
    h21 wconstant $C_a__xasm2>0
]

[ifndef $C_a__xasm2>1
    h16 wconstant $C_a__xasm2>1
]

[ifndef $C_a__xasm2>1IMM
    h13 wconstant $C_a__xasm2>1IMM
]

[ifndef $C_a__xasm2>flag
    h4 wconstant $C_a__xasm2>flag
]

[ifndef $C_a__xasm2>flagIMM
    h1 wconstant $C_a__xasm2>flagIMM
]

[ifndef $C_a_branch
    h46 wconstant $C_a_branch
]

[ifndef $C_a_debugonoff
    h63 wconstant $C_a_debugonoff
]

[ifndef $C_a_doconl
    h52 wconstant $C_a_doconl
]

[ifndef $C_a_doconw
    h4A wconstant $C_a_doconw
]

[ifndef $C_a_dovarl
    h4D wconstant $C_a_dovarl
]

[ifndef $C_a_dovarw
    h4F wconstant $C_a_dovarw
]

[ifndef $C_a_exit
    h61 wconstant $C_a_exit
]

[ifndef $C_a_litl
    h57 wconstant $C_a_litl
]

[ifndef $C_a_litw
    h5D wconstant $C_a_litw
]

[ifndef $C_a_lxasm
    hB2 wconstant $C_a_lxasm
]

[ifndef $C_a_next
    h63 wconstant $C_a_next
]

[ifndef $C_a_reset
    h91 wconstant $C_a_reset
]

[ifndef $C_a_rspop
    hAB wconstant $C_a_rspop
]

[ifndef $C_a_rspop_ret
    hB1 wconstant $C_a_rspop_ret
]

[ifndef $C_a_rspush
    h9C wconstant $C_a_rspush
]

[ifndef $C_a_rspush_ret
    hA2 wconstant $C_a_rspush_ret
]

[ifndef $C_a_stpop
    hA4 wconstant $C_a_stpop
]

[ifndef $C_a_stpop_ret
    hAA wconstant $C_a_stpop_ret
]

[ifndef $C_a_stpoptreg
    hA3 wconstant $C_a_stpoptreg
]

[ifndef $C_a_stpoptreg_ret
    hAA wconstant $C_a_stpoptreg_ret
]

[ifndef $C_a_stpush
    h95 wconstant $C_a_stpush
]

[ifndef $C_a_stpush_ret
    h9B wconstant $C_a_stpush_ret
]

[ifndef $C_fAddrMask
    hC5 wconstant $C_fAddrMask
]

[ifndef $C_fCondMask
    hC3 wconstant $C_fCondMask
]

[ifndef $C_fDestInc
    hC2 wconstant $C_fDestInc
]

[ifndef $C_fLongMask
    hC6 wconstant $C_fLongMask
]

[ifndef $C_fMask
    hC4 wconstant $C_fMask
]

[ifndef $C_resetDreg
    hC7 wconstant $C_resetDreg
]

[ifndef $C_rsBot
    hF2 wconstant $C_rsBot
]

[ifndef $C_rsPtr
    hCA wconstant $C_rsPtr
]

[ifndef $C_rsTop
    h112 wconstant $C_rsTop
]

[ifndef $C_stBot
    hD2 wconstant $C_stBot
]

[ifndef $C_stPtr
    hC9 wconstant $C_stPtr
]

[ifndef $C_stTOS
    hCB wconstant $C_stTOS
]

[ifndef $C_stTop
    hF2 wconstant $C_stTop
]

[ifndef $C_treg1
    hCC wconstant $C_treg1
]

[ifndef $C_treg2
    hCD wconstant $C_treg2
]

[ifndef $C_treg3
    hCE wconstant $C_treg3
]

[ifndef $C_treg4
    hCF wconstant $C_treg4
]

[ifndef $C_treg5
    hD0 wconstant $C_treg5
]

[ifndef $C_treg6
    hD1 wconstant $C_treg6
]

[ifndef $C_varEnd
    h112 wconstant $C_varEnd
]

[ifndef $S_baud
    hE100 wconstant $S_baud
]

[ifndef $S_cdsz
    hE0 wconstant $S_cdsz
]

[ifndef $S_con
    h7 wconstant $S_con
]

[ifndef $S_rxpin
    h1F wconstant $S_rxpin
]

[ifndef $S_txpin
    h1E wconstant $S_txpin
]

[ifndef $V_>in
    hDC wconstant $V_>in
]

[ifndef $V_>out
    hDA wconstant $V_>out
]

[ifndef $V_base
    hD2 wconstant $V_base
]

[ifndef $V_cds
    hD0 wconstant $V_cds
]

[ifndef $V_coghere
    hD8 wconstant $V_coghere
]

[ifndef $V_debugValue
    hCC wconstant $V_debugValue
]

[ifndef $V_debugcmd
    hCA wconstant $V_debugcmd
]

[ifndef $V_execword
    hD4 wconstant $V_execword
]

[ifndef $V_lasterr
    hDE wconstant $V_lasterr
]

[ifndef $V_lc
    h83 wconstant $V_lc
]

[ifndef $V_numpad
    hA8 wconstant $V_numpad
]

[ifndef $V_pad
    h4 wconstant $V_pad
]

[ifndef $V_state
    hDF wconstant $V_state
]

[ifndef $V_t0
    h84 wconstant $V_t0
]

[ifndef $V_t1
    h86 wconstant $V_t1
]

[ifndef $V_tbuf
    h88 wconstant $V_tbuf
]



\
\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[ifndef variable
: variable
	lockdict create $C_a_dovarl w, 0 l, forthentry freedict
;
]
\
\
\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
[ifndef 2*
: 2* _xasm2>1IMM h0001 _cnip h05F _cnip ; 
]
\ padnw ( -- t/f ) move past current word and parse the next word, true if there is a next word
[ifndef padnw
: padnw
	nextword
	parsebl
;
]

\ aallot ( n1 -- ) add n1 to coghere, allocates space in the cog or release it, n1 is # of longs
[ifndef aallot
: aallot
	coghere W+!
	coghere W@ par >=
	if
		 hAA ERR
	then
;
]
\ cog, ( x -- ) allocate 1 long in the cog and copy x to that location
[ifndef cog,
: cog,
	coghere W@ COG!
	1 aallot
;
]

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

\
\ forget ( -- ) wind the dictionary back to the word which follows - caution
[ifndef forget
: forget
	parsenw (forget)
;
]



wvariable _numPatches

: localLabelPrefix
	c" __"
;

\ defineLocalLabel ( addr cstr  -- )
: defineLocalLabel
	lockdict ccreate $C_a_doconw w, w, forthentry freedict
;
\ patchName ( n -- cstr) uses tbuf
: patchName
	c" __%%" tbuf ccopy <# # # # # #> tbuf cappend tbuf
;


\ definePatch ( dstflag addr cstr1 cstr2 -- ) create a word named cstr2
\
\ worddefinedbycstr2 ( -- cstr1 n1) 
\
\
: definePatch
	lockdict ccreate
	$H_cq w, dup here W@ ccopy C@ 1+ allot herewal
	$C_a_litw w, h1FF and swap if h8000 or then w, 
	$C_a_exit w, 
	forthentry freedict
;
\ addPatch ( dstflag addr cstr1 -- )
: addPatch
	_numPatches W@ patchName definePatch
	1 _numPatches W+!
;

\
\
\ _ec ( cstr -1|n1 -- cstr 0 | n1 -1) 
: _ec dup -1 = if drop 0 else nip h10 lshift -1 then ;

\ oc= ( cstr1 cstr2 -- cstr1 t/f)
: oc= over cstr= ;


\ cnd1 ( cstr -- cstr -1 | cstr n1 ) process a subset of conditions 
: cnd1
	c" if_always" oc=
		if h003C else
	c" if_never" oc=
		if h0000 else
	c" if_e" oc=
		if h0028 else
	c" if_ne" oc=
		if h0014 else
	c" if_a" oc= 
		if h0004 else
	c" if_b" oc=
		if h0030 else
	c" if_ae" oc=
		if h000C else
	c" if_be" oc=
		if h0038 else
	c" if_c" oc=
		if h0030 else
	c" if_nc" oc=
		if h000C else
	c" if_z" oc=
		if h0028 else
	c" if_nz" oc=
		if h0014 else
	c" if_c_eq_z" oc=
		if h0024 else
	c" if_c_ne_z" oc=
		if h0018 else
	c" if_c_and_z" oc=
		if h0020 else
	c" if_c_and_nz" oc=
		if h0010 else
	-1 
		thens
; 

\ cnd2 ( cstr -- cstr -1 | cstr n1 ) process a subset of conditions  
: cnd2
	c" if_nc_and_z" oc=
		if h0008 else
	c" if_nc_and_nz" oc=
		if h0004 else
	c" if_c_or_z" oc=
		if h0038 else
	c" if_c_or_nz" oc=
		if h0034 else
	c" if_nc_or_z" oc=
		if h002C else
	c" if_nc_or_nz" oc=
		if h001C else
	c" if_z_eq_c" oc=
		if h0024 else
	c" if_z_ne_c" oc=
		if h0018 else
	c" if_z_and_c" oc=
		if h0020 else
	c" if_z_and_nc" oc=
		if h0008 else
	c" if_nz_and_c" oc=
		if h0010 else
	c" if_nz_and_nc" oc=
		if h0004 else
	c" if_z_or_c" oc=
		if h0038 else
	c" if_z_or_nc" oc=
		if h002C else
	c" if_nz_or_c" oc=
		if h0034 else
	c" if_nz_or_nc" oc=
		if h001C else
	-1
		thens
; 

\ cnd ( cstr -- cstr 0 | n1 -1 ) process the condition statement n1 is the mask to apply id successful 
: cnd 
	cnd1
	dup -1 =
	if
		drop
		cnd2
	 then
	_ec
; 

\ ai1 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes 
: ai1
	c" abs" oc=
		if hA8BC else
	c" absneg" oc=
		if hACBC else
	c" add" oc=
		if h80BC else
	c" addabs" oc=
		if h88BC else
	c" adds" oc=
		if hD0BC else
	c" addsx"oc=
		if hD8BC else
	c" addx" oc=
		if hC8BC else
	c" and" oc=
		if h60BC else
	c" andn" oc=
		if h64BC else
	c" cmp" oc=
		if h843C else
	c" cmps" oc=
		if hC03C else
	c" cmpsub" oc=
		if hE03C else
	c" cmpsx" oc=
		if hC43C else
	c" cmpx" oc=
		if hCC3C else
	c" djnz" oc=
		if hE4BC else
	c" max" oc=
		if h4CBC else
	c" maxs" oc=
		if h44BC else
	c" min" oc=
		if h48BC else
	-1
		thens
;

\ ai2 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes  
: ai2
	c" mins" oc=
		if h40BC else
	c" mov" oc=
		if hA0BC else
	c" movd" oc=
		if h54BC else
	c" movi" oc=
		if h58BC else
	c" movs" oc=
		if h50BC else
	c" muxc" oc=
		if h70BC else
	c" muxnc" oc=
		if h74BC else
	c" muxnz" oc=
		if h7CBC else
	c" muxz" oc=
		if h78BC else
	c" neg" oc=
		if hA4BC else
	c" negc" oc=
		if hB03C else
	c" negnc" oc=
		if hB4BC else
	c" negnz" oc=
		if hBCBC else
	c" negz"oc=
		if hB9BC else
	c" or" oc=
		if h68BC else
	c" rdbyte" oc=
		if h00BC else
	c" rdlong" oc=
		if h08BC else
	c" rdword" oc=
		if h04BC else
	-1
		thens
;

\ ai3 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes  
: ai3
	c" rcl" oc=
		if h34BC else
	c" rcr" oc=
		if h30BC else
	c" rev" oc=
		if h3CBC else
	c" rol" oc=
		if h24BC else
	c" ror" oc=
		if h20BC else
	c" sar" oc=
		if h38BC else
	c" shl" oc=
		if h2CBC else
	c" shr" oc=
		if h28BC else
	c" sub" oc=
		if h84BC else
	c" subabs" oc=
		if h8CBC else
	c" subs" oc=
		if hD4BC else
	c" subsx" oc=
		if hDCBC else
	c" subx" oc=
		if hCCBC else
	c" sumc" oc=
		if h90BC else
	c" sumnc" oc=
		if h94BC else
	c" sumnz" oc=
		if h9CBC else
	c" sumz" oc=
		if h98BC else
	c" test" oc=
		if h603C else
	-1
		thens
;

\ ai4 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes  
: ai4
	c" tjnz" oc=
		if hE83C else
	c" tjz" oc=
		if hEC3C else
	c" waitcnt" oc=
		if hF8BC else
	c" waitpeq" oc=
		if hF03C else
	c" waitpne" oc=
		if hF43C else
	c" waitvid" oc=
		if hFC3C else
	c" wrbyte" oc=
		if h003C else
	c" wrlong" oc=
		if h083C else
	c" wrword" oc=
		if h043C else
	c" xor" oc=
		if h6CBC else
	c" jmpret" oc=
		if h5CBC else
	-1
		thens
;

\ asminstds ( cstr -- cstr 0 | n1 -1 ) process op codes with a destination and a source
: asminstds
	ai1 dup -1 =
	if
		drop ai2 dup -1 =
		if
			drop ai3 dup -1 =
			if
				drop ai4
			then
		then
	then
	_ec
;
 
\ asminstd ( cstr -- cstr 0 | n1 -1 ) process opcodes with a destination only 
: asminstd c" clkset"  oc= if h0C7C0000 else c" cogid" oc= if h0CFC0001 else c" coginit" oc= if h0C7C0002 else
c" cogstop" oc= if h0C7C0003 else c" lockclr" oc= if h0C7C0007 else c" locknew" oc= if h0CFC0004 else
c" lockret" oc= if h0C7C0005 else c" lockset" oc= if h0C7C0006 else 0 thens dup if nip -1 then ;

\ asminsts ( cstr -- cstr 0 | n1 -1 ) process opcodes with a source only
: asminsts c" jmp" oc= if h5C3C else c" long" oc= if 0 else -1 thens _ec ;

\ _mc ( src dst -- n) 
: _mc h9 lshift or h5CFC0000 or ;

wvariable amacroptr
variable orgoffset

: amacro
	c" jnext" oc=
		if $C_a_next h5C7C0000 or else
	c" jexit" oc=
		if $C_a_exit h5C7C0000 or else
	c" spush" oc=
		if $C_a_stpush $C_a_stpush_ret _mc else
	c" spopt" oc=
		if $C_a_stpoptreg $C_a_stpoptreg_ret _mc else
	c" spop" oc=
		if $C_a_stpop $C_a_stpop_ret _mc else
	c" rpush" oc=
		if $C_a_rspush $C_a_rspush_ret _mc else
	c" rpop" oc=
		if $C_a_rspop $C_a_rspop_ret _mc else
	0
		thens
;

' amacro amacroptr W!

\ asminst ( cstr -- cstr 0 | n1 -1 ) process the only opcode with no dest or source
: asminst
	c" nop" oc=
		if 1 else
	c" ret" oc=
		if h5C7C0000 else
	amacroptr W@ execute
		thens

	dup
	if
		dup 1 = 
		if
			drop 0
		then
		nip  -1
	then
;

wvariable _asmerror 0 _asmerror W!

\ asmerr ( cstr cstr -- ) report an error and consume all the keys left
: asmerr .cstr .cstr cr padbl clearkeys -1 _asmerror W! ;


\ evalop3 ( t/f cstr -- cstr n1 ) t/f 0 - source op, -1 dest op, evaluate the operand as either as a forth word, a number,
\ or a local label
: evalop3
	hFDEB0317 rot2
\ forth word
	dup 
	find -1 =
\ ( t/f cstr addr flag -- )
	if
\ need to make sure the stack value is right
\ ( t/f cstr addr  -- )
		execute
\ ( t/f cstr value -- )
		rot drop
\ ( cstr value -- )
	else
\ ( t/f cstr cstr -- )
		localLabelPrefix npfx
		if
\ ( t/f cstr -- )
			tuck
\ ( cstr t/f cstr -- )
			coghere W@ swap addPatch
			0
\ ( cstr 0 -- )
		else
\ ( t/f cstr -- )
			nip dup
\ ( cstr cstr -- )
			dup C@++ xisnumber
			if
				C@++ xnumber
			else
				c" ? " asmerr 0
			then
\ ( cstr value -- )
		then
	then
\ ( cstr value -- )
	rot hFDEB0317 <>
	if
		over c" ? " asmerr
	then
;

\ evalop2 ( t/f cstr -- n1 ) t/f 0 - source op, -1 dest op, evaluate the operand as either as a forth word, a number,
\ or a local label
: evalop2
	evalop3
\ ( cstr value -- )
	nip
;

\ evalop1 ( t/f cstr -- n1 ) t/f 0 - source op, -1 dest op, evaluate the operand as either as a forth word, a number,
\ or a local label
: evalop1
	evalop3
\ ( cstr value -- )
	dup 0 h1FF between
	if
		nip
	else
		drop c" ? " asmerr 0
	then
;

\ evalop ( t/f cstr -- n1 ) t/f 0 - source op, -1 dest op, evaluate the operand as either as a forth word, a number,
\ or a local label
: evalop
	evalop1 h1FF and
;

\ asmsrc ( n1 -- n1 ) n1 is the asm opcode, can be modified to set the immediate bit, the operand is evaluated as
\ a forth word/number
: asmsrc
	padnw 
	if
		pad>in c" #" cstr=
		if
			h00400000 or padnw
		else
			-1
		then
		if
			0 pad>in evalop or 0
		else
			-1
		then
	else
		-1
	then
	if
		c" Source Operand" c"  ?" asmerr
	then
;

\ asmdst ( n1 -- n1 ) n1 is the asm opcode
: asmdst
	padnw
	if
		-1 pad>in evalop h9 lshift or 0
	else
		-1
	then
	if
		." Dest Operand" c"  ?" asmerr
	then
;

\ (label) ( n1 n2 -- n3 n4 ) check to make sure the rest of the pad is empty
\ if not generate an error and set n3 = -1 & n4 = 0
: (label)
	padnw
	if
		pad>in c" Unexpected data after a label:" asmerr drop -1 swap
	then
;

\ asmopend ( n2 n1 -- n3 ) or in the update conditions
: asmopend padnw
if begin pad>in dup 1+ C@ 27 <> 
	if
		dup c" wc" cstr= if drop h01000000 or else
		dup c" wz" cstr= if drop h02000000 or else
		dup c" wr" cstr= if drop h00800000 or else
		dup c" nr" cstr= if drop hFF7FFFFF and else
		c" Unexpected word " asmerr then then then then  
	else drop padbl then
	padnw 0=
until then
dup 0= if nip else hFFC3FFFF and or then ;

\ asmdstsrc ( n1 -- n1 )
: asmdstsrc
	asmdst padnw 
	if
		pad>in c" ," cstr=
		if
			asmsrc 0
		else
			-1
		then
			else -1
	then
	if
		." Expected" c"  ," asmerr
	else
		asmopend
	then
;

\ asmdone ( cogstart -- )
: asmdone
	_numPatches W@
	if
	_numPatches W@ 0 
		do
			i patchName find
			if
				execute
\ ( cstr patch_addr -- )
				swap find
				if
\ ( patch_addr addr -- )
					execute
\ ( patch_addr patch_data -- )
					swap dup h8000 and swap h7FFF and swap
\ (  patch_data patch_addr destFlag -- )
					over COG@ swap
\ (  patch_data patch_addr ASMINST destFlag -- )
					if
\ (  patch_data patch_addr ASMINST -- )
						rot h9 lshift or swap COG!
					else
						rot or swap COG!
					then
				
				else
\ ( patch_addr cstr -- )
					nip c" Undefined Label "
					asmerr
					cr
				then
			else
				c" Undefined Patch " asmerr
				cr
			then
		loop
	then

	_asmerror W@
	if
		drop
	else

		coghere W@
		." lockdict create " padnw
		if
			pad>in .cstr space
		else
			." defasm "
		then
		." forthentry" cr
		." $C_a_lxasm w, "
		2dup orgoffset L@
		+ h68 emit u. space orgoffset L@ + h68 emit u. 
		."  1- tuck - h9 lshift or here W@ alignl h10 lshift or l," cr
		swap 0 rot2
		do
			
			i COG@ dup 0=
			if
				drop ." 0 l, "
			else
\				h68 emit base W@ h10 base W! swap u. base W!
				h7A emit base W@ h40 base W! swap u. base W!
				." l, "
			then
			1+ dup h8 >=
			if
				drop
				0 cr
			then
		loop
		drop
		cr ." freedict" cr
	then
;

\ asmline ( -- t/f )
: asmline
	parsebl dup
	if
		pad>in 1+ C@ dup h27 <> swap h5C <> and and
	then
	0=
\ not a blank line, and not a comment line
	if
		padbl
		0 0
	else
		pad>in c" ;asm" name= 

\ assembler done
		if
			-1 0
		else
\ we have a local label
			pad>in localLabelPrefix npfx
			if
				coghere W@ orgoffset L@ + pad>in defineLocalLabel
				0 0 (label) nextword
			else
\ process the condition, default to "if_always"
				pad>in cnd
				if
					padnw
					if
						0 swap -1
					else
						c" Opcode"
						c"  ?" asmerr
						-1 0
					then
				else
					drop 0 h003C0000 -1
				then
			then
		then
	then

	if
		pad>in asminst
\ process in the op-code, source, dest, and update flags
		if
			asmopend cog,
		else
			asminsts
			if
				asmsrc asmopend cog,
			else
				asminstd
				if
					asmdst asmopend cog,
				else
					asminstds
					if
						asmdstsrc cog,
					else
						2drop 0 pad>in evalop2 cog, nextword
	thens
;

\ _rasm ( asmaddr -- )
: _rasm
	base W@ swap hex
	coghere W@ - orgoffset L!
	1 coghere W+!
	lockdict
	0 _asmerror W!
	0 c" __%%ASM" defineLocalLabel
	0 _numPatches W!
	coghere W@
	begin
		accept
		0 >in W!
		asmline
		
		dup 0=
		if
			parsenw dup
			if
				c" ?" swap asmerr
			else
				drop
			then
		then
		_asmerror W@ or
	until

	_asmerror W@
	if
		drop
	else
		cr cr
		asmdone
	then

	cr cr

	padnw
	drop
	base W!

	c" __%%ASM" (forget)

	freedict
;


\ :rasm ( asmaddr -- )
: :rasm
	coghere W@ swap _rasm coghere W!
;

: :asm
	coghere W@ _rasm
;
