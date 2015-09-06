\
\ assuming you want to mount the filesystem on boot
\
\
c" onboot" find drop pfa>nfa 1+ c" onb001" C@++ rot swap cmove
\
\ onboot ( n1 -- n1) load the file sd_boot.f
: onboot
	onb001 1 sd_mount 
\ do not execute sd_boot.f if escape has been hit
	fkey? and fkey? and or h1B <>
	if
		c" sdboot.f" sd_load
	then
;
