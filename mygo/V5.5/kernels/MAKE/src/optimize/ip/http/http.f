
mountusr

mkdir http/
cd http/

\
\ These files are low level files which provide the headers for the various documents
\
\

1 fwrite header200htm
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" C@++ c" header200htm" sd_append
c" ~h0D~h0AExpires: Fri, 25 Dec 2015 05:00:00 GMT" C@++ c" header200htm" sd_append
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" C@++ c" header200htm" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header200htm" sd_append
c" ~h0D~h0AContent-Type: text/html" C@++ c" header200htm" sd_append
c" ~h0D~h0AContent-Length: " C@++ c" header200htm" sd_append

1 fwrite header200fsp
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: no-cache" C@++ c" header200fsp" sd_append
c" ~h0D~h0AExpires: Sat, 9 Apr 2011 05:00:00 GMT" C@++ c" header200fsp" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header200fsp" sd_append
c" ~h0D~h0AContent-Type: text/html" C@++ c" header200fsp" sd_append
c" ~h0D~h0ATransfer-Encoding: chunked~h0D~h0A~h0D~h0A" C@++ c" header200fsp" sd_append

1 fwrite header404
HTTP/1.1 404 Not Found...
c" ~h0D~h0AExpires: Fri, 25 Dec 2015 05:00:00 GMT" C@++ c" header404" sd_append
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" C@++ c" header404" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header404" sd_append
c" ~h0D~h0AContent-Type: text/html" C@++ c" header404" sd_append
c" ~h0D~h0AContent-Length: " C@++ c" header404" sd_append

1 fwrite header200png
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" C@++ c" header200png" sd_append
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" C@++ c" header200png" sd_append
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" C@++ c" header200png" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header200png" sd_append
c" ~h0D~h0AContent-Type: image/png" C@++ c" header200png" sd_append
c" ~h0D~h0AContent-Length: " C@++ c" header200png" sd_append

1 fwrite header200ico
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" C@++ c" header200ico" sd_append
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" C@++ c" header200ico" sd_append
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" C@++ c" header200ico" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header200ico" sd_append
c" ~h0D~h0AContent-Type: image/x-icon" C@++ c" header200ico" sd_append
c" ~h0D~h0AContent-Length: " C@++ c" header200ico" sd_append

1 fwrite header200jpg
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" C@++ c" header200jpg" sd_append
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" C@++ c" header200jpg" sd_append
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" C@++ c" header200jpg" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header200jpg" sd_append
c" ~h0D~h0AContent-Type: image/jpeg" C@++ c" header200jpg" sd_append
c" ~h0D~h0AContent-Length: " C@++ c" header200jpg" sd_append

1 fwrite header200gif
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" C@++ c" header200gif" sd_append
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" C@++ c" header200gif" sd_append
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" C@++ c" header200gif" sd_append
c" ~h0D~h0AConnection: close" C@++ c" header200gif" sd_append
c" ~h0D~h0AContent-Type: image/gif" C@++ c" header200gif" sd_append
c" ~h0D~h0AContent-Length: " C@++ c" header200gif" sd_append

h_10000 fwrite reqdata
NULL
...


\ 1 fwrite index.html
\ HTTP/1.1 302 Found
\ Location: /index.htm
\ Connection: close...

\
\ This is the page returned when an invalid link is requested
\

1 fwrite r404.htm
<html>
	<head>
		<title>Not Found</title>
	</head>
	<body>
		<p>
			<h1>Not Found</h1>
		</p>
		<p>
			<a href="/index.htm">Home</a>
		</p>
	</body>
</html>
...


\
\ 
\ the root page
\

1 fwrite index.htm
<html>
	<head>
		<link rel="shorcut icon" href="/favicon.ico" />
		<title>index.htm</title>
	</head>
	<body>
		<h1>index.htm</h1>
		<p><a href="testhtm.htm">testhtm.htm - root page for the static pages tests</a></p>
		<p><a href="testfsp.htm">testfsp.htm - root page for the forth server pages tests</a></p>
	</body>
</html>
...

\
\ followed by various test and demo pages
\

d50 fwrite testhtm.htm
<html>
	<head>
		<title>testhtm.htm</title>
	</head>
	<body>
		<h1>testhtm.htm</h1>
		<p><a href="testinvalid.htm">testinvalid.htm - a page with valid and invalid links</a></p>
		<p><a href="testgraphic.htm">testgrahpic.htm - a page with a graphic</a></p>
	</body>
</html>
...


d50 fwrite testinvalid.htm
<html>
	<head>
		<title>testinvalid.htm</title>
	</head>
	<body>
		<h1>testinvalid.htm</h1>
		<p><a href="/index.htm">index.htm - the root page</a></p>
		<p><a href="/invalid.htm">invalid.htm</a></p>
		<p><a href="/invalid">invalid</a></p>
	</body>
</html>
...

d50 fwrite testgraphic.htm
<html>
	<head>
		<title>testgraphic.htm</title>
	</head>
	<body>
		<h1>testgraphic.htm</h1>
		<p><a href="/index.htm">index.htm - the root page</a></p>
		<p>And of course a gratuitous image</p>
		<p><img src="/test.png"></p>
	</body>
</html>
...


d50 fwrite testfsp.htm
<html>
	<head>
		<title>testfsp.htm</title>
	</head>
	<body>
		<h1>testfsp.htm</h1>
		<p><a href="/index.htm">index.htm - the root page</a></p>
		<p><a href="testnull.fsp">testnull.fsp - a page with no active elements</a></p>
		<p><a href="testcnt.fsp">testcnt.fsp - a page which display the cnt register</a></p>
		<p><a href="test1.fsp">test1.fsp - a page with forms</a></p>
		<p><a href="time.fsp">time.fsp - a page for time</a></p>
	</body>
</html>
...



d50 fwrite testnull.fsp
<html>
	<head>
		<title>testnull.fsp</title>
	</head>
	<body>
		<h1>testnull.fsp</h1>
		<p><a href="/index.htm">index.htm - the root page</a></p>
		<p>A static fsp page.</p>
	</body>
</html>
...

d50 fwrite testcnt.fsp
<html>
	<head>
		<title>testcnt.fsp</title>
	</head>
	<body>
		<h1>testcnt.fsp</h1>
		<p><a href="/index.htm">index.htm - the root page</a></p>
		<pre>
cnt COG@ dup .
		</pre>
		<p><?f cnt COG@ dup . ?></p>
		<pre>
cnt COG@ dup . swap - dup .
		</pre>
		<p><?f cnt COG@ dup . swap - dup . ?></p>
		<pre>
d1_000_000 um* clkfreq um/mod nip .
		</pre>
		<p><?f d1_000_000 um* clkfreq um/mod nip . ?> microseconds</p>
	</body>
</html>
...


10 fwrite test1.fsp
<html>
	<head>
		<title>test1.fsp</title>
	</head>
	<body>
		<p>

		<?f
c" Running on: " .cstr prop W@ propid W@ . .cstr c"  COG: " .cstr cogid . cr c" <br>~h0D" .cstr
: test1tmp
	." REQDATA: length: " reqdata C@ .  ."  data: " reqdata .cstr cr ." <br>~h0D"
;

test1tmp

		?>

		</p>

		<p><a href="index.htm">Index</a></p>
		<p>FORM1<br>
			<form name="test1form1" action="/test1.fsp" method="get" >
				<input type="hidden" name="version" value="<?f version W@ .cstr ?>"/>
				Username: <input type="text" name="user" />
				<input type="submit" value="Submit" />
			</form>
		</p>
		<p>FORM2<br>
			<form name="test1form2" action="/test1.fsp" method="get" >
				<input type="hidden" name="version" value="<?f version W@ .cstr ?>"/>
				Username: <input type="text" name="user" value="FRED" />
				<input type="submit" value="Submit" />
			</form>
		</p>
	</body>
</html>
...


10 fwrite time.fsp
<html>
	<head>
		<title>time.fsp</title>
	</head>
	<body>
		<h1>time.fsp</h1>
		<p><a href="/index.htm">index.htm - the root page</a></p>
<pre>
<?f
\ nn ( cstr -- num)
: nn
	C@++
	over C@ h3D =
	if
		1- swap 1+ swap
	then
	2dup
	xisnumber
	if
		xnumber
	else
		2drop 0
	then
;


c" Running on: " .cstr prop W@ propid W@ . .cstr c"  COG: " .cstr cogid . cr c" <br>~h0D" .cstr
: test1tmp
	." REQDATA: length: " reqdata C@ .  ."  data: " reqdata .cstr cr ." <br>~h0D"
;

test1tmp

?>
</pre>

<h4>cnt COG@ dup . mountusr cd http/ ls</h4>
<pre>
<?f cnt COG@ dup . cr mountusr cd http/ ls ?>
</pre>
<h4>hA nfcog cogstate orC! fload rtc.f fload daytime.f hA nfcog cogstate andnC!</h4>
<pre>
<?f
hA nfcog cogstate orC!
fload rtc.f
fload daytime.f 
hA nfcog cogstate andnC! 
?>
</pre>

<pre>
<?f
: t
	padbl
	reqdata pad ccopy
	h20 pad C!
	1 >in W!

	h3D parseword
	if
		pad>in nextword drop
		h26 parseword
	if
		pad>in nextword nn timezone L!
		h3D parseword
	if
		pad>in nextword drop
		h20 parseword
	if
		pad>in nextword nn rtccorrect

	thens
	padbl
;		

: tt
	reqdata C@ 0 >
	if
		t
	then
;


tt
?>
</pre>

<p>
	<form name="timeform1" action="/time.fsp" method="get" >
	TimeZone: <input type="text" name="timezone" value="<?f timezone L@ . ?>" />
	RTC Correction (100th of a second): <input type="text" name="rtccorrect" value="<?f rtccorrect? . ?>" />
	<input type="submit" value="Submit" />
	</form>
</p>


<h4> datetime rtccorrect? 0 ip_SOCKdaytime rtccorrect rtccorrect? 0 ip_SOCKtelnet </h4>
<pre>
<?f
datetime
rtccorrect? dup .
0 ip_SOCKdaytime
rtccorrect
rtccorrect? .
0 ip_SOCKtelnet
?>
</pre>

<h4> cnt COG@ dup . swap - dup . </42>
<pre>
<?f cnt COG@ dup . swap - dup . ?>
</pre>
<h4> d1_000_000 um* clkfreq um/mod nip . </h4>
<pre>
<?f d1_000_000 um* clkfreq um/mod nip . ?> microseconds
</pre>
	</body>
</html>

...



[ifndef test_getnumber
\ test_getnumber ( -- n1 t/f)
: test_getnumber
	parsenw
\						\ ( cstr/0 == - )
	dup
	if
\						\ ( cstr/0 == - )
		dup C@++ isnumber
\						\ ( cstr t/f == - )
		if
\						\ got a valid number
			C@++ number -1
\						\ ( n1 -1 == - )
		else
\						\ print an error message
			_udf dup .cstr cr
			0
\						\ ( cstr 0 == - )			
		then
	else
		0
\						\ ( 0 0 == - )			
	then
;

\ test_params ( -- n1 .. ncount count)
: test_params
	0 >r
\						\ ( == count )
	begin
		test_getnumber
\						\ ( ... n1/ctr -1/0 == count )
		if
						\ ( ... n1 == count )
			r> 1+ >r 0
						\ ( ... n1 0 == count+1 )
		else
\						\ ( ... -1 == count )
			drop -1
		then
	until
	r>
\						\ ( ... count == - )
;




\ append_hex ( cstr -- )
: _append_hex 
	begin
		accept
		0 >in W!
		test_params dup
		if
			dup t0 W! 0
			do
				t0 W@ i 1+ - pad + C!
			loop
			pad over t0 W@ swap
			sd_append
			0
		else
			drop -1
		then
	until
	drop
;

lockdict wvariable tname 20 allot freedict


: fwrite_hex
	base W@ hex swap
	tname ccopy tname
	0 over sd_trunc _append_hex
	base W!
;
]


10 fcreate test.png

c" test.png" fwrite_hex
89 50 4E 47 0D 0A 1A 0A 00 00 00 0D 49 48 44 52
00 00 00 64 00 00 00 64 08 02 00 00 00 FF 80 02
03 00 00 00 01 73 52 47 42 00 AE CE 1C E9 00 00
00 04 67 41 4D 41 00 00 B1 8F 0B FC 61 05 00 00
00 20 63 48 52 4D 00 00 7A 26 00 00 80 84 00 00
FA 00 00 00 80 E8 00 00 75 30 00 00 EA 60 00 00
3A 98 00 00 17 70 9C BA 51 3C 00 00 01 BC 49 44
41 54 78 5E ED DD C1 92 82 30 10 45 51 E7 FF 3F
1A 83 0B C7 C2 4C 91 EE 69 48 89 87 72 65 A5 23
5E DE 4D 02 8B F0 B3 2C CB CD 31 48 A0 C1 72 0C
12 B8 0D B6 D3 6C 55 10 85 71 02 60 8D B3 EA 25
6B 70 B0 BB 7C B3 77 8A 9D 64 AD 14 DA 0C F9 E5
9F 06 E0 ED 00 EB 8F 58 80 15 D0 05 2C B0 8E 19
5E 25 4B B2 24 6B FA C2 85 86 FF D5 30 50 3F FD
6A 9F 79 02 92 15 48 46 17 56 A0 FE CC 0B 3B FD
B7 AA 92 15 B8 4F FF 84 A6 FD B8 54 C2 3A 66 BE
9E 90 A7 F5 91 5E EF CF 80 D5 C1 02 56 20 A1 60
81 75 CC BC 2D 59 92 25 59 D3 97 20 34 A4 21 0D
69 18 B0 00 2C B0 7E 33 B0 3E 4A 98 9E 88 AA 13
30 1B 06 AE 25 58 60 59 3A 54 0D 3D E9 7E 68 48
43 1A A6 F5 A9 2A A4 21 0D 69 58 65 53 BA 1F 1A
D2 90 86 69 7D AA 0A 69 48 43 1A 56 D9 94 EE 87
86 34 A4 61 5A 9F AA 42 1A D2 90 86 55 36 A5 FB
A1 21 0D 69 98 D6 A7 AA 90 86 34 A4 61 95 4D E9
7E 68 48 43 1A A6 F5 A9 2A A4 21 0D 69 58 65 53
BA 1F 1A D2 90 86 69 7D AA 0A 69 48 43 1A 56 D9
94 EE 87 86 34 A4 61 5A 9F AA C2 33 34 FC 84 AD
40 06 CF F1 D8 4D 30 8E F1 A1 2A 2A 45 FD B4 6E
6C BD 39 7A A5 C1 1A 25 D5 66 53 B0 C0 2A 1A A4
36 6B 33 C9 92 2C C9 0A DC B0 80 05 56 60 C8 00
EB A2 B0 5E DF B9 F0 58 A1 6D 8F EE 97 D7 7A 53
C3 D0 ED CE A6 51 8B 43 AF EC 1B DF 14 B2 FF 9F
C1 7A 66 05 AC C1 07 39 8F 3D 65 76 DB 4A 96 64
ED 86 A4 D3 40 B2 02 D4 C0 02 2B 40 20 D0 54 B2
C0 0A 10 08 34 95 AC 00 AC 3B 4E 23 73 BD BC 90
55 0D 00 00 00 00 49 45 4E 44 AE 42 60 82



10 fcreate favicon.ico


c" favicon.ico" fwrite_hex
00 00 01 00 01 00 20 20 00 00 01 00 08 00 A8 08
00 00 16 00 00 00 28 00 00 00 20 00 00 00 40 00
00 00 01 00 08 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 80 00 00 80 00 00 00 80 80 00 80 00
00 00 80 00 80 00 80 80 00 00 C0 C0 C0 00 C0 DC
C0 00 F0 CA A6 00 33 00 00 04 00 00 33 04 33 00
33 04 33 33 00 04 16 16 16 04 1C 1C 1C 04 22 22
22 04 29 29 29 04 55 55 55 04 4D 4D 4D 04 42 42
42 04 39 39 39 04 80 7C FF 04 50 50 FF 04 93 00
D6 04 FF EC CC 04 C6 D6 EF 04 D6 E7 E7 04 90 A9
AD 04 00 FF 33 04 00 00 66 04 00 00 99 04 00 00
CC 04 00 33 00 04 00 33 33 04 00 33 66 04 00 33
99 04 00 33 CC 04 00 33 FF 04 00 66 00 04 00 66
33 04 00 66 66 04 00 66 99 04 00 66 CC 04 00 66
FF 04 00 99 00 04 00 99 33 04 00 99 66 04 00 99
99 04 00 99 CC 04 00 99 FF 04 00 CC 00 04 00 CC
33 04 00 CC 66 04 00 CC 99 04 00 CC CC 04 00 CC
FF 04 00 FF 66 04 00 FF 99 04 00 FF CC 04 33 FF
00 04 FF 00 33 04 33 00 66 04 33 00 99 04 33 00
CC 04 33 00 FF 04 FF 33 00 04 33 33 33 04 33 33
66 04 33 33 99 04 33 33 CC 04 33 33 FF 04 33 66
00 04 33 66 33 04 33 66 66 04 33 66 99 04 33 66
CC 04 33 66 FF 04 33 99 00 04 33 99 33 04 33 99
66 04 33 99 99 04 33 99 CC 04 33 99 FF 04 33 CC
00 04 33 CC 33 04 33 CC 66 04 33 CC 99 04 33 CC
CC 04 33 CC FF 04 33 FF 33 04 33 FF 66 04 33 FF
99 04 33 FF CC 04 33 FF FF 04 66 00 00 04 66 00
33 04 66 00 66 04 66 00 99 04 66 00 CC 04 66 00
FF 04 66 33 00 04 66 33 33 04 66 33 66 04 66 33
99 04 66 33 CC 04 66 33 FF 04 66 66 00 04 66 66
33 04 66 66 66 04 66 66 99 04 66 66 CC 04 66 99
00 04 66 99 33 04 66 99 66 04 66 99 99 04 66 99
CC 04 66 99 FF 04 66 CC 00 04 66 CC 33 04 66 CC
99 04 66 CC CC 04 66 CC FF 04 66 FF 00 04 66 FF
33 04 66 FF 99 04 66 FF CC 04 CC 00 FF 04 FF 00
CC 04 99 99 00 04 99 33 99 04 99 00 99 04 99 00
CC 04 99 00 00 04 99 33 33 04 99 00 66 04 99 33
CC 04 99 00 FF 04 99 66 00 04 99 66 33 04 99 33
66 04 99 66 99 04 99 66 CC 04 99 33 FF 04 99 99
33 04 99 99 66 04 99 99 99 04 99 99 CC 04 99 99
FF 04 99 CC 00 04 99 CC 33 04 66 CC 66 04 99 CC
99 04 99 CC CC 04 99 CC FF 04 99 FF 00 04 99 FF
33 04 99 CC 66 04 99 FF 99 04 99 FF CC 04 99 FF
FF 04 CC 00 00 04 99 00 33 04 CC 00 66 04 CC 00
99 04 CC 00 CC 04 99 33 00 04 CC 33 33 04 CC 33
66 04 CC 33 99 04 CC 33 CC 04 CC 33 FF 04 CC 66
00 04 CC 66 33 04 99 66 66 04 CC 66 99 04 CC 66
CC 04 99 66 FF 04 CC 99 00 04 CC 99 33 04 CC 99
66 04 CC 99 99 04 CC 99 CC 04 CC 99 FF 04 CC CC
00 04 CC CC 33 04 CC CC 66 04 CC CC 99 04 CC CC
CC 04 CC CC FF 04 CC FF 00 04 CC FF 33 04 99 FF
66 04 CC FF 99 04 CC FF CC 04 CC FF FF 04 CC 00
33 04 FF 00 66 04 FF 00 99 04 CC 33 00 04 FF 33
33 04 FF 33 66 04 FF 33 99 04 FF 33 CC 04 FF 33
FF 04 FF 66 00 04 FF 66 33 04 CC 66 66 04 FF 66
99 04 FF 66 CC 04 CC 66 FF 04 FF 99 00 04 FF 99
33 04 FF 99 66 04 FF 99 99 04 FF 99 CC 04 FF 99
FF 04 FF CC 00 04 FF CC 33 04 FF CC 66 04 FF CC
99 04 FF CC CC 04 FF CC FF 04 FF FF 33 04 CC FF
66 04 FF FF 99 04 FF FF CC 04 66 66 FF 04 66 FF
66 04 66 FF FF 04 FF 66 66 04 FF 66 FF 04 FF FF
66 04 21 00 A5 04 5F 5F 5F 04 77 77 77 04 86 86
86 04 96 96 96 04 CB CB CB 04 B2 B2 B2 04 D7 D7
D7 04 DD DD DD 04 E3 E3 E3 04 EA EA EA 04 F1 F1
F1 04 F8 F8 F8 04 F0 FB FF 00 A4 A0 A0 00 80 80
80 00 00 00 FF 00 00 FF 00 00 00 FF FF 00 FF 00
00 00 FF 00 FF 00 FF FF 00 00 FF FF FF 00 FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF F9 F9 F9 F9 FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF F9 F9 F9 F9 FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 FF FF FF FF FF FF F9 F9 F9 F9 FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 FF FF FF FF F9 F9 F9 F9 FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
F9 F9 FF FF FF FF F9 F9 F9 F9 FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FF FF FF FF FF FF FF FF FF FF FF FF
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FC FC FF FF
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FC FC FF FF
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FC FC FF FF
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
FC FC FC FC FC FC FC FC FC FC FC FC FC FC 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00




forget test_getnumber

{

3 fwrite wp1
=FWIKI SYNTAX=

Text is simply pured into a paragraph. This
means that carriage returnes are ignored. A blank
line will start a new paragraph.

So this is a new paragraph. If you want a heading it needs to be
at the begining of a line. The valid line headings are as follows:


=Level 1=
==Level 2==
===Level 3===
=+Level 4+=
=++Level 5++=

All of the heading must be on one line. To link to another page the syntax
is [[pagename|linktext]] or [[pagename]].

[[pagename|link text]]
[(httplink|link text)]
((image))

textlkwdmokwmo  wfjonwofnoufrn

**BOLD**
__underlined__
//italic//

<<
code
>>

*List item must be at the start of a line
 *one level of nesting for lists
  *two levels of nesting for list

-numbered list
 -one level of nesting
  -two levels of nesting

}
