\ Copyright (c) 2010 Sal Sanci

fl

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

\ stringmap mapname ( -- )
[ifndef stringmap
: string/wordmap
	create forthentry $C_a_dovarw w,
;
]

\ string/word ( cstr word -- )
[ifndef string/word
: string/word
	swap here W@ over C@ 1+ allot herewal ccopy w,
;
]  

\ string/word_lookup ( cstr map -- cstr 0 | word -1)
[ifndef string/word_lookup
: string/word_lookup
	0 rot2
	begin

		2dup cstr=
		if
			C@++ + alignw dup W@ 1 ST! -1 2 ST! -1
		else
			C@++ + alignw 2+ dup C@ 0=
		then
	until
	drop swap
;
]
\ string/long ( cstr long -- )
[ifndef string/long
: string/long
	swap here W@ over C@ 1+ allot herewal ccopy l,
;
]  

\ string/long_lookup ( cstr map -- cstr 0 | long -1)
[ifndef string/long_lookup
: string/long_lookup
	0 rot2
	begin

		2dup cstr=
		if
			C@++ + alignl dup L@ 1 ST! -1 2 ST! -1
		else
			C@++ + alignl 4+ dup C@ 0=
		then
	until
	drop swap
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


lockdict stringmap _cnd
c" if_always"		h003C	string/word
c" if_never"		0	string/word
c" if_e"		h0028	string/word
c" if_ne"		h0014	string/word
c" if_a"		h0004	string/word
c" if_b"		h0030	string/word
c" if_ae"		h000C	string/word
c" if_be"		h0038	string/word
c" if_c"		h0030	string/word
c" if_nc"		h000C	string/word
c" if_z"		h0028	string/word
c" if_nz"		h0014	string/word
c" if_c_eq_z"		h0024	string/word
c" if_c_ne_z"		h0018	string/word
c" if_c_and_z"		h0020	string/word
c" if_nc_and_z"		h0008	string/word
c" if_nc_and_nz"	h0004	string/word
c" if_c_or_z"		h0038	string/word
c" if_c_or_nz"		h0034	string/word
c" if_nc_or_z"		h002C	string/word
c" if_nc_or_nz"		h001C	string/word
c" if_z_eq_c"		h0024	string/word
c" if_z_ne_c"		h0018	string/word
c" if_z_and_c"		h0020	string/word
c" if_z_and_nc"		h0008	string/word
c" if_nz_and_c"		h0010	string/word
c" if_nz_and_nc"	h0004	string/word
c" if_z_or_c"		h0038	string/word
c" if_z_or_nc"		h002C	string/word
c" if_nz_or_c"		h0034	string/word
c" if_nz_or_nc"		h001C	string/word
c" "			0 	string/word
freedict


lockdict stringmap _asmds
c" abs"		hA8BC string/word
c" absneg"	hACBC string/word
c" add"		h80BC string/word
c" addabs"	h88BC string/word
c" adds"	hD0BC string/word
c" addsx"	hD8BC string/word
c" addx"	hC8BC string/word
c" and"		h60BC string/word
c" andn"	h64BC string/word
c" cmp"		h843C string/word
c" cmps"	hC03C string/word
c" cmpsub"	hE03C string/word
c" cmpsx"	hC43C string/word
c" cmpx"	hCC3C string/word
c" djnz"	hE4BC string/word
c" jmpret"	h5CBC string/word
c" max" 	h4CBC string/word
c" maxs"	h44BC string/word
c" min"		h48BC string/word
c" mins"	h40BC string/word
c" mov"		hA0BC string/word
c" movd"	h54BC string/word
c" movi"	h58BC string/word
c" movs"	h50BC string/word
c" muxc"	h70BC string/word
c" muxnc"	h74BC string/word
c" muxnz"	h7CBC string/word
c" muxz"	h78BC string/word
c" neg"		hA4BC string/word
c" negc"	hB03C string/word
c" negnc"	hB4BC string/word
c" negnz"	hBCBC string/word
c" negz"	hB9BC string/word
c" or"		h68BC string/word
c" rdbyte" 	h00BC string/word
c" rdlong"	h08BC string/word
c" rdword"	h04BC string/word
c" rcl"		h34BC string/word
c" rcr"		h30BC string/word
c" rev"		h3CBC string/word
c" rol"		h24BC string/word
c" ror"		h20BC string/word
c" sar"		h38BC string/word
c" shl"		h2CBC string/word
c" shr"		h28BC string/word
c" sub"		h84BC string/word
c" subabs"	h8CBC string/word
c" subs"	hD4BC string/word
c" subsx"	hDCBC string/word
c" subx"	hCCBC string/word
c" sumc"	h90BC string/word
c" sumnc"	h94BC string/word
c" sumnz"	h9CBC string/word
c" sumz"	h98BC string/word
c" test"	h603C string/word
c" tjnz"	hE83C string/word
c" tjz"		hEC3C string/word
c" waitcnt"	hF8BC string/word
c" waitpeq"	hF03C string/word
c" waitpne"	hF43C string/word
c" waitvid"	hFC3C string/word
c" wrbyte"	h003C string/word
c" wrlong"	h083C string/word
c" wrword"	h043C string/word
c" xor"		h6CBC string/word
c" "		0 string/word
freedict

lockdict stringmap _asmd
c" clkset"	h0C7C0000 string/long
c" cogid"	h0CFC0001 string/long
c" coginit"	h0C7C0002 string/long
c" cogstop"	h0C7C0003 string/long
c" lockclr"	h0C7C0007 string/long
c" locknew"	h0CFC0004 string/long
c" lockret"	h0C7C0005 string/long
c" lockset"	h0C7C0006 string/long
c" "		0 string/long
freedict

lockdict stringmap _asms
c" jmp" 	h5C3C string/word
c" long"	0 string/word
c" "		0 string/word
freedict

lockdict stringmap _asm
c" nop"		0 string/long
c" ret"		h5C7C0000 string/long
c" jnext" 	$C_a_next h5C7C0000 or string/long
c" jexit"	$C_a_exit h5C7C0000 or string/long
c" spush"	$C_a_stpush $C_a_stpush_ret h9 lshift or h5C7C0000 or string/long
c" spopt"	$C_a_stpoptreg $C_a_stpoptreg_ret h9 lshift or h5C7C0000 or string/long
c" spop"	$C_a_stpop $C_a_stpop_ret h9 lshift or h5C7C0000 or string/long
c" rpush"	$C_a_rspush $C_a_rspush_ret h9 lshift or h5C7C0000 or string/long
c" rpop" 	$C_a_rspop $C_a_rspop_ret h9 lshift or h5C7C0000 or string/long
c" "		0 string/long
freedict

\
\ _lu ( cstr map -- cstr 0 | n1 -1) 
: _lu
	string/word_lookup dup if swap h10 lshift swap then
;

\ cnd ( cstr -- cstr 0 | n1 -1 ) process the condition statement n1 is the mask to apply if successful 
: cnd 
	_cnd _lu
;
 
\ asminstds ( cstr -- cstr 0 | n1 -1 ) process op codes with a destination and a source
: asminstds
	_asmds _lu
;
 
\ asminstd ( cstr -- cstr 0 | n1 -1 ) process opcodes with a destination only 
: asminstd
	_asmd string/long_lookup 
;

\ asminsts ( cstr -- cstr 0 | n1 -1 ) process opcodes with a source only
: asminsts
	_asms _lu
;

\ _mc ( src dst -- n) 
: _mc
	h9 lshift or h5CFC0000 or
;

\ asminst ( cstr -- cstr 0 | n1 -1 ) process the only opcode with no dest or source
: asminst
	_asm string/long_lookup 
;

wvariable _asmerror 0 _asmerror W!

\ asmerr ( cstr cstr -- ) report an error and consume all the keys left
: asmerr
	.cstr .cstr cr padbl clearkeys -1 _asmerror W!
;


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
: asmopend
	padnw
	if
		begin
			pad>in dup 1+ C@ 27 <> 
			if
				dup c" wc" cstr= if drop h01000000 or else
				dup c" wz" cstr= if drop h02000000 or else
				dup c" wr" cstr= if drop h00800000 or else
				dup c" nr" cstr= if drop hFF7FFFFF and else
				c" Unexpected word " asmerr then then then then  
			else
				drop padbl
			then
			padnw 0=
		until
	then
	dup 0=
	if
		nip
	else
		hFFC3FFFF and or
	then
;

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




{


fl


[ifndef $C_a_lxasm
    hB2 wconstant $C_a_lxasm
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

[ifndef $C_stTOS
    hCB wconstant $C_stTOS
]

[ifndef $C_fDestInc
    hC2 wconstant $C_fDestInc
]

[ifndef $C_fLongMask
    hC6 wconstant $C_fLongMask
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

[ifndef $C_fAddrMask
    hC5 wconstant $C_fAddrMask
]
\ __mc ( src dst op -- )
: __mc
	h10 lshift swap h9 lshift or or l,
;
	
\ __mcs ( src op -- )
: __mcs
	0 swap __mc
;
\ _mc ( src dst -- ) 
: _mc h_5CFC __mc ;

\
\ _:masm name ( startaddr endaddr -- )
: _:masm
	lockdict create forthentry
\ ( start end -- )
	0 w, over - h9 lshift or here W@ alignl h10 lshift or l,
;



: :masm
	build_BootOpt coghere W@ _:masm
;

: ;masm
	$C_a_exit h5C7C_0000 or l,
	lastnfa nfa>pfa dup 2+ alignl
\ lastpfa long
	here W@ over - 4/
	over L@ h9 rshift h1FF and 
	>=
	if
		." word too long~h0D"
		2drop
	else
		dup L@ h_0001_FE00 andn
\ lastpfa long iw		
		here W@ 2 ST@ - h1FF and h9 lshift or
		swap L!
		$C_a_lxasm swap W!
	then

	
	freedict
;


\ mov ( src dst -- )
: mov
	hA0BC __mc
;

\ and ( src dst -- )
: and
	hA0BC __mc
;

\ or ( src dst -- )
: or
	h60BC __mc
;

\ andn ( src dst -- )
: andn
	h64BC __mc
;

: nop
	0 l,
;

: exit
	$C_a_exit h5C7C _mcs 
;

: spush
	$C_a_stpush $C_a_stpush_ret _mc
;

: spop
	$C_a_stpop $C_a_stpop_ret _mc
;

: rpush
	$C_a_strpush $C_a_strpush_ret _mc
;

: rpop
	$C_a_strpop $C_a_strpop_ret _mc
;

: spoptreg1
	$C_a_stpoptreg $C_a_stpoptreg_ret _mc
;



\ inbyte ( -- c1)
:masm inbyte
	
0 reg datain
1 >m reg clkbit
2 >m reg databit
8 reg nbits

	clkbit inbit
	databit inbit

	for
		clkbit waitbitlo
		clkbit waitbithi
		databit inbit
		if
			1 datain ori
		then
		1 datain lshifti
	nbits next
	inbyte spush
;asm

\ outbyte( c1 -- )
: masm outbyte

0 reg dataout
1 >m reg clkbit
2 >m reg databit
8 reg nbits

100 reg currentticks
100 reg ticks

	clkbit outbitset
	dataout spop
	clkbit outbit
	databit outbit

	currentticks addnow
	for
		currentticks ticks waitticks
		clkbit outbitclr
		
		7 >m dataout andout
		nop
		clkbit outbitset
		nop
	nbits next
;asm	

}


