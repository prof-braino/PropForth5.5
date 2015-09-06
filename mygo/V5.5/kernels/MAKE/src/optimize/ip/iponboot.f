\
\ assuming you want to start telnet
\
\
c" onboot" find drop pfa>nfa 1+ c" onb001" C@++ rot swap cmove
\
\ onboot ( n1 -- n1)
: onboot
	onb001 
\ do not execute if escape has been hit
	fkey? and fkey? and or h1B <>
	if
		startTelnet
	then
;
