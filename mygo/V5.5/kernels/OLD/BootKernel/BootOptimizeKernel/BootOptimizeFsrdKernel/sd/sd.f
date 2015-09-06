fl
\
\ for manual loading of the sd drivers
\
fswrite sd.f

\
\ SD CONFIG PARAMETERS BEGIN
\
\ definitions for io pins connecting to the sd card
\

\
\ Spinneret Configuration
\
[ifndef _sd_cs
h13 wconstant _sd_cs
]
[ifndef _sd_di
h14 wconstant _sd_di
]
[ifndef _sd_clk
h15 wconstant _sd_clk
]
[ifndef _sd_do
h10 wconstant _sd_do
]



{
\
\ PLAB CONFIG
\ 
[ifndef _sd_cs
h00 wconstant _sd_cs \ DAT3 PIN2 
]
[ifndef _sd_di
h01 wconstant _sd_di	\ CMD PIN3
]
[ifndef _sd_clk
h02 wconstant _sd_clk	\ CLK PIN6
]
[ifndef _sd_do
h03 wconstant _sd_do	\ DATA0 PIN8

}

\
\
\
\ SD CONFIG PARAMETERS END
\

fsload sd_init.f
fsload sd_run.f
fsload sdfs.f
: mountsys 1 sd_mount ;

...
