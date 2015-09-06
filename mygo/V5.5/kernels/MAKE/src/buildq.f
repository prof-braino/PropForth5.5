\
\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[ifndef #C
: #C
	-1 >out W+! pad>out C!
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
\ _nd ( n1 -- n2 ) internal format routine
[ifndef _nd
: _nd
	base W@ d_40 over <
	if
		d_6
	else
		d_15 over <
		if
			d_8
		else
			d_9 over <
			if
				d_10
			else
			d_7 over <
				if
					d_11
				else
				d_6 over <
					if
						d_12
					else
						d_3 over <
						if
							d_16
						else
							d_32
	thens
	nip
	swap u/mod swap 0<>
	if
		1+
	then
;
]	
\
\ _ft ( n1 divisor -- cstr ) internal format routine
[ifndef _ft
: _ft
\ set to output an underscore every 4 digits, or 3 if the base it 8 - 10
	h4 base W@ h_8 h_A between
	if
		1-
	then
	rot2
	<#
	_nd 0
	do
		#
		over i 1+ swap u/mod drop
		0=
		if
			lasti? 0=
			if
				h_5F #C
			then
		then
	loop
	#>
	nip
;
]
\
\
\ _wf ( n1 -- cstr ) format n1 as a word
[ifndef _wf
: _wf
	h_FFFF and 2 _ft
;
]
\
\
\ .word ( n1 -- ) output a word
[ifndef .word
: .word
	_wf .cstr
;
]
\
\ _words ( cstr -- ) prints the words in the forth dictionary starting with cstr, 0 prints all
[ifndef _words
: _words 
	0 >r lastnfa ." NFA (Forth/Asm Immediate eXecute) Name"
	begin
		2dup swap dup
		if
			npfx
		else
			2drop -1
		then
		if
			r> dup 0=
			if
				cr
			then
			1+ h3 and >r
			dup .word space dup C@ dup h80 and
			if
				h46 
			else
				h41
			then
			emit dup h40 and
			if
				h49
			else
				h20
			then
			emit h20 and
			if
				h58
			else
				h20
			then
			emit space dup .strname dup C@ namemax and h15 swap - 0 max spaces
		then
		nfa>next dup 0=
	until
	r> 3drop cr
;
]
\
\
\ build? ( -- ) print out build information
\
[ifndef build?
: build?
	cr
	c" build_" _words
	cr
	version W@ .cstr cr
;
]
