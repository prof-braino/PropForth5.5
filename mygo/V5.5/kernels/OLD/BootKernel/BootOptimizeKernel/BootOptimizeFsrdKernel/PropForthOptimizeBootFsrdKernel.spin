 {{

Copyright (c) 2011 Sal Sanci

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

PropForth is built on SpinForth and is really rev 2 of SpinForth. There have been many changes. As opposed to describing
them all, suffice it to say PropForth is really tuned to freeing up as many cog longs as possible. Found this was the
resource that was of most limit. Of course this is always traded against performance, and the performance considered
was compile performance.

This forth is case sensitive!!!!!! BIG CHANGE!

By default there are now 161 longs free in the cog. The stacks are still in the cogs, and this takes up 64 longs,
32 for the data stack and 32 for the return stack. Found this tradeoff to be worth it.

The core of function is kept small, and functions like debugging can be loaded in if they are needed.

When PropForth starts, cog 0 is the spin cog which starts everything up, and then loads the serial driver (57.6Kb if you need
different modify in the main spin startup routine), in cog 7 and starts cog 6 as a PropForth cog.

57.6K Baud is ok no delays necessary.

THIS IS NOT AN ANSI FORTH!
It is a minimal forth tuned for the propeller. However most words adhere to the ANSI standard.

Locks 0 - 7 are allocated by the spin startup code are by forth.
0 - the forth dictionary
1 - the eeprom

Forth is a language which I like for microcontrollers. It is intended to allow interactive development
on the microcontroller.

The Propeller architecture is different enough from the norm to require a slightly different Forth.
So this is uniquely developed for the propeller. If you don't like it, the source follows. Indulge yourself.

Names are case unique in THIS forth, so aCount and acount are NOT the same, in this implementation the max
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
and a 32 long return stack. There are about 160 free registers for code and data in each cog running forth.

Naming conventions:

cog:
  a_xxx - a forth word, an address poiting to code which can be executed as forth word
  c_xxx - cog code, point to code, but can not be executed as a forth word, for instance a subroutine
  v_xxx - a cog long, points to a variable

The execption to this is the special cog registers, which are named exactly as they are in the propeller
documentation. eg par, phsa, ctra, etc.


cogdata:

Each cog has an area assigned to it, and this area is used forth cog specific data. Though this are is in
main memory there is an agreed upon isolation. When a cog is started the par register points to this area.

The forth dictionary is stored in main memory and is shared. So updating the dictionary requires it be
locked so only one cog at a time can update the dictionary. Variables can be defined in the dictionary
or in the cog.

In the cog, there is only a long variable accessed via COG@ and COG!

In main memory, variables can be a long (32 bits), a word (16 bits). The most efficient
are words. This forth is implemented using words. Longs need to be long aligned and can waste bytes.


main memory:

Main memory can be accessed as a long, L! L@, a word, W! W@, and as a character C! C@ ,

There is an area of main memory reserved for each cog, the cogdata area. The PAR register is
initialized with the start of the 224 bytes allocated to each cog. This area is where IO communcation is done,
and system variables for each cog are stored.                   
              
There is stack and return stack checking for overflow and underflow.
For the stack, this only occurs on words which access more then the top item on the stack.
So using c@ with an empty stack will return a value and not trigger stack checking. However
C! with an empty stack will trigger a stack underflow.
Trade between size performance and error checking, seemed reasonable.

}}
CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  dlrS_cdsz = 224           ' $S_cdsz forth word 
  dlrS_txpin = 30           ' $S_txpin forth word 
  dlrS_rxpin= 31            ' $S_rxpin forth word 
  dlrS_baud = 57_600        ' $S_baud forth word 
  dlrS_con = 7              ' $S_con forth word
  startcog = 6
VAR


OBJ
' for the vgahires text driver
'  vgatext : "vga_hires_text"
PUB Main | tmp
' allocate locks for PropForth 
  locknew
  locknew
  locknew
  locknew
  locknew
  locknew
  locknew
  locknew

' and the memory variables
  bytefill( @cogdataPFA, 0, 8 * dlrS_cdsz)  
  WORD[ @_finitPFA + 2] := 0

' start forth cog
  coginit(startcog, @entryPFA, @cogdataPFA + (startcog * dlrS_cdsz))
' stop the spin cog 
  cogstop( 0)
    

DAT


a_base 
                        org     0
{{

Assembler Code                        

Assembler routines which correspond to forth words are documented in the forth area

}}                                                                                              
entryPFA

                        jmp     #a_next
a__xasmtwogtflagIMM
                        rdword  tregone , IP
                        add     IP , # 2
                        jmp     # a__xasmtwogtflag1
a__xasmtwogtflag
                        call    #a_stpoptreg
a__xasmtwogtflag1
                        rdword  tregsix , IP
                        movi    a__xasmtwogtflagi , tregsix
                        add     IP , # 2
                        
                        andn    a__xasmtwogtflagf1 , fCondMask
                        andn    a__xasmtwogtflagf2  , fCondMask
                        shl     tregsix , # 6
                        and     tregsix , fCondMask  wz

                if_nz   or      a__xasmtwogtflagf1  , tregsix
                if_nz   xor     tregsix , fCondMask
                if_nz   or      a__xasmtwogtflagf2  , tregsix                     
a__xasmtwogtflagi                        
                        and     stTOS , tregone
a__xasmtwogtflagf1
                        mov     stTOS , fLongMask
a__xasmtwogtflagf2
                        mov     stTOS , # 0     
                        jmp     #a_next


a__xasmtwogtoneIMM
                        rdword  tregone , IP
                        add     IP , # 2
                        jmp     # a__xasmtwogtones1
a__xasmtwogtone
                        call    #a_stpoptreg
a__xasmtwogtones1
                        rdword  tregsix , IP
                        movi    a__xasmtwogtonei , tregsix
                        add     IP , # 2
a__xasmtwogtonei                        
                        and     stTOS , tregone

                        jmp     #a_next

a__xasmonegtone
                        rdword  tregone, IP
                        movi    a__xasmonegtonei, tregone
                        add     IP, #2
a__xasmonegtonei                        
                        abs     stTOS, stTOS
                        jmp     #a_next

a__xasmtwogtz
                        rdword  tregone, IP
                        movi    a__xasmtwogtzi, tregone
                        add     IP, #2
                        call    #a_stpoptreg
a__xasmtwogtzi                        
                        abs     stTOS, tregone
a_drop
                        call    #a_stPop
                        jmp     #a_next
a_RSat
                        add     stTOS , rsPtr
                        add     stTOS , # 1
                        cmp     stTOS, # rsTop-1           wc,wz
              if_a      mov     tregsix , # $4
              if_a      jmp     # a_reset
                        jmp     # a_COGat
                        
a_STat
                        add     stTOS , stPtr
                        add     stTOS , # 1
                        cmp     stTOS, # stTop-1           wc,wz
              if_ae     mov     tregsix , # $3
              if_ae     jmp     # a_reset
                                               
a_COGat
                        movs    a_COGatget, stTOS
                        nop                             ' necessary, really needs to be documented
a_COGatget              mov     stTOS, stTOS
                        jmp     #a_next

a_RSbang
                        add     stTOS , rsPtr
                        add     stTOS , # 1
                        cmp     stTOS, # rsTop-1           wc,wz
              if_a      mov     tregsix , # $2
              if_a      jmp     # a_reset
                        jmp     # a_COGbang
                                   
a_STbang
                        add     stTOS , stPtr
                        add     stTOS , # 2
                        cmp     stTOS, # stTop-1           wc,wz
              if_ae     mov     tregsix , # $2
              if_ae     jmp     # a_reset
a_COGbang
                        movd    a_COGbangput, stTOS
                        call    #a_stPop
a_COGbangput            mov     stTOS, stTOS    
                        jmp     #a_drop
a_branch
                        rdword  tregone,IP        ' the next word
                        add     IP, tregone       ' add the offset
                        and     IP , fAddrMask
                        jmp     #a_next
a_doconw
                        call    #a_stPush
                        rdword  stTOS, IP
                        jmp     #a_exit
a_dovarl
                        add     IP, #3
                        andn    IP, #3          ' align to a long boundary
a_dovarw
                        call    #a_stPush
                        mov     stTOS, IP       
                        jmp     #a_exit
a_doconl                 
                        call    #a_stPush
                        add     IP, #3
                        andn    IP, #3          ' align to a long boundary
                        rdlong  stTOS, IP
                        jmp     #a_exit


a_litl               
                        call    #a_stPush
                        add     IP, #3
                        andn    IP, #3          ' align to a long boundary
                        rdlong  stTOS, IP
                        add     IP, #4
                        jmp     #a_next
a_litw
                        call    #a_stPush       
                        rdword  stTOS, IP
a_litw1                        
                        add     IP, #2
                        jmp     #a_next
a_exit
                        call    #a_rsPop
                        mov     IP, tregfive
'                        jmp     #a_next        SINCE WE ARE ALREADY There
a_next
a_debugonoff        
        if_never        jmpret a_dum_ret, # a_dum         ' when debug is loaded this address will be patched
                                                
                        rdword  tregone,IP                ' the next word
                        test    tregone, fMask    wz
        if_z            add     IP, #2                  ' if the one of the hi bits is not set, it is an assembler word,  inc IP
        if_z            jmp     tregone
                        rdword  tregone, IP               ' otherwise it is a forth word 
                        mov     tregfive, IP
                        add     tregfive, #2
                        mov     IP, tregone       
                        call    #a_rsPush
                        jmp     #a_next
a__maskin
                        and     stTOS, ina      wz
                        muxnz   stTOS, fLongMask
                        jmp     # a_next

a__maskouthi
                        jmp # a__maskoutex            wz

a__maskoutlo
                        test    stTOS, #0       wz
a__maskoutex
                        muxnz   outa, stTOS
                        jmp     # a_drop
                                                
a_rgt
                        call    #a_rsPop
                        call    #a_stPush
                        mov     stTOS, tregfive
                        jmp     #a_next
a_twogtr
                        mov     tregfive, stTOS
                        call    #a_stPop
                        call    #a_rsPush       
a_gtr
                        mov     tregfive, stTOS
                        call    #a_stPop
                        call    #a_rsPush
                        jmp     #a_next
a_lparenlooprparen
                        mov     tregone, #1
                        jmp     #a_lparenpluslooprparen1
a_lparenpluslooprparen
                        call    #a_stpoptreg        
a_lparenpluslooprparen1
                        call    #a_rsPop
                        mov     tregtwo, tregfive
                        call    #a_rsPop
                        add     tregfive, tregone
                        cmps    tregtwo, tregfive       wc ,wz
                if_a    call    #a_rsPush               ' branch
                if_a    mov     tregfive, tregtwo            ' branch
                if_a    call    #a_rsPush               ' branch
                if_a    jmp     #a_branch
                        jmp     #a_litw1        

a_zbranch
                        call    #a_stpoptreg
                        cmp     tregone, #0       wz      ' is the TOS zero?
                if_z    jmp     #a_branch 
                        jmp     #a_litw1

a_reset
                        mov     tregfive , par
                        add     tregfive , # $DE                     ' must align with the lasterr definition in forth
                        wrbyte  tregsix , tregfive  
                        coginit resetDreg
                        
{{                        

a_stPush - push stTOS on to stack

}}
a_stPush
                        movd    a_stPush1, stPtr    
                        cmp     stPtr, #stBot           wc
              if_b      mov     tregsix , # $1
              if_b      jmp     # a_reset
a_stPush1               mov     stPtr, stTOS               
                        sub     stPtr, #1
a_stPush_ret                        
                        ret                                  
{{

a_rsPush - push tregfive on to return stack

}}
a_rsPush
                        movd    a_rsPush1, rsPtr    
                        cmp     rsPtr, #rsBot           wc
              if_b      mov     tregsix , # $2
              if_b      jmp     # a_reset
a_rsPush1               mov     tregone, tregfive              
                        sub     rsPtr, #1
a_rsPush_ret                        
                        ret

{{

a_stpoptreg - move stTOS to tregone, and pop stTOS from stack

}}
a_stpoptreg                                                    
                        mov     tregone, stTOS    
{{

a_stPop - pop stTOS from stack

}}
a_stPop
                        add     stPtr, #1       
                        movs    a_stPop1, stPtr    
                        cmp     stPtr, #stTop           wc,wz
              if_ae     mov     tregsix , # $3
              if_ae     jmp     # a_reset
a_stPop1                mov     stTOS, stPtr
a_stPop_ret
a_stpoptreg_ret
                        ret                       
                               
{{

a_rsPop - pop tregfive from return stack

}}
a_rsPop
                        add     rsPtr, #1
                        movs    a_rsPop1, rsPtr    
                        cmp     rsPtr, #rsTop           wc,wz
              if_ae     mov     tregsix , # $4
              if_ae     jmp     # a_reset
a_rsPop1
a_dum
                        mov     tregfive, tregone
a_dum_ret
a_rsPop_ret                        
                        ret

                               
a_lxasm
                        add     IP, #3
                        andn    IP, #3          ' align to a long boundary
                        rdlong  tregsix , IP
                        
                        movd    a_lxasm1 , tregsix
                        mov     tregthree, tregsix
                        add     tregthree , # 1
a_lxasm1                        
                        cmp     tregsix , tregsix wz
              if_z      jmp     tregthree                       
                        
                        movd    a_lxasm2 , tregsix
                        shr     tregsix , # 9
                        and     tregsix , #$1FF
                       
a_lxasm2
                        rdlong  varend , IP
                        add     a_lxasm2 , fDestInc
                        add     IP , # 4
                        djnz    tregsix ,# a_lxasm2

                        jmp     tregthree                  

              
'
' variables used by the forth interpreter
'
                        
fDestInc                long    $00000200       ' -2
fCondMask               long    $003C0000       ' -1
fMask                   long    $FE00           ' 0
fAddrMask               long    $7FFF           ' 1
fLongMask               long    $FFFFFFFF       ' 2
resetDreg               long    0               ' 3
IP                      long    @fstartPFA  + $10               ' 4
stPtr                   long    ((@stTop - @a_base) /4) - 1     ' 5
rsPtr                   long    ((@rsTop - @a_base) /4) - 1     ' 6
stTOS                   long    0                               ' 7

{{
These variables are overlapped with the cog data area variables to save space
}}
cogdataPFA

tregone                 long    0               ' 8 working reg
tregtwo                 long    0               ' 9 working reg
tregthree               long    0               ' a working reg
tregfour                long    0               ' b working reg
tregfive                long    0               ' c working reg / call parameter reg
tregsix                 long    0               ' d working reg
stBot                                           ' e
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 ' e
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 ' 1e
                        
                        
stTop                                                                   ' 2e
rsBot
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 ' 2e
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 ' 3e
rsTop                                                                   ' 4e


varEnd                                                                  

{{

cogdata

This data area is used for variables which are unique to each instance of forth, like
inbyte, emitptr, >in, pad, etc...

}}
'cogdataPFA              long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0        ' 224 bytes cog 0  
'                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
'                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
'                        long    0,0, 0,0, 0,0, 0,0,
'                        long                         0,0, 0,0, 0,0, 0,0        ' 224 bytes cog 1
'                        long    0,0, 0,0, 0,0,                                   
                        long                   0,0,  0,0, 0,0, 0,0, 0,0           
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                         
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 224 bytes cog 2
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0          
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0
                        long                         0,0, 0,0, 0,0, 0,0         ' 224 bytes cog 3
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0          
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 224 bytes cog 4
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0           
                        long    0,0, 0,0, 0,0, 0,0
                        long                         0,0, 0,0, 0,0, 0,0         ' 224 bytes cog 5                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0           
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 224 bytes cog 6
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0           
                        long    0,0, 0,0, 0,0, 0,0
                        long                         0,0, 0,0, 0,0, 0,0         ' 224 bytes cog 7
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                          
{{

Start of the Forth Dicitonary

Dictionary Entry Structure
                        - there is no code pointer, it is inherent
LinkField               - points to the previous name field in the dictionary
        word
NameField
        byte            - length of the name field (lo 5 bits)
                        -  bit 7 ($80) set if it is a forth word 
                        -  bit 6 ($40) set if it is an immediate word 
                        -  bit 5 ($20) set if it is an eXecute word - execute this word in interactive mode as well
                                       if the immediate flag is set 
        bytes           - the actual name
                        - if the name is a word constant, and it starts with $C_ the spinMaker assumes it to be a reference to the cog data
                          space and sets the constant to be (name - a_base) /4.  If it starts with $H_ it is assumed to be a main memory
                          reference and the constant is set to be namePFA +$10
                          if the name is an assembler word the address is set to (a_name - a_base)/4 assembler names are not constants, they
                          are a different type of dictionary entry

ParameterField          - the list of addresses to execute, and literals for a forth word
                        - if it is a forth word one ofthe hi bit ($FE00) will be set
                        - assembler addresses are always < 512
                        - this of course means that the ForthDictStart must have at least 512 bytes used before it, since this is only
                          128 longs, and the assembler code, and forth stacks are before this, this is not an issue
                        - if it is an assembler word there is only 1 word and it is the assembler address
                         

Generated form forth code from here on in - written in forth spin generated
***************************************************************************************************************
***************************************************************************************************************
***************************************************************************************************************
}}



ForthDictStart

                        word    0
wlastnfaNFA             byte    $88,"wlastnfa"
wlastnfaPFA             word    (@a_dovarw - @a_base)/4
                        word    @H_lastlfa + $12

                        word    @wlastnfaNFA + $10
hereNFA                 byte    $84,"here"
herePFA                 word    (@a_dovarw - @a_base)/4
                        word    @wfreespacestart + $10

                        word    @hereNFA + $10
dictendNFA              byte    $87,"dictend"
dictendPFA              word    (@a_dovarw - @a_base)/4
                        word    @ForthMemoryEnd + $10

                        word    @dictendNFA + $10
memendNFA               byte    $86,"memend"
memendPFA               word    (@a_dovarw - @a_base)/4
                        word    @ForthMemoryEnd + $10

                        word    @memendNFA + $10
build_BootKernelNFA     byte    $90,"build_BootKernel"
build_BootKernelPFA     word    (@a_doconw - @a_base)/4
                        word    $0001

                        word    @build_BootKernelNFA + $10
propidNFA               byte    $86,"propid"
propidPFA               word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @propidNFA + $10
lparenproprparenNFA     byte    $86,"(prop)"
lparenproprparenPFA     word    @cqPFA + $10
                        byte    $04,"Prop"
                        word    (@a_exit - @a_base)/4

                        word    @lparenproprparenNFA + $10
lparenversionrparenNFA  byte    $89,"(version)"
lparenversionrparenPFA  word    @cqPFA + $10
                        byte    $20,"PropForth v5.0 2012JAN09 14:30 0"
                        word    (@a_exit - @a_base)/4

                        word    @lparenversionrparenNFA + $10
propNFA                 byte    $84,"prop"
propPFA                 word    (@a_dovarw - @a_base)/4
                        word    $0AB2

                        word    @propNFA + $10
versionNFA              byte    $87,"version"
versionPFA              word    (@a_dovarw - @a_base)/4
                        word    $0AC8

                        word    @versionNFA + $10
_finitNFA               byte    $86,"_finit"
_finitPFA               word    (@a_dovarw - @a_base)/4
                        word    $FFFF

                        word    @_finitNFA + $10
dlrS_cdszNFA            byte    $87,"$S_cdsz"
dlrS_cdszPFA            word    (@a_doconw - @a_base)/4
                        word    dlrS_cdsz

                        word    @dlrS_cdszNFA + $10
dlrS_txpinNFA           byte    $88,"$S_txpin"
dlrS_txpinPFA           word    (@a_doconw - @a_base)/4
                        word    dlrS_txpin

                        word    @dlrS_txpinNFA + $10
dlrS_rxpinNFA           byte    $88,"$S_rxpin"
dlrS_rxpinPFA           word    (@a_doconw - @a_base)/4
                        word    dlrS_rxpin

                        word    @dlrS_rxpinNFA + $10
dlrS_baudNFA            byte    $87,"$S_baud"
dlrS_baudPFA            word    (@a_doconw - @a_base)/4
                        word    dlrS_baud

                        word    @dlrS_baudNFA + $10
dlrS_conNFA             byte    $86,"$S_con"
dlrS_conPFA             word    (@a_doconw - @a_base)/4
                        word    dlrS_con

                        word    @dlrS_conNFA + $10
dlrH_entryNFA           byte    $88,"$H_entry"
dlrH_entryPFA           word    (@a_doconw - @a_base)/4
                        word    @entryPFA  + $10

                        word    @dlrH_entryNFA + $10
dlrH_cogdataNFA         byte    $8A,"$H_cogdata"
dlrH_cogdataPFA         word    (@a_doconw - @a_base)/4
                        word    @cogdataPFA  + $10

                        word    @dlrH_cogdataNFA + $10
dlrH_cqNFA              byte    $85,"$H_cq"
dlrH_cqPFA              word    (@a_doconw - @a_base)/4
                        word    @cqPFA  + $10

                        word    @dlrH_cqNFA + $10
dlrH_dqNFA              byte    $85,"$H_dq"
dlrH_dqPFA              word    (@a_doconw - @a_base)/4
                        word    @dqPFA  + $10

                        word    @dlrH_dqNFA + $10
dlrC_a_exitNFA          byte    $89,"$C_a_exit"
dlrC_a_exitPFA          word    (@a_doconw - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @dlrC_a_exitNFA + $10
dlrC_a_dovarwNFA        byte    $8B,"$C_a_dovarw"
dlrC_a_dovarwPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_dovarw - @a_base)/4

                        word    @dlrC_a_dovarwNFA + $10
dlrC_a_doconwNFA        byte    $8B,"$C_a_doconw"
dlrC_a_doconwPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_doconw - @a_base)/4

                        word    @dlrC_a_doconwNFA + $10
dlrC_a_branchNFA        byte    $8B,"$C_a_branch"
dlrC_a_branchPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_branch - @a_base)/4

                        word    @dlrC_a_branchNFA + $10
dlrC_a_litwNFA          byte    $89,"$C_a_litw"
dlrC_a_litwPFA          word    (@a_doconw - @a_base)/4
                        word    (@a_litw - @a_base)/4

                        word    @dlrC_a_litwNFA + $10
dlrC_a_twogtrNFA        byte    $88,"$C_a_2>r"
dlrC_a_twogtrPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_twogtr - @a_base)/4

                        word    @dlrC_a_twogtrNFA + $10
dlrC_a_lparenlooprparenNFA byte    $8B,"$C_a_(loop)"
dlrC_a_lparenlooprparenPFA word    (@a_doconw - @a_base)/4
                        word    (@a_lparenlooprparen - @a_base)/4

                        word    @dlrC_a_lparenlooprparenNFA + $10
dlrC_a_lparenpluslooprparenNFA byte    $8C,"$C_a_(+loop)"
dlrC_a_lparenpluslooprparenPFA word    (@a_doconw - @a_base)/4
                        word    (@a_lparenpluslooprparen - @a_base)/4

                        word    @dlrC_a_lparenpluslooprparenNFA + $10
dlrC_a_zbranchNFA       byte    $8C,"$C_a_0branch"
dlrC_a_zbranchPFA       word    (@a_doconw - @a_base)/4
                        word    (@a_zbranch - @a_base)/4

                        word    @dlrC_a_zbranchNFA + $10
dlrC_a_litlNFA          byte    $89,"$C_a_litl"
dlrC_a_litlPFA          word    (@a_doconw - @a_base)/4
                        word    (@a_litl - @a_base)/4

                        word    @dlrC_a_litlNFA + $10
dlrC_a_lxasmNFA         byte    $8A,"$C_a_lxasm"
dlrC_a_lxasmPFA         word    (@a_doconw - @a_base)/4
                        word    (@a_lxasm - @a_base)/4

                        word    @dlrC_a_lxasmNFA + $10
dlrC_varEndNFA          byte    $89,"$C_varEnd"
dlrC_varEndPFA          word    (@a_doconw - @a_base)/4
                        word    (@varEnd - @a_base)/4

                        word    @dlrC_varEndNFA + $10
dlrC_fMaskNFA           byte    $88,"$C_fMask"
dlrC_fMaskPFA           word    (@a_doconw - @a_base)/4
                        word    (@fMask - @a_base)/4

                        word    @dlrC_fMaskNFA + $10
dlrC_resetDregNFA       byte    $8C,"$C_resetDreg"
dlrC_resetDregPFA       word    (@a_doconw - @a_base)/4
                        word    (@resetDreg - @a_base)/4

                        word    @dlrC_resetDregNFA + $10
dlrC_IPNFA              byte    $85,"$C_IP"
dlrC_IPPFA              word    (@a_doconw - @a_base)/4
                        word    (@IP - @a_base)/4

                        word    @dlrC_IPNFA + $10
dlrC_a_nextNFA          byte    $89,"$C_a_next"
dlrC_a_nextPFA          word    (@a_doconw - @a_base)/4
                        word    (@a_next - @a_base)/4

                        word    @dlrC_a_nextNFA + $10
blNFA                   byte    $82,"bl"
blPFA                   word    (@a_doconw - @a_base)/4
                        word    $0020

                        word    @blNFA + $10
minusoneNFA             byte    $82,"-1"
minusonePFA             word    (@a_litl - @a_base)/4
                        long    $FFFFFFFF
                        word    (@a_exit - @a_base)/4

                        word    @minusoneNFA + $10
zNFA                    byte    $81,"0"
zPFA                    word    (@a_doconw - @a_base)/4
                        word    $0000

                        word    @zNFA + $10
oneNFA                  byte    $81,"1"
onePFA                  word    (@a_doconw - @a_base)/4
                        word    $0001

                        word    @oneNFA + $10
twoNFA                  byte    $81,"2"
twoPFA                  word    (@a_doconw - @a_base)/4
                        word    $0002

                        word    @twoNFA + $10
parNFA                  byte    $83,"par"
parPFA                  word    (@a_doconw - @a_base)/4
                        word    $01F0

                        word    @parNFA + $10
cntNFA                  byte    $83,"cnt"
cntPFA                  word    (@a_doconw - @a_base)/4
                        word    $01F1

                        word    @cntNFA + $10
inaNFA                  byte    $83,"ina"
inaPFA                  word    (@a_doconw - @a_base)/4
                        word    $01F2

                        word    @inaNFA + $10
outaNFA                 byte    $84,"outa"
outaPFA                 word    (@a_doconw - @a_base)/4
                        word    $01F4

                        word    @outaNFA + $10
diraNFA                 byte    $84,"dira"
diraPFA                 word    (@a_doconw - @a_base)/4
                        word    $01F6

                        word    @diraNFA + $10
_wkeytoNFA              byte    $87,"_wkeyto"
_wkeytoPFA              word    (@a_dovarw - @a_base)/4
                        word    $2000

                        word    @_wkeytoNFA + $10
_cnipNFA                byte    $C5,"_cnip"
_cnipPFA                word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @twominusPFA + $10
                        word    @dupPFA + $10
                        word    @WatPFA + $10
                        word    @overPFA + $10
                        word    @twominusPFA + $10
                        word    @WbangPFA + $10
                        word    @herePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_cnipNFA + $10
_xasmtwogtflagIMMNFA    byte    $0E,"_xasm2>flagIMM"
_xasmtwogtflagIMMPFA    word    (@a__xasmtwogtflagIMM - @a_base)/4

                        word    @_xasmtwogtflagIMMNFA + $10
_xasmtwogtflagNFA       byte    $0B,"_xasm2>flag"
_xasmtwogtflagPFA       word    (@a__xasmtwogtflag - @a_base)/4

                        word    @_xasmtwogtflagNFA + $10
_xasmtwogtoneIMMNFA     byte    $0B,"_xasm2>1IMM"
_xasmtwogtoneIMMPFA     word    (@a__xasmtwogtoneIMM - @a_base)/4

                        word    @_xasmtwogtoneIMMNFA + $10
_xasmtwogtoneNFA        byte    $08,"_xasm2>1"
_xasmtwogtonePFA        word    (@a__xasmtwogtone - @a_base)/4

                        word    @_xasmtwogtoneNFA + $10
_xasmonegtoneNFA        byte    $08,"_xasm1>1"
_xasmonegtonePFA        word    (@a__xasmonegtone - @a_base)/4

                        word    @_xasmonegtoneNFA + $10
_xasmtwogtzNFA          byte    $08,"_xasm2>0"
_xasmtwogtzPFA          word    (@a__xasmtwogtz - @a_base)/4

                        word    @_xasmtwogtzNFA + $10
lxasmNFA                byte    $05,"lxasm"
lxasmPFA                word    (@a_lxasm - @a_base)/4

                        word    @lxasmNFA + $10
_maskinNFA              byte    $07,"_maskin"
_maskinPFA              word    (@a__maskin - @a_base)/4

                        word    @_maskinNFA + $10
_maskoutloNFA           byte    $0A,"_maskoutlo"
_maskoutloPFA           word    (@a__maskoutlo - @a_base)/4

                        word    @_maskoutloNFA + $10
_maskouthiNFA           byte    $0A,"_maskouthi"
_maskouthiPFA           word    (@a__maskouthi - @a_base)/4

                        word    @_maskouthiNFA + $10
andNFA                  byte    $83,"and"
andPFA                  word    (@a__xasmtwogtone - @a_base)/4
                        word    $00C7
                        word    (@a_exit - @a_base)/4

                        word    @andNFA + $10
andnNFA                 byte    $84,"andn"
andnPFA                 word    (@a__xasmtwogtone - @a_base)/4
                        word    $00CF
                        word    (@a_exit - @a_base)/4

                        word    @andnNFA + $10
LatNFA                  byte    $82,"L@"
LatPFA                  word    (@a__xasmonegtone - @a_base)/4
                        word    $0017
                        word    (@a_exit - @a_base)/4

                        word    @LatNFA + $10
CatNFA                  byte    $82,"C@"
CatPFA                  word    (@a__xasmonegtone - @a_base)/4
                        word    $0007
                        word    (@a_exit - @a_base)/4

                        word    @CatNFA + $10
WatNFA                  byte    $82,"W@"
WatPFA                  word    (@a__xasmonegtone - @a_base)/4
                        word    $0009
                        word    (@a_exit - @a_base)/4

                        word    @WatNFA + $10
RSatNFA                 byte    $03,"RS@"
RSatPFA                 word    (@a_RSat - @a_base)/4

                        word    @RSatNFA + $10
STatNFA                 byte    $03,"ST@"
STatPFA                 word    (@a_STat - @a_base)/4

                        word    @STatNFA + $10
COGatNFA                byte    $04,"COG@"
COGatPFA                word    (@a_COGat - @a_base)/4

                        word    @COGatNFA + $10
LbangNFA                byte    $82,"L!"
LbangPFA                word    (@a__xasmtwogtz - @a_base)/4
                        word    $0010
                        word    (@a_exit - @a_base)/4

                        word    @LbangNFA + $10
CbangNFA                byte    $82,"C!"
CbangPFA                word    (@a__xasmtwogtz - @a_base)/4
                        word    $0000
                        word    (@a_exit - @a_base)/4

                        word    @CbangNFA + $10
WbangNFA                byte    $82,"W!"
WbangPFA                word    (@a__xasmtwogtz - @a_base)/4
                        word    $0008
                        word    (@a_exit - @a_base)/4

                        word    @WbangNFA + $10
RSbangNFA               byte    $03,"RS!"
RSbangPFA               word    (@a_RSbang - @a_base)/4

                        word    @RSbangNFA + $10
STbangNFA               byte    $03,"ST!"
STbangPFA               word    (@a_STbang - @a_base)/4

                        word    @STbangNFA + $10
COGbangNFA              byte    $04,"COG!"
COGbangPFA              word    (@a_COGbang - @a_base)/4

                        word    @COGbangNFA + $10
branchNFA               byte    $06,"branch"
branchPFA               word    (@a_branch - @a_base)/4

                        word    @branchNFA + $10
huboprNFA               byte    $86,"hubopr"
huboprPFA               word    (@a__xasmtwogtone - @a_base)/4
                        word    $001F
                        word    (@a_exit - @a_base)/4

                        word    @huboprNFA + $10
hubopfNFA               byte    $86,"hubopf"
hubopfPFA               word    (@a__xasmtwogtflag - @a_base)/4
                        word    $C01F
                        word    (@a_exit - @a_base)/4

                        word    @hubopfNFA + $10
doconwNFA               byte    $06,"doconw"
doconwPFA               word    (@a_doconw - @a_base)/4

                        word    @doconwNFA + $10
doconlNFA               byte    $06,"doconl"
doconlPFA               word    (@a_doconl - @a_base)/4

                        word    @doconlNFA + $10
dovarwNFA               byte    $06,"dovarw"
dovarwPFA               word    (@a_dovarw - @a_base)/4

                        word    @dovarwNFA + $10
dovarlNFA               byte    $06,"dovarl"
dovarlPFA               word    (@a_dovarl - @a_base)/4

                        word    @dovarlNFA + $10
dropNFA                 byte    $04,"drop"
dropPFA                 word    (@a_drop - @a_base)/4

                        word    @dropNFA + $10
dupNFA                  byte    $83,"dup"
dupPFA                  word    (@a_litw - @a_base)/4
                        word    $0000
                        word    (@a_STat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @dupNFA + $10
eqNFA                   byte    $81,"="
eqPFA                   word    (@a__xasmtwogtflag - @a_base)/4
                        word    $A186
                        word    (@a_exit - @a_base)/4

                        word    @eqNFA + $10
exitNFA                 byte    $04,"exit"
exitPFA                 word    (@a_exit - @a_base)/4

                        word    @exitNFA + $10
gtNFA                   byte    $81,">"
gtPFA                   word    (@a__xasmtwogtflag - @a_base)/4
                        word    $1186
                        word    (@a_exit - @a_base)/4

                        word    @gtNFA + $10
litwNFA                 byte    $04,"litw"
litwPFA                 word    (@a_litw - @a_base)/4

                        word    @litwNFA + $10
litlNFA                 byte    $04,"litl"
litlPFA                 word    (@a_litl - @a_base)/4

                        word    @litlNFA + $10
lshiftNFA               byte    $86,"lshift"
lshiftPFA               word    (@a__xasmtwogtone - @a_base)/4
                        word    $005F
                        word    (@a_exit - @a_base)/4

                        word    @lshiftNFA + $10
ltNFA                   byte    $81,"<"
ltPFA                   word    (@a__xasmtwogtflag - @a_base)/4
                        word    $C186
                        word    (@a_exit - @a_base)/4

                        word    @ltNFA + $10
maxNFA                  byte    $83,"max"
maxPFA                  word    (@a__xasmtwogtone - @a_base)/4
                        word    $0087
                        word    (@a_exit - @a_base)/4

                        word    @maxNFA + $10
minNFA                  byte    $83,"min"
minPFA                  word    (@a__xasmtwogtone - @a_base)/4
                        word    $008F
                        word    (@a_exit - @a_base)/4

                        word    @minNFA + $10
minusNFA                byte    $81,"-"
minusPFA                word    (@a__xasmtwogtone - @a_base)/4
                        word    $010F
                        word    (@a_exit - @a_base)/4

                        word    @minusNFA + $10
orNFA                   byte    $82,"or"
orPFA                   word    (@a__xasmtwogtone - @a_base)/4
                        word    $00D7
                        word    (@a_exit - @a_base)/4

                        word    @orNFA + $10
xorNFA                  byte    $83,"xor"
xorPFA                  word    (@a__xasmtwogtone - @a_base)/4
                        word    $00DF
                        word    (@a_exit - @a_base)/4

                        word    @xorNFA + $10
overNFA                 byte    $84,"over"
overPFA                 word    (@a_litw - @a_base)/4
                        word    $0001
                        word    (@a_STat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @overNFA + $10
plusNFA                 byte    $81,"+"
plusPFA                 word    (@a__xasmtwogtone - @a_base)/4
                        word    $0107
                        word    (@a_exit - @a_base)/4

                        word    @plusNFA + $10
rotNFA                  byte    $83,"rot"
rotPFA                  word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_STat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_STat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_STat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    (@a_STbang - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    (@a_STbang - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_STbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @rotNFA + $10
rshiftNFA               byte    $86,"rshift"
rshiftPFA               word    (@a__xasmtwogtone - @a_base)/4
                        word    $0057
                        word    (@a_exit - @a_base)/4

                        word    @rshiftNFA + $10
rgtNFA                  byte    $02,"r>"
rgtPFA                  word    (@a_rgt - @a_base)/4

                        word    @rgtNFA + $10
gtrNFA                  byte    $02,">r"
gtrPFA                  word    (@a_gtr - @a_base)/4

                        word    @gtrNFA + $10
twogtrNFA               byte    $03,"2>r"
twogtrPFA               word    (@a_twogtr - @a_base)/4

                        word    @twogtrNFA + $10
zbranchNFA              byte    $07,"0branch"
zbranchPFA              word    (@a_zbranch - @a_base)/4

                        word    @zbranchNFA + $10
lparenlooprparenNFA     byte    $06,"(loop)"
lparenlooprparenPFA     word    (@a_lparenlooprparen - @a_base)/4

                        word    @lparenlooprparenNFA + $10
lparenpluslooprparenNFA byte    $07,"(+loop)"
lparenpluslooprparenPFA word    (@a_lparenpluslooprparen - @a_base)/4

                        word    @lparenpluslooprparenNFA + $10
swapNFA                 byte    $84,"swap"
swapPFA                 word    @onePFA + $10
                        word    (@a_STat - @a_base)/4
                        word    @onePFA + $10
                        word    (@a_STat - @a_base)/4
                        word    @twoPFA + $10
                        word    (@a_STbang - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_STbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @swapNFA + $10
negateNFA               byte    $86,"negate"
negatePFA               word    (@a__xasmonegtone - @a_base)/4
                        word    $014F
                        word    (@a_exit - @a_base)/4

                        word    @negateNFA + $10
rebootNFA               byte    $86,"reboot"
rebootPFA               word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @zPFA + $10
                        word    @huboprPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @rebootNFA + $10
cogstopNFA              byte    $87,"cogstop"
cogstopPFA              word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @huboprPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @cogioPFA + $10
                        word    @fourplusPFA + $10
                        word    @dlrS_cdszPFA + $10
                        word    @twominusPFA + $10
                        word    @twominusPFA + $10
                        word    @zPFA + $10
                        word    @fillPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogstopNFA + $10
cogresetNFA             byte    $88,"cogreset"
cogresetPFA             word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @dupPFA + $10
                        word    @cogidPFA + $10
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @dupPFA + $10
                        word    @cogstopPFA + $10
                        word    @dupPFA + $10
                        word    @dupPFA + $10
                        word    @cogioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @lshiftPFA + $10
                        word    @dlrH_entryPFA + $10
                        word    @twoPFA + $10
                        word    @lshiftPFA + $10
                        word    @orPFA + $10
                        word    @orPFA + $10
                        word    @twoPFA + $10
                        word    @huboprPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @cogstatePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $8000
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEE
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @cogresetNFA + $10
resetNFA                byte    $85,"reset"
resetPFA                word    @cogidPFA + $10
                        word    @cogresetPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @resetNFA + $10
clkfreqNFA              byte    $87,"clkfreq"
clkfreqPFA              word    @zPFA + $10
                        word    @LatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @clkfreqNFA + $10
_pplusNFA               byte    $83,"_p+"
_pplusPFA               word    @parPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_pplusNFA + $10
cogioNFA                byte    $85,"cogio"
cogioPFA                word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @dlrS_cdszPFA + $10
                        word    @ustarPFA + $10
                        word    @dlrH_cogdataPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogioNFA + $10
cogiochanNFA            byte    $89,"cogiochan"
cogiochanPFA            word    @overPFA + $10
                        word    @cognchanPFA + $10
                        word    @oneminusPFA + $10
                        word    @minPFA + $10
                        word    @fourstarPFA + $10
                        word    @swapPFA + $10
                        word    @cogioPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogiochanNFA + $10
ioNFA                   byte    $82,"io"
ioPFA                   word    @parPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @ioNFA + $10
ERRNFA                  byte    $83,"ERR"
ERRPFA                  word    @clearkeysPFA + $10
                        word    @lasterrPFA + $10
                        word    @CbangPFA + $10
                        word    @resetPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ERRNFA + $10
lpareniodisrparenNFA    byte    $87,"(iodis)"
lpareniodisrparenPFA    word    @cogiochanPFA + $10
                        word    @twoplusPFA + $10
                        word    @dupPFA + $10
                        word    @WatPFA + $10
                        word    @swapPFA + $10
                        word    @zPFA + $10
                        word    @swapPFA + $10
                        word    @WbangPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    @zPFA + $10
                        word    @swapPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lpareniodisrparenNFA + $10
iodisNFA                byte    $85,"iodis"
iodisPFA                word    @zPFA + $10
                        word    @lpareniodisrparenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @iodisNFA + $10
lparenioconnrparenNFA   byte    $88,"(ioconn)"
lparenioconnrparenPFA   word    @twodupPFA + $10
                        word    @lpareniodisrparenPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    (@a_gtr - @a_base)/4
                        word    @twodupPFA + $10
                        word    @lpareniodisrparenPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    (@a_rgt - @a_base)/4
                        word    @cogiochanPFA + $10
                        word    @rottwoPFA + $10
                        word    @cogiochanPFA + $10
                        word    @twodupPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    @swapPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparenioconnrparenNFA + $10
ioconnNFA               byte    $86,"ioconn"
ioconnPFA               word    @zPFA + $10
                        word    @tuckPFA + $10
                        word    @lparenioconnrparenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ioconnNFA + $10
lpareniolinkrparenNFA   byte    $88,"(iolink)"
lpareniolinkrparenPFA   word    @cogiochanPFA + $10
                        word    @rottwoPFA + $10
                        word    @cogiochanPFA + $10
                        word    @swapPFA + $10
                        word    @overPFA + $10
                        word    @twoplusPFA + $10
                        word    @WatPFA + $10
                        word    @overPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    @swapPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lpareniolinkrparenNFA + $10
iolinkNFA               byte    $86,"iolink"
iolinkPFA               word    @zPFA + $10
                        word    @tuckPFA + $10
                        word    @lpareniolinkrparenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @iolinkNFA + $10
lpareniounlinkrparenNFA byte    $8A,"(iounlink)"
lpareniounlinkrparenPFA word    @cogiochanPFA + $10
                        word    @twoplusPFA + $10
                        word    @dupPFA + $10
                        word    @WatPFA + $10
                        word    @twoplusPFA + $10
                        word    @dupPFA + $10
                        word    @WatPFA + $10
                        word    @rotPFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    @swapPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lpareniounlinkrparenNFA + $10
iounlinkNFA             byte    $88,"iounlink"
iounlinkPFA             word    @zPFA + $10
                        word    @lpareniounlinkrparenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @iounlinkNFA + $10
padNFA                  byte    $83,"pad"
padPFA                  word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padNFA + $10
cogpadNFA               byte    $86,"cogpad"
cogpadPFA               word    @cogioPFA + $10
                        word    @fourplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogpadNFA + $10
padgtinNFA              byte    $86,"pad>in"
padgtinPFA              word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @padPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padgtinNFA + $10
namemaxNFA              byte    $87,"namemax"
namemaxPFA              word    (@a_doconw - @a_base)/4
                        word    $001F

                        word    @namemaxNFA + $10
padsizeNFA              byte    $87,"padsize"
padsizePFA              word    (@a_doconw - @a_base)/4
                        word    $0080

                        word    @padsizeNFA + $10
_lcNFA                  byte    $83,"_lc"
_lcPFA                  word    (@a_litw - @a_base)/4
                        word    $0083
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_lcNFA + $10
tzNFA                   byte    $82,"t0"
tzPFA                   word    (@a_litw - @a_base)/4
                        word    $0084
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tzNFA + $10
toneNFA                 byte    $82,"t1"
tonePFA                 word    (@a_litw - @a_base)/4
                        word    $0086
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @toneNFA + $10
tbufNFA                 byte    $84,"tbuf"
tbufPFA                 word    (@a_litw - @a_base)/4
                        word    $0088
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tbufNFA + $10
numpadNFA               byte    $86,"numpad"
numpadPFA               word    (@a_litw - @a_base)/4
                        word    $00A8
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @numpadNFA + $10
cognumpadNFA            byte    $89,"cognumpad"
cognumpadPFA            word    @cogioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00A8
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cognumpadNFA + $10
padgtoutNFA             byte    $87,"pad>out"
padgtoutPFA             word    @gtoutPFA + $10
                        word    @WatPFA + $10
                        word    @numpadPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padgtoutNFA + $10
numpadsizeNFA           byte    $8A,"numpadsize"
numpadsizePFA           word    (@a_doconw - @a_base)/4
                        word    $0022

                        word    @numpadsizeNFA + $10
cdsNFA                  byte    $83,"cds"
cdsPFA                  word    (@a_litw - @a_base)/4
                        word    $00D0
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cdsNFA + $10
cogcdsNFA               byte    $86,"cogcds"
cogcdsPFA               word    @cogioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00D0
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogcdsNFA + $10
baseNFA                 byte    $84,"base"
basePFA                 word    (@a_litw - @a_base)/4
                        word    $00D2
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @baseNFA + $10
execwordNFA             byte    $88,"execword"
execwordPFA             word    (@a_litw - @a_base)/4
                        word    $00D4
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @execwordNFA + $10
executeNFA              byte    $87,"execute"
executePFA              word    @dupPFA + $10
                        word    @dlrC_fMaskPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @dlrC_IPPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0014
                        word    @execwordPFA + $10
                        word    @WbangPFA + $10
                        word    @dlrC_a_exitPFA + $10
                        word    @execwordPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    @execwordPFA + $10
                        word    @dlrC_IPPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @executeNFA + $10
coghereNFA              byte    $87,"coghere"
cogherePFA              word    (@a_litw - @a_base)/4
                        word    $00D8
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @coghereNFA + $10
gtoutNFA                byte    $84,">out"
gtoutPFA                word    (@a_litw - @a_base)/4
                        word    $00DA
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtoutNFA + $10
gtinNFA                 byte    $83,">in"
gtinPFA                 word    (@a_litw - @a_base)/4
                        word    $00DC
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtinNFA + $10
lasterrNFA              byte    $87,"lasterr"
lasterrPFA              word    (@a_litw - @a_base)/4
                        word    $00DE
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lasterrNFA + $10
stateNFA                byte    $85,"state"
statePFA                word    (@a_litw - @a_base)/4
                        word    $00DF
                        word    @_pplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @stateNFA + $10
cogstateNFA             byte    $88,"cogstate"
cogstatePFA             word    @cogioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00DF
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogstateNFA + $10
_pqNFA                  byte    $83,"_p?"
_pqPFA                  word    @twoPFA + $10
                        word    @statePFA + $10
                        word    @CatPFA + $10
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_pqNFA + $10
cognchanNFA             byte    $88,"cognchan"
cognchanPFA             word    @cogstatePFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0005
                        word    @rshiftPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cognchanNFA + $10
gtconNFA                byte    $84,">con"
gtconPFA                word    @dlrS_conPFA + $10
                        word    @ioconnPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtconNFA + $10
compileqNFA             byte    $88,"compile?"
compileqPFA             word    @statePFA + $10
                        word    @CatPFA + $10
                        word    @onePFA + $10
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @compileqNFA + $10
twodupNFA               byte    $84,"2dup"
twodupPFA               word    @overPFA + $10
                        word    @overPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twodupNFA + $10
twodropNFA              byte    $85,"2drop"
twodropPFA              word    (@a_drop - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @twodropNFA + $10
threedropNFA            byte    $85,"3drop"
threedropPFA            word    @twodropPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @threedropNFA + $10
zeqNFA                  byte    $82,"0="
zeqPFA                  word    (@a__xasmtwogtflagIMM - @a_base)/4
                        word    $0000
                        word    $A186
                        word    (@a_exit - @a_base)/4

                        word    @zeqNFA + $10
ltgtNFA                 byte    $82,"<>"
ltgtPFA                 word    (@a__xasmtwogtflag - @a_base)/4
                        word    $5186
                        word    (@a_exit - @a_base)/4

                        word    @ltgtNFA + $10
zltgtNFA                byte    $83,"0<>"
zltgtPFA                word    (@a__xasmtwogtflagIMM - @a_base)/4
                        word    $0000
                        word    $5186
                        word    (@a_exit - @a_base)/4

                        word    @zltgtNFA + $10
zltNFA                  byte    $82,"0<"
zltPFA                  word    (@a__xasmtwogtflagIMM - @a_base)/4
                        word    $0000
                        word    $C186
                        word    (@a_exit - @a_base)/4

                        word    @zltNFA + $10
zgtNFA                  byte    $82,"0>"
zgtPFA                  word    (@a__xasmtwogtflagIMM - @a_base)/4
                        word    $0000
                        word    $1186
                        word    (@a_exit - @a_base)/4

                        word    @zgtNFA + $10
oneplusNFA              byte    $82,"1+"
oneplusPFA              word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0001
                        word    $0107
                        word    (@a_exit - @a_base)/4

                        word    @oneplusNFA + $10
oneminusNFA             byte    $82,"1-"
oneminusPFA             word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0001
                        word    $010F
                        word    (@a_exit - @a_base)/4

                        word    @oneminusNFA + $10
twoplusNFA              byte    $82,"2+"
twoplusPFA              word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0002
                        word    $0107
                        word    (@a_exit - @a_base)/4

                        word    @twoplusNFA + $10
twominusNFA             byte    $82,"2-"
twominusPFA             word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0002
                        word    $010F
                        word    (@a_exit - @a_base)/4

                        word    @twominusNFA + $10
fourplusNFA             byte    $82,"4+"
fourplusPFA             word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0004
                        word    $0107
                        word    (@a_exit - @a_base)/4

                        word    @fourplusNFA + $10
fourstarNFA             byte    $82,"4*"
fourstarPFA             word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0002
                        word    $005F
                        word    (@a_exit - @a_base)/4

                        word    @fourstarNFA + $10
twoslashNFA             byte    $82,"2/"
twoslashPFA             word    (@a__xasmtwogtoneIMM - @a_base)/4
                        word    $0001
                        word    $0077
                        word    (@a_exit - @a_base)/4

                        word    @twoslashNFA + $10
rottwoNFA               byte    $84,"rot2"
rottwoPFA               word    @twoPFA + $10
                        word    (@a_STat - @a_base)/4
                        word    @twoPFA + $10
                        word    (@a_STat - @a_base)/4
                        word    @twoPFA + $10
                        word    (@a_STat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    (@a_STbang - @a_base)/4
                        word    @onePFA + $10
                        word    (@a_STbang - @a_base)/4
                        word    @onePFA + $10
                        word    (@a_STbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @rottwoNFA + $10
nipNFA                  byte    $83,"nip"
nipPFA                  word    @swapPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @nipNFA + $10
tuckNFA                 byte    $84,"tuck"
tuckPFA                 word    @swapPFA + $10
                        word    @overPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tuckNFA + $10
gteqNFA                 byte    $82,">="
gteqPFA                 word    (@a__xasmtwogtflag - @a_base)/4
                        word    $3186
                        word    (@a_exit - @a_base)/4

                        word    @gteqNFA + $10
lteqNFA                 byte    $82,"<="
lteqPFA                 word    (@a__xasmtwogtflag - @a_base)/4
                        word    $E186
                        word    (@a_exit - @a_base)/4

                        word    @lteqNFA + $10
zgteqNFA                byte    $83,"0>="
zgteqPFA                word    (@a__xasmtwogtflagIMM - @a_base)/4
                        word    $0000
                        word    $3186
                        word    (@a_exit - @a_base)/4

                        word    @zgteqNFA + $10
WplusbangNFA            byte    $83,"W+!"
WplusbangPFA            word    @dupPFA + $10
                        word    @WatPFA + $10
                        word    @rotPFA + $10
                        word    @plusPFA + $10
                        word    @swapPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @WplusbangNFA + $10
orCbangNFA              byte    $84,"orC!"
orCbangPFA              word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @rotPFA + $10
                        word    @orPFA + $10
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @orCbangNFA + $10
andnCbangNFA            byte    $86,"andnC!"
andnCbangPFA            word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @rotPFA + $10
                        word    @andnPFA + $10
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @andnCbangNFA + $10
betweenNFA              byte    $87,"between"
betweenPFA              word    @rottwoPFA + $10
                        word    @overPFA + $10
                        word    @lteqPFA + $10
                        word    @rottwoPFA + $10
                        word    @gteqPFA + $10
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @betweenNFA + $10
crNFA                   byte    $82,"cr"
crPFA                   word    (@a_litw - @a_base)/4
                        word    $000D
                        word    @emitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @crNFA + $10
spaceNFA                byte    $85,"space"
spacePFA                word    @blPFA + $10
                        word    @emitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @spaceNFA + $10
spacesNFA               byte    $86,"spaces"
spacesPFA               word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @spacePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFFC
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @spacesNFA + $10
boundsNFA               byte    $86,"bounds"
boundsPFA               word    @overPFA + $10
                        word    @plusPFA + $10
                        word    @swapPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @boundsNFA + $10
alignlNFA               byte    $86,"alignl"
alignlPFA               word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @andnPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @alignlNFA + $10
alignwNFA               byte    $86,"alignw"
alignwPFA               word    @oneplusPFA + $10
                        word    @onePFA + $10
                        word    @andnPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @alignwNFA + $10
CatplusplusNFA          byte    $84,"C@++"
CatplusplusPFA          word    @dupPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @CatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @CatplusplusNFA + $10
todigitNFA              byte    $87,"todigit"
todigitPFA              word    (@a_litw - @a_base)/4
                        word    $0030
                        word    @minusPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    @gtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @minusPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0026
                        word    @gtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @minusPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0027
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @todigitNFA + $10
isdigitNFA              byte    $87,"isdigit"
isdigitPFA              word    @todigitPFA + $10
                        word    @zPFA + $10
                        word    @basePFA + $10
                        word    @WatPFA + $10
                        word    @oneminusPFA + $10
                        word    @betweenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @isdigitNFA + $10
isunumberNFA            byte    $89,"isunumber"
isunumberPFA            word    @boundsPFA + $10
                        word    @minusonePFA + $10
                        word    @rottwoPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $005F
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @isdigitPFA + $10
                        word    @andPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFE8
                        word    (@a_exit - @a_base)/4

                        word    @isunumberNFA + $10
unumberNFA              byte    $87,"unumber"
unumberPFA              word    @boundsPFA + $10
                        word    @zPFA + $10
                        word    @rottwoPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $005F
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @basePFA + $10
                        word    @WatPFA + $10
                        word    @ustarPFA + $10
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @todigitPFA + $10
                        word    @plusPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFE2
                        word    (@a_exit - @a_base)/4

                        word    @unumberNFA + $10
numberNFA               byte    $86,"number"
numberPFA               word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    @oneminusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    @swapPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @unumberPFA + $10
                        word    @negatePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @unumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @numberNFA + $10
_xnuNFA                 byte    $84,"_xnu"
_xnuPFA                 word    @basePFA + $10
                        word    @WatPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    @oneminusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    @swapPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @numberPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_xnuNFA + $10
xnumberNFA              byte    $87,"xnumber"
xnumberPFA              word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $007A
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @_xnuPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $004A
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0068
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @_xnuPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0032
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0064
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @_xnuPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $001A
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0062
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @twoPFA + $10
                        word    @_xnuPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @numberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @xnumberNFA + $10
isnumberNFA             byte    $88,"isnumber"
isnumberPFA             word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    @oneminusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    @swapPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @isunumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @isnumberNFA + $10
_xisNFA                 byte    $84,"_xis"
_xisPFA                 word    @basePFA + $10
                        word    @WatPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    @oneminusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    @swapPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @isnumberPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_xisNFA + $10
xisnumberNFA            byte    $89,"xisnumber"
xisnumberPFA            word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $007A
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @_xisPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $004A
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0068
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @_xisPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0032
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0064
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @_xisPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $001A
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0062
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @twoPFA + $10
                        word    @_xisPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @isnumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @xisnumberNFA + $10
npfxNFA                 byte    $84,"npfx"
npfxPFA                 word    @namelenPFA + $10
                        word    @rotPFA + $10
                        word    @namelenPFA + $10
                        word    @rotPFA + $10
                        word    @twodupPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0024
                        word    @minPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEC
                        word    @zltgtPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @twodropPFA + $10
                        word    @twodropPFA + $10
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @npfxNFA + $10
namelenNFA              byte    $87,"namelen"
namelenPFA              word    @CatplusplusPFA + $10
                        word    @namemaxPFA + $10
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @namelenNFA + $10
cmoveNFA                byte    $85,"cmove"
cmovePFA                word    @dupPFA + $10
                        word    @zgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    @iPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF8
                        word    (@a_drop - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @threedropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cmoveNFA + $10
namecopyNFA             byte    $88,"namecopy"
namecopyPFA             word    @overPFA + $10
                        word    @namelenPFA + $10
                        word    @oneplusPFA + $10
                        word    @nipPFA + $10
                        word    @cmovePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @namecopyNFA + $10
ccopyNFA                byte    $85,"ccopy"
ccopyPFA                word    @overPFA + $10
                        word    @CatPFA + $10
                        word    @oneplusPFA + $10
                        word    @cmovePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ccopyNFA + $10
cappendNFA              byte    $87,"cappend"
cappendPFA              word    @dupPFA + $10
                        word    @CatplusplusPFA + $10
                        word    @plusPFA + $10
                        word    @rottwoPFA + $10
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @swapPFA + $10
                        word    @oneplusPFA + $10
                        word    @rottwoPFA + $10
                        word    @cmovePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cappendNFA + $10
cappendnNFA             byte    $88,"cappendn"
cappendnPFA             word    @swapPFA + $10
                        word    @lthashPFA + $10
                        word    @hashsPFA + $10
                        word    @hashgtPFA + $10
                        word    @swapPFA + $10
                        word    @cappendPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cappendnNFA + $10
lparennfcogrparenNFA    byte    $87,"(nfcog)"
lparennfcogrparenPFA    word    @minusonePFA + $10
                        word    @minusonePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @iPFA + $10
                        word    @minusPFA + $10
                        word    @dupPFA + $10
                        word    @cogstatePFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @andPFA + $10
                        word    @overPFA + $10
                        word    @cogioPFA + $10
                        word    @LatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @eqPFA + $10
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    @nipPFA + $10
                        word    @nipPFA + $10
                        word    @zPFA + $10
                        word    @leavePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFCA
                        word    (@a_exit - @a_base)/4

                        word    @lparennfcogrparenNFA + $10
nfcogNFA                byte    $85,"nfcog"
nfcogPFA                word    @lparennfcogrparenPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0005
                        word    @ERRPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @nfcogNFA + $10
cogxNFA                 byte    $84,"cogx"
cogxPFA                 word    @ioPFA + $10
                        word    @twoplusPFA + $10
                        word    @WatPFA + $10
                        word    @rottwoPFA + $10
                        word    @cogioPFA + $10
                        word    @ioPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    @dotcstrPFA + $10
                        word    @crPFA + $10
                        word    @ioPFA + $10
                        word    @twoplusPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogxNFA + $10
dotstrnameNFA           byte    $88,".strname"
dotstrnamePFA           word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @namelenPFA + $10
                        word    @dotstrPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $000A
                        word    (@a_drop - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $003F
                        word    @emitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotstrnameNFA + $10
dotcstrNFA              byte    $85,".cstr"
dotcstrPFA              word    @CatplusplusPFA + $10
                        word    @dotstrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotcstrNFA + $10
dqNFA                   byte    $82,"dq"
dqPFA                   word    (@a_rgt - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    @twodupPFA + $10
                        word    @plusPFA + $10
                        word    @alignwPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @dotstrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dqNFA + $10
iNFA                    byte    $81,"i"
iPFA                    word    @twoPFA + $10
                        word    (@a_RSat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @iNFA + $10
setiNFA                 byte    $84,"seti"
setiPFA                 word    @twoPFA + $10
                        word    (@a_RSbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @setiNFA + $10
fillNFA                 byte    $84,"fill"
fillPFA                 word    @rottwoPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @dupPFA + $10
                        word    @iPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF8
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @fillNFA + $10
nfagtlfaNFA             byte    $87,"nfa>lfa"
nfagtlfaPFA             word    @twominusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @nfagtlfaNFA + $10
nfagtpfaNFA             byte    $87,"nfa>pfa"
nfagtpfaPFA             word    @namelenPFA + $10
                        word    @plusPFA + $10
                        word    @alignwPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @nfagtpfaNFA + $10
nfagtnextNFA            byte    $88,"nfa>next"
nfagtnextPFA            word    @nfagtlfaPFA + $10
                        word    @WatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @nfagtnextNFA + $10
lastnfaNFA              byte    $87,"lastnfa"
lastnfaPFA              word    @wlastnfaPFA + $10
                        word    @WatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lastnfaNFA + $10
isnamecharNFA           byte    $8A,"isnamechar"
isnamecharPFA           word    (@a_litw - @a_base)/4
                        word    $0021
                        word    (@a_litw - @a_base)/4
                        word    $007E
                        word    @betweenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @isnamecharNFA + $10
_forthpfagtnfaNFA       byte    $8D,"_forthpfa>nfa"
_forthpfagtnfaPFA       word    @oneminusPFA + $10
                        word    @oneminusPFA + $10
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @isnamecharPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF4
                        word    (@a_exit - @a_base)/4

                        word    @_forthpfagtnfaNFA + $10
_asmpfagtnfaNFA         byte    $8B,"_asmpfa>nfa"
_asmpfagtnfaPFA         word    @lastnfaPFA + $10
                        word    @twodupPFA + $10
                        word    @nfagtpfaPFA + $10
                        word    @WatPFA + $10
                        word    @eqPFA + $10
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @nfagtnextPFA + $10
                        word    @dupPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFD8
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_asmpfagtnfaNFA + $10
pfagtnfaNFA             byte    $87,"pfa>nfa"
pfagtnfaPFA             word    @dupPFA + $10
                        word    @dlrC_fMaskPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @_forthpfagtnfaPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_asmpfagtnfaPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @pfagtnfaNFA + $10
acceptNFA               byte    $86,"accept"
acceptPFA               word    @padblPFA + $10
                        word    @_acceptPFA + $10
                        word    @statePFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @padPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @dotstrPFA + $10
                        word    @crPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @acceptNFA + $10
parseNFA                byte    $85,"parse"
parsePFA                word    @padsizePFA + $10
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @lteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $007A
                        word    @dupPFA + $10
                        word    @_lcPFA + $10
                        word    @CbangPFA + $10
                        word    @zPFA + $10
                        word    @twodupPFA + $10
                        word    @padgtinPFA + $10
                        word    @plusPFA + $10
                        word    @CatPFA + $10
                        word    @tuckPFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0056
                        word    (@a_litw - @a_base)/4
                        word    $007E
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0048
                        word    @dupPFA + $10
                        word    @padgtinPFA + $10
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @twodupPFA + $10
                        word    @xisnumberPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0030
                        word    @xnumberPFA + $10
                        word    @overPFA + $10
                        word    @CbangPFA + $10
                        word    @overPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @overPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    @CbangPFA + $10
                        word    @oneminusPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEE
                        word    (@a_drop - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @threedropPFA + $10
                        word    @oneplusPFA + $10
                        word    @zPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FF92
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @parseNFA + $10
nextwordNFA             byte    $88,"nextword"
nextwordPFA             word    @padsizePFA + $10
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @gtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    @padgtinPFA + $10
                        word    @CatPFA + $10
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @plusPFA + $10
                        word    @oneplusPFA + $10
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @nextwordNFA + $10
parsewordNFA            byte    $89,"parseword"
parsewordPFA            word    @skipblPFA + $10
                        word    @parsePFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @oneminusPFA + $10
                        word    @twodupPFA + $10
                        word    @padPFA + $10
                        word    @plusPFA + $10
                        word    @CbangPFA + $10
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @parsewordNFA + $10
parseblNFA              byte    $87,"parsebl"
parseblPFA              word    @blPFA + $10
                        word    @parsewordPFA + $10
                        word    @zltgtPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @parseblNFA + $10
parsenwNFA              byte    $87,"parsenw"
parsenwPFA              word    @parseblPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @padgtinPFA + $10
                        word    @nextwordPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @parsenwNFA + $10
findNFA                 byte    $84,"find"
findPFA                 word    @lastnfaPFA + $10
                        word    @overPFA + $10
                        word    @_dictsearchPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0044
                        word    @nipPFA + $10
                        word    @dupPFA + $10
                        word    @nfagtpfaPFA + $10
                        word    @overPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @WatPFA + $10
                        word    @swapPFA + $10
                        word    @CatPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @twoPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @onePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @findNFA + $10
lthashNFA               byte    $82,"<#"
lthashPFA               word    @numpadsizePFA + $10
                        word    @gtoutPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lthashNFA + $10
hashgtNFA               byte    $82,"#>"
hashgtPFA               word    (@a_drop - @a_base)/4
                        word    @numpadsizePFA + $10
                        word    @gtoutPFA + $10
                        word    @WatPFA + $10
                        word    @minusPFA + $10
                        word    @minusonePFA + $10
                        word    @gtoutPFA + $10
                        word    @WplusbangPFA + $10
                        word    @padgtoutPFA + $10
                        word    @CbangPFA + $10
                        word    @padgtoutPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @hashgtNFA + $10
tocharNFA               byte    $86,"tochar"
tocharPFA               word    (@a_litw - @a_base)/4
                        word    $003F
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0030
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0039
                        word    @gtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $005D
                        word    @gtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tocharNFA + $10
hashNFA                 byte    $81,"#"
hashPFA                 word    @basePFA + $10
                        word    @WatPFA + $10
                        word    @uslashmodPFA + $10
                        word    @swapPFA + $10
                        word    @tocharPFA + $10
                        word    @minusonePFA + $10
                        word    @gtoutPFA + $10
                        word    @WplusbangPFA + $10
                        word    @padgtoutPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @hashNFA + $10
hashsNFA                byte    $82,"#s"
hashsPFA                word    @hashPFA + $10
                        word    @dupPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF8
                        word    (@a_exit - @a_base)/4

                        word    @hashsNFA + $10
udotNFA                 byte    $82,"u."
udotPFA                 word    @lthashPFA + $10
                        word    @hashsPFA + $10
                        word    @hashgtPFA + $10
                        word    @dotcstrPFA + $10
                        word    @spacePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @udotNFA + $10
dotNFA                  byte    $81,"."
dotPFA                  word    @dupPFA + $10
                        word    @zltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @emitPFA + $10
                        word    @negatePFA + $10
                        word    @udotPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotNFA + $10
cogidNFA                byte    $85,"cogid"
cogidPFA                word    @minusonePFA + $10
                        word    @onePFA + $10
                        word    @huboprPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogidNFA + $10
_lockarrayNFA           byte    $8A,"_lockarray"
_lockarrayPFA           word    (@a_dovarw - @a_base)/4
                        word    $0F0F
                        WORD    0,0,0
                        word    @_lockarrayNFA + $10
lockNFA                 byte    $84,"lock"
lockPFA                 word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @dupPFA + $10
                        word    @_lockarrayPFA + $10
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @andPFA + $10
                        word    @cogidPFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0026
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @plusPFA + $10
                        word    @tuckPFA + $10
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00F0
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0006
                        word    @ERRPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0046
                        word    (@a_drop - @a_base)/4
                        word    @swapPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1000
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @lshiftPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @overPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0006
                        word    @hubopfPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEA
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @ERRPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @cogidPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @plusPFA + $10
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lockNFA + $10
unlockNFA               byte    $86,"unlock"
unlockPFA               word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @dupPFA + $10
                        word    @_lockarrayPFA + $10
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @andPFA + $10
                        word    @cogidPFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0036
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @minusPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00F0
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    (@a_drop - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @hubopfPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @swapPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @ERRPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @unlockNFA + $10
unlockallNFA            byte    $89,"unlockall"
unlockallPFA            word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @_lockarrayPFA + $10
                        word    @iPFA + $10
                        word    @plusPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @andPFA + $10
                        word    @cogidPFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @_lockarrayPFA + $10
                        word    @iPFA + $10
                        word    @plusPFA + $10
                        word    @CbangPFA + $10
                        word    @iPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @hubopfPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFD2
                        word    (@a_exit - @a_base)/4

                        word    @unlockallNFA + $10
twolockNFA              byte    $85,"2lock"
twolockPFA              word    @twoPFA + $10
                        word    @lockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twolockNFA + $10
twounlockNFA            byte    $87,"2unlock"
twounlockPFA            word    @twoPFA + $10
                        word    @unlockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twounlockNFA + $10
checkdictNFA            byte    $89,"checkdict"
checkdictPFA            word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @plusPFA + $10
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    @ERRPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @checkdictNFA + $10
lparencreatebeginrparenNFA byte    $8D,"(createbegin)"
lparencreatebeginrparenPFA word    @lockdictPFA + $10
                        word    @herewalPFA + $10
                        word    @wlastnfaPFA + $10
                        word    @WatPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @dupPFA + $10
                        word    @twoplusPFA + $10
                        word    @wlastnfaPFA + $10
                        word    @WbangPFA + $10
                        word    @swapPFA + $10
                        word    @overPFA + $10
                        word    @WbangPFA + $10
                        word    @twoplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparencreatebeginrparenNFA + $10
lparencreateendrparenNFA byte    $8B,"(createend)"
lparencreateendrparenPFA word    @overPFA + $10
                        word    @namecopyPFA + $10
                        word    @namelenPFA + $10
                        word    @plusPFA + $10
                        word    @alignwPFA + $10
                        word    @herePFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparencreateendrparenNFA + $10
ccreateNFA              byte    $87,"ccreate"
ccreatePFA              word    @lparencreatebeginrparenPFA + $10
                        word    @swapPFA + $10
                        word    @lparencreateendrparenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ccreateNFA + $10
createNFA               byte    $86,"create"
createPFA               word    @blPFA + $10
                        word    @parsewordPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @lparencreatebeginrparenPFA + $10
                        word    @padgtinPFA + $10
                        word    @lparencreateendrparenPFA + $10
                        word    @nextwordPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @createNFA + $10
herewalNFA              byte    $87,"herewal"
herewalPFA              word    @lockdictPFA + $10
                        word    @twoPFA + $10
                        word    @checkdictPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @alignwPFA + $10
                        word    @herePFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @herewalNFA + $10
allotNFA                byte    $85,"allot"
allotPFA                word    @lockdictPFA + $10
                        word    @dupPFA + $10
                        word    @checkdictPFA + $10
                        word    @herePFA + $10
                        word    @WplusbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @allotNFA + $10
wcommaNFA               byte    $82,"w,"
wcommaPFA               word    @lockdictPFA + $10
                        word    @herewalPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @WbangPFA + $10
                        word    @twoPFA + $10
                        word    @allotPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @wcommaNFA + $10
ccommaNFA               byte    $82,"c,"
ccommaPFA               word    @lockdictPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @CbangPFA + $10
                        word    @onePFA + $10
                        word    @allotPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ccommaNFA + $10
herelalNFA              byte    $87,"herelal"
herelalPFA              word    @lockdictPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @checkdictPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @alignlPFA + $10
                        word    @herePFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @herelalNFA + $10
lcommaNFA               byte    $82,"l,"
lcommaPFA               word    @lockdictPFA + $10
                        word    @herelalPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @LbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @allotPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lcommaNFA + $10
orlnfaNFA               byte    $86,"orlnfa"
orlnfaPFA               word    @lastnfaPFA + $10
                        word    @orCbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @orlnfaNFA + $10
forthentryNFA           byte    $8A,"forthentry"
forthentryPFA           word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @orlnfaPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @forthentryNFA + $10
immediateNFA            byte    $89,"immediate"
immediatePFA            word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @orlnfaPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @immediateNFA + $10
execNFA                 byte    $84,"exec"
execPFA                 word    (@a_litw - @a_base)/4
                        word    $0060
                        word    @orlnfaPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @execNFA + $10
leaveNFA                byte    $85,"leave"
leavePFA                word    @onePFA + $10
                        word    (@a_RSat - @a_base)/4
                        word    @twoPFA + $10
                        word    (@a_RSbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @leaveNFA + $10
clearkeysNFA            byte    $89,"clearkeys"
clearkeysPFA            word    @onePFA + $10
                        word    @statePFA + $10
                        word    @andnCbangPFA + $10
                        word    @zPFA + $10
                        word    @_wkeytoPFA + $10
                        word    @WatPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @fkeyqPFA + $10
                        word    @nipPFA + $10
                        word    @orPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF8
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFE8
                        word    (@a_exit - @a_base)/4

                        word    @clearkeysNFA + $10
wgtlNFA                 byte    $83,"w>l"
wgtlPFA                 word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @andPFA + $10
                        word    @swapPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @lshiftPFA + $10
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @wgtlNFA + $10
lgtwNFA                 byte    $83,"l>w"
lgtwPFA                 word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @rshiftPFA + $10
                        word    @swapPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lgtwNFA + $10
colonNFA                byte    $81,":"
colonPFA                word    @lockdictPFA + $10
                        word    @createPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $3741
                        word    @onePFA + $10
                        word    @statePFA + $10
                        word    @orCbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @colonNFA + $10
_mmcsNFA                byte    $85,"_mmcs"
_mmcsPFA                word    @_pqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0026
                        word    @dqPFA + $10
                        byte    $1F,"MISMATCHED CONTROL STRUCTURE(S)"
                        word    @crPFA + $10
                        word    @clearkeysPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_mmcsNFA + $10
scolonNFA               byte    $C1,";"
scolonPFA               word    @dlrC_a_exitPFA + $10
                        word    @wcommaPFA + $10
                        word    @onePFA + $10
                        word    @statePFA + $10
                        word    @andnCbangPFA + $10
                        word    @forthentryPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $3741
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @_mmcsPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @scolonNFA + $10
dothenNFA               byte    $86,"dothen"
dothenPFA               word    @lgtwPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1235
                        word    @eqPFA + $10
                        word    @swapPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1239
                        word    @eqPFA + $10
                        word    @orPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    @dupPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @swapPFA + $10
                        word    @minusPFA + $10
                        word    @swapPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_mmcsPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dothenNFA + $10
thenNFA                 byte    $C4,"then"
thenPFA                 word    @dothenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @thenNFA + $10
thensNFA                byte    $C5,"thens"
thensPFA                word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @andPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1235
                        word    @eqPFA + $10
                        word    @swapPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1239
                        word    @eqPFA + $10
                        word    @orPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @dothenPFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFD6
                        word    (@a_exit - @a_base)/4

                        word    @thensNFA + $10
ifNFA                   byte    $C2,"if"
ifPFA                   word    @dlrC_a_zbranchPFA + $10
                        word    @wcommaPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1235
                        word    @wgtlPFA + $10
                        word    @zPFA + $10
                        word    @wcommaPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ifNFA + $10
elseNFA                 byte    $C4,"else"
elsePFA                 word    @dlrC_a_branchPFA + $10
                        word    @wcommaPFA + $10
                        word    @zPFA + $10
                        word    @wcommaPFA + $10
                        word    @dothenPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @twominusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1239
                        word    @wgtlPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @elseNFA + $10
untilNFA                byte    $C5,"until"
untilPFA                word    @lgtwPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1317
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    @dlrC_a_zbranchPFA + $10
                        word    @wcommaPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @minusPFA + $10
                        word    @wcommaPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_mmcsPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @untilNFA + $10
beginNFA                byte    $C5,"begin"
beginPFA                word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $1317
                        word    @wgtlPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @beginNFA + $10
doloopNFA               byte    $86,"doloop"
doloopPFA               word    @swapPFA + $10
                        word    @lgtwPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $2329
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    @swapPFA + $10
                        word    @wcommaPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @minusPFA + $10
                        word    @wcommaPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_mmcsPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @doloopNFA + $10
loopNFA                 byte    $C4,"loop"
loopPFA                 word    @dlrC_a_lparenlooprparenPFA + $10
                        word    @doloopPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @loopNFA + $10
plusloopNFA             byte    $C5,"+loop"
plusloopPFA             word    @dlrC_a_lparenpluslooprparenPFA + $10
                        word    @doloopPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @plusloopNFA + $10
doNFA                   byte    $C2,"do"
doPFA                   word    @dlrC_a_twogtrPFA + $10
                        word    @wcommaPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $2329
                        word    @wgtlPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @doNFA + $10
_ecsNFA                 byte    $84,"_ecs"
_ecsPFA                 word    (@a_litw - @a_base)/4
                        word    $003A
                        word    @emitPFA + $10
                        word    @spacePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_ecsNFA + $10
_udfNFA                 byte    $84,"_udf"
_udfPFA                 word    @dqPFA + $10
                        byte    $0F,"UNDEFINED WORD "
                        word    (@a_exit - @a_base)/4

                        word    @_udfNFA + $10
_qpNFA                  byte    $83,"_qp"
_qpPFA                  word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @parsePFA + $10
                        word    @oneminusPFA + $10
                        word    @padgtinPFA + $10
                        word    @twodupPFA + $10
                        word    @CbangPFA + $10
                        word    @swapPFA + $10
                        word    @twoplusPFA + $10
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_qpNFA + $10
_spNFA                  byte    $83,"_sp"
_spPFA                  word    @wcommaPFA + $10
                        word    @_qpPFA + $10
                        word    @dupPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @ccopyPFA + $10
                        word    @CatPFA + $10
                        word    @oneplusPFA + $10
                        word    @allotPFA + $10
                        word    @herewalPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_spNFA + $10
dotquoteNFA             byte    $C2,".",$22
dotquotePFA             word    @dlrH_dqPFA + $10
                        word    @_spPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotquoteNFA + $10
fisnumberNFA            byte    $89,"fisnumber"
fisnumberPFA            word    @xisnumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fisnumberNFA + $10
fnumberNFA              byte    $87,"fnumber"
fnumberPFA              word    @xnumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fnumberNFA + $10
interpretpadNFA         byte    $8C,"interpretpad"
interpretpadPFA         word    @onePFA + $10
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    @blPFA + $10
                        word    @parsewordPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $00D4
                        word    @padgtinPFA + $10
                        word    @nextwordPFA + $10
                        word    @findPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $006C
                        word    @dupPFA + $10
                        word    @minusonePFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    (@a_drop - @a_base)/4
                        word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @wcommaPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @executePFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0048
                        word    @twoPFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @executePFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0038
                        word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @executePFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $002A
                        word    @pfagtnfaPFA + $10
                        word    @_pqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $001C
                        word    @dqPFA + $10
                        byte    $0F,"IMMEDIATE WORD "
                        word    @dotstrnamePFA + $10
                        word    @crPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    @clearkeysPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $005A
                        word    (@a_drop - @a_base)/4
                        word    @dupPFA + $10
                        word    @CatplusplusPFA + $10
                        word    @fisnumberPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0030
                        word    @CatplusplusPFA + $10
                        word    @fnumberPFA + $10
                        word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0020
                        word    @dupPFA + $10
                        word    @zPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @betweenPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @dlrC_a_litwPFA + $10
                        word    @wcommaPFA + $10
                        word    @wcommaPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @dlrC_a_litlPFA + $10
                        word    @wcommaPFA + $10
                        word    @lcommaPFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0020
                        word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @freedictPFA + $10
                        word    @onePFA + $10
                        word    @statePFA + $10
                        word    @andnCbangPFA + $10
                        word    @_pqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @_udfPFA + $10
                        word    @dotstrnamePFA + $10
                        word    @crPFA + $10
                        word    @clearkeysPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FF22
                        word    (@a_exit - @a_base)/4

                        word    @interpretpadNFA + $10
interpretNFA            byte    $89,"interpret"
interpretPFA            word    @acceptPFA + $10
                        word    @interpretpadPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @interpretNFA + $10
_wconeNFA               byte    $84,"_wc1"
_wconePFA               word    @lockdictPFA + $10
                        word    @createPFA + $10
                        word    @dlrC_a_doconwPFA + $10
                        word    @wcommaPFA + $10
                        word    @wcommaPFA + $10
                        word    @forthentryPFA + $10
                        word    @lastnfaPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_wconeNFA + $10
wconstantNFA            byte    $89,"wconstant"
wconstantPFA            word    @_wconePFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @wconstantNFA + $10
wvariableNFA            byte    $89,"wvariable"
wvariablePFA            word    @lockdictPFA + $10
                        word    @createPFA + $10
                        word    @dlrC_a_dovarwPFA + $10
                        word    @wcommaPFA + $10
                        word    @zPFA + $10
                        word    @wcommaPFA + $10
                        word    @forthentryPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @wvariableNFA + $10
asmlabelNFA             byte    $88,"asmlabel"
asmlabelPFA             word    @lockdictPFA + $10
                        word    @createPFA + $10
                        word    @wcommaPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @asmlabelNFA + $10
hexNFA                  byte    $83,"hex"
hexPFA                  word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @hexNFA + $10
delmsNFA                byte    $85,"delms"
delmsPFA                word    (@a_litl - @a_base)/4
                        long    $7FFFFFFF
                        word    @clkfreqPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $03E8
                        word    @uslashPFA + $10
                        word    @uslashPFA + $10
                        word    @minPFA + $10
                        word    @onePFA + $10
                        word    @maxPFA + $10
                        word    @clkfreqPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $03E8
                        word    @uslashPFA + $10
                        word    @ustarPFA + $10
                        word    @cntPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    @cntPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @minusPFA + $10
                        word    @zltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @delmsNFA + $10
gtmNFA                  byte    $82,">m"
gtmPFA                  word    @onePFA + $10
                        word    @swapPFA + $10
                        word    @lshiftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtmNFA + $10
bsNFA                   byte    $E1,"\"
bsPFA                   word    @padsizePFA + $10
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @bsNFA + $10
_dlNFA                  byte    $83,"_dl"
_dlPFA                  word    @padblPFA + $10
                        word    @padPFA + $10
                        word    @oneplusPFA + $10
                        word    @statePFA + $10
                        word    @CatPFA + $10
                        word    @rottwoPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @statePFA + $10
                        word    @orCbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @statePFA + $10
                        word    @andnCbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002E
                        word    @emitPFA + $10
                        word    @crPFA + $10
                        word    @acceptPFA + $10
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @twoPFA + $10
                        word    (@a_STat - @a_base)/4
                        word    @eqPFA + $10
                        word    @overPFA + $10
                        word    @oneplusPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    (@a_STat - @a_base)/4
                        word    @eqPFA + $10
                        word    @orPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFDA
                        word    (@a_drop - @a_base)/4
                        word    @emitPFA + $10
                        word    @crPFA + $10
                        word    @statePFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_dlNFA + $10
cboNFA                  byte    $E1,"{"
cboPFA                  word    (@a_litw - @a_base)/4
                        word    $007D
                        word    @_dlPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cboNFA + $10
cbcNFA                  byte    $E1,"}"
cbcPFA                  word    (@a_exit - @a_base)/4

                        word    @cbcNFA + $10
_ifNFA                  byte    $83,"_if"
_ifPFA                  word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $005D
                        word    @_dlPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_ifNFA + $10
sboifNFA                byte    $E3,"[if"
sboifPFA                word    @_ifPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @sboifNFA + $10
sboifdefNFA             byte    $E6,"[ifdef"
sboifdefPFA             word    @parsenwPFA + $10
                        word    @findPFA + $10
                        word    @nipPFA + $10
                        word    @_ifPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @sboifdefNFA + $10
sboifndefNFA            byte    $E7,"[ifndef"
sboifndefPFA            word    @parsenwPFA + $10
                        word    @findPFA + $10
                        word    @nipPFA + $10
                        word    @zeqPFA + $10
                        word    @_ifPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @sboifndefNFA + $10
sbcNFA                  byte    $E1,"]"
sbcPFA                  word    (@a_exit - @a_base)/4

                        word    @sbcNFA + $10
dotdotdotNFA            byte    $E3,"..."
dotdotdotPFA            word    (@a_exit - @a_base)/4

                        word    @dotdotdotNFA + $10
tickNFA                 byte    $81,"'"
tickPFA                 word    @parsenwPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    @findPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @_pqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @_udfPFA + $10
                        word    @crPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tickNFA + $10
cqNFA                   byte    $82,"cq"
cqPFA                   word    (@a_rgt - @a_base)/4
                        word    @dupPFA + $10
                        word    @CatplusplusPFA + $10
                        word    @plusPFA + $10
                        word    @alignwPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @cqNFA + $10
cquoteNFA               byte    $E2,"c",$22
cquotePFA               word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @dlrH_cqPFA + $10
                        word    @_spPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_qpPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cquoteNFA + $10
fl_lockNFA              byte    $87,"fl_lock"
fl_lockPFA              word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @fl_lockNFA + $10
fl_inNFA                byte    $85,"fl_in"
fl_inPFA                word    (@a_dovarw - @a_base)/4
                        word    $56E7

                        word    @fl_inNFA + $10
lparenfloutrparenNFA    byte    $87,"(flout)"
lparenfloutrparenPFA    word    @ioPFA + $10
                        word    @twoplusPFA + $10
                        word    @WatPFA + $10
                        word    @dupPFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @andPFA + $10
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @ltPFA + $10
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @dupPFA + $10
                        word    @oneplusPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    @CatPFA + $10
                        word    @swapPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lparenfloutrparenNFA + $10
lparenflrparenNFA       byte    $84,"(fl)"
lparenflrparenPFA       word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @twominusPFA + $10
                        word    @tzPFA + $10
                        word    @WbangPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @plusPFA + $10
                        word    @dupPFA + $10
                        word    @fl_inPFA + $10
                        word    @WbangPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    @tonePFA + $10
                        word    @WbangPFA + $10
                        word    @_wkeytoPFA + $10
                        word    @WatPFA + $10
                        word    @minusonePFA + $10
                        word    @fkeyqPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_drop - @a_base)/4
                        word    @lparenfloutrparenPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $00F2
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    (@a_drop - @a_base)/4
                        word    @onePFA + $10
                        word    @tonePFA + $10
                        word    @WplusbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $00C4
                        word    @swapPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $00A8
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $005C
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    (@a_drop - @a_base)/4
                        word    @keyPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000D
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF6
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0084
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $007B
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0030
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $001F
                        word    @overPFA + $10
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $001F
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @lparenfloutrparenPFA + $10
                        word    @keyPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $007D
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFE0
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $004A
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    @eqPFA + $10
                        word    @overPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @eqPFA + $10
                        word    @orPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $001E
                        word    (@a_drop - @a_base)/4
                        word    @keyPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    @eqPFA + $10
                        word    @overPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @eqPFA + $10
                        word    @orPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFE6
                        word    @dupPFA + $10
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @dupPFA + $10
                        word    @oneplusPFA + $10
                        word    @fl_inPFA + $10
                        word    @WbangPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000D
                        word    @eqPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0018
                        word    @dupPFA + $10
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @dupPFA + $10
                        word    @oneplusPFA + $10
                        word    @fl_inPFA + $10
                        word    @WbangPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000D
                        word    @eqPFA + $10
                        word    @lparenfloutrparenPFA + $10
                        word    @fkeyqPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FF1C
                        word    (@a_drop - @a_base)/4
                        word    @nipPFA + $10
                        word    @_wkeytoPFA + $10
                        word    @WatPFA + $10
                        word    @swapPFA + $10
                        word    @swapPFA + $10
                        word    @oneminusPFA + $10
                        word    @swapPFA + $10
                        word    @overPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FEF4
                        word    @twodropPFA + $10
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $001C
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @dupPFA + $10
                        word    @CatPFA + $10
                        word    @emitPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF2
                        word    @crPFA + $10
                        word    @crPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    @twoplusPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    @tonePFA + $10
                        word    @WatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparenflrparenNFA + $10
flNFA                   byte    $82,"fl"
flPFA                   word    @lockdictPFA + $10
                        word    @fl_lockPFA + $10
                        word    @WatPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @freedictPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $004E
                        word    @minusonePFA + $10
                        word    @fl_lockPFA + $10
                        word    @WbangPFA + $10
                        word    @cogidPFA + $10
                        word    @nfcogPFA + $10
                        word    @dupPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @iolinkPFA + $10
                        word    @freedictPFA + $10
                        word    @lparenflrparenPFA + $10
                        word    @cogidPFA + $10
                        word    @iounlinkPFA + $10
                        word    @zPFA + $10
                        word    @fl_lockPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    @overPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0026
                        word    @cogresetPFA + $10
                        word    @crPFA + $10
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $15,"characters overflowed"
                        word    @crPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @twodropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @flNFA + $10
fstartNFA               byte    $86,"fstart"
fstartPFA               word    @ioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @lshiftPFA + $10
                        word    @dlrH_entryPFA + $10
                        word    @twoPFA + $10
                        word    @lshiftPFA + $10
                        word    @orPFA + $10
                        word    @cogidPFA + $10
                        word    @orPFA + $10
                        word    @dlrC_resetDregPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    @lasterrPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @ioPFA + $10
                        word    @WbangPFA + $10
                        word    @padPFA + $10
                        word    @dlrS_cdszPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @minusPFA + $10
                        word    @zPFA + $10
                        word    @fillPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    @init_cogherePFA + $10
                        word    @lockdictPFA + $10
                        word    @_finitPFA + $10
                        word    @WatPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0046
                        word    @minusonePFA + $10
                        word    @_finitPFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    @zPFA + $10
                        word    @fl_lockPFA + $10
                        word    @WbangPFA + $10
                        word    @lparenversionrparenPFA + $10
                        word    @versionPFA + $10
                        word    @WbangPFA + $10
                        word    @lparenproprparenPFA + $10
                        word    @propPFA + $10
                        word    @WbangPFA + $10
                        word    @_lockarrayPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @iPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    @cqPFA + $10
                        byte    $06,"onboot"
                        word    @findPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @executePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @freedictPFA + $10
                        word    @cqPFA + $10
                        byte    $07,"onreset"
                        word    @tbufPFA + $10
                        word    @ccopyPFA + $10
                        word    @cogidPFA + $10
                        word    @tbufPFA + $10
                        word    @cappendnPFA + $10
                        word    @tbufPFA + $10
                        word    @findPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @executePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0014
                        word    (@a_drop - @a_base)/4
                        word    @cqPFA + $10
                        byte    $07,"onreset"
                        word    @findPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @executePFA + $10
                        word    @compileqPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $002A
                        word    @_pqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0024
                        word    @twolockPFA + $10
                        word    @propPFA + $10
                        word    @WatPFA + $10
                        word    @dotcstrPFA + $10
                        word    @propidPFA + $10
                        word    @WatPFA + $10
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $03,"Cog"
                        word    @cogidPFA + $10
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $02,"ok"
                        word    @crPFA + $10
                        word    @twounlockPFA + $10
                        word    @interpretPFA + $10
                        word    @zPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFCA
                        word    (@a_exit - @a_base)/4

                        word    @fstartNFA + $10
initconNFA              byte    $87,"initcon"
initconPFA              word    @dlrS_txpinPFA + $10
                        word    @dlrS_rxpinPFA + $10
                        word    @dlrS_baudPFA + $10
                        word    @serialPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @initconNFA + $10
onbzzoneNFA             byte    $86,"onb001"
onbzzonePFA             word    @dlrS_conPFA + $10
                        word    @iodisPFA + $10
                        word    @dlrS_conPFA + $10
                        word    @cogresetPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @delmsPFA + $10
                        word    @cqPFA + $10
                        byte    $07,"initcon"
                        word    @dlrS_conPFA + $10
                        word    @cogxPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @delmsPFA + $10
                        word    @cogidPFA + $10
                        word    @gtconPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @cogidPFA + $10
                        word    @ltgtPFA + $10
                        word    @iPFA + $10
                        word    @dlrS_conPFA + $10
                        word    @ltgtPFA + $10
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @iPFA + $10
                        word    @cogresetPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFE8
                        word    (@a_exit - @a_base)/4

                        word    @onbzzoneNFA + $10
onresetNFA              byte    $87,"onreset"
onresetPFA              word    @unlockallPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @statePFA + $10
                        word    @orCbangPFA + $10
                        word    @versionPFA + $10
                        word    @WatPFA + $10
                        word    @cdsPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @onresetNFA + $10
lockdictNFA             byte    $88,"lockdict"
lockdictPFA             word    @zPFA + $10
                        word    @lockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lockdictNFA + $10
freedictNFA             byte    $88,"freedict"
freedictPFA             word    @zPFA + $10
                        word    @unlockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @freedictNFA + $10
ugteqNFA                byte    $83,"u>="
ugteqPFA                word    (@a__xasmtwogtflag - @a_base)/4
                        word    $310E
                        word    (@a_exit - @a_base)/4

                        word    @ugteqNFA + $10
build_BootOptNFA        byte    $8D,"build_BootOpt"
build_BootOptPFA        word    (@a_doconw - @a_base)/4
                        word    $0112

                        word    @build_BootOptNFA + $10
umstarNFA               byte    $83,"um*"
umstarPFA               word    (@a_lxasm - @a_base)/4
                        long    $F114_2112
                        long    $5CFD_54A3
                        long    $A0FD_9A00
                        long    $A0FD_9C00
                        long    $A0FD_9E00
                        long    $2BFD_9601
                        long    $5C4C_011B
                        long    $81BD_9ECC
                        long    $C8BD_9ACE
                        long    $2DFD_9801
                        long    $34FD_9C01
                        long    $5C54_0117
                        long    $A0BD_96CF
                        long    $5CFD_3695
                        long    $A0BD_96CD
                        long    $5C7C_0061

                        word    @umstarNFA + $10
umslashmodNFA           byte    $86,"um/mod"
umslashmodPFA           word    (@a_lxasm - @a_base)/4
                        long    $E88C_2312
                        long    $5CFD_54A3
                        long    $A0BD_A2CB
                        long    $5CFD_54A4
                        long    $A0FD_9C40
                        long    $A0FD_9A00
                        long    $2DFD_9601
                        long    $35FD_A201
                        long    $35FD_9A01
                        long    $84B1_9ACC
                        long    $E18D_9ACC
                        long    $34FD_9E01
                        long    $E4FD_9D18
                        long    $A0BD_96CD
                        long    $5CFD_3695
                        long    $A0BD_96CF
                        long    $5C7C_0061

                        word    @umslashmodNFA + $10
cstreqNFA               byte    $85,"cstr="
cstreqPFA               word    (@a_lxasm - @a_base)/4
                        long    $0FA8_1B12
                        long    $5CFD_54A3
                        long    $00BD_9ACC
                        long    $80FD_9A01
                        long    $84FD_9601
                        long    $00BD_9CCC
                        long    $80FD_9801
                        long    $80FD_9601
                        long    $00BD_9ECB
                        long    $863D_9CCF
                        long    $E4E9_9B17
                        long    $78BD_96C6
                        long    $5C7C_0061

                        word    @cstreqNFA + $10
nameeqNFA               byte    $85,"name="
nameeqPFA               word    (@a_lxasm - @a_base)/4
                        long    $BA5C_2512
                        long    $5CFD_54A3
                        long    $00BD_9ACC
                        long    $60FD_9A1F
                        long    $80FD_9801
                        long    $00BD_9ECB
                        long    $60FD_9E1F
                        long    $A0BD_9CCD
                        long    $80FD_9A01
                        long    $5C7C_0120
                        long    $00BD_9CCC
                        long    $80FD_9801
                        long    $80FD_9601
                        long    $00BD_9ECB
                        long    $863D_9CCF
                        long    $E4E9_9B1C
                        long    $78BD_96C6
                        long    $5C7C_0061

                        word    @nameeqNFA + $10
_dictsearchNFA          byte    $8B,"_dictsearch"
_dictsearchPFA          word    (@a_lxasm - @a_base)/4
                        long    $8450_3312
                        long    $5CFD_54A3
                        long    $A0BD_A0CC
                        long    $A0BD_A2CB
                        long    $00BD_9ACC
                        long    $60FD_9A1F
                        long    $80FD_9801
                        long    $00BD_9ECB
                        long    $60FD_9E1F
                        long    $A0BD_9CCD
                        long    $80FD_9A01
                        long    $5C7C_0122
                        long    $00BD_9CCC
                        long    $80FD_9801
                        long    $80FD_9601
                        long    $00BD_9ECB
                        long    $863D_9CCF
                        long    $E4E9_9B1E
                        long    $A0BD_96D1
                        long    $5C68_0061
                        long    $84FD_A202
                        long    $06BD_96D1
                        long    $5C68_0061
                        long    $A0BD_98D0
                        long    $5C7C_0115

                        word    @_dictsearchNFA + $10
padblNFA                byte    $85,"padbl"
padblPFA                word    (@a_lxasm - @a_base)/4
                        long    $3070_1312
                        long    $A0BD_A1F0
                        long    $80FD_A004
                        long    $A0FD_9C20
                        long    $083E_34D0
                        long    $80FD_A004
                        long    $E4FD_9D16
                        long    $5C7C_0061
                        long    $2020_2020

                        word    @padblNFA + $10
_acceptNFA              byte    $87,"_accept"
_acceptPFA              word    (@a_lxasm - @a_base)/4
                        long    $AEEC_5D12
                        long    $5CFD_3695
                        long    $A0BD_9BF0
                        long    $80FD_9A02
                        long    $04BD_A2CD
                        long    $80FD_9ADD
                        long    $00BD_98CD
                        long    $627D_9808
                        long    $A0D5_A200
                        long    $84FD_9ADA
                        long    $A0BD_96CD
                        long    $A0FD_9C7E
                        long    $04BD_9FF0
                        long    $627D_9F00
                        long    $5C54_011E
                        long    $A0FD_9900
                        long    $043D_99F0
                        long    $867D_9E0D
                        long    $A0E9_9C01
                        long    $5C68_0135
                        long    $867D_9E08
                        long    $5C68_012C
                        long    $48FD_9E20
                        long    $003D_9ECB
                        long    $80FD_9601
                        long    $5C7C_0135
                        long    $5CFE_7F39
                        long    $A0FD_9E20
                        long    $5CFE_7F39
                        long    $84FD_9601
                        long    $48BD_96CD
                        long    $003D_9ECB
                        long    $80FD_9C02
                        long    $4CFD_9C7E
                        long    $A0FD_9E08
                        long    $5CFE_7F39
                        long    $E4FD_9D1E
                        long    $84BD_96CD
                        long    $5C7C_0061
                        long    $867D_A200
                        long    $5C68_013F
                        long    $04BD_98D1
                        long    $627D_9900
                        long    $5C68_013B
                        long    $043D_9ED1
                        long    $5C7C_0000

                        word    @_acceptNFA + $10
dotstrNFA               byte    $84,".str"
dotstrPFA               word    (@a_lxasm - @a_base)/4
                        long    $B86C_2112
                        long    $5CFD_54A3
                        long    $867D_9800
                        long    $A095_A3F0
                        long    $80D5_A202
                        long    $0695_9AD1
                        long    $5C68_0120
                        long    $00BD_9ECB
                        long    $80FD_9601
                        long    $04BD_9CCD
                        long    $627D_9D00
                        long    $5C68_011B
                        long    $043D_9ECD
                        long    $E4FD_9919
                        long    $5CFD_54A4
                        long    $5C7C_0061

                        word    @dotstrNFA + $10
_fkeyqNFA               byte    $86,"_fkey?"
_fkeyqPFA               word    (@a_lxasm - @a_base)/4
                        long    $3534_1712
                        long    $04BD_98CB
                        long    $627D_9900
                        long    $78BD_9AC6
                        long    $5C54_0119
                        long    $A0FD_9D00
                        long    $043D_9CCB
                        long    $A0BD_96CC
                        long    $5CFD_3695
                        long    $A0BD_96CD
                        long    $5C7C_0061

                        word    @_fkeyqNFA + $10
fkeyqNFA                byte    $85,"fkey?"
fkeyqPFA                word    (@a_lxasm - @a_base)/4
                        long    $11F4_1712
                        long    $5CFD_3695
                        long    $04BD_97F0
                        long    $627D_9700
                        long    $78BD_98C6
                        long    $5C54_011A
                        long    $A0FD_9D00
                        long    $043D_9DF0
                        long    $5CFD_3695
                        long    $A0BD_96CC
                        long    $5C7C_0061

                        word    @fkeyqNFA + $10
keyNFA                  byte    $83,"key"
keyPFA                  word    (@a_lxasm - @a_base)/4
                        long    $E0FC_1112
                        long    $5CFD_3695
                        long    $04BD_97F0
                        long    $627D_9700
                        long    $5C54_0114
                        long    $A0FD_9900
                        long    $043D_99F0
                        long    $5C7C_0061

                        word    @keyNFA + $10
_femitqNFA              byte    $87,"_femit?"
_femitqPFA              word    (@a_lxasm - @a_base)/4
                        long    $4594_1D12
                        long    $5CFD_54A3
                        long    $60FD_96FF
                        long    $A0BD_9ACC
                        long    $80FD_9A02
                        long    $06BD_9CCD
                        long    $78BD_9EC6
                        long    $5C68_011E
                        long    $04BD_9ACE
                        long    $627D_9B00
                        long    $7CBD_9EC6
                        long    $0415_96CE
                        long    $A0BD_96CF
                        long    $5C7C_0061

                        word    @_femitqNFA + $10
femitqNFA               byte    $86,"femit?"
femitqPFA               word    (@a_lxasm - @a_base)/4
                        long    $A854_1B12
                        long    $60FD_96FF
                        long    $A0BD_9BF0
                        long    $80FD_9A02
                        long    $06BD_9CCD
                        long    $78BD_9EC6
                        long    $5C68_011D
                        long    $04BD_9ACE
                        long    $627D_9B00
                        long    $7CBD_9EC6
                        long    $0415_96CE
                        long    $A0BD_96CF
                        long    $5C7C_0061

                        word    @femitqNFA + $10
emitNFA                 byte    $84,"emit"
emitPFA                 word    (@a_lxasm - @a_base)/4
                        long    $DAC8_1912
                        long    $5CFD_54A3
                        long    $60FD_98FF
                        long    $A0BD_9BF0
                        long    $80FD_9A02
                        long    $06BD_9CCD
                        long    $5C68_011D
                        long    $04BD_9ACE
                        long    $627D_9B00
                        long    $5C68_0119
                        long    $043D_98CE
                        long    $5C7C_0061

                        word    @emitNFA + $10
skipblNFA               byte    $86,"skipbl"
skipblPFA               word    (@a_lxasm - @a_base)/4
                        long    $A654_2512
                        long    $A0BD_99F0
                        long    $80FD_98DC
                        long    $04BD_9ACC
                        long    $877D_9A80
                        long    $5C4C_0123
                        long    $A0FD_9C80
                        long    $84BD_9CCD
                        long    $80FD_9A04
                        long    $80BD_9BF0
                        long    $00BD_A0CD
                        long    $867D_A020
                        long    $80E9_9A01
                        long    $E4E9_9D1C
                        long    $84FD_9A04
                        long    $84BD_9BF0
                        long    $043D_9ACC
                        long    $5C7C_0061

                        word    @skipblNFA + $10
_eereadNFA              byte    $87,"_eeread"
_eereadPFA              word    (@a_lxasm - @a_base)/4
                        long    $00AC_4112
                        long    $5C7C_011A
                        long    $2000_0000
                        long    $1000_0000
                        long    $0000_000D
                        long    $A0BD_A316
                        long    $E4FD_A318
                        long    $5C7C_0000
                        long    $A0BD_98CB
                        long    $A0FD_9600
                        long    $64BF_ED14
                        long    $A0FD_9C08
                        long    $5CFE_3317
                        long    $613E_29F2
                        long    $34FD_9601
                        long    $68BF_E915
                        long    $5CFE_3317
                        long    $5CFE_3317
                        long    $64BF_E915
                        long    $5CFE_3317
                        long    $E4FD_9D1E
                        long    $867D_9800
                        long    $7CBF_E914
                        long    $68BF_ED14
                        long    $5CFE_3317
                        long    $68BF_E915
                        long    $5CFE_3317
                        long    $5CFE_3317
                        long    $64BF_E915
                        long    $64BF_E914
                        long    $5CFE_3317
                        long    $5C7C_0061

                        word    @_eereadNFA + $10
_eewriteNFA             byte    $88,"_eewrite"
_eewritePFA             word    (@a_lxasm - @a_base)/4
                        long    $2998_3F12
                        long    $5C7C_011A
                        long    $2000_0000
                        long    $1000_0000
                        long    $0000_000D
                        long    $A0BD_A316
                        long    $E4FD_A318
                        long    $5C7C_0000
                        long    $A0FD_9C08
                        long    $627D_9680
                        long    $7CBF_E914
                        long    $5CFE_3317
                        long    $68BF_E915
                        long    $5CFE_3317
                        long    $5CFE_3317
                        long    $64BF_E915
                        long    $2CFD_9601
                        long    $5CFE_3317
                        long    $E4FD_9D1B
                        long    $64BF_ED14
                        long    $623E_29F2
                        long    $7CBD_96C6
                        long    $5CFE_3317
                        long    $68BF_E915
                        long    $5CFE_3317
                        long    $5CFE_3317
                        long    $64BF_E915
                        long    $5CFE_3317
                        long    $64BF_E914
                        long    $68BF_ED14
                        long    $5C7C_0061

                        word    @_eewriteNFA + $10
init_coghereNFA         byte    $8C,"init_coghere"
init_cogherePFA         word    (@a_litw - @a_base)/4
                        word    $0140
                        word    @cogherePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @init_coghereNFA + $10
ustarNFA                byte    $82,"u*"
ustarPFA                word    @umstarPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @ustarNFA + $10
uslashmodNFA            byte    $85,"u/mod"
uslashmodPFA            word    @zPFA + $10
                        word    @swapPFA + $10
                        word    @umslashmodPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @uslashmodNFA + $10
uslashNFA               byte    $82,"u/"
uslashPFA               word    @uslashmodPFA + $10
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @uslashNFA + $10
build_fsrdNFA           byte    $8A,"build_fsrd"
build_fsrdPFA           word    (@a_doconw - @a_base)/4
                        word    $0001

                        word    @build_fsrdNFA + $10
dlrC_a_doconlNFA        byte    $8B,"$C_a_doconl"
dlrC_a_doconlPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_doconl - @a_base)/4

                        word    @dlrC_a_doconlNFA + $10
constantNFA             byte    $88,"constant"
constantPFA             word    @lockdictPFA + $10
                        word    @createPFA + $10
                        word    @dlrC_a_doconlPFA + $10
                        word    @wcommaPFA + $10
                        word    @lcommaPFA + $10
                        word    @forthentryPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @constantNFA + $10
fsbotNFA                byte    $85,"fsbot"
fsbotPFA                word    (@a_doconl - @a_base)/4
                        long    $00008000

                        word    @fsbotNFA + $10
fstopNFA                byte    $85,"fstop"
fstopPFA                word    (@a_doconl - @a_base)/4
                        long    $00010000

                        word    @fstopNFA + $10
fspsNFA                 byte    $84,"fsps"
fspsPFA                 word    (@a_doconw - @a_base)/4
                        word    $0040

                        word    @fspsNFA + $10
lastiqNFA               byte    $86,"lasti?"
lastiqPFA               word    @onePFA + $10
                        word    (@a_RSat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_RSat - @a_base)/4
                        word    @oneplusPFA + $10
                        word    @eqPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lastiqNFA + $10
hashCNFA                byte    $82,"#C"
hashCPFA                word    @minusonePFA + $10
                        word    @gtoutPFA + $10
                        word    @WplusbangPFA + $10
                        word    @padgtoutPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @hashCNFA + $10
_ndNFA                  byte    $83,"_nd"
_ndPFA                  word    @basePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0028
                        word    @overPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0006
                        word    (@a_branch - @a_base)/4
                        word    $006A
                        word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @overPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    (@a_branch - @a_base)/4
                        word    $0056
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    @overPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    (@a_branch - @a_base)/4
                        word    $0042
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @overPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $000B
                        word    (@a_branch - @a_base)/4
                        word    $002E
                        word    (@a_litw - @a_base)/4
                        word    $0006
                        word    @overPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $000C
                        word    (@a_branch - @a_base)/4
                        word    $001A
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @overPFA + $10
                        word    @ltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @nipPFA + $10
                        word    @swapPFA + $10
                        word    @uslashmodPFA + $10
                        word    @swapPFA + $10
                        word    @zltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @oneplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_ndNFA + $10
_ftNFA                  byte    $83,"_ft"
_ftPFA                  word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @basePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @betweenPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @oneminusPFA + $10
                        word    @rottwoPFA + $10
                        word    @lthashPFA + $10
                        word    @_ndPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @hashPFA + $10
                        word    @overPFA + $10
                        word    @iPFA + $10
                        word    @oneplusPFA + $10
                        word    @swapPFA + $10
                        word    @uslashmodPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @lastiqPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $005F
                        word    @hashCPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFDC
                        word    @hashgtPFA + $10
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_ftNFA + $10
_bfNFA                  byte    $83,"_bf"
_bfPFA                  word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @_ftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_bfNFA + $10
dotbyteNFA              byte    $85,".byte"
dotbytePFA              word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    @_bfPFA + $10
                        word    @dotcstrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotbyteNFA + $10
_wfNFA                  byte    $83,"_wf"
_wfPFA                  word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @andPFA + $10
                        word    @twoPFA + $10
                        word    @_ftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_wfNFA + $10
dotwordNFA              byte    $85,".word"
dotwordPFA              word    @_wfPFA + $10
                        word    @dotcstrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotwordNFA + $10
_lfNFA                  byte    $83,"_lf"
_lfPFA                  word    @onePFA + $10
                        word    @_ftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_lfNFA + $10
dotlongNFA              byte    $85,".long"
dotlongPFA              word    @_lfPFA + $10
                        word    @dotcstrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotlongNFA + $10
onelockNFA              byte    $85,"1lock"
onelockPFA              word    @onePFA + $10
                        word    @lockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @onelockNFA + $10
oneunlockNFA            byte    $87,"1unlock"
oneunlockPFA            word    @onePFA + $10
                        word    @unlockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @oneunlockNFA + $10
iboundNFA               byte    $86,"ibound"
iboundPFA               word    @onePFA + $10
                        word    (@a_RSat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @iboundNFA + $10
invertNFA               byte    $86,"invert"
invertPFA               word    @minusonePFA + $10
                        word    @xorPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @invertNFA + $10
pininNFA                byte    $85,"pinin"
pininPFA                word    @gtmPFA + $10
                        word    @invertPFA + $10
                        word    @diraPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @andPFA + $10
                        word    @diraPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @pininNFA + $10
pinoutNFA               byte    $86,"pinout"
pinoutPFA               word    @gtmPFA + $10
                        word    @diraPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @orPFA + $10
                        word    @diraPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @pinoutNFA + $10
pinloNFA                byte    $85,"pinlo"
pinloPFA                word    @gtmPFA + $10
                        word    (@a__maskoutlo - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @pinloNFA + $10
pinhiNFA                byte    $85,"pinhi"
pinhiPFA                word    @gtmPFA + $10
                        word    (@a__maskouthi - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @pinhiNFA + $10
pxNFA                   byte    $82,"px"
pxPFA                   word    @swapPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @pinhiPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @pinloPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @pxNFA + $10
_sdaiNFA                byte    $85,"_sdai"
_sdaiPFA                word    (@a_litw - @a_base)/4
                        word    $001D
                        word    @pininPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_sdaiNFA + $10
_sdaoNFA                byte    $85,"_sdao"
_sdaoPFA                word    (@a_litw - @a_base)/4
                        word    $001D
                        word    @pinoutPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_sdaoNFA + $10
_scliNFA                byte    $85,"_scli"
_scliPFA                word    (@a_litw - @a_base)/4
                        word    $001C
                        word    @pininPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_scliNFA + $10
_scloNFA                byte    $85,"_sclo"
_scloPFA                word    (@a_litw - @a_base)/4
                        word    $001C
                        word    @pinoutPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_scloNFA + $10
_sdalNFA                byte    $85,"_sdal"
_sdalPFA                word    (@a_litl - @a_base)/4
                        long    $20000000
                        word    (@a__maskoutlo - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sdalNFA + $10
_sdahNFA                byte    $85,"_sdah"
_sdahPFA                word    (@a_litl - @a_base)/4
                        long    $20000000
                        word    (@a__maskouthi - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sdahNFA + $10
_scllNFA                byte    $85,"_scll"
_scllPFA                word    (@a_litl - @a_base)/4
                        long    $10000000
                        word    (@a__maskoutlo - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_scllNFA + $10
_sclhNFA                byte    $85,"_sclh"
_sclhPFA                word    (@a_litl - @a_base)/4
                        long    $10000000
                        word    (@a__maskouthi - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sclhNFA + $10
_sdaqNFA                byte    $85,"_sda?"
_sdaqPFA                word    (@a_litl - @a_base)/4
                        long    $20000000
                        word    (@a__maskin - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sdaqNFA + $10
_eestartNFA             byte    $88,"_eestart"
_eestartPFA             word    @_sclhPFA + $10
                        word    @_scloPFA + $10
                        word    @_sdahPFA + $10
                        word    @_sdaoPFA + $10
                        word    @_sdalPFA + $10
                        word    @_scllPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_eestartNFA + $10
_eestopNFA              byte    $87,"_eestop"
_eestopPFA              word    @_sclhPFA + $10
                        word    @_sdahPFA + $10
                        word    @_scllPFA + $10
                        word    @_scliPFA + $10
                        word    @_sdaiPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_eestopNFA + $10
eereadpageNFA           byte    $8A,"eereadpage"
eereadpagePFA           word    @onelockPFA + $10
                        word    @onePFA + $10
                        word    @maxPFA + $10
                        word    @rotPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    @swapPFA + $10
                        word    @dupPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @rshiftPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    @swapPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @rshiftPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @onePFA + $10
                        word    @lshiftPFA + $10
                        word    @dupPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @_eestartPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00A0
                        word    @orPFA + $10
                        word    @_eewritePFA + $10
                        word    @swapPFA + $10
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    @swapPFA + $10
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    @_eestartPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $00A1
                        word    @orPFA + $10
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    @rottwoPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @lastiqPFA + $10
                        word    @_eereadPFA + $10
                        word    @iPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    @_eestopPFA + $10
                        word    @oneunlockPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @eereadpageNFA + $10
_fskNFA                 byte    $84,"_fsk"
_fskPFA                 word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @lshiftPFA + $10
                        word    @keyPFA + $10
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fskNFA + $10
_fnfNFA                 byte    $84,"_fnf"
_fnfPFA                 word    @crPFA + $10
                        word    @dqPFA + $10
                        byte    $0E,"FILE NOT FOUND"
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fnfNFA + $10
_fspaNFA                byte    $85,"_fspa"
_fspaPFA                word    @fspsPFA + $10
                        word    @oneminusPFA + $10
                        word    @plusPFA + $10
                        word    @fspsPFA + $10
                        word    @oneminusPFA + $10
                        word    @andnPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fspaNFA + $10
_fsnextNFA              byte    $87,"_fsnext"
_fsnextPFA              word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    @tonePFA + $10
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    @twoplusPFA + $10
                        word    @oneplusPFA + $10
                        word    @plusPFA + $10
                        word    @_fspaPFA + $10
                        word    @dupPFA + $10
                        word    @fstopPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fsnextNFA + $10
_fsrdNFA                byte    $85,"_fsrd"
_fsrdPFA                word    @dupPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @rotPFA + $10
                        word    @dupPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    @plusPFA + $10
                        word    @fstopPFA + $10
                        word    @oneminusPFA + $10
                        word    @gtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $000B
                        word    @ERRPFA + $10
                        word    @rottwoPFA + $10
                        word    @eereadpagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @ERRPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fsrdNFA + $10
_fsfreeNFA              byte    $87,"_fsfree"
_fsfreePFA              word    @minusonePFA + $10
                        word    @fsbotPFA + $10
                        word    @dupPFA + $10
                        word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @_fsrdPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @nipPFA + $10
                        word    @dupPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_fsnextPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFDA
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_fsfreeNFA + $10
_fsfindNFA              byte    $87,"_fsfind"
_fsfindPFA              word    @fsbotPFA + $10
                        word    @zPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @dupPFA + $10
                        word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @_fsrdPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0016
                        word    @overPFA + $10
                        word    @tonePFA + $10
                        word    @cstreqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_rgt - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    @dupPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @_fsnextPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFCC
                        word    @twodropPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_fsfindNFA + $10
_fslastNFA              byte    $87,"_fslast"
_fslastPFA              word    @zPFA + $10
                        word    @fsbotPFA + $10
                        word    @dupPFA + $10
                        word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @_fsrdPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @nipPFA + $10
                        word    @dupPFA + $10
                        word    @_fsnextPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFDA
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_fslastNFA + $10
fsfreeNFA               byte    $86,"fsfree"
fsfreePFA               word    @_fsfreePFA + $10
                        word    @dupPFA + $10
                        word    @minusonePFA + $10
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @fstopPFA + $10
                        word    @swapPFA + $10
                        word    @minusPFA + $10
                        word    @crPFA + $10
                        word    @dotlongPFA + $10
                        word    @dqPFA + $10
                        byte    $21," bytes free in EEPROM file system"
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fsfreeNFA + $10
fslsNFA                 byte    $84,"fsls"
fslsPFA                 word    @crPFA + $10
                        word    @fsbotPFA + $10
                        word    @dupPFA + $10
                        word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @_fsrdPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @eqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0018
                        word    @dupPFA + $10
                        word    @dotlongPFA + $10
                        word    @spacePFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    @dotwordPFA + $10
                        word    @spacePFA + $10
                        word    @tonePFA + $10
                        word    @dotcstrPFA + $10
                        word    @crPFA + $10
                        word    @_fsnextPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFCA
                        word    (@a_drop - @a_base)/4
                        word    @fsfreePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fslsNFA + $10
_fsreadNFA              byte    $87,"_fsread"
_fsreadPFA              word    @_fsfindPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $004C
                        word    @dupPFA + $10
                        word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @_fsrdPFA + $10
                        word    @tonePFA + $10
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    @twoplusPFA + $10
                        word    @oneplusPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @fspsPFA + $10
                        word    @iPFA + $10
                        word    @fspsPFA + $10
                        word    @oneminusPFA + $10
                        word    @andPFA + $10
                        word    @minusPFA + $10
                        word    @iboundPFA + $10
                        word    @iPFA + $10
                        word    @minusPFA + $10
                        word    @minPFA + $10
                        word    @iPFA + $10
                        word    @padPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_STat - @a_base)/4
                        word    @_fsrdPFA + $10
                        word    @padPFA + $10
                        word    @overPFA + $10
                        word    @dotstrPFA + $10
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFD8
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    @padblPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fsreadNFA + $10
_fspNFA                 byte    $84,"_fsp"
_fspPFA                 word    @parsenwPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @dupPFA + $10
                        word    @_fsfindPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fspNFA + $10
fsreadNFA               byte    $86,"fsread"
fsreadPFA               word    @_fspPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @_fsreadPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @_fnfPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fsreadNFA + $10
_fsloadNFA              byte    $87,"_fsload"
_fsloadPFA              word    @dupPFA + $10
                        word    @_fsfindPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $001A
                        word    @lockdictPFA + $10
                        word    @cogidPFA + $10
                        word    @nfcogPFA + $10
                        word    @iolinkPFA + $10
                        word    @freedictPFA + $10
                        word    @_fsreadPFA + $10
                        word    @crPFA + $10
                        word    @crPFA + $10
                        word    @cogidPFA + $10
                        word    @iounlinkPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_fsloadNFA + $10
fsloadNFA               byte    $86,"fsload"
fsloadPFA               word    @_fspPFA + $10
                        word    @dupPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @_fsloadPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @_fnfPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fsloadNFA + $10
onbootNFA               byte    $86,"onboot"
onbootPFA               word    @onbzzonePFA + $10
                        word    @fkeyqPFA + $10
                        word    @andPFA + $10
                        word    @fkeyqPFA + $10
                        word    @andPFA + $10
                        word    @orPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $001B
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    @cqPFA + $10
                        byte    $06,"boot.f"
                        word    @_fsloadPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @onbootNFA + $10
serstrNFA               byte    $86,"serstr"
serstrPFA               word    @cqPFA + $10
                        byte    $06,"SERIAL"
                        word    (@a_exit - @a_base)/4

                        word    @serstrNFA + $10
_bmsgNFA                byte    $85,"_bmsg"
_bmsgPFA                word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @crPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFFC
                        word    (@a_litw - @a_base)/4
                        word    $001E
                        word    @spacesPFA + $10
                        word    @dotcstrPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @crPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFFC
                        word    (@a_exit - @a_base)/4

                        word    @_bmsgNFA + $10
_serialNFA              byte    $87,"_serial"
_serialPFA              word    (@a_lxasm - @a_base)/4
                        long    $3FC9_5912
                        long    $5C7C_018D
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0100
                        long    $0000_0100
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $0000_0000
                        long    $5CBE_4322
                        long    $627E_3300
                        long    $5C54_012D
                        long    $A0BE_5519
                        long    $A0FE_3300
                        long    $68FE_5500
                        long    $2CFE_5402
                        long    $68FE_5401
                        long    $A0FE_560B
                        long    $A0BE_59F1
                        long    $29FE_5401
                        long    $70BF_E91C
                        long    $80BE_591A
                        long    $5CBE_4322
                        long    $A0BD_992C
                        long    $84BD_99F1
                        long    $C17D_9800
                        long    $5C4C_013A
                        long    $E4FE_5737
                        long    $5C7C_012D
                        long    $5CBE_4520
                        long    $5CBE_4523
                        long    $5CBE_4520
                        long    $5CBE_4524
                        long    $5CBE_4520
                        long    $5CBE_4525
                        long    $5CBE_4520
                        long    $5CBE_4526
                        long    $5C7C_0141
                        long    $5CBE_4722
                        long    $627E_3100
                        long    $5C54_014A
                        long    $A0BD_9914
                        long    $80FD_9801
                        long    $60FD_987F
                        long    $863D_9915
                        long    $5C68_014A
                        long    $80BE_291D
                        long    $003E_3114
                        long    $A0FE_3100
                        long    $A0BE_28CC
                        long    $5C7C_014A
                        long    $5CBE_4922
                        long    $863E_2915
                        long    $5C68_0157
                        long    $A0BD_991F
                        long    $06BD_9ACC
                        long    $0495_9CCD
                        long    $6255_9D00
                        long    $5C68_0157
                        long    $80BE_2B1D
                        long    $00BD_9D15
                        long    $84BE_2B1D
                        long    $80FE_2A01
                        long    $043D_9CCD
                        long    $60FE_2A7F
                        long    $5C7C_0157
                        long    $5CBE_4B22
                        long    $0ABD_9CD0
                        long    $5C68_0170
                        long    $A0FD_9800
                        long    $083D_98D0
                        long    $48FD_9C10
                        long    $64BF_E91C
                        long    $80BD_9DF1
                        long    $F8FD_9C00
                        long    $68BF_E91C
                        long    $04BD_9DF0
                        long    $627D_9D00
                        long    $5C54_0166
                        long    $A0BD_9916
                        long    $80FD_9801
                        long    $60FD_983F
                        long    $863D_9917
                        long    $5C68_0166
                        long    $80BE_2D1E
                        long    $003D_9D16
                        long    $A0BE_2CCC
                        long    $867D_9C0D
                        long    $08A9_98D1
                        long    $6269_9801
                        long    $A0D5_9900
                        long    $A0E9_980A
                        long    $043D_99F0
                        long    $5C7C_0166
                        long    $5CBE_4D22
                        long    $863E_2D17
                        long    $5C68_0182
                        long    $627E_3300
                        long    $5C68_0182
                        long    $80BE_2F1E
                        long    $00BE_3317
                        long    $84BE_2F1E
                        long    $80FE_2E01
                        long    $60FE_2E3F
                        long    $5C7C_0182
                        long    $A0BD_A1F0
                        long    $80FD_A0C4
                        long    $A0BD_A3F0
                        long    $80FD_A2C8
                        long    $A0BE_34CB
                        long    $5CFD_54A4
                        long    $A0FE_3601
                        long    $2CBE_36CB
                        long    $5CFD_54A4
                        long    $A0FE_3801
                        long    $2CBE_38CB
                        long    $5CFD_54A4
                        long    $A0BE_3BF0
                        long    $80FE_3A04
                        long    $A0BE_3D1D
                        long    $80FE_3C80
                        long    $A0BE_3FF0
                        long    $80FE_3E02
                        long    $A0FD_9900
                        long    $083D_99F0
                        long    $A0FE_432D
                        long    $A0FE_4541
                        long    $A0FE_474A
                        long    $A0FE_4957
                        long    $A0FE_4B66
                        long    $A0FE_4D82
                        long    $68BF_E91C
                        long    $68BF_ED1C
                        long    $5CBE_4121
                        long    $623E_37F2
                        long    $5C54_01A9
                        long    $A0FE_5009
                        long    $A0BE_531A
                        long    $28FE_5202
                        long    $80BE_53F1
                        long    $80BE_531A
                        long    $5CBE_4121
                        long    $A0BD_9929
                        long    $84BD_99F1
                        long    $C17D_9800
                        long    $5C4C_01B1
                        long    $613E_37F2
                        long    $30FE_4E01
                        long    $E4FE_51B0
                        long    $5C4C_01A9
                        long    $28FE_4E17
                        long    $60FE_4EFF
                        long    $A0BE_3127
                        long    $5C7C_01A9
H_lastlfa

                        word    @_serialNFA + $10
serialNFA               byte    $86,"serial"
serialPFA               word    @clkfreqPFA + $10
                        word    @swapPFA + $10
                        word    @uslashPFA + $10
                        word    @serstrPFA + $10
                        word    @cdsPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @statePFA + $10
                        word    @andnCbangPFA + $10
                        word    @zPFA + $10
                        word    @ioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00C4
                        word    @plusPFA + $10
                        word    @LbangPFA + $10
                        word    @zPFA + $10
                        word    @ioPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00C8
                        word    @plusPFA + $10
                        word    @LbangPFA + $10
                        word    @_serialPFA + $10
                        word    (@a_exit - @a_base)/4

wfreespacestart

                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0
ForthMemoryEnd
