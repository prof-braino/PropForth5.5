fl

\
\ After getting norom, and mcs working the 2 together
\
\ load this file
\ run 0 onboot
\ 5 0 term
\
\
\



1 wconstant  build_mcsnorom


c" onboot" find drop pfa>nfa 1+ c" onb002" C@++ rot swap cmove
: onboot
	 onb002 h80 delms
	h2 _finit andnC!
	_finit W@ 1 and
	if

\
\ Reference regression system
\
\
		h8 h9 hA hB rambootnx
		c" h8 h9 hA h5 mcsmaster" h5 cogx h10 delms

\
\ Spinneret PLAB0
\
\		d26 d27 d24 d25 rambootnx
\		c" d26 d27 d24 d5 mcsmaster" h5 cogx h10 delms


		h10000 0
		do
			h5 cogio mcsstate@ h4 =
			if
				h2 _finit orC!
				leave
			then
		loop
	else
		c" h1C h1D hFF h5 mcsslave" h5 cogx h10 delms
		h10000 0
		do
			h5 cogio mcsstate@ 4 =
			if
				h2 _finit orC!
				leave
			then
		loop
		h5 0
		do
			i 0 h5 i (ioconn)
		loop
	then
;		


\ ...
{
fl


: stats
	5 cogio
	." Master Pin:      " dup mcspinm@ . cr
	." Slave Pin:       " dup mcspinm@ . cr cr

	." Errors:          "  dup mcserr L@ . cr

	." Frames:          "  dup mcscnt L@ . cr

	." State:           "  dup mcsstate@ . cr

 	dup mcscnt dup L@

	clkfreq cnt COG@ + 0 waitcnt drop
	swap L@ -


	." frames/s:        " dup . cr
	." bps:             " h60 u* . cr cr
	drop
;

: start
	." booting sub-propeller chip~h0D"
	8 9 10 11 rambootnx
	." starting serial driver on cog4~h0D"
	4 cogreset h100 delms
	c" 1 0 57600 serial" 4 cogx
	16 delms
	." starting a terminal using serial driver on cog 4~h0D"
	4 0 term
;

: t 4 0 term ;

: dco
		h5 0
		do
			i 0 h5 i (ioconn)
		loop
;

: mstart
	c" h8 h9 hA h5 mcsmaster" h5 cogx
	c" c~h22 h1C h1D hFF h5 mcsslave~h22 h5 cogx" h4 cogx
;

}


