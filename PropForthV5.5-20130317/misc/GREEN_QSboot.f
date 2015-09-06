fl

fswrite btstat.f


\ for the HC06
\ green wire
[ifndef hcProgPin
	22 wconstant hcProgPin
]
\ white/orange wire
[ifndef hcRx
	26 wconstant hcRx
]
\ white/green wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

]


hcSerialCog cogreset 100 delms
c" hcRx hcTx hcBaud serial" hcSerialCog cogx 100 delms
1 hcSerialCog sersetflags


hcProgPin pinhi hcProgPin pinout

c" AT" hcSend
c" AT+VERSION" hcSend

hcProgPin pinlo 

...

fswrite btinit.f


\ for the HC06
\ green wire
[ifndef hcProgPin
	22 wconstant hcProgPin
]
\ white/orange wire
[ifndef hcRx
	26 wconstant hcRx
]
\ white/green wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef hcBaud
	d_230400 4/ wconstant hcBaud
]
[ifndef hcSerialCog
	0 wconstant hcSerialCog
]

[ifndef hcSend
: hcSend
	cogid hcSerialCog iolink .cstr 1000 delms cogid iounlink cr
;

]

hcProgPin pinhi hcProgPin pinout

c" AT" hcSend
c" AT+VERSION" hcSend
c" AT+NAMESanciQStart" hcSend
c" AT+PIN1111" hcSend
c" AT+PN" hcSend
c" AT+BAUD9" hcSend


hcProgPin pinlo 

\ after the hc05 is power cycled, the baud rate will change, not like the hc06

...


fswrite boot.f
hA state orC! version W@ .cstr cr cr cr



: getfile
	." ~h0D........~h0D"
	fsread
	." ~h0D,,,,,,,,~h0D"
;


\ findEETOP ( -- n1 ) the top of the eeprom + 1
: findEETOP
\
\ search 32k block increments until we get a fail
\
	0
	h100000 h8000
	do
		i t0 2 eereadpage
		if
			leave
		else
			i h7FFE + t0 3 eereadpage
			if
				leave
			else
				drop i h8000 +
			then
		then
	h8000 +loop
;

c" boot.f - Finding top of eeprom, " .cstr findEETOP ' fstop 2+ alignl L! forget findEETOP c" Top of eeprom at: " .cstr fstop . cr


c" boot.f - DONE PropForth Loaded~h0D~h0D" .cstr hA state andnC!

\ white/orange wire
[ifndef hcRx
	26 wconstant hcRx
]
\ white/green wire
[ifndef hcTx
	27 wconstant hcTx
]

[ifndef _ready_led
	23 wconstant _ready_led
]

c" QS__" prop W@ ccopy
: onreset6
	fkey? and fkey? and or h1B <>
	if
		$S_con iodis $S_con cogreset 100 delms
		c" _ready_led dup pinout pinhi" $S_con cogx
		c" hcRx hcTx 57600 serial" $S_con cogx 100 delms
		cogid >con
	then
	c" onreset6" (forget)
;


...

fswrite manifest.txt

home.html
pins.html
term.html

...



fswrite home.html

<!DOCTYPE html>
<html>
	<head>
		<script>
		
		var autorunTimer;
		
		function setJavascriptError( e) {
			document.getElementById("idErrorStatus").innerHTML = "<h1>Javascript Error</h1><p>" + e + '</p><p><button onclick="Android.goHome()">goHome</button></p>';
		}
		function setPageid() {
			try {
				document.getElementById("idPage").innerHTML= window.location.href + " - " + Android.version();
			} catch( e) { setJavascriptError("setPageid ERROR: " + e); }
		}
		function setBackgroundOff(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundOff();
			} catch( e) { setJavascriptError("setBackgroundOff ERROR: " + e); }
		}
		function setBackgroundOn(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundOn();
			} catch( e) { setJavascriptError("setBackgroundOn ERROR: " + e); }
		}
		function setBackgroundInfo(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundInfo();
			} catch( e) { setJavascriptError("setBackgroundInfo ERROR: " + e); }
		}
		
		function myTimer() {
			try {
				var d=new Date();
				var t=d.toLocaleTimeString();
				document.getElementById("idTime").innerHTML=t;
				
				if(Android.isBluetoothConnected()) {
					var err = Android.getBluetoothError();
					if( err.length > 0) {
						document.getElementById("idErrorStatus").innerHTML = err;
					}				
				} else {
						document.getElementById("idErrorStatus").innerHTML = "BLUETOOTH DISCONNECTED";
				}
			} catch(e) { setJavascriptError("myTimer ERROR: " + e); }
		}
		function doBodyOnLoad() {
			try {
				setPageid();
				setBackgroundInfo("idInfoBanner");
				setBackgroundOn("idPins");
				setBackgroundOn("idTerm");
				setInterval(function(){myTimer()},100);
			} catch(e) { setJavascriptError("doBodyOnLoad ERROR: " + e); }
		}
		</script>
		
	</head>
	<body onload="doBodyOnLoad()">
		<table><tr id="idInfoBanner" style="text-align:center;">
		<td id="idPage"        style="width:40%;" >Page</td>
		<td id="idTime"        style="width:20%;" >Time</td>
		<td id="idErrorStatus" style="width:40%;" >No problems</td>
		</tr></table>
		<br><br><br>
		
		<button id="idPins" onclick='document.location.replace("pins.html")'>pins.html</button>
		<button id="idTerm" onclick='document.location.replace("term.html")'>term.html</button>
		<br><br><br>
		<button onclick="Android.goHome()">goHome</button>

	</body>
</html>


...

fswrite pins.html
<!DOCTYPE html>
<html>
	<head>
		<script>
		
		var autorunTimer;
		
		function setJavascriptError( e) {
			document.getElementById("idErrorStatus").innerHTML = "<h1>Javascript Error</h1><p>" + e + '</p><p><button onclick="Android.goHome()">goHome</button></p>';
		}
		function setPageid() {
			try {
				document.getElementById("idPage").innerHTML= window.location.href + " - " + Android.version();
			} catch( e) { setJavascriptError("setPageid ERROR: " + e); }
		}
		function setBackgroundOff(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundOff();
			} catch( e) { setJavascriptError("setBackgroundOff ERROR: " + e); }
		}
		function setBackgroundOn(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundOn();
			} catch( e) { setJavascriptError("setBackgroundOn ERROR: " + e); }
		}
		function setBackgroundInfo(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundInfo();
			} catch( e) { setJavascriptError("setBackgroundInfo ERROR: " + e); }
		}
		
		function myTimer() {
			try {
				var d=new Date();
				var t=d.toLocaleTimeString();
				document.getElementById("idTime").innerHTML=t;
				
				var nd = Android.btread();
				if(nd.length > 0) {
					document.getElementById("idCogina").innerHTML = nd;
				}				
				Android.btwrite("base W@ hex ina COG@ .long space cnt COG@ .long base W!\x0D");
				
				if(Android.isBluetoothConnected()) {
					var err = Android.getBluetoothError();
					if( err.length > 0) {
						document.getElementById("idErrorStatus").innerHTML = err;
					}				
				} else {
						document.getElementById("idErrorStatus").innerHTML = "BLUETOOTH DISCONNECTED";
				}
			} catch(e) { setJavascriptError("myTimer ERROR: " + e); }
		}
		function doBodyOnLoad()
		{
			try {
				setPageid();
				setBackgroundInfo("idInfoBanner");
				Android.btwrite("hA state orC!\x0D");
				Android.btwrite("d16 dup pinout pinlo d17 dup pinout pinlo d18 dup pinout pinlo d19 dup pinout pinlo\x0D");
				Android.btwrite("d20 dup pinout pinlo d21 dup pinout pinlo d22 dup pinout pinlo\x0D");
				setInterval(function(){myTimer()},100);
			} catch(e) {
				setJavascriptError("doBodyOnLoad ERROR: " + e);
			}
		}
		function doBodyOnUnload() {
			try {
				Android.btwrite("d16 dup pinlo pinin d17 dup pinlo pinin d18 dup pinlo pinin d19 dup pinlo pinin\x0D");
				Android.btwrite("d20 dup pinlo pinin d21 dup pinlo pinin d22 dup pinlo pinin\x0D");
				Android.btwrite("hA state andnC!\x0D");
			} catch(e) { setJavascriptError("doBodyOnUnload ERROR: " + e); }
		}
		</script>
	</head>
	<body onload="doBodyOnLoad()" onunload="doBodyOnUnload()">
		<table><tr id="idInfoBanner" style="text-align:center;">
		<td id="idPage"        style="width:40%;" >Page</td>
		<td id="idTime"        style="width:20%;" >Time</td>
		<td id="idErrorStatus" style="width:40%;" >No problems</td>
		</tr></table>
		<br><br><br>
		<p id="idCogina">INDATA</p>
		
		<button onclick="Android.btwrite('d16 pinlo\x0D')">16 OFF</button>
		<button onclick="Android.btwrite('d16 pinhi\x0D')">16 ON</button>
	
		<button onclick="Android.btwrite('d17 pinlo\x0D')">17 OFF</button>
		<button onclick="Android.btwrite('d17 pinhi\x0D')">17 ON</button>
	
		<button onclick="Android.btwrite('d18 pinlo\x0D')">18 OFF</button>
		<button onclick="Android.btwrite('d18 pinhi\x0D')">18 ON</button>
		<br>
		<button onclick="Android.btwrite('d19 pinlo\x0D')">19 OFF</button>
		<button onclick="Android.btwrite('d19 pinhi\x0D')">19 ON</button>
		
		<button onclick="Android.btwrite('d20 pinlo\x0D')">20 OFF</button>
		<button onclick="Android.btwrite('d20 pinhi\x0D')">20 ON</button>
		
		<button onclick="Android.btwrite('d21 pinlo\x0D')">21 OFF</button>
		<button onclick="Android.btwrite('d21 pinhi\x0D')">21 ON</button>
		<br><br><br>
		<button onclick="Android.goAppHome()">goAppHome</button>
	</body>
</html>


...

fswrite term.html

<!DOCTYPE html>
<html>
	<head>
		<script>
		function setJavascriptError( e) {
			document.getElementById("idErrorStatus").innerHTML = "<h1>Javascript Error</h1><p>" + e + '</p><p><button onclick="Android.goHome()">goHome</button></p>';
		}
		function setPageid() {
			try {
				document.getElementById("idPage").innerHTML= window.location.href + " - " + Android.version();
			} catch( e) { setJavascriptError("setPageid ERROR: " + e); }
		}
		function setBackgroundOff(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundOff();
			} catch( e) { setJavascriptError("setBackgroundOff ERROR: " + e); }
		}
		function setBackgroundOn(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundOn();
			} catch( e) { setJavascriptError("setBackgroundOn ERROR: " + e); }
		}
		function setBackgroundInfo(i) {
			try {
					document.getElementById(i).style.backgroundColor=Android.getColorBackgroundInfo();
			} catch( e) { setJavascriptError("setBackgroundInfo ERROR: " + e); }
		}
		function myTimer() {
			try {
				var d=new Date();
				var t=d.toLocaleTimeString();
				document.getElementById("idTime").innerHTML=t;
				
				if(Android.isBluetoothConnected()) {
					var err = Android.getBluetoothError();
					if( err.length > 0) {
						document.getElementById("idErrorStatus").innerHTML = err;
					}				
				} else {
						document.getElementById("idErrorStatus").innerHTML = "BLUETOOTH DISCONNECTED";
				}
				
				var nd = Android.btread();
				if(nd.length > 0) {
					document.getElementById("dout").innerHTML=document.getElementById("dout").innerHTML+nd;
				}
			} catch(e) { setJavascriptError("myTimer ERROR: " + e); }
		}
		function getInputData() {
			var rc  = "";
			try {
				rc = document.getElementById("din").value;
				rc = rc.replace(/\\r/g , "\x0D");
				rc = rc.replace(/\\P/g , "\x10");
				rc = rc.replace(/\\Q/g , "\x11");
				rc = rc.replace(/\\S/g , "\x12");
			} catch(e) { setJavascriptError("getInputData ERROR: " + e); }
			return rc;
		}
		function setInputData( d) {
			var rc  = "";
			try {
				d = d.replace(/\x0D/g , "\\r");
				d = d.replace(/\x10/g , "\\P");
				d = d.replace(/\x11/g , "\\Q");
				d = d.replace(/\x12/g , "\\S");
				document.getElementById("din").value = d;
			} catch(e) { setJavascriptError("setInputData ERROR: " + e); }
		}
		function processMacros() {
			try {
				var mlist = "";
				var l = [];
				var o = JSON.parse(Android.JSONTest(Android.getAppSetPreferencesJSON("TERMmacro")));
				for( var m in o) {
					l.push(m);
				}
				var sl = l.sort();
				for(var i = 0; i < sl.length; i++) {
					if( o[sl[i]].length > 0) {
						mlist += "<button onclick='runMacro(" + '"' + sl[i] + '"' + ");'>" +sl[i]+ "</button>";
					}
				}
			} catch(e) { setJavascriptError("processMacros ERROR: " + e); }
			document.getElementById("macroButtons").innerHTML= mlist;
		}
		
		function addMacro() {
			var mname = "";
			try {
				mname = document.getElementById("macroName").value;
				document.getElementById("macroName").value = "";
				Android.setAppSetPreference("TERMmacro", mname, Android.b64Encode(getInputData()));
				processMacros();
			} catch(e) { setJavascriptError("addMacro ERROR: " + e); }
		}
		
		function runMacro( n ) {
			try {
				setInputData( Android.b64Decode(Android.getAppSetPreference("TERMmacro", n)));			
				Android.btwrite(getInputData());
			} catch(e) { setJavascriptError("runMacro ERROR: " + e); }
		}
		
		function doBodyOnLoad() {
			try {
				setPageid();
				setBackgroundInfo("idInfoBanner");
				processMacros();
				myTimer();
				setInterval(function(){myTimer();},300);
			} catch(e) { setJavascriptError("doBodyOnLoad ERROR: " + e); }
		}
		</script>
		
	</head>
	<body onload="doBodyOnLoad()">
		<table><tr id="idInfoBanner" style="text-align:center;">
		<td id="idPage"        style="width:40%;" >Page</td>
		<td id="idTime"        style="width:20%;" >Time</td>
		<td id="idErrorStatus" style="width:40%;" >No problems</td>
		</tr></table>
		<br>
		
		<button onclick='document.getElementById("dout").innerHTML=""'>CLEAR</button>
		<button onclick="Android.goAppHome()">goAppHome</button>
		<br>
		<pre id="dout">
		</pre><br>
		<input id="din" type="text" size="80"  value=""><br>
		<button onclick='document.getElementById("dout").innerHTML=""'>CLEAR</button>
		<button onclick='document.getElementById("din").value=""'>CLEAR INPUT</button>
		<button onclick='Android.btwrite(getInputData());'>SEND</button>
		<button onclick='Android.btwrite(getInputData()+"\x0D")'>SEND+CR</button>
		<input id="macroName" type="text" size="10"  value="">
		<button onclick="addMacro();">ADD MACRO</button>
		<br><br>
		<div id="macroButtons"></div>
		<br><br>
		<button onclick="Android.goAppHome()">goAppHome</button>

	</body>
</html>


...




