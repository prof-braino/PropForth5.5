fl

1 wconstant build_spinimage

lastnfa nfa>lfa W@ wconstant imageLastnfa

c" wlastnfa" find drop pfa>nfa nfa>lfa wconstant imageStart
c" build_spinimage" find drop  pfa>nfa nfa>lfa wconstant imageEnd

c" fstart" find drop wconstant fstartPFA
c" _finit" find drop wconstant _finitPFA

[ifdef neverever
As fl send the bytes in up until the ], it release a byte for every character sent. Tcog getting
the bytes simply discards them as never ever if not defined.

This leaves spave if the dictionary to define the array taht follow, and thus we can have up to
100 $S_XXXXXXX constants, which allow for the configuration of the PropForth image.

These constants, though defined in forth, are by convention replaced with a spin constant
dlrS_XXXXXXX

A very simple but powerful mechanism which allows the configuration of a PropForth Image.

BTW, 100 configuration options is way too many, there are other better mechanisms when we start
getting to this number.

]
\
\
\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
[ifndef 2*
: 2* _xasm2>1IMM h0001 _cnip h05F _cnip ; 
]
\
wvariable numConstantsOfInterest 0 numConstantsOfInterest W!
lockdict wvariable ConstantsOfInterest 100 2* allot freedict
\
\ findConstantsOfInterest ( -- )
: findConstantsOfInterest
	lastnfa
	begin
		c" $S_" over swap
		npfx
		if
			dup nfa>pfa dup W@ $C_a_doconw =
			if
				2+
				ConstantsOfInterest numConstantsOfInterest W@ 2* + W!
				numConstantsOfInterest W@ 1+ 
				100 min numConstantsOfInterest W!
			else
				drop
			then
		then
		nfa>lfa W@ dup 0=
	until
	  

;
\
: isConstantOfInterest?
	numConstantsOfInterest W@ 0<>
	if
		0 swap
		numConstantsOfInterest W@ 0
		do
			i 2* ConstantsOfInterest + W@ over =
			if
				nip -1 swap leave
			then
		loop
		drop
	else
		drop 0
	then
;	
\
: spinImage
	findConstantsOfInterest
	base W@ hex
	lastnfa W@
	here W@ 
	imageEnd here W!
	imageLastnfa wlastnfa W!
	." ~h0D~h0DForthDictStart~h0D~h0D"
	." ~h0D' " imageStart .
	." ~h0D  word $" imageStart W@ .
	imageEnd imageStart 2+
	do
		i _finitPFA =
		if
			." ~h0D~h0D_finitPFA~h0D~h0D  word $" i W@ .
		else

		i fstartPFA =
		if
			." ~h0D~h0DfstartPFA~h0D~h0D  word $" i W@ .
		else

		i isConstantOfInterest?
		if
				
			." ~h0D~h0D  word dlr"
			i 2- pfa>nfa namelen 1- swap 1+ swap .str
		else

		i h1F and 0=
		if
			." ~h0D' " i .
			." ~h0D  word $" i W@ .
		else
			." , $" i W@ .
		thens
	2 +loop
	cr cr
	here W!
	lastnfa W!

	memend W@ 2- imageEnd
	."   word "
	do
		i h3F and 0=
		if
			." 0~h0D' " i .
			." ~h0D  word "
		else
			." 0, "
		then
	2 +loop
	." 0~h0D~h0D~h0D"
	base W!		
;
