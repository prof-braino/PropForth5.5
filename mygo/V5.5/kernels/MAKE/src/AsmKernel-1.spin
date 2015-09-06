{{

Copyright (c) 2012 Sal Sanci

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Yet Another Forth

PropForth V5 is a major advance. The kernel has not changed much as it was
stable. The major changes have to do with the paging in and out of assembler
words, and extending the forms for single instruction assembler words. This
allowed the kernel to get smaller and faster.

This forth is case sensitive!!!!!!

By default there are now 176 longs free in the cog. The stacks are still in
the cogs, and this takes up 64 longs, 32 for the data stack and 32 for the
return stack. Found this tradeoff to be worth it.

The core of function is kept small, and functions like debugging can be
loaded in if they are needed.

When PropForth starts, cog 0 is the spin cog which starts everything up.
It starts cog 6 as a forth cog (this constant can be chaged in spin) which
loads the serial driver (230.4Kb if you need different modify the constants),
in cog 7.  At this speed the unoptimized kernels are easily overrun. If you
are experimenting with these kernels, run at 57.6K or use throttling to slow
down the number of characters per second.



THIS IS NOT AN ANSI FORTH!
It is a minimal forth tuned for the propeller. However most words adhere to the ANSI standard.

Locks 0 - 7 are allocated by the spin startup code are by forth.
0 - the forth dictionary
1 - the eeprom

Forth is a language which I like for microcontrollers. It is intended to allow interactive development
on the microcontroller.

The Propeller architecture is different enough from the norm to require a slightly different Forth.
So this is uniquely developed for the propeller. If you don't like it, the source follows. Indulge yourself.

Names are case sensitive in THIS forth, so aCount and acount are NOT the same, in this implementation the max
length for a name is 31 characters. Names are stored as a counted string. 1 byte for the length, and up to 31 bytes
for the name. The upper bits are used as follows.
$80 - 0 - this is an assembler word
      1 - this is a forth word
$40 - 0 - this is not an immediate word
      1 - this is an immediate word
$20 - 0 - do not execute in interactive mode if the immediate word flag is set
      1 - execute this word in intercactive mode if the immediate flag is set

Be sure these flags are masked if you are manipulating names with the counted string routines.                  

The cog memory is used for the assembler code and variables to run Forth, a 32 long stack,
and a 32 long return stack. There are about 176 free registers for code and data in each cog running forth.

cogdata:

Each cog has an area assigned to it, and this area is used forth cog specific data. Though this area is in
main memory there is an agreed upon isolation. When a cog is started the par register points to this area.

The forth dictionary is stored in main memory and is shared. So updating the dictionary requires it be
locked so only one cog at a time can update the dictionary. Variables are defined in the dictionary.


In the cog, memory is accessed via COG@ and COG! as a long.

In main memory, variables can be a long (32 bits), a word (16 bits). The most efficient
are words. This forth is implemented using words. Longs need to be long aligned and can waste bytes.


main memory:

Main memory can be accessed as a long, L! L@, a word, W! W@, and as a character C! C@ ,

There is an area of main memory reserved for each cog, the cogdata area. The PAR register is
initialized with the start of the 224 bytes allocated to each cog. This area is where IO communcation is done,
and system variables for each cog are stored.                   
              
There is stack and return stack checking for overflow and underflow.
For the stack, this only occurs on words which access more then the top item on the stack.
So using C@ with an empty stack will return a value and not trigger stack checking. However
C! with an empty stack will trigger a stack underflow.
Trade between size performance and error checking, seemed reasonable.


}}

