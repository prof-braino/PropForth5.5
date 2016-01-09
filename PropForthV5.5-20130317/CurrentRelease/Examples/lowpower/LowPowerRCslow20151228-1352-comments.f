fl

\ 20151228 - move to github, from 20130406
\ sleep ( -- ) go into low power mode until a transition is detected on the serial input line to the cog

: sleep

\ print out a message, and pause, this will allow the serial driver to output the message before we shut it down

  ." ~h0D~h0DGOING TO SLEEP~h0D~h0D" 100 delms

\ shut down all the cogs but this one
  8 0
  do
    i cogid <>
    if
      i cogstop
    then
  loop

\ make sure the serial input pin is an input

  $S_rxpin pinin

\ n1 0 hubopr drop is the same as a clkset, which writes to the propeller CLK register
\ setting the propeller CLK register to zero, sets the main clock to RCSLOW (13 - 33Khz)

  0 0 hubopr drop

\ wait for the serial line to be high

  $S_rxpin >m dup waitpeq

\ wait for the serial line to be lo

  $S_rxpin >m dup waitpne

\ turn on the oscillator and PLL, assumes we have a crystal/resonator of 4 - 16 Mhz

  h_68 0 hubopr drop

\ wait at least 10 millisec for the oscillator and pll to stabilize
\ we are still running with a main clock of 13 - 33Khz, so this loop is longer than 10 ms

  100 0
  do
  loop

\ set the clock to be 16x the crystal

  h_6F 0 hubopr drop

\ and execute the onboot word, this performs the initialization sequence

  0 onboot drop

  ." ~h0D~h0D AWAKE~h0D~h0D" 100 delms

;


