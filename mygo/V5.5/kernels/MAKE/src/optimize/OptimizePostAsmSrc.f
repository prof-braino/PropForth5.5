\
\ Output of assembling OpimizeAsmSrc.f goes above this comment block
\
\
\
\ u* ( u1 u2 -- u1*u2) u1 multiplied by u2
: u*
	um* drop
;

\ u/mod ( u1 u2 -- remainder quotient ) \ unsigned divide & mod  u1 divided by u2
: u/mod
	0 swap um/mod
;

\
\
\ u/ ( u1 u2 -- u1/u2) u1 divided by u2
: u/
	u/mod nip
;
\
\
\ fl ( -- ) buffer the input and route to a free cog
: fl
	lockdict fl_lock W@
	if
		freedict
	else
		-1 fl_lock W! cogid nfcog dup >r iolink freedict

\
\ dictend - pointer to the next character for output
\ initialize
\
		cnt COG@ 0 dictend W@ 2- here W@ h80 + dup dictend W!

\ ( timeoutcount num_overflow bufend bufstart -- )
		begin
			2dup <=
			if
				fkey? nip
				if
					cnt COG@ 3 ST!
					rot 1+ rot2
				else
					dup dictend a_flout
				then
			else
				fkey?
				if
					swap 2 ST@ a_cha
					cnt COG@ 3 ST!
				else
					drop dup dictend a_flout
				then
			then
			cnt COG@ 4 ST@ - clkfreq >
		until
		begin
			dup dictend a_flout
			dup dictend W@ <=
		until
		cr cr
		drop 2+ dictend W!
		cogid iounlink
		0 fl_lock W!
		r> over
		if
			cogreset
			cr . ." characters overflowed" cr
		else
			2drop
		then
		drop
	thens
;

