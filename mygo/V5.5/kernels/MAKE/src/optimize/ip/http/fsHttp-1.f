fl

\
\
\ EC! ( n1 eeAddr -- )
[ifndef CW!
: EC!
	swap t0 C! t0 1 eewritepage
	if
		hA ERR
	then
;
]

\ fsAppend ( cstr -- )
: fsAppend
	_fslast dup
	if
\ cstr addr
		dup EW@ 
\ cstr addr flen
		over 2+ EC@ + 3 + over +
\ cstr addr cstr addrend clen 
		2 ST@ dup C@ rot swap
		bounds
		do
			1+
			dup C@ i
			EC!
		loop
		drop
\ cstr addr
		swap C@ over EW@ +
\ addr flen
		2dup swap EW!
		over 2+ EC@ + + 
		_fspa
		-1 swap dup fstop 1- <
		if
			EW!
		else
			2drop
		then	

	else
		drop
	then
;

\
\ These files are low level files which provide the headers for the various documents
\
\

fswrite header200htm
HTTP/1.1 200 Ok...

c" ~h0D~h0ACache-Control: public" fsAppend
c" ~h0D~h0AExpires: Fri, 25 Dec 2015 05:00:00 GMT" fsAppend
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close"  fsAppend
c" ~h0D~h0AContent-Type: text/html" fsAppend
c" ~h0D~h0AContent-Length: " fsAppend

fswrite header200fsp
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: no-cache" fsAppend
c" ~h0D~h0AExpires: Sat, 9 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close" fsAppend
c" ~h0D~h0AContent-Type: text/html" fsAppend
c" ~h0D~h0ATransfer-Encoding: chunked~h0D~h0A~h0D~h0A" fsAppend

fswrite header404
HTTP/1.1 404 Not Found...
c" ~h0D~h0AExpires: Fri, 25 Dec 2015 05:00:00 GMT" fsAppend
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close" fsAppend
c" ~h0D~h0AContent-Type: text/html" fsAppend
c" ~h0D~h0AContent-Length: " fsAppend

fswrite header200png
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" fsAppend
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" fsAppend
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close" fsAppend
c" ~h0D~h0AContent-Type: image/png" fsAppend
c" ~h0D~h0AContent-Length: " fsAppend

fswrite header200ico
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" fsAppend
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" fsAppend
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close" C@++ c" fsAppend
c" ~h0D~h0AContent-Type: image/x-icon" fsAppend
c" ~h0D~h0AContent-Length: " fsAppend

fswrite header200jpg
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" fsAppend
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" fsAppend
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close" C@++ c" fsAppend
c" ~h0D~h0AContent-Type: image/jpeg" fsAppend
c" ~h0D~h0AContent-Length: " fsAppend

fswrite header200gif
HTTP/1.1 200 Ok...
c" ~h0D~h0ACache-Control: public" fsAppend
c" ~h0D~h0AExpires:  Fri, 25 Dec 2015 05:00:00 GMT" fsAppend
c" ~h0D~h0ALast-Modified: Fri, 22 Apr 2011 05:00:00 GMT" fsAppend
c" ~h0D~h0AConnection: close" fsAppend
c" ~h0D~h0AContent-Type: image/gif" fsAppend
c" ~h0D~h0AContent-Length: " fsAppend




\
\ This is the page returned when an invalid link is requested
\

fswrite r404.htm
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

fswrite index.htm
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

fswrite testhtm.htm
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


fswrite testinvalid.htm
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

fswrite testgraphic.htm
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


fswrite testfsp.htm
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



fswrite testnull.fsp
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

fswrite testcnt.fsp
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


fswrite test1.fsp
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

fswrite time.fsp
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

<h4>cnt COG@ dup .</h4>
<pre>
<?f cnt COG@ dup . ?>
</pre>
<h4>hA nfcog cogstate orC! fsload rtc.f fsload daytime.f hA nfcog cogstate andnC!</h4>
<pre>
<?f
hA nfcog cogstate orC!
fsload rtc.f
fsload daytime.f 
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


