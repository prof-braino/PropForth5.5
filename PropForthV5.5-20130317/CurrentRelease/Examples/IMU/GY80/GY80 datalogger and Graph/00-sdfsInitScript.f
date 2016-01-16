fl

\ Run this script to initialize the file system

\
\
\ first partion has system information and partition files
\ it is a 32 Megabyte partition, should be more than
\ adequate for a lot of configuration files.
\
\ This information is generated automatically, after an sd_init
\ _sd_maxblock will be valid
\
[ifndef $C_a_doconl
    h52 wconstant $C_a_doconl
]
\
\ constant ( x -- ) skip blanks parse the next word and create a constant, allocate a long, 4 bytes
[ifndef constant
: constant
	lockdict create $C_a_doconl w, l, forthentry freedict
;
]

sd_init

1 constant _sysstart


\ _sd_CrEaTe ( n1 n2 -- ) n1 - starting block, n2 - last block + 1, CREATE a file system, WIPES OUT DATA
: _sd_CrEaTe
	sd_cogbuf h80 bounds
	do
		h20202020 i COG!
	loop
	h20202F01 dup sd_cogbuf COG!
	sd_cogbuf h20 + COG!
	h10000 sd_cogbuf h2A + COG!
	h81 sd_cogbuf h2B + COG!
	over sd_cogbuf h2E + COG!
	over sd_cogbuf h2F + COG!
	over sd_cogbuf h32 + COG!
	sd_cogbuf h33 + COG!
	dup h81 + sd_cogbuf h36 + COG!
	sd_lock	dup sd_blockwrite
	_sd_initdir
	sd_unlock
;




\ 32 Megabytes
h10000 _sysstart + constant _sysblocks

_sd_maxblock L@ constant _usrend


_sysstart _sysblocks _sd_CrEaTe
_sysstart _sysblocks + _usrend _sd_CrEaTe	

_sysstart sd_mount


h2 fwrite .sdcardinfo

                      SDCard size:...




	_sd_maxblock L@ 2/ _nf C@++
	c" .sdcardinfo" sd_append
	c"  Kbytes~h0D~h0D" C@++ c" .sdcardinfo" sd_append

	c" File System: sys~h0D                      Start Block:" C@++ c" .sdcardinfo" sd_append

	_sysstart _nf C@++ c" .sdcardinfo" sd_append

	c" ~h0D                        End Block:" C@++ c" .sdcardinfo" sd_append

	_sysstart _sysblocks + _nf C@++ c" .sdcardinfo" sd_append

	c" ~h0D        File System Size (blocks):" C@++ c" .sdcardinfo" sd_append

	_sysblocks _nf C@++ c" .sdcardinfo" sd_append

	c" ~h0D        File System Size  (bytes):" C@++ c" .sdcardinfo" sd_append

	_sysblocks 2/ _nf C@++
	c" .sdcardinfo" sd_append

	c"  Kbytes~h0D~h0D" C@++ c" .sdcardinfo" sd_append


	c" File System: usr~h0D                      Start Block:" C@++ c" .sdcardinfo" sd_append

	_sysstart _sysblocks + _nf C@++ c" .sdcardinfo" sd_append

	c" ~h0D                        End Block:" C@++ c" .sdcardinfo" sd_append
	_usrend _nf C@++ c" .sdcardinfo" sd_append

	c" ~h0D        File System Size (blocks):" C@++ c" .sdcardinfo" sd_append
	_usrend _sysstart _sysblocks + - _nf C@++ c" .sdcardinfo" sd_append

	c" ~h0D        File System Size  (bytes):" C@++ c" .sdcardinfo" sd_append

	_usrend _sysstart _sysblocks + - 2/ _nf C@++
	c" .sdcardinfo" sd_append
	c"  Kbytes~h0D~h0D" C@++ c" .sdcardinfo" sd_append


h100 fwrite sdboot.f

hA state orC! cr

c" sdboot.f  -  initializing~h0D~h0D" .cstr
1 sd_mount

\ mountsys ( -- ) mount the system disk
[ifndef mountsys
: mountsys sd_init ...

	_sysstart <# # # # # # # # # # # #> C@++ c" sdboot.f" sd_append

	c"  sd_mount ; ~h0D]~h0D" C@++  c" sdboot.f"  sd_append

	c" \ mountusr ( -- ) mount the user disk~h0D[ifndef mountusr~h0D: mountusr sd_init " C@++ c" sdboot.f" sd_append

	_sysstart _sysblocks + <# #s #> C@++ c" sdboot.f" sd_append
	
	c"  sd_mount ; ~h0D]~h0D"  C@++ c" sdboot.f" sd_append

	c" c~h22 sdboot.f  -  Loading usrboot.f~h7Eh0D~h7Eh0D~h22 .cstr~h0D~h0D" C@++ c" sdboot.f" sd_append

	c" fload usrboot.f~h0D" C@++  c" sdboot.f"  sd_append
	
	c" c~h22 sdboot.f  -  DONE - PropForth Loaded ~h7Eh0D~h7Eh0D~h22 .cstr~h0D~h0D" C@++ c" sdboot.f" sd_append
	c" hA state andnC!~h0D~h0D" C@++ c" sdboot.f" sd_append

100 fwrite usrboot.f
version W@  .cstr cr

c" usrboot.f  -  initializing~h0D~h0D" .cstr

1 sd_mount

fread .sdcardinfo

c" usrboot.f  -  DONE~h0D~h0D" .cstr
...

mkdir .partion-sys/

_sysstart _sysblocks + sd_mount

mkdir .partion-usr/

_sysstart sd_mount

forget _sysstart



