fl
\
\
\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
[ifndef 2*
: 2* _xasm2>1IMM h0001 _cnip h05F _cnip ; 
]


: sym 
	cr
	lastnfa
	begin
\ (nfa -- )
		c" $C_" over swap npfx
\ (nfa flag -- )
		over c" $V_" npfx or
		
		if
			." [ifndef " dup .strname cr
			base W@ ."     h" over nfa>pfa 2+ W@ hex . base W! ." wconstant " dup .strname cr
			." ]" cr cr 
		then		
		nfa>next dup 0=
	until
	drop cr
;

\ _wordArray ( n cstr -- addr)
: _wordArray
	lockdict ccreate $C_a_dovarw w, here W@ 0 w, swap 0 max h1000 min dup w, 2* allot forthentry freedict
	dup dup W@ swap 2+ swap 2* 0 fill
;

\ _waAppend( addr val -- )
: _waAppend
	over dup W@ swap 2+ W@ <
	if
		over dup W@ 2+ 2* +  W!
		1 swap W+!
		
	else
		hDD ERR
	then
;

\ _string ( cstr name -- addr)
: _string
	lockdict ccreate here W@ 2+ swap
	$H_cq w, dup here W@ ccopy C@ 1+ allot herewal
	$C_a_exit w, 
	forthentry freedict
;

\ cstr> ( addr1 addr2 -- )
: cstr>
	0 rot2
\ ( 0 a1 a2 -- )
	2dup C@ swap C@ swap
\ ( 0 a1 a2 l1 l2 -- )
	2dup
	>
	>r
	min  rot
\ ( 0 a2 length  a1 -- )
	1+ rot 1+ rot
\ ( 0 a1+1 a2+1 length -- )
	bounds
	do
\ ( 0 a1+n -- )
		dup C@ i C@
		-
		rot + tuck
		0<>
		if
			leave
		then
		1+
	loop
	drop
	dup
	if
		r> drop 0>
	else
\ strings are the same for length compared, if a1 is longer than a2 then true
		drop r>
	then
;

\ _strBsort ( addr -- addr t/f )
: _strBsort
	-1 swap
	dup W@ 1 >
	if
		dup W@ 1- 2* over 4+ swap bounds
		do
			i W@ i 2+ W@
			cstr>
			if
				i W@ i 2+ W@
				i W! i 2+ W!
				nip 0 swap
			then
		2 +loop
	then
	swap		
;

\ strBsort ( addr -- addr ) bubble sort of string array
: strBsort
	begin
		_strBsort
	until
;

\ symgen ( -- )
: symgen
	lockdict
	h400 c" _wlist" _wordArray
	lastnfa
	begin
\ (array nfa -- )
\ (nfa -- )
		c" $C_" over swap npfx
\ (nfa flag -- )
		over c" $V_" npfx or
		over c" $S_" npfx or
		
		if
			dup tbuf namecopy
			tbuf C@ h1F and tbuf C!
			over tbuf c" _$$" _string
			_waAppend
		then		
		nfa>next dup 0=

	until
	drop
	strBsort
	dup W@ 0<>
	if

		cr cr cr
		dup W@ 2* over 4+ swap bounds
		do
			i W@
			." [ifndef " dup .cstr cr
			base W@ ."     h"
			over find
			if
				execute
			else
				drop 0
			then	 
			hex . base W! ." wconstant "  .cstr cr
			." ]" cr cr 


		2 +loop
	then	
	drop	
\	c" _wlist" (forget)
	freedict	
;

