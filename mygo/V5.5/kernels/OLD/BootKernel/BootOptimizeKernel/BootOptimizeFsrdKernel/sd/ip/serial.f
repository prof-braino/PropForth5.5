100 fwrite  serial.f
\
\ serial ( n1 n2 n3 -- )
\ n1 - tx pin
\ n2 - rx pin
\ n3 - baud rate
\
\ _serial ( n1 n2 n3 -- )
\ n1 - tx pin
\ n2 - rx pin
\ n3 - clocks/bit
\
\ h00 - h04 -- io channel for serial driver
\ h04 - h84 -- receive buffer
\ h84 - hC4 -- transmit  buffer
\ hC4 - hC8 -- long - send a break for this number of clock cycles
\ hc8 - hCC -- flags
\       h_0000_0001 - if true do not expand cr to cr lf on transmit
\
\
lockdict create _serial forthentry
$C_a_lxasm w, h1BE  h113  1- tuck - h9 lshift or here W@ alignl cnt COG@ dup h10 rshift xor h3 andn xor h10 lshift or l,
z1SV06D l, 0 l, 0 l, 0 l, 0 l, z40 l, z40 l, 0 l,
0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l,
0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l,
0 l, 0 l, z1Si[CY l, z1YVZC0 l, z1SL04g l, z2Wi\KP l, z2WyZC0 l, z1by\K0 l,
zfy\G2 l, z1by\G1 l, z2Wy\OB l, z2Wi\ak l, zcy\G1 l, z1jix[S l, z20i\[Q l, z1Si[CY l,
z2WiP[f l, z24iPak l, z31VPW0 l, z1SJ04t l, z3[y\Sq l, z1SV04g l, z1Si[KW l, z1Si[KZ l,
z1Si[KW l, z1Si[K[ l, z1Si[KW l, z1Si[K\ l, z1Si[KW l, z1Si[K] l, z1SV051 l, z1Si[SY l,
z1YVZ40 l, z1SL05A l, z2WiP[K l, z20yPW1 l, z1WyPXy l, z26FP[L l, z1SQ05A l, z20iY[T l,
zFZ4K l, z2WyZ40 l, z2WiYZC l, z1SV05A l, z1Si[[Y l, z26FY[L l, z1SQ05N l, z2WiP[V l,
z6iPeC l, z4\PmD l, z1YLPn0 l, z1SQ05N l, z20iYfT l, ziPnL l, z24iYfT l, z20yYb1 l,
z4FPmD l, z1WyYcy l, z1SV05N l, z1Si[fY l, zAiPmG l, z1SQ05j l, z2WyPW0 l, z8FPZG l,
z18yPjG l, z1[ix[S l, z20iPqk l, z3ryPj0 l, z1bix[S l, z4iPqj l, z1YVPn0 l, z1SL05] l,
z2WiP[M l, z20yPW1 l, z1WyPWy l, z26FP[N l, z1SQ05] l, z20iYnU l, zFPnM l, z2WiYmC l,
z26VPjD l, z8dPZH l, z1YQPW1 l, z2WoP[0 l, z2WtPWA l, z4FPaj l, z1SV05] l, z1Si[nY l,
z26FYnN l, z1SQ062 l, z1YVZC0 l, z1SQ062 l, z20iYvU l, ziZCN l, z24iYvU l, z20yYr1 l,
z1WyYry l, z1SV062 l, z2WiQ7j l, z20yQ34 l, z2WiQFj l, z20yQB8 l, z2WiZJB l, z1SyLI[ l,
z2WyZO1 l, zfiZRB l, z1SyLI[ l, z2WyZW1 l, zfiZZB l, z1SyLI[ l, z2WiZij l, z20yZb4 l,
z2WiZnT l, z20yZl0 l, z2WiZyj l, z20yZr2 l, z2WyP[0 l, z8FPaj l, z2Wy[Cg l, z2Wy[L1 l,
z2Wy[TA l, z2Wy[\N l, z2Wy[g] l, z2Wy[p2 l, z1bix[S l, z1bixnS l, z1Si[4X l, z1YFZVl l,
z1SL06c l, z2Wy\09 l, z2Wi\CQ l, zby\82 l, z20i\Fk l, z20i\CQ l, z1Si[4X l, z2WiP[c l,
z24iPak l, z31VPW0 l, z1SJ06k l, z1XFZVl l, zjy[r1 l, z3[y\6j l, z1SJ06c l, zby[rN l,
z1Wy[uy l, z2WiZ4a l, z1SV06c l,
freedict
\
\
\
: serial clkfreq swap u/ c" SERIAL" cds W! 4 state andnC! 0 io hC4 + L! 0 io hC8 + L! _serial ;
\
\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[ifndef term
: term over cognchan min
        ." Hit CTL-F to exit comterm" cr
        >r >r cogid 0 r> r> (iolink)
        begin key dup h6 = if drop 1 else emit 0 then until
        cogid iounlink ;
]

\ on PLAB2
: startbrb
5 cogreset
100 delms c" 31 pinhi 31 pinout 1 0 57600 serial" 5 cogx
100 delms 1 5 sersetflags
100 delms c" ~h0D ~h0D ~h0D ~h0D" 5 cogx
100 delms c" 1 7 sersetflags" 5 cogx
100 delms 5 0 term
;

\ on PLAB3
: startprot
5 cogreset
100 delms c" 31 pinhi 31 pinout 1 0 57600 serial" 5 cogx
100 delms 1 5 sersetflags
100 delms c" ~h0D ~h0D ~h0D ~h0D" 5 cogx
100 delms c" 1 7 sersetflags" 5 cogx
100 delms 5 0 term
;

\ on PLAB3
: startdemo
6 cogreset
100 delms c" 31 pinhi 31 pinout 3 4 57600 serial" 6 cogx 100 delms 1 6 sersetflags
100 delms c" ~h0D ~h0D ~h0D ~h0D" 6 cogx
100 delms c" 1 7 sersetflags" 6 cogx
100 delms 6 0 term
;


\ 

...

