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


