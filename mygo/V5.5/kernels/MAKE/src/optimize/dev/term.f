[ifndef rcogx
\ rcogx ( cstr cog channel -- ) send cstr to the cog/channel
: rcogx
	io 2+ W@
\ ( cstr cog channel oldio+2 -- )
	rot cogio
\ ( cstr channel oldio+2 cogio -- )
	rot 4* +
\ ( cstr oldio+2 chaddr -- )
	io 2+ W!
\ ( cstr oldio+2 -- )
	swap .cstr cr
	io 2+ W!
;
]

[ifndef build_sdfs
: rfsend
	2drop ." NO~h0D"
;
]

[ifndef rfsend
\ rfsend filename ( cog channel -- )
: rfsend
	4* swap cogio +
	_sd_fsp dup
	if
\ ( chaddr fname -- )
		io 2+ W@
\ ( chaddr fname oldio+2 -- )
		rot io 2+ W!
\ ( fname oldio+2 -- )
		swap
		sd_read
		io 2+ W!
	else
		2drop _fnf
	then
;
]





[ifndef term
: term
	over cognchan min ." Hit CTL-P to exit term, CTL-Q exit nest1 CTL-R exit nest2 ... CTL-exit nest9~h0D~h0A"
	>r >r cogid 0 r> r> (iolink)
	begin
		key dup h10 =
		if
			drop -1
		else
			dup h11 h19 between
			if
				1-
			then
			emit 0
		then
	until
	cogid iounlink
;
]
