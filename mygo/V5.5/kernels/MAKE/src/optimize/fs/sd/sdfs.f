\
\
1 wconstant build_sdfs
c" Loading sdfs.f ..." .cstr

\
\

{

Status: RELEASE 2012 JUN 07


sdfs is meant to be a very simple fast file system on top of sd_driver.

The design criteria are around small code size and speed, as opposed to generality
and versatility.


Main concepts:

1. A file system occupies n contiguos 512 byte blocks on the SD card. If it is
desired that the card should be FAT32 formatted, it should be possible to format
card, create a very large file, figure out which blocks the file occupies, and mount
sdfs to use those blocks.

This means sdfs could be manipulated on a pc by writing some code. This is NOT a goal of
the initial implementation.

The file system must not start at block 0, block 1 is the first valid block number.

This also means multiple file systems can be defined on one sd card, useful for isolating
functions like logging.

An sd card can be partitioned into multiple "disks", each which can contain one file system.
There is no partition table or disk routines, when a filesystem is created, the start and end
inherently defines the partion.

2. Files are 2 - n contigous blocks, the maximum file size is 2Gig, (max positive 32 bit
integer.) When a file is created, the space that is allocated to the file (the space is
allocated as blocks of 512 bytes) is the maximum size the file can grow to.
This trades space efficiency for a very simple and fast allocation.

3. File names must be 1 to 26 characters in length, and can only contain characters 0h30 - 0h7D.
There are no other restrictions on file names. It is recommended that names do not use special
characters. The reason for this is mapping urls to file names gets more complicated.

4. There is directory support, a directory is a fixed length file, whose name ends with a /
There is no other differentiator. A directory can contain up to 2048 entries. A simple hashing
mechanism makes navigation quick. (This hash function should be tested more thouroughly for at
some point, but initial testing seems ok.) This optimizes for opening files, the result is that
to list a directory the whole directory must be traversed, so directory "listing" is slower.
However, assuming the hash function performs reasonably, finding a file, and opening the file
file be fast, and not slow down as there are more entries in the directory.

}
1 .

{

The root directory is /

Pathnames are simple concatenated directory and file names. 

The maximum total length of a path name is 120 characters, this should make mapping urls to files
very easy, and allow the use of the pad for parsing and file name manipulation.

To access a file, or directory, the current directory must be set to the parent of the file or
directory. File access is only in that directory. This means no relative navigation or fully
qualified file names. Reasons are 2 fold, 1 simplicity, 2 security. This will bebome evident
when the http server is using the file system.


5. There is no limit on directory depth other than that which is imposed by the maximum path
name length. The deeper a file is in the structure, the longer it will take to navigate to it.

6. Each file has a header block, immediately followed by all the data blocks.

7. The header block number is used by routines to reference files and directories.

8. Block numbers are absolute, this makes debugging, repair, and verification much simpler.
Unfortunately it means you cannot easily move the file system around.

9. The main interface routines to sdfs are:
}

2 .

\ _sd_CrEaTe ( n1 n2 -- ) n1 - starting block, n2 - last block + 1, CREATE a file system, WIPES OUT DATA
\
\ sd_mount ( n1 -- ) mount the file system, n1 - the starting block of the file system,
\ the file system must be mounted before it is used
\
\
\ sd_createdir ( cstr -- n1 ) cstr is the name of the directory to create, n1 is the header block
\ of the directory. If this directory already exists, it returns the root block of the existing
\ directory
\
\
\ sd_cd.. ( -- ) make the parent directory the current directory
\
\ sd_cd ( cstr -- ) make cstr the current directory, if it does not exists, nothing happens
\ the directory name in cstr must have a / at the end of it
\ 
\ sd_cwd ( -- ) get the pathname of the current directory and copy it to pad
\
\ sd_ls ( -- ) list the current directory
\
\
\ sd_createfile ( cstr n1 -- n2) allocate n1 blocks, this includes the header block
\
\ sd_find ( filename -- blocknumber/0) search for filename in the current directory
\
\ sd_stat ( filename -- ) prints stats for the file
\
\
\ sd_write ( numblocks filename -- ) writes a new or existing file until ... followed immediately by a cr is encountered
\ if the file exists, writing will be truncated to the existing maximum file size allocated when the file was created
\
\
\ sd_trunc ( length filename -- ) sets the number of bytes used in the file to length
\
\ sd_appendblk( addr size blk -- )
\ sd_append( addr size filename -- )
\
\ sd_readblk ( n1 -- ) n1 - header block number of file,
\				read the file and emit the char
\ sd_read ( filename -- ) read the file and emit the chars
\
\ sd_loadblk ( n1 -- ) n1 - the header block for the fileloads the file,
\ 			routes the file to the next free forth cog
\ sd_load ( cstr -- ) loads the file, routes the file to the next free forth cog
\
\
\
\ These are provided for command line convenience
\

\ ls ( -- )
\ cd dirname ( -- )
\ cd.. ( -- )
\ cd/ ( -- )
\ cwd ( -- ) print the current directory
\ mkdir dirname ( -- )
\ fread filename ( -- )
\ fcreate filename ( numblocks_to_allocate -- )
\ fwrite filename ( numblocks_to_allocate -- )
\ fstat filename ( -- )
\
\

3 .

\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[ifndef #C
: #C
	-1 >out W+! pad>out C!
	
;
]
\
\
\ _nf ( n1 -- cstr ) formats n1 to a fixed format 16 wide, leading spaces variable, one trailing space
[ifndef _nf
: _nf
	<# bl #C # # # h2C #C # # # h2C #C # # #  h2C #C # # # #>
	dup C@++ bounds
	do
		i C@ dup isdigit swap todigit 0<> and  
		if
			leave
			
		else
			bl i C!
		then
	loop
;
]
\
\
\ .num ( n1 -- ) print n1 as a fixed format number
[ifndef .num
: .num
	_nf .cstr
;
]
\
\ pad>cog ( n1 -- ) the cog address to start writing 32 longs
[ifndef pad>cog
: pad>cog 
	pad swap h20 mem>cog
;
]
\
\ tbuf>cog7 ( n1 -- ) the cog address to start writing 7 longs
[ifndef tbuf>cog7
: tbuf>cog7
	tbuf swap h7 mem>cog
;
]
\
\ cog>pad ( n1 -- ) the cog address to start reading 32 longs
[ifndef cog>pad
: cog>pad
	pad swap h20 cog>mem
;
]
\
\ cog>tbuf7 ( n1 -- ) the cog address to start reading 7 longs
[ifndef cog>tbuf7
: cog>tbuf7
	tbuf swap h7 cog>mem
;
]
\
\ _fnf ( --) file not found message
[ifndef _fnf
: _fnf
	cr ." FILE NOT FOUND" cr
;
]
\
\
4 .

{
file header block:

00 - 1F : 000 - 07F - a counted string which is the full pathname of this file, must be padded with blanks 
20 - 26 : 080 - 09B - a counted string which is the file name of this file, must be padded with blanks
27	: 09C - 09F - 20202020
28	: 0A0 - 0A3 - 20202020
29	: 0A4 - 0A7 - 20202020
2A	: 0A8 - 0AB - Length of file in bytes
2B	: 0AC - 0AF - Number of blocks allocated to this file (including the header block)
2C	: 0B0 - 0B4 - 20202020
2D	: 0B4 - 0B7 - 20202020
2E	: 0B8 - 0BB - the block number of the root directory
2F	: 0BC - 0BF - the block number of the parent directory
30	: 0C0 - 0C4 - 20202020
31	: 0C4 - 0C7 - 20202020
32	: 0C8 - 0CB - the first block in this files sytem \ same as the block number of the root directory
33	: 0CC - 0CF - The last block + 1 in this file system
34	: 0D0 - 0D4 - 20202020
35	: 0D4 - 0D7 - 20202020
36	: 0D8 - 0DB - if this is the root header block, this is the first free block, otherwise ignored
37 - 7F	: 0DC - 1FF - blanks

directory entry:

000 - 01B - counted string, the file name, field must be padded with blanks
01C - 01F - header block number of file

32 bytes, 16 directory entries / 512 byte block  -- 2048 directory enties = 128 blocks
}
\
\
\
\ sd_mount ( n1 -- ) mount the file system, n1 - the starting block of the file system,
\ the file system must be mounted before it is used
: sd_mount
	sd_init v_currentdir COG!
;
\
\ sd_cwd ( -- ) get the pathname of the current directory and copy it to pad
: sd_cwd
	v_currentdir COG@ sd_blockread
	sd_cogbuf cog>pad
;
\
\ _sd_initdir ( n1 -- ) n1, directory block number, initialize the directory
: _sd_initdir
	sd_cogbuf h80 bounds
	do
		h20202020 i COG!
	loop
	sd_cogbuf h80 bounds
	do
		h20202000 i COG!
		 0 i h7 + COG!
	h8 +loop
	1+ h80 bounds
	do
		i sd_blockwrite
	loop
;
\ _sd_alloc ( n1 -- n2 ) n1 - number of blocks to allocate, n2 - starting block, assumes v_currentdir is valid
: _sd_alloc
	v_currentdir COG@ sd_blockread
	sd_cogbuf h2E + COG@
	sd_lock
\					\ ( n1 rootblock -- ) 
	dup sd_blockread swap
\					\ ( rootblock  n1 -- ) 
	sd_cogbuf h36 + COG@ tuck
\					\ ( rootblock  firstfreeblock n1 firstfreeblock -- ) 
	+ dup sd_cogbuf h36 + COG!
\					\ ( rootblock  firstfreeblock newfirstfreeblock -- ) 
	sd_cogbuf h33 + COG@ <
	if
\					\ ( rootblock  firstfreeblock -- ) 
		swap sd_blockwrite
	else
		hFD ERR		
	then
	sd_unlock
;
\
\ _sd_hash ( cstr -- hash ) hashes a name to a value between 0 & 7F
: _sd_hash
	tbuf h20 bl fill tbuf ccopy
	0 tbuf h1C bounds
	do
		i L@ xor 
	h4 +loop
	dup h10 rshift xor dup h8  rshift xor h7F and
;
\
\
\ _sd_setdirentry ( filename blocknumber -- ) write the directory entry
: _sd_setdirentry
	over _sd_hash
\							( filename blocknumber hash -- )
	h80 0
	do
		dup i + h7F and v_currentdir COG@ 1+ +
\							( filename blocknumber hash dirblock -- )
		sd_lock
		dup sd_blockread
		sd_cogbuf h80 bounds
		do
			i COG@ h20202000 =
			if
\							( filename blocknumber hash dirblock -- )
				i tbuf>cog7
				rot i h7 + COG!
\							( filename hash dirblock -- )
				dup sd_blockwrite
				0 rot2 leave
\							( filename 0 hash dirblock -- )
			then
		h8 +loop
		sd_unlock
		drop
		over 0=
		if
			leave
		then
\							( filename blocknumber hash -- )
	loop
	drop nip
	0<>
	if
		hFE ERR
	then
;

5 .

\
\ sd_find ( filename -- blocknumber/0) search for filename in the current directory
: sd_find
	dup _sd_hash -1
\							( filename hash flag -- )
	h80 0
	do        
		over i + h7F and v_currentdir COG@ 1+ +
		sd_blockread
\							( filename hash flag -- )
		sd_cogbuf h80 bounds
		do
			i COG@ h20202000 =
			if
				drop 0 leave
\							( filename hash 0  -- )
			else
				i cog>tbuf7 rot dup tbuf cstr=
\							( hash flag filename t/f  -- )
				if
					rot2 drop i h7 + COG@ leave
\							( filename hash blocknumber  -- )
				else
					rot2
\							( filename hash -1  -- )
				then
\				
			then
		h8 +loop
		dup -1 <>
		if
			leave
		then
\							( filename hash blocknumber/0 -- )
	loop
	nip nip
;
\
\   
\ sd_createfile ( cstr n1 -- n2) allocate n1 blocks, this includes the header block,
\  create a directory entry, and write the file header,
\ n2 is the block number of the file header
: sd_createfile
	over sd_find dup
	if
		nip nip
		dup sd_blockread
	else
		drop

		tuck
		_sd_alloc tuck
		_sd_setdirentry
\							\ ( n1 fileheaderblocknumber -- )
		v_currentdir COG@ sd_blockread
		sd_cogbuf cog>pad
		tbuf pad cappend
\							\ ( n1 fileheaderblocknumber -- )
		sd_cogbuf pad>cog padbl
		sd_cogbuf h20 + tbuf>cog7
		0 sd_cogbuf h2A + COG! 
		swap sd_cogbuf h2B + COG!
		v_currentdir COG@ sd_cogbuf h2F + COG!
		h20202020 sd_cogbuf h36 + COG!
		dup sd_blockwrite
	then
;
\
\
\ sd_createdir ( cstr -- n1 ) cstr is the name of the directory to create, n1 is the header block
\ of the directory. If this directory already exists, it returns the root block of the existing
\ directory
: sd_createdir
	dup C@++ + 1- C@ h2F <>
	if
		hFA ERR
	then
	dup sd_find dup
	if
		nip
	else
		drop
		sd_lock
		h81 sd_createfile
		dup _sd_initdir
		sd_unlock
	then
;
\
\
\ sd_ls ( -- ) list the current directory
: sd_ls
	v_currentdir COG@ 1+ h80 bounds
	do
		i sd_blockread
		sd_cogbuf h80 bounds
		do
			i COG@ h20202000 <>
			if
				i h7 + COG@ .
				tbuf i h7 bounds
				do i COG@ over L! 4+ loop drop
				tbuf .cstr cr
			then
		h8 +loop
	loop
;
\
\
\ sd_cd.. ( -- ) make the parent directory the current directory
: sd_cd..
	v_currentdir COG@ sd_blockread
	sd_cogbuf h2F + COG@ v_currentdir COG!
;
\
\
\ sd_cd ( cstr -- ) make cstr the current directory, if it does not exists, nothing happens
\ the directory name in cstr must have a / at the end of it
: sd_cd
	dup C@++ + 1- C@ h2F <>
	if
		hFA ERR
	then
	sd_find dup 0<>
	if
		v_currentdir COG!
	else
		drop
	then
;
\
\
\ _fsk ( n1 -- n2) n1<<8 or a key from the input
[ifndef _fsk
: _fsk
	h8 lshift key or
;
]

6 .


\
\ sd_write ( numblocks filename -- ) writes a new or existing file until ... followed immediately by a cr is encountered
\ if the file exists, writing will be truncated to the existing maximum file size allocated when the file was created
: sd_write
\ t0/t1 a long which is the number of bytes written
\ tbuf - a long which is the file size
	0 t0 L!
\							( numblocks filename -- )
	over 1+ sd_createfile
	sd_cogbuf h2B + COG@ 1- h200 u* tbuf L!
	dup 1+
\							( numblocks blocknumber blocknumber+1 -- )
	rot
	key _fsk _fsk _fsk
\							( blocknumber blocknumber+1 numblocks keys -- )
	rot2 bounds
	do
\							( blocknumber keys -- )
		sd_cogbuf h80 bounds
		do
			pad h80 bounds
			do
\							check to see if we have a ... at the end of a line
				h2E2E2E0D over =
				if
					leave
				else
					dup h18 rshift
					dup emit
					i C!
					t0 L@ dup tbuf L@ <
					if
						1+ t0 L! _fsk
					else
						2drop h2E2E2E0D leave
					then
				then
			loop
			i pad>cog
			h2E2E2E0D over =
			if
				leave
			then
		h20 +loop
		i sd_blockwrite
		h2E2E2E0D over =
		if
			leave
		then
	loop
	drop dup sd_blockread
	t0 L@ sd_cogbuf h2A + COG!
	sd_blockwrite
	padbl
;
\
\ sd_readblk ( n1 -- ) n1 - header block number of file,
\				read the file and emit the chars
: sd_readblk
\							should validate
	dup
	if
		dup sd_blockread 1+
\ 							( firstblock -- )
		sd_cogbuf h2A + COG@
		h200 u/mod
\ 							( firstblock remainder numblocks -- )
		rot swap
\							( remainder firstblock numblocks -- )
		dup
		if
			2dup bounds
			do
				i sd_blockread
				sd_cogbuf h80 bounds
				do
					i cog>pad
					pad h80 .str
				h20 +loop
			loop
		then
\ 							( remainder firstblock numblocks -- )
		+ sd_blockread
\ 							( remainder -- )
		sd_cogbuf h80 bounds
		do
			i
			cog>pad
			pad over h80 min
			.str
			h80 -
			dup 0 <=
			if
				leave
			then
		h20 +loop
		drop				
	else
		drop
	then
	padbl
;
\
\ sd_read ( filename -- ) read the file and emit the chars
: sd_read
	sd_find sd_readblk
;
\
\ sd_load ( cstr -- ) loads the file, routes the file to the next free forth cog
: sd_load
	cogid nfcog iolink
	sd_read cr cr
	cogid iounlink
;
\
\ sd_loadblk ( n1 -- ) n1 - the header block for the fileloads the file,
\ 			routes the file to the next free forth cog
: sd_loadblk
	cogid nfcog iolink
	sd_readblk cr cr
	cogid iounlink
;

7 .

\
\
\ sd_trunc ( length filename -- ) sets the number of bytes used in the file to length
: sd_trunc
	sd_find dup
	if
		dup sd_blockread
		swap sd_cogbuf h2B + COG@ h200 u* min
		sd_cogbuf h2A + COG!
		sd_blockwrite
	else
		drop
	then
	padbl
;
\
\
\
\ sd_stat ( filename -- ) prints stats for the file
: sd_stat
	sd_find dup
	if
		sd_blockread
		." File Length:~h09~h09" sd_cogbuf h2A + COG@
		dup h200 u/mod swap if 1+ then .num ."  blocks " .num ."  bytes~h0D"
		." Num Blocks Allocated:~h09" sd_cogbuf h2B + COG@
		dup .num ."  blocks " h200 u* .num ."  bytes~h0D"
	else
		drop
	then
;
\
\
\ _readlong ( addr -- long ) reads an unaligned long
: _readlong
	dup h3 and
	if
		dup h3 + C@ h8 lshift
		over 2+ C@ or h8 lshift
		over 1+ C@ or h8 lshift
		swap C@ or
	else
		L@
	then
;
\
\
\ _sd_appendbytes ( src byteoffset nbytes  -- updatedsrc )
\ t0	- nybtes
\ t1	- byteoffset
\ tbuf	- src
: _sd_appendbytes
	dup 0=
	if
		2drop
	else
		t0 W!
		t1 W!
		tbuf W!

		t1 W@ h3 and
		if
\							( -- )
			h4 t1 W@ h3 and -
\							( nfillbytes -- )
			-1 over h3 lshift rshift
\							( nfillbytes cogbufmask --  )
			t1 W@ 4/ sd_cogbuf + tuck COG@
\							( nfillbytes cogaddr cogbufmask cogbufdata --  )
			and
\							( nfillbytes cogaddr cogbufdata --  )
\
			tbuf W@ _readlong t1 W@
			h3 and h3 lshift
			lshift or			
\							( nfillbytes cogaddr cogbufdata --  )
			swap COG!
			dup t1 W+!
			dup tbuf W+!
			negate t0 W+!
\							( -- )
		then
\
		tbuf W@ t1 W@ 4/ sd_cogbuf + t0 W@ h4 u/mod swap
		if
			1+
		then
		bounds
		do
			dup _readlong
			i COG!
			h4 +
		loop
		drop
		tbuf W@ t0 W@ +
	then
;
8 .

\
\ sd_appendblk( addr size headerblk -- ) append buffer of size to the file at headerblk
: sd_appendblk
	dup sd_blockread
\							( addr size fileblock -- )
	over sd_cogbuf h2A + COG@
\							( addr size fileblock size filesize -- )
	+ dup sd_cogbuf h2B + COG@ h200 u*
\							( addr size fileblock newsize newsize allocatedsize -- )
	<
	if
\							( addr size fileblock newsize -- :: newsize fileblock )
		>r dup >r 1+
\							( addr size firstdatablock --  :: newsize fileblock )
		sd_cogbuf h2A + COG@
		h200 u/mod rot +
\							( addr size offset datablock --  :: newsize fileblock )
		begin
			dup >r sd_blockread
\							( addr size offset -- :: newsize fileblock datablock size -- )
			over >r rot swap
\							( size addr offset -- :: newsize fileblock datablock size -- )
			h200 over - r> min
\							( size addr offset numbytesthisblock -- :: newsize fileblock datablock -- )
			dup >r _sd_appendbytes r>
\							( size addr numbytesthisblock -- :: newsize fileblock datablock -- )
			rot swap - 0
\							( addr size 0 -- :: newsize fileblock datablock -- )
			over 0 <= r>
			dup sd_blockwrite
			1+
			swap
\							( addr size 0 datablock flag -- :: newsize fileblock -- )
		until
		r> dup sd_blockread
		r> sd_cogbuf h2A + COG!
		sd_blockwrite
	then
	drop 3drop
;
\
\ sd_append( addr size filename -- ) append buffer of size to the file
: sd_append
	sd_find dup
	if
		sd_appendblk	
	else
		3drop
	then
;
\
\
\ _sd_dn ( dirname -- t/f )
: _sd_dn
	C@++ + 1- C@ h2F <>
	if
		." INVALID DIRNAME~h0D"
		0
	else
		-1
	then
;
\
\
\ ls ( -- )
: ls sd_ls ;
\
\ cd dirname ( -- )
: cd
	parsenw
	dup 0= 
	if
		drop
	else
		dup _sd_dn
		if
			sd_cd
		else
			drop
		then
	then
;
\
\
\
\ cd.. ( -- )
: cd.. sd_cd.. ;
\
\ cd/ ( -- )
: cd/ v_currentdir COG@ sd_blockread sd_cogbuf h2E + COG@ v_currentdir COG! ;
\
\ cwd ( -- ) print the current directory
: cwd
	sd_cwd pad .cstr cr padbl
;
\
\
\ mkdir dirname ( -- )
: mkdir
	parsenw dup 0=
	if
		drop
	else
		dup _sd_dn
		if
			sd_createdir drop
		else
			drop
		then
	then
;
\
\
\ _sd_fsp ( -- cstr ) filename, if cstr is 0 no file found
: _sd_fsp
	parsenw dup
	if
		dup sd_find 0=
		if
			drop 0
		then
	then
;
\
\
\ fread filename ( -- )
: fread _sd_fsp dup if sd_read else drop _fnf then ;
\
\ fcreate filename ( numblocks_to_allocate -- )
: fcreate parsenw dup if swap sd_createfile drop else 2drop then ;
\
\ fwrite filename ( numblocks_to_allocate -- )
: fwrite parsenw dup if sd_write else 2drop then ;
\
\ fstat filename ( -- )
: fstat _sd_fsp dup if sd_stat else drop _fnf then ;
\
\ fload filename ( -- )
: fload _sd_fsp dup if sd_load else drop _fnf then ;

c" Loaded sdfs.f~h0D" .cstr

