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
  dlrS_baud = 57_600        ' $S_baud forth word - the actual baud rate will be 4 times this number
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


' A48
  word $0 , $7788 , $616C , $7473 , $666E , $61 , $4F , $4216 , $A4A , $6884 , $7265 , $65
' A60
  word $4F , $4480 , $A5A , $6487 , $6369 , $6574 , $646E , $4F , $7F94 , $A66 , $6D86 , $6D65 , $6E65 , $64 , $4F , $7F94
' A80
  word $A74 , $6290 , $6975 , $646C , $425F , $6F6F , $4B74 , $7265 , $656E , $6C , $4A , $1 , $A82 , $7086 , $6F72 , $6970
' AA0
  word $64 , $4F , $0 , $A9A , $2886 , $7270 , $706F , $29 , $2644 , $5004 , $6F72 , $70 , $61 , $AA8 , $2889 , $6576
' AC0
  word $7372 , $6F69 , $296E , $2644 , $5020 , $6F72 , $4670 , $726F , $6874 , $7620 , $2E35 , $2030 , $3032 , $3231 , $414A , $304E
' AE0
  word $2039 , $3431 , $333A , $2030 , $30 , $61 , $ABC , $7084 , $6F72 , $70 , $4F , $AB2 , $AEE , $7687 , $7265 , $6973
' B00
  word $6E6F , $4F , $AC8 , $AFA , $5F86 , $6966 , $696E , $74

_finitPFA

  word $4F , $FFFF , $B08 , $2487 , $5F53 , $6463 , $7A73 , $4A

  word dlrS_cdsz, $B16 , $2488 , $5F53 , $7874 , $6970 , $6E , $4A

  word dlrS_txpin, $B24 , $2488 , $5F53 , $7872 , $6970 , $6E , $4A

  word dlrS_rxpin, $B34 , $2487 , $5F53 , $6162 , $6475 , $4A

  word dlrS_baud, $B44 , $2486 , $5F53 , $6F63 , $6E , $4A

  word dlrS_con, $B52
' B60
  word $2488 , $5F48 , $6E65 , $7274 , $79 , $4A , $18 , $B60 , $248A , $5F48 , $6F63 , $6467 , $7461 , $61 , $4A , $348
' B80
  word $B70 , $2485 , $5F48 , $7163 , $4A , $2644 , $B82 , $2485 , $5F48 , $7164 , $4A , $1A48 , $B8E , $2489 , $5F43 , $5F61
' BA0
  word $7865 , $7469 , $4A , $61 , $B9A , $248B , $5F43 , $5F61 , $6F64 , $6176 , $7772 , $4A , $4F , $BAA , $248B , $5F43
' BC0
  word $5F61 , $6F64 , $6F63 , $776E , $4A , $4A , $BBC , $248B , $5F43 , $5F61 , $7262 , $6E61 , $6863 , $4A , $46 , $BCE
' BE0
  word $2489 , $5F43 , $5F61 , $696C , $7774 , $4A , $5D , $BE0 , $2488 , $5F43 , $5F61 , $3E32 , $72 , $4A , $79 , $BF0
' C00
  word $248B , $5F43 , $5F61 , $6C28 , $6F6F , $2970 , $4A , $80 , $C00 , $248C , $5F43 , $5F61 , $2B28 , $6F6C , $706F , $29
' C20
  word $4A , $82 , $C12 , $248C , $5F43 , $5F61 , $6230 , $6172 , $636E , $68 , $4A , $8D , $C26 , $2489 , $5F43 , $5F61
' C40
  word $696C , $6C74 , $4A , $57 , $C3A , $248A , $5F43 , $5F61 , $786C , $7361 , $6D , $4A , $B2 , $C4A , $2489 , $5F43
' C60
  word $6176 , $4572 , $646E , $4A , $112 , $C5C , $2488 , $5F43 , $4D66 , $7361 , $6B , $4A , $C4 , $C6C , $248C , $5F43
' C80
  word $6572 , $6573 , $4474 , $6572 , $67 , $4A , $C7 , $C7C , $2485 , $5F43 , $5049 , $4A , $C8 , $C90 , $2489 , $5F43
' CA0
  word $5F61 , $656E , $7478 , $4A , $63 , $C9C , $6282 , $6C , $4A , $20 , $CAC , $2D82 , $31 , $57 , $FFFF , $FFFF
' CC0
  word $61 , $CB6 , $3081 , $4A , $0 , $CC4 , $3181 , $4A , $1 , $CCC , $3281 , $4A , $2 , $CD4 , $7083 , $7261
' CE0
  word $4A , $1F0 , $CDC , $6383 , $746E , $4A , $1F1 , $CE6 , $6983 , $616E , $4A , $1F2 , $CF0 , $6F84 , $7475 , $61
' D00
  word $4A , $1F4 , $CFA , $6484 , $7269 , $61 , $4A , $1F6 , $D06 , $5F87 , $6B77 , $7965 , $6F74 , $4F , $2000 , $D12
' D20
  word $5FC5 , $6E63 , $7069 , $A60 , $E08 , $14C6 , $ED2 , $E08 , $F68 , $14C6 , $E46 , $A60 , $E46 , $61 , $D20 , $5F0E
' D40
  word $6178 , $6D73 , $3E32 , $6C66 , $6761 , $4D49 , $4D , $1 , $D3E , $5F0B , $6178 , $6D73 , $3E32 , $6C66 , $6761 , $4
' D60
  word $D52 , $5F0B , $6178 , $6D73 , $3E32 , $4931 , $4D4D , $13 , $D62 , $5F08 , $6178 , $6D73 , $3E32 , $31 , $16 , $D72
' D80
  word $5F08 , $6178 , $6D73 , $3E31 , $31 , $1C , $D80 , $5F08 , $6178 , $6D73 , $3E32 , $30 , $21 , $D8E , $6C05 , $6178
' DA0
  word $6D73 , $B2 , $D9C , $5F07 , $616D , $6B73 , $6E69 , $6E , $DA6 , $5F0A , $616D , $6B73 , $756F , $6C74 , $6F , $72
' DC0
  word $DB2 , $5F0A , $616D , $6B73 , $756F , $6874 , $69 , $71 , $DC2 , $6183 , $646E , $16 , $C7 , $61 , $DD2 , $6184
' DE0
  word $646E , $6E , $16 , $CF , $61 , $DDE , $4C82 , $40 , $1C , $17 , $61 , $DEC , $4382 , $40 , $1C , $7
' E00
  word $61 , $DF8 , $5782 , $40 , $1C , $9 , $61 , $E04 , $5203 , $4053 , $28 , $E10 , $5303 , $4054 , $2E , $E18
' E20
  word $4304 , $474F , $40 , $33 , $E20 , $4C82 , $21 , $21 , $10 , $61 , $E2A , $4382 , $21 , $21 , $0 , $61
' E40
  word $E36 , $5782 , $21 , $21 , $8 , $61 , $E42 , $5203 , $2153 , $37 , $E4E , $5303 , $2154 , $3D , $E56 , $4304
' E60
  word $474F , $21 , $42 , $E5E , $6206 , $6172 , $636E , $68 , $46 , $E68 , $6886 , $6275 , $706F , $72 , $16 , $1F
' E80
  word $61 , $E74 , $6886 , $6275 , $706F , $66 , $4 , $C01F , $61 , $E84 , $6406 , $636F , $6E6F , $77 , $4A , $E94
' EA0
  word $6406 , $636F , $6E6F , $6C , $52 , $EA0 , $6406 , $766F , $7261 , $77 , $4F , $EAC , $6406 , $766F , $7261 , $6C
' EC0
  word $4D , $EB8 , $6404 , $6F72 , $70 , $26 , $EC4 , $6483 , $7075 , $5D , $0 , $2E , $61 , $ECE , $3D81 , $4
' EE0
  word $A186 , $61 , $EDC , $6504 , $6978 , $74 , $61 , $EE6 , $3E81 , $4 , $1186 , $61 , $EF0 , $6C04 , $7469 , $77
' F00
  word $5D , $EFA , $6C04 , $7469 , $6C , $57 , $F04 , $6C86 , $6873 , $6669 , $74 , $16 , $5F , $61 , $F0E , $3C81
' F20
  word $4 , $C186 , $61 , $F1E , $6D83 , $7861 , $16 , $87 , $61 , $F28 , $6D83 , $6E69 , $16 , $8F , $61 , $F34
' F40
  word $2D81 , $16 , $10F , $61 , $F40 , $6F82 , $72 , $16 , $D7 , $61 , $F4A , $7883 , $726F , $16 , $DF , $61
' F60
  word $F56 , $6F84 , $6576 , $72 , $5D , $1 , $2E , $61 , $F62 , $2B81 , $16 , $107 , $61 , $F72 , $7283 , $746F
' F80
  word $5D , $2 , $2E , $5D , $2 , $2E , $5D , $2 , $2E , $5D , $3 , $3D , $5D , $3 , $3D , $CC6
' FA0
  word $3D , $61 , $F7C , $7286 , $6873 , $6669 , $74 , $16 , $57 , $61 , $FA6 , $7202 , $3E , $75 , $FB6 , $3E02
' FC0
  word $72 , $7C , $FBE , $3203 , $723E , $79 , $FC6 , $3007 , $7262 , $6E61 , $6863 , $8D , $FCE , $2806 , $6F6C , $706F
' FE0
  word $29 , $80 , $FDA , $2807 , $6C2B , $6F6F , $2970 , $82 , $FE6 , $7384 , $6177 , $70 , $CCE , $2E , $CCE , $2E
' 1000
  word $CD6 , $3D , $CC6 , $3D , $61 , $FF2 , $6E86 , $6765 , $7461 , $65 , $1C , $14F , $61 , $100C , $7286 , $6265
' 1020
  word $6F6F , $74 , $5D , $FF , $CC6 , $E7C , $61 , $101C , $6387 , $676F , $7473 , $706F , $ED2 , $5D , $3 , $E7C
' 1040
  word $26 , $10E4 , $14D4 , $B1E , $14C6 , $14C6 , $CC6 , $1A78 , $61 , $1030 , $6388 , $676F , $6572 , $6573 , $74 , $5D
' 1060
  word $7 , $DD6 , $ED2 , $1DCC , $1466 , $8D , $6 , $ED2 , $1038 , $ED2 , $ED2 , $10E4 , $5D , $10 , $F16 , $B6A
' 1080
  word $CD6 , $F16 , $F4E , $F4E , $CD6 , $E7C , $26 , $13CE , $5D , $8000 , $CC6 , $79 , $ED2 , $DFC , $5D , $4
' 10A0
  word $DD6 , $8D , $4 , $20D6 , $80 , $FFEE , $26 , $61 , $1054 , $7285 , $7365 , $7465 , $1DCC , $105E , $61 , $10B2
' 10C0
  word $6387 , $6B6C , $7266 , $7165 , $CC6 , $DF0 , $61 , $10C0 , $5F83 , $2B70 , $CE0 , $33 , $F74 , $61 , $10D0 , $6385
' 10E0
  word $676F , $6F69 , $5D , $7 , $DD6 , $B1E , $2E10 , $B7C , $F74 , $61 , $10DE , $6389 , $676F , $6F69 , $6863 , $6E61
' 1100
  word $F68 , $13F6 , $14AA , $F38 , $14E2 , $FF8 , $10E4 , $F74 , $61 , $10F6 , $6982 , $6F , $CE0 , $33 , $61 , $1114
' 1120
  word $4583 , $5252 , $20EC , $13AA , $E3A , $10B8 , $61 , $1120 , $2887 , $6F69 , $6964 , $2973 , $1100 , $14B8 , $ED2 , $E08
' 1140
  word $FF8 , $CC6 , $FF8 , $E46 , $ED2 , $8D , $E , $CC6 , $FF8 , $14B8 , $E46 , $46 , $4 , $26 , $61 , $1130
' 1160
  word $6985 , $646F , $7369 , $CC6 , $1138 , $61 , $1160 , $2888 , $6F69 , $6F63 , $6E6E , $29 , $1430 , $1138 , $7C , $7C
' 1180
  word $1430 , $1138 , $75 , $75 , $1100 , $1500 , $1100 , $1430 , $14B8 , $E46 , $FF8 , $14B8 , $E46 , $61 , $116E , $6986
' 11A0
  word $636F , $6E6F , $6E , $CC6 , $1530 , $1178 , $61 , $119E , $2888 , $6F69 , $696C , $6B6E , $29 , $1100 , $1500 , $1100
' 11C0
  word $FF8 , $F68 , $14B8 , $E08 , $F68 , $14B8 , $E46 , $FF8 , $14B8 , $E46 , $61 , $11B0 , $6986 , $6C6F , $6E69 , $6B
' 11E0
  word $CC6 , $1530 , $11BA , $61 , $11D8 , $288A , $6F69 , $6E75 , $696C , $6B6E , $29 , $1100 , $14B8 , $ED2 , $E08 , $14B8
' 1200
  word $ED2 , $E08 , $F80 , $E46 , $CC6 , $FF8 , $E46 , $61 , $11EA , $6988 , $756F , $6C6E , $6E69 , $6B , $CC6 , $11F6
' 1220
  word $61 , $1212 , $7083 , $6461 , $5D , $4 , $10D4 , $61 , $1224 , $6386 , $676F , $6170 , $64 , $10E4 , $14D4 , $61
' 1240
  word $1232 , $7086 , $6461 , $693E , $6E , $1398 , $E08 , $1228 , $F74 , $61 , $1242 , $6E87 , $6D61 , $6D65 , $7861 , $4A
' 1260
  word $1F , $1256 , $7087 , $6461 , $6973 , $657A , $4A , $80 , $1264 , $5F83 , $636C , $5D , $83 , $10D4 , $61 , $1272
' 1280
  word $7482 , $30 , $5D , $84 , $10D4 , $61 , $1280 , $7482 , $31 , $5D , $86 , $10D4 , $61 , $128E , $7484 , $7562
' 12A0
  word $66 , $5D , $88 , $10D4 , $61 , $129C , $6E86 , $6D75 , $6170 , $64 , $5D , $A8 , $10D4 , $61 , $12AC , $6389
' 12C0
  word $676F , $756E , $706D , $6461 , $10E4 , $5D , $A8 , $F74 , $61 , $12BE , $7087 , $6461 , $6F3E , $7475 , $138A , $E08
' 12E0
  word $12B4 , $F74 , $61 , $12D4 , $6E8A , $6D75 , $6170 , $7364 , $7A69 , $65 , $4A , $22 , $12E8 , $6383 , $7364 , $5D
' 1300
  word $D0 , $10D4 , $61 , $12FA , $6386 , $676F , $6463 , $73 , $10E4 , $5D , $D0 , $F74 , $61 , $1308 , $6284 , $7361
' 1320
  word $65 , $5D , $D2 , $10D4 , $61 , $131C , $6588 , $6578 , $7763 , $726F , $64 , $5D , $D4 , $10D4 , $61 , $132C
' 1340
  word $6587 , $6578 , $7563 , $6574 , $ED2 , $C76 , $33 , $DD6 , $8D , $A , $C96 , $42 , $46 , $14 , $1336 , $E46
' 1360
  word $BA4 , $1336 , $14B8 , $E46 , $1336 , $C96 , $42 , $61 , $1340 , $6387 , $676F , $6568 , $6572 , $5D , $D8 , $10D4
' 1380
  word $61 , $1372 , $3E84 , $756F , $74 , $5D , $DA , $10D4 , $61 , $1384 , $3E83 , $6E69 , $5D , $DC , $10D4 , $61
' 13A0
  word $1394 , $6C87 , $7361 , $6574 , $7272 , $5D , $DE , $10D4 , $61 , $13A2 , $7385 , $6174 , $6574 , $5D , $DF , $10D4
' 13C0
  word $61 , $13B4 , $6388 , $676F , $7473 , $7461 , $65 , $10E4 , $5D , $DF , $F74 , $61 , $13C4 , $5F83 , $3F70 , $CD6
' 13E0
  word $13BA , $DFC , $DD6 , $1458 , $61 , $13DA , $6388 , $676F , $636E , $6168 , $6E , $13CE , $DFC , $5D , $5 , $FAE
' 1400
  word $149C , $61 , $13EC , $3E84 , $6F63 , $6E , $B5A , $11A6 , $61 , $1406 , $6388 , $6D6F , $6970 , $656C , $3F , $13BA
' 1420
  word $DFC , $CCE , $DD6 , $61 , $1414 , $3284 , $7564 , $70 , $F68 , $F68 , $61 , $142A , $3285 , $7264 , $706F , $26
' 1440
  word $26 , $61 , $1438 , $3385 , $7264 , $706F , $143E , $26 , $61 , $1446 , $3082 , $3D , $1 , $0 , $A186 , $61
' 1460
  word $1454 , $3C82 , $3E , $4 , $5186 , $61 , $1462 , $3083 , $3E3C , $1 , $0 , $5186 , $61 , $146E , $3082 , $3C
' 1480
  word $1 , $0 , $C186 , $61 , $147C , $3082 , $3E , $1 , $0 , $1186 , $61 , $148A , $3182 , $2B , $13 , $1
' 14A0
  word $107 , $61 , $1498 , $3182 , $2D , $13 , $1 , $10F , $61 , $14A6 , $3282 , $2B , $13 , $2 , $107 , $61
' 14C0
  word $14B4 , $3282 , $2D , $13 , $2 , $10F , $61 , $14C2 , $3482 , $2B , $13 , $4 , $107 , $61 , $14D0 , $3482
' 14E0
  word $2A , $13 , $2 , $5F , $61 , $14DE , $3282 , $2F , $13 , $1 , $77 , $61 , $14EC , $7284 , $746F , $32
' 1500
  word $CD6 , $2E , $CD6 , $2E , $CD6 , $2E , $5D , $4 , $3D , $CCE , $3D , $CCE , $3D , $61 , $14FA , $6E83
' 1520
  word $7069 , $FF8 , $26 , $61 , $151E , $7484 , $6375 , $6B , $FF8 , $F68 , $61 , $152A , $3E82 , $3D , $4 , $3186
' 1540
  word $61 , $1538 , $3C82 , $3D , $4 , $E186 , $61 , $1544 , $3083 , $3D3E , $1 , $0 , $3186 , $61 , $1550 , $5783
' 1560
  word $212B , $ED2 , $E08 , $F80 , $F74 , $FF8 , $E46 , $61 , $155E , $6F84 , $4372 , $21 , $ED2 , $DFC , $F80 , $F4E
' 1580
  word $FF8 , $E3A , $61 , $1572 , $6186 , $646E , $436E , $21 , $ED2 , $DFC , $F80 , $DE4 , $FF8 , $E3A , $61 , $1588
' 15A0
  word $6287 , $7465 , $6577 , $6E65 , $1500 , $F68 , $1548 , $1500 , $153C , $DD6 , $61 , $15A0 , $6382 , $72 , $5D , $D
' 15C0
  word $2C50 , $61 , $15B8 , $7385 , $6170 , $6563 , $CB0 , $2C50 , $61 , $15C6 , $7386 , $6170 , $6563 , $73 , $ED2 , $8D
' 15E0
  word $10 , $CC6 , $79 , $15CC , $80 , $FFFC , $46 , $4 , $26 , $61 , $15D4 , $6286 , $756F , $646E , $73 , $F68
' 1600
  word $F74 , $FF8 , $61 , $15F6 , $6186 , $696C , $6E67 , $6C , $5D , $3 , $F74 , $5D , $3 , $DE4 , $61 , $1608
' 1620
  word $6186 , $696C , $6E67 , $77 , $149C , $CCE , $DE4 , $61 , $1620 , $4384 , $2B40 , $2B , $ED2 , $149C , $FF8 , $DFC
' 1640
  word $61 , $1632 , $7487 , $646F , $6769 , $7469 , $5D , $30 , $F42 , $ED2 , $5D , $9 , $EF2 , $8D , $18 , $5D
' 1660
  word $7 , $F42 , $ED2 , $5D , $A , $F20 , $8D , $6 , $26 , $CBA , $ED2 , $5D , $26 , $EF2 , $8D , $18
' 1680
  word $5D , $3 , $F42 , $ED2 , $5D , $27 , $F20 , $8D , $6 , $26 , $CBA , $61 , $1644 , $6987 , $6473 , $6769
' 16A0
  word $7469 , $164C , $CC6 , $1322 , $E08 , $14AA , $15A8 , $61 , $169A , $6989 , $7573 , $756E , $626D , $7265 , $15FE , $CBA
' 16C0
  word $1500 , $79 , $1A5C , $DFC , $5D , $5F , $1466 , $8D , $A , $1A5C , $DFC , $16A2 , $DD6 , $80 , $FFE8 , $61
' 16E0
  word $16B2 , $7587 , $756E , $626D , $7265 , $15FE , $CC6 , $1500 , $79 , $1A5C , $DFC , $5D , $5F , $1466 , $8D , $10
' 1700
  word $1322 , $E08 , $2E10 , $1A5C , $DFC , $164C , $F74 , $80 , $FFE2 , $61 , $16E2 , $6E86 , $6D75 , $6562 , $72 , $F68
' 1720
  word $DFC , $5D , $2D , $EDE , $8D , $16 , $14AA , $CC6 , $F2C , $FF8 , $149C , $FF8 , $16EA , $1014 , $46 , $4
' 1740
  word $16EA , $61 , $1716 , $5F84 , $6E78 , $75 , $1322 , $E08 , $7C , $1322 , $E46 , $14AA , $CC6 , $F2C , $FF8 , $149C
' 1760
  word $FF8 , $171E , $75 , $1322 , $E46 , $61 , $1746 , $7887 , $756E , $626D , $7265 , $F68 , $DFC , $5D , $7A , $EDE
' 1780
  word $8D , $C , $5D , $40 , $174C , $46 , $4A , $F68 , $DFC , $5D , $68 , $EDE , $8D , $C , $5D , $10
' 17A0
  word $174C , $46 , $32 , $F68 , $DFC , $5D , $64 , $EDE , $8D , $C , $5D , $A , $174C , $46 , $1A , $F68
' 17C0
  word $DFC , $5D , $62 , $EDE , $8D , $A , $CD6 , $174C , $46 , $4 , $171E , $61 , $176E , $6988 , $6E73 , $6D75
' 17E0
  word $6562 , $72 , $F68 , $DFC , $5D , $2D , $EDE , $8D , $E , $14AA , $CC6 , $F2C , $FF8 , $149C , $FF8 , $16BC
' 1800
  word $61 , $17DA , $5F84 , $6978 , $73 , $1322 , $E08 , $7C , $1322 , $E46 , $14AA , $CC6 , $F2C , $FF8 , $149C , $FF8
' 1820
  word $17E4 , $75 , $1322 , $E46 , $61 , $1804 , $7889 , $7369 , $756E , $626D , $7265 , $F68 , $DFC , $5D , $7A , $EDE
' 1840
  word $8D , $C , $5D , $40 , $180A , $46 , $4A , $F68 , $DFC , $5D , $68 , $EDE , $8D , $C , $5D , $10
' 1860
  word $180A , $46 , $32 , $F68 , $DFC , $5D , $64 , $EDE , $8D , $C , $5D , $A , $180A , $46 , $1A , $F68
' 1880
  word $DFC , $5D , $62 , $EDE , $8D , $A , $CD6 , $180A , $46 , $4 , $17E4 , $61 , $182C , $6E84 , $6670 , $78
' 18A0
  word $18E4 , $F80 , $18E4 , $F80 , $1430 , $153C , $8D , $24 , $F38 , $15FE , $79 , $1638 , $1A5C , $DFC , $1466 , $8D
' 18C0
  word $8 , $26 , $CC6 , $20D6 , $80 , $FFEC , $1472 , $46 , $8 , $143E , $143E , $CC6 , $61 , $189A , $6E87 , $6D61
' 18E0
  word $6C65 , $6E65 , $1638 , $125E , $DD6 , $61 , $18DC , $6385 , $6F6D , $6576 , $ED2 , $148E , $8D , $16 , $15FE , $79
' 1900
  word $1638 , $1A5C , $E3A , $80 , $FFF8 , $26 , $46 , $4 , $144C , $61 , $18EE , $6E88 , $6D61 , $6365 , $706F , $79
' 1920
  word $F68 , $18E4 , $149C , $1522 , $18F4 , $61 , $1916 , $6385 , $6F63 , $7970 , $F68 , $DFC , $149C , $18F4 , $61 , $192E
' 1940
  word $6387 , $7061 , $6570 , $646E , $ED2 , $1638 , $F74 , $1500 , $F68 , $DFC , $F68 , $DFC , $F74 , $FF8 , $E3A , $ED2
' 1960
  word $DFC , $FF8 , $149C , $1500 , $18F4 , $61 , $1940 , $6388 , $7061 , $6570 , $646E , $6E , $FF8 , $1D0C , $1D8E , $1D1A
' 1980
  word $FF8 , $1948 , $61 , $196E , $2887 , $666E , $6F63 , $2967 , $CBA , $CBA , $5D , $8 , $CC6 , $79 , $5D , $7
' 19A0
  word $1A5C , $F42 , $ED2 , $13CE , $DFC , $5D , $4 , $DD6 , $F68 , $10E4 , $DF0 , $5D , $100 , $EDE , $DD6 , $8D
' 19C0
  word $E , $1522 , $1522 , $CC6 , $20D6 , $46 , $4 , $26 , $80 , $FFCA , $61 , $1988 , $6E85 , $6366 , $676F , $1990
' 19E0
  word $8D , $8 , $5D , $5 , $1124 , $61 , $19D8 , $6384 , $676F , $78 , $1118 , $14B8 , $E08 , $1500 , $10E4 , $1118
' 1A00
  word $14B8 , $E46 , $1A3C , $15BC , $1118 , $14B8 , $E46 , $61 , $19EE , $2E88 , $7473 , $6E72 , $6D61 , $65 , $ED2 , $8D
' 1A20
  word $A , $18E4 , $2AE8 , $46 , $A , $26 , $5D , $3F , $2C50 , $61 , $1A12 , $2E85 , $7363 , $7274 , $1638 , $2AE8
' 1A40
  word $61 , $1A36 , $6482 , $71 , $75 , $1638 , $1430 , $F74 , $1628 , $7C , $2AE8 , $61 , $1A44 , $6981 , $CD6 , $28
' 1A60
  word $61 , $1A5A , $7384 , $7465 , $69 , $CD6 , $37 , $61 , $1A64 , $6684 , $6C69 , $6C , $1500 , $15FE , $79 , $ED2
' 1A80
  word $1A5C , $E3A , $80 , $FFF8 , $26 , $61 , $1A72 , $6E87 , $6166 , $6C3E , $6166 , $14C6 , $61 , $1A8E , $6E87 , $6166
' 1AA0
  word $703E , $6166 , $18E4 , $F74 , $1628 , $61 , $1A9C , $6E88 , $6166 , $6E3E , $7865 , $74 , $1A96 , $E08 , $61 , $1AAE
' 1AC0
  word $6C87 , $7361 , $6E74 , $6166 , $A54 , $E08 , $61 , $1AC0 , $698A , $6E73 , $6D61 , $6365 , $6168 , $72 , $5D , $21
' 1AE0
  word $5D , $7E , $15A8 , $61 , $1AD0 , $5F8D , $6F66 , $7472 , $7068 , $6166 , $6E3E , $6166 , $14AA , $14AA , $ED2 , $DFC
' 1B00
  word $1ADC , $1458 , $8D , $FFF4 , $61 , $1AEA , $5F8B , $7361 , $706D , $6166 , $6E3E , $6166 , $1AC8 , $1430 , $1AA4 , $E08
' 1B20
  word $EDE , $F68 , $DFC , $5D , $80 , $DD6 , $1458 , $DD6 , $8D , $8 , $CBA , $46 , $8 , $1AB8 , $ED2 , $1458
' 1B40
  word $8D , $FFD8 , $1522 , $61 , $1B0C , $7087 , $6166 , $6E3E , $6166 , $ED2 , $C76 , $33 , $DD6 , $8D , $8 , $1AF8
' 1B60
  word $46 , $4 , $1B18 , $61 , $1B4A , $6186 , $6363 , $7065 , $74 , $29F4 , $2A26 , $13BA , $DFC , $5D , $10 , $DD6
' 1B80
  word $8D , $10 , $1228 , $149C , $FF8 , $2AE8 , $15BC , $46 , $4 , $26 , $61 , $1B6A , $7085 , $7261 , $6573 , $126C
' 1BA0
  word $1398 , $E08 , $1548 , $8D , $8 , $CC6 , $46 , $7A , $ED2 , $1276 , $E3A , $CC6 , $1430 , $124A , $F74 , $DFC
' 1BC0
  word $1530 , $EDE , $8D , $A , $26 , $CBA , $46 , $56 , $5D , $7E , $EDE , $8D , $48 , $ED2 , $124A , $F74
' 1BE0
  word $ED2 , $149C , $5D , $3 , $1430 , $1836 , $8D , $30 , $1776 , $F68 , $E3A , $F68 , $CC6 , $79 , $ED2 , $DFC
' 1C00
  word $F68 , $5D , $3 , $F74 , $E3A , $14AA , $80 , $FFEE , $26 , $5D , $3 , $1398 , $1562 , $46 , $4 , $144C
' 1C20
  word $149C , $CC6 , $8D , $FF92 , $1522 , $61 , $1B98 , $6E88 , $7865 , $7774 , $726F , $64 , $126C , $1398 , $E08 , $EF2
' 1C40
  word $8D , $12 , $124A , $DFC , $1398 , $E08 , $F74 , $149C , $1398 , $E46 , $61 , $1C2E , $7089 , $7261 , $6573 , $6F77
' 1C60
  word $6472 , $2C8E , $1B9E , $ED2 , $8D , $14 , $1398 , $E08 , $14AA , $1430 , $1228 , $F74 , $E3A , $1398 , $E46 , $61
' 1C80
  word $1C58 , $7087 , $7261 , $6573 , $6C62 , $CB0 , $1C62 , $1472 , $61 , $1C82 , $7087 , $7261 , $6573 , $776E , $1C8A , $8D
' 1CA0
  word $A , $124A , $1C38 , $46 , $4 , $CC6 , $61 , $1C94 , $6684 , $6E69 , $64 , $1AC8 , $F68 , $2986 , $ED2 , $8D
' 1CC0
  word $44 , $1522 , $ED2 , $1AA4 , $F68 , $DFC , $5D , $80 , $DD6 , $1458 , $8D , $4 , $E08 , $FF8 , $DFC , $ED2
' 1CE0
  word $5D , $40 , $DD6 , $8D , $18 , $5D , $20 , $DD6 , $8D , $8 , $CD6 , $46 , $4 , $CCE , $46 , $6
' 1D00
  word $26 , $CBA , $61 , $1CB0 , $3C82 , $23 , $12F4 , $138A , $E46 , $61 , $1D08 , $2382 , $3E , $26 , $12F4 , $138A
' 1D20
  word $E08 , $F42 , $CBA , $138A , $1562 , $12DC , $E3A , $12DC , $61 , $1D16 , $7486 , $636F , $6168 , $72 , $5D , $3F
' 1D40
  word $DD6 , $5D , $30 , $F74 , $ED2 , $5D , $39 , $EF2 , $8D , $8 , $5D , $7 , $F74 , $ED2 , $5D , $5D
' 1D60
  word $EF2 , $8D , $8 , $5D , $3 , $F74 , $61 , $1D34 , $2381 , $1322 , $E08 , $2E1E , $FF8 , $1D3C , $CBA , $138A
' 1D80
  word $1562 , $12DC , $E3A , $61 , $1D70 , $2382 , $73 , $1D72 , $ED2 , $1458 , $8D , $FFF8 , $61 , $1D8A , $7582 , $2E
' 1DA0
  word $1D0C , $1D8E , $1D1A , $1A3C , $15CC , $61 , $1D9C , $2E81 , $ED2 , $1480 , $8D , $A , $5D , $2D , $2C50 , $1014
' 1DC0
  word $1DA0 , $61 , $1DAE , $6385 , $676F , $6469 , $CBA , $CCE , $E7C , $61 , $1DC6 , $5F8A , $6F6C , $6B63 , $7261 , $6172
' 1DE0
  word $79 , $4F , $F0F , $F0F , $F0F , $F0F , $1DD6 , $6C84 , $636F , $6B , $5D , $7 , $DD6 , $ED2 , $1DE2 , $F74
' 1E00
  word $ED2 , $DFC , $ED2 , $5D , $F , $DD6 , $1DCC , $EDE , $8D , $26 , $5D , $10 , $F74 , $1530 , $FF8 , $E3A
' 1E20
  word $5D , $F0 , $DD6 , $1458 , $8D , $8 , $5D , $6 , $1124 , $26 , $46 , $46 , $26 , $FF8 , $CBA , $5D
' 1E40
  word $1000 , $5D , $8 , $F16 , $CC6 , $79 , $F68 , $5D , $6 , $E8C , $1458 , $8D , $8 , $26 , $CC6 , $20D6
' 1E60
  word $80 , $FFEA , $8D , $8 , $5D , $7 , $1124 , $26 , $1DCC , $5D , $10 , $F74 , $FF8 , $E3A , $61 , $1DEE
' 1E80
  word $7586 , $6C6E , $636F , $6B , $5D , $7 , $DD6 , $ED2 , $1DE2 , $F74 , $ED2 , $DFC , $ED2 , $5D , $F , $DD6
' 1EA0
  word $1DCC , $EDE , $8D , $36 , $5D , $10 , $F42 , $ED2 , $5D , $F0 , $DD6 , $1458 , $8D , $18 , $26 , $5D
' 1EC0
  word $F , $FF8 , $E3A , $5D , $7 , $E8C , $26 , $46 , $8 , $FF8 , $E3A , $26 , $46 , $8 , $5D , $8
' 1EE0
  word $1124 , $61 , $1E80 , $7589 , $6C6E , $636F , $616B , $6C6C , $5D , $8 , $CC6 , $79 , $1DE2 , $1A5C , $F74 , $DFC
' 1F00
  word $5D , $F , $DD6 , $1DCC , $EDE , $8D , $18 , $5D , $F , $1DE2 , $1A5C , $F74 , $E3A , $1A5C , $5D , $7
' 1F20
  word $E8C , $26 , $80 , $FFD2 , $61 , $1EE6 , $3285 , $6F6C , $6B63 , $CD6 , $1DF4 , $61 , $1F2C , $3287 , $6E75 , $6F6C
' 1F40
  word $6B63 , $CD6 , $1E88 , $61 , $1F3A , $6389 , $6568 , $6B63 , $6964 , $7463 , $A60 , $E08 , $F74 , $A6E , $E08 , $153C
' 1F60
  word $8D , $8 , $5D , $9 , $1124 , $61 , $1F4A , $288D , $7263 , $6165 , $6574 , $6562 , $6967 , $296E , $2812 , $1FF2
' 1F80
  word $A54 , $E08 , $A60 , $E08 , $ED2 , $14B8 , $A54 , $E46 , $FF8 , $F68 , $E46 , $14B8 , $61 , $1F6E , $288B , $7263
' 1FA0
  word $6165 , $6574 , $6E65 , $2964 , $F68 , $1920 , $18E4 , $F74 , $1628 , $A60 , $E46 , $2824 , $61 , $1F9C , $6387 , $7263
' 1FC0
  word $6165 , $6574 , $1F7C , $FF8 , $1FA8 , $61 , $1FBC , $6386 , $6572 , $7461 , $65 , $CB0 , $1C62 , $8D , $A , $1F7C
' 1FE0
  word $124A , $1FA8 , $1C38 , $61 , $1FCE , $6887 , $7265 , $7765 , $6C61 , $2812 , $CD6 , $1F54 , $A60 , $E08 , $1628 , $A60
' 2000
  word $E46 , $2824 , $61 , $1FEA , $6185 , $6C6C , $746F , $2812 , $ED2 , $1F54 , $A60 , $1562 , $2824 , $61 , $2008 , $7782
' 2020
  word $2C , $2812 , $1FF2 , $A60 , $E08 , $E46 , $CD6 , $200E , $2824 , $61 , $201E , $6382 , $2C , $2812 , $A60 , $E08
' 2040
  word $E3A , $CCE , $200E , $2824 , $61 , $2036 , $6887 , $7265 , $6C65 , $6C61 , $2812 , $5D , $4 , $1F54 , $A60 , $E08
' 2060
  word $1610 , $A60 , $E46 , $2824 , $61 , $204C , $6C82 , $2C , $2812 , $2054 , $A60 , $E08 , $E2E , $5D , $4 , $200E
' 2080
  word $2824 , $61 , $206C , $6F86 , $6C72 , $666E , $61 , $1AC8 , $1578 , $61 , $2086 , $668A , $726F , $6874 , $6E65 , $7274
' 20A0
  word $79 , $5D , $80 , $208E , $61 , $2096 , $6989 , $6D6D , $6465 , $6169 , $6574 , $5D , $40 , $208E , $61 , $20AC
' 20C0
  word $6584 , $6578 , $63 , $5D , $60 , $208E , $61 , $20C0 , $6C85 , $6165 , $6576 , $CCE , $28 , $CD6 , $37 , $61
' 20E0
  word $20D0 , $6389 , $656C , $7261 , $656B , $7379 , $CCE , $13BA , $1590 , $CC6 , $D1A , $E08 , $CC6 , $79 , $2B6C , $1522
' 2100
  word $F4E , $80 , $FFF8 , $1458 , $8D , $FFE8 , $61 , $20E2 , $7783 , $6C3E , $5D , $FFFF , $DD6 , $FF8 , $5D , $10
' 2120
  word $F16 , $F4E , $61 , $2110 , $6C83 , $773E , $ED2 , $5D , $10 , $FAE , $FF8 , $5D , $FFFF , $DD6 , $61 , $2128
' 2140
  word $3A81 , $2812 , $1FD6 , $5D , $3741 , $CCE , $13BA , $1578 , $61 , $2140 , $5F85 , $6D6D , $7363 , $13DE , $8D , $26
' 2160
  word $1A48 , $4D1F , $5349 , $414D , $4354 , $4548 , $2044 , $4F43 , $544E , $4F52 , $204C , $5453 , $5552 , $5443 , $5255 , $2845
' 2180
  word $2953 , $15BC , $20EC , $61 , $2154 , $3BC1 , $BA4 , $2022 , $CCE , $13BA , $1590 , $20A2 , $5D , $3741 , $1466 , $8D
' 21A0
  word $4 , $215A , $2824 , $61 , $218A , $6486 , $746F , $6568 , $6E , $212C , $ED2 , $5D , $1235 , $EDE , $FF8 , $5D
' 21C0
  word $1239 , $EDE , $F4E , $8D , $14 , $ED2 , $A60 , $E08 , $FF8 , $F42 , $FF8 , $E46 , $46 , $4 , $215A , $61
' 21E0
  word $21AA , $74C4 , $6568 , $6E , $21B2 , $61 , $21E2 , $74C5 , $6568 , $736E , $ED2 , $5D , $FFFF , $DD6 , $ED2 , $5D
' 2200
  word $1235 , $EDE , $FF8 , $5D , $1239 , $EDE , $F4E , $8D , $A , $21B2 , $CC6 , $46 , $4 , $CBA , $8D , $FFD6
' 2220
  word $61 , $21EE , $69C2 , $66 , $C34 , $2022 , $A60 , $E08 , $5D , $1235 , $2114 , $CC6 , $2022 , $61 , $2224 , $65C4
' 2240
  word $736C , $65 , $BDA , $2022 , $CC6 , $2022 , $21B2 , $A60 , $E08 , $14C6 , $5D , $1239 , $2114 , $61 , $223E , $75C5
' 2260
  word $746E , $6C69 , $212C , $5D , $1317 , $EDE , $8D , $12 , $C34 , $2022 , $A60 , $E08 , $F42 , $2022 , $46 , $4
' 2280
  word $215A , $61 , $225E , $62C5 , $6765 , $6E69 , $A60 , $E08 , $5D , $1317 , $2114 , $61 , $2286 , $6486 , $6C6F , $6F6F
' 22A0
  word $70 , $FF8 , $212C , $5D , $2329 , $EDE , $8D , $12 , $FF8 , $2022 , $A60 , $E08 , $F42 , $2022 , $46 , $4
' 22C0
  word $215A , $61 , $229A , $6CC4 , $6F6F , $70 , $C0C , $22A2 , $61 , $22C6 , $2BC5 , $6F6C , $706F , $C20 , $22A2 , $61
' 22E0
  word $22D4 , $64C2 , $6F , $BFA , $2022 , $A60 , $E08 , $5D , $2329 , $2114 , $61 , $22E2 , $5F84 , $6365 , $73 , $5D
' 2300
  word $3A , $2C50 , $15CC , $61 , $22F8 , $5F84 , $6475 , $66 , $1A48 , $550F , $444E , $4645 , $4E49 , $4445 , $5720 , $524F
' 2320
  word $2044 , $61 , $230A , $5F83 , $7071 , $5D , $22 , $1B9E , $14AA , $124A , $1430 , $E3A , $FF8 , $14B8 , $1398 , $1562
' 2340
  word $61 , $2326 , $5F83 , $7073 , $2022 , $232A , $ED2 , $A60 , $E08 , $1934 , $DFC , $149C , $200E , $1FF2 , $61 , $2344
' 2360
  word $2EC2 , $22 , $B94 , $2348 , $61 , $2360 , $6689 , $7369 , $756E , $626D , $7265 , $1836 , $61 , $236C , $6687 , $756E
' 2380
  word $626D , $7265 , $1776 , $61 , $237C , $698C , $746E , $7265 , $7270 , $7465 , $6170 , $64 , $CCE , $1398 , $E46 , $CB0
' 23A0
  word $1C62 , $8D , $D4 , $124A , $1C38 , $1CB6 , $ED2 , $8D , $6C , $ED2 , $CBA , $EDE , $8D , $18 , $26 , $141E
' 23C0
  word $8D , $8 , $2022 , $46 , $4 , $1348 , $CC6 , $46 , $48 , $CD6 , $EDE , $8D , $A , $1348 , $CC6 , $46
' 23E0
  word $38 , $141E , $8D , $A , $1348 , $CC6 , $46 , $2A , $1B52 , $13DE , $8D , $1C , $1A48 , $490F , $4D4D , $4445
' 2400
  word $4149 , $4554 , $5720 , $524F , $2044 , $1A1C , $15BC , $46 , $4 , $26 , $20EC , $CBA , $46 , $5A , $26 , $ED2
' 2420
  word $1638 , $2376 , $8D , $30 , $1638 , $2384 , $141E , $8D , $20 , $ED2 , $CC6 , $5D , $FFFF , $15A8 , $8D , $C
' 2440
  word $BEA , $2022 , $2022 , $46 , $8 , $C44 , $2022 , $2070 , $CC6 , $46 , $20 , $141E , $8D , $4 , $2824 , $CCE
' 2460
  word $13BA , $1590 , $13DE , $8D , $8 , $2310 , $1A1C , $15BC , $20EC , $CBA , $46 , $4 , $CBA , $8D , $FF22 , $61
' 2480
  word $238A , $6989 , $746E , $7265 , $7270 , $7465 , $1B72 , $2398 , $61 , $2482 , $5F84 , $6377 , $31 , $2812 , $1FD6 , $BC8
' 24A0
  word $2022 , $2022 , $20A2 , $1AC8 , $2824 , $61 , $2494 , $7789 , $6F63 , $736E , $6174 , $746E , $249A , $26 , $61 , $24AE
' 24C0
  word $7789 , $6176 , $6972 , $6261 , $656C , $2812 , $1FD6 , $BB6 , $2022 , $CC6 , $2022 , $20A2 , $2824 , $61 , $24C0 , $6188
' 24E0
  word $6D73 , $616C , $6562 , $6C , $2812 , $1FD6 , $2022 , $2824 , $61 , $24DE , $6883 , $7865 , $5D , $10 , $1322 , $E46
' 2500
  word $61 , $24F4 , $6485 , $6C65 , $736D , $57 , $FFFF , $7FFF , $10C8 , $5D , $3E8 , $2E2C , $2E2C , $F38 , $CCE , $F2C
' 2520
  word $10C8 , $5D , $3E8 , $2E2C , $2E10 , $CEA , $33 , $F74 , $ED2 , $CEA , $33 , $F42 , $1480 , $8D , $FFF4 , $26
' 2540
  word $61 , $2504 , $3E82 , $6D , $CCE , $FF8 , $F16 , $61 , $2544 , $5CE1 , $126C , $1398 , $E46 , $61 , $2552 , $5F83
' 2560
  word $6C64 , $29F4 , $1228 , $149C , $13BA , $DFC , $1500 , $5D , $8 , $13BA , $1578 , $5D , $10 , $13BA , $1590 , $5D
' 2580
  word $2E , $2C50 , $15BC , $1B72 , $ED2 , $DFC , $CD6 , $2E , $EDE , $F68 , $149C , $DFC , $5D , $3 , $2E , $EDE
' 25A0
  word $F4E , $8D , $FFDA , $26 , $2C50 , $15BC , $13BA , $E3A , $61 , $255E , $7BE1 , $5D , $7D , $2562 , $61 , $25B4
' 25C0
  word $7DE1 , $61 , $25C0 , $5F83 , $6669 , $1458 , $8D , $8 , $5D , $5D , $2562 , $61 , $25C6 , $5BE3 , $6669 , $25CA
' 25E0
  word $61 , $25DA , $5BE6 , $6669 , $6564 , $66 , $1C9C , $1CB6 , $1522 , $25CA , $61 , $25E4 , $5BE7 , $6669 , $646E , $6665
' 2600
  word $1C9C , $1CB6 , $1522 , $1458 , $25CA , $61 , $25F8 , $5DE1 , $61 , $260E , $2EE3 , $2E2E , $61 , $2614 , $2781 , $1C9C
' 2620
  word $ED2 , $8D , $18 , $1CB6 , $1458 , $8D , $10 , $13DE , $8D , $6 , $2310 , $15BC , $26 , $CC6 , $61 , $261C
' 2640
  word $6382 , $71 , $75 , $ED2 , $1638 , $F74 , $1628 , $7C , $61 , $2640 , $63E2 , $22 , $141E , $8D , $A , $B88
' 2660
  word $2348 , $46 , $4 , $232A , $61 , $2654 , $6687 , $5F6C , $6F6C , $6B63 , $4F , $0 , $266C , $6686 , $7473 , $7261
' 2680
  word $74

fstartPFA

  word $1118 , $5D , $10 , $F16 , $B6A , $CD6 , $F16 , $F4E , $1DCC , $F4E , $C8A , $42 , $13AA , $DFC , $5D
' 26A0
  word $100 , $1118 , $E46 , $1228 , $B1E , $5D , $4 , $F42 , $CC6 , $1A78 , $5D , $A , $1322 , $E46 , $2E00 , $2812
' 26C0
  word $B10 , $E08 , $1458 , $8D , $46 , $CBA , $B10 , $E46 , $2824 , $CC6 , $2674 , $E46 , $AC6 , $B02 , $E46 , $AB0
' 26E0
  word $AF4 , $E46 , $1DE2 , $5D , $8 , $15FE , $79 , $5D , $F , $1A5C , $E3A , $80 , $FFF6 , $2644 , $6F06 , $626E
' 2700
  word $6F6F , $74 , $1CB6 , $26 , $1348 , $46 , $4 , $2824 , $2644 , $6F07 , $726E , $7365 , $7465 , $12A2 , $1934 , $1DCC
' 2720
  word $12A2 , $1978 , $12A2 , $1CB6 , $8D , $8 , $1348 , $46 , $14 , $26 , $2644 , $6F07 , $726E , $7365 , $7465 , $1CB6
' 2740
  word $26 , $1348 , $141E , $1458 , $8D , $2A , $13DE , $8D , $24 , $1F32 , $AF4 , $E08 , $1A3C , $AA2 , $E08 , $1DB0
' 2760
  word $1A48 , $4303 , $676F , $1DCC , $1DB0 , $1A48 , $6F02 , $6B , $15BC , $1F42 , $248C , $CC6 , $8D , $FFCA , $61 , $267A
' 2780
  word $6987 , $696E , $6374 , $6E6F , $B2E , $B3E , $B4C , $32D2 , $61 , $2780 , $6F86 , $626E , $6F6F , $74 , $B5A , $1166
' 27A0
  word $B5A , $105E , $5D , $10 , $250A , $2644 , $6907 , $696E , $6374 , $6E6F , $B5A , $19F4 , $5D , $100 , $250A , $1DCC
' 27C0
  word $140C , $5D , $8 , $CC6 , $79 , $1A5C , $1DCC , $1466 , $1A5C , $B5A , $1466 , $DD6 , $8D , $6 , $1A5C , $105E
' 27E0
  word $80 , $FFE8 , $61 , $2794 , $6F87 , $726E , $3065 , $3130 , $1EF0 , $5D , $4 , $13BA , $1578 , $B02 , $E08 , $12FE
' 2800
  word $E46 , $26 , $61 , $27E8 , $6C88 , $636F , $646B , $6369 , $74 , $CC6 , $1DF4 , $61 , $2808 , $6688 , $6572 , $6465
' 2820
  word $6369 , $74 , $CC6 , $1E88 , $61 , $281A , $7583 , $3D3E , $4 , $310E , $61 , $282C , $628D , $6975 , $646C , $425F
' 2840
  word $6F6F , $4F74 , $7470 , $4A , $112 , $2838 , $7583 , $2A6D , $B2 , $0 , $2112 , $3118 , $54A3 , $5CFD , $9A00 , $A0FD
' 2860
  word $9C00 , $A0FD , $9E00 , $A0FD , $9601 , $2BFD , $11B , $5C4C , $9ECC , $81BD , $9ACE , $C8BD , $9801 , $2DFD , $9C01 , $34FD
' 2880
  word $117 , $5C54 , $96CF , $A0BD , $3695 , $5CFD , $96CD , $A0BD , $61 , $5C7C , $284C , $7586 , $2F6D , $6F6D , $64 , $B2
' 28A0
  word $2312 , $3164 , $54A3 , $5CFD , $A2CB , $A0BD , $54A4 , $5CFD , $9C40 , $A0FD , $9A00 , $A0FD , $9601 , $2DFD , $A201 , $35FD
' 28C0
  word $9A01 , $35FD , $9ACC , $84B1 , $9ACC , $E18D , $9E01 , $34FD , $9D18 , $E4FD , $96CD , $A0BD , $3695 , $5CFD , $96CF , $A0BD
' 28E0
  word $61 , $5C7C , $2896 , $6385 , $7473 , $3D72 , $B2 , $0 , $1B12 , $31B4 , $54A3 , $5CFD , $9ACC , $BD , $9A01 , $80FD
' 2900
  word $9601 , $84FD , $9CCC , $BD , $9801 , $80FD , $9601 , $80FD , $9ECB , $BD , $9CCF , $863D , $9B17 , $E4E9 , $96C6 , $78BD
' 2920
  word $61 , $5C7C , $28E6 , $6E85 , $6D61 , $3D65 , $B2 , $0 , $2512 , $31F4 , $54A3 , $5CFD , $9ACC , $BD , $9A1F , $60FD
' 2940
  word $9801 , $80FD , $9ECB , $BD , $9E1F , $60FD , $9CCD , $A0BD , $9A01 , $80FD , $120 , $5C7C , $9CCC , $BD , $9801 , $80FD
' 2960
  word $9601 , $80FD , $9ECB , $BD , $9CCF , $863D , $9B1C , $E4E9 , $96C6 , $78BD , $61 , $5C7C , $2926 , $5F8B , $6964 , $7463
' 2980
  word $6573 , $7261 , $6863 , $B2 , $3312 , $324C , $54A3 , $5CFD , $A0CC , $A0BD , $A2CB , $A0BD , $9ACC , $BD , $9A1F , $60FD
' 29A0
  word $9801 , $80FD , $9ECB , $BD , $9E1F , $60FD , $9CCD , $A0BD , $9A01 , $80FD , $122 , $5C7C , $9CCC , $BD , $9801 , $80FD
' 29C0
  word $9601 , $80FD , $9ECB , $BD , $9CCF , $863D , $9B1E , $E4E9 , $96D1 , $A0BD , $61 , $5C68 , $A202 , $84FD , $96D1 , $6BD
' 29E0
  word $61 , $5C68 , $98D0 , $A0BD , $115 , $5C7C , $297A , $7085 , $6461 , $6C62 , $B2 , $0 , $1312 , $32BC , $A1F0 , $A0BD
' 2A00
  word $A004 , $80FD , $9C20 , $A0FD , $34D0 , $83E , $A004 , $80FD , $9D16 , $E4FD , $61 , $5C7C , $2020 , $2020 , $29EE , $5F87
' 2A20
  word $6361 , $6563 , $7470 , $B2 , $5D12 , $32EC , $3695 , $5CFD , $9BF0 , $A0BD , $9A02 , $80FD , $A2CD , $4BD , $9ADD , $80FD
' 2A40
  word $98CD , $BD , $9808 , $627D , $A200 , $A0D5 , $9ADA , $84FD , $96CD , $A0BD , $9C7E , $A0FD , $9FF0 , $4BD , $9F00 , $627D
' 2A60
  word $11E , $5C54 , $9900 , $A0FD , $99F0 , $43D , $9E0D , $867D , $9C01 , $A0E9 , $135 , $5C68 , $9E08 , $867D , $12C , $5C68
' 2A80
  word $9E20 , $48FD , $9ECB , $3D , $9601 , $80FD , $135 , $5C7C , $7F39 , $5CFE , $9E20 , $A0FD , $7F39 , $5CFE , $9601 , $84FD
' 2AA0
  word $96CD , $48BD , $9ECB , $3D , $9C02 , $80FD , $9C7E , $4CFD , $9E08 , $A0FD , $7F39 , $5CFE , $9D1E , $E4FD , $96CD , $84BD
' 2AC0
  word $61 , $5C7C , $A200 , $867D , $13F , $5C68 , $98D1 , $4BD , $9900 , $627D , $13B , $5C68 , $9ED1 , $43D , $0 , $5C7C
' 2AE0
  word $2A1E , $2E84 , $7473 , $72 , $B2 , $0 , $2112 , $33B0 , $54A3 , $5CFD , $9800 , $867D , $A3F0 , $A095 , $A202 , $80D5
' 2B00
  word $9AD1 , $695 , $120 , $5C68 , $9ECB , $BD , $9601 , $80FD , $9CCD , $4BD , $9D00 , $627D , $11B , $5C68 , $9ECD , $43D
' 2B20
  word $9919 , $E4FD , $54A4 , $5CFD , $61 , $5C7C , $2AE2 , $5F86 , $6B66 , $7965 , $3F , $B2 , $1712 , $33FC , $98CB , $4BD
' 2B40
  word $9900 , $627D , $9AC6 , $78BD , $119 , $5C54 , $9D00 , $A0FD , $9CCB , $43D , $96CC , $A0BD , $3695 , $5CFD , $96CD , $A0BD
' 2B60
  word $61 , $5C7C , $2B2E , $6685 , $656B , $3F79 , $B2 , $0 , $1712 , $3434 , $3695 , $5CFD , $97F0 , $4BD , $9700 , $627D
' 2B80
  word $98C6 , $78BD , $11A , $5C54 , $9D00 , $A0FD , $9DF0 , $43D , $3695 , $5CFD , $96CC , $A0BD , $61 , $5C7C , $2B66 , $6B83
' 2BA0
  word $7965 , $B2 , $1112 , $3468 , $3695 , $5CFD , $97F0 , $4BD , $9700 , $627D , $114 , $5C54 , $9900 , $A0FD , $99F0 , $43D
' 2BC0
  word $61 , $5C7C , $2B9E , $5F87 , $6566 , $696D , $3F74 , $B2 , $1D12 , $3494 , $54A3 , $5CFD , $96FF , $60FD , $9ACC , $A0BD
' 2BE0
  word $9A02 , $80FD , $9CCD , $6BD , $9EC6 , $78BD , $11E , $5C68 , $9ACE , $4BD , $9B00 , $627D , $9EC6 , $7CBD , $96CE , $415
' 2C00
  word $96CF , $A0BD , $61 , $5C7C , $2BC6 , $6686 , $6D65 , $7469 , $3F , $B2 , $1B12 , $34D8 , $96FF , $60FD , $9BF0 , $A0BD
' 2C20
  word $9A02 , $80FD , $9CCD , $6BD , $9EC6 , $78BD , $11D , $5C68 , $9ACE , $4BD , $9B00 , $627D , $9EC6 , $7CBD , $96CE , $415
' 2C40
  word $96CF , $A0BD , $61 , $5C7C , $2C0A , $6584 , $696D , $74 , $B2 , $0 , $1912 , $3518 , $54A3 , $5CFD , $98FF , $60FD
' 2C60
  word $9BF0 , $A0BD , $9A02 , $80FD , $9CCD , $6BD , $11D , $5C68 , $9ACE , $4BD , $9B00 , $627D , $119 , $5C68 , $98CE , $43D
' 2C80
  word $61 , $5C7C , $2C4A , $7386 , $696B , $6270 , $6C , $B2 , $2512 , $3554 , $99F0 , $A0BD , $98DC , $80FD , $9ACC , $4BD
' 2CA0
  word $9A80 , $877D , $123 , $5C4C , $9C80 , $A0FD , $9CCD , $84BD , $9A04 , $80FD , $9BF0 , $80BD , $A0CD , $BD , $A020 , $867D
' 2CC0
  word $9A01 , $80E9 , $9D1C , $E4E9 , $9A04 , $84FD , $9BF0 , $84BD , $9ACC , $43D , $61 , $5C7C , $2C86 , $5F87 , $6565 , $6572
' 2CE0
  word $6461 , $B2 , $4112 , $35A8 , $11A , $5C7C , $0 , $2000 , $0 , $1000 , $D , $0 , $A316 , $A0BD , $A318 , $E4FD
' 2D00
  word $0 , $5C7C , $98CB , $A0BD , $9600 , $A0FD , $ED14 , $64BF , $9C08 , $A0FD , $3317 , $5CFE , $29F2 , $613E , $9601 , $34FD
' 2D20
  word $E915 , $68BF , $3317 , $5CFE , $3317 , $5CFE , $E915 , $64BF , $3317 , $5CFE , $9D1E , $E4FD , $9800 , $867D , $E914 , $7CBF
' 2D40
  word $ED14 , $68BF , $3317 , $5CFE , $E915 , $68BF , $3317 , $5CFE , $3317 , $5CFE , $E915 , $64BF , $E914 , $64BF , $3317 , $5CFE
' 2D60
  word $61 , $5C7C , $2CDA , $5F88 , $6565 , $7277 , $7469 , $65 , $B2 , $0 , $3F12 , $3638 , $11A , $5C7C , $0 , $2000
' 2D80
  word $0 , $1000 , $D , $0 , $A316 , $A0BD , $A318 , $E4FD , $0 , $5C7C , $9C08 , $A0FD , $9680 , $627D , $E914 , $7CBF
' 2DA0
  word $3317 , $5CFE , $E915 , $68BF , $3317 , $5CFE , $3317 , $5CFE , $E915 , $64BF , $9601 , $2CFD , $3317 , $5CFE , $9D1B , $E4FD
' 2DC0
  word $ED14 , $64BF , $29F2 , $623E , $96C6 , $7CBD , $3317 , $5CFE , $E915 , $68BF , $3317 , $5CFE , $3317 , $5CFE , $E915 , $64BF
' 2DE0
  word $3317 , $5CFE , $E914 , $64BF , $ED14 , $68BF , $61 , $5C7C , $2D66 , $698C , $696E , $5F74 , $6F63 , $6867 , $7265 , $65
' 2E00
  word $5D , $140 , $137A , $E46 , $61 , $2DF2 , $7582 , $2A , $2850 , $26 , $61 , $2E0C , $7585 , $6D2F , $646F , $CC6
' 2E20
  word $FF8 , $289E , $61 , $2E18 , $7582 , $2F , $2E1E , $1522 , $61 , $2E28 , $6185 , $635F , $6168 , $B2 , $4F12 , $336C
' 2E40
  word $A2CB , $A0BD , $54A4 , $5CFD , $54A3 , $5CFD , $965C , $867D , $11D , $5C54 , $7134 , $5CFE , $960D , $867D , $118 , $5C54
' 2E60
  word $7134 , $5CFE , $116 , $5C7C , $967B , $867D , $123 , $5C54 , $7134 , $5CFE , $967D , $867D , $11F , $5C54 , $7134 , $5CFE
' 2E80
  word $9620 , $867D , $9609 , $8655 , $12A , $5C54 , $7134 , $5CFE , $9620 , $867D , $9609 , $8655 , $126 , $5C68 , $12C , $5C7C
' 2EA0
  word $7134 , $5CFE , $960D , $867D , $96CC , $3D , $9801 , $80FD , $98D1 , $853D , $12B , $5C50 , $96CC , $A0BD , $61 , $5C7C
' 2EC0
  word $100 , $0 , $97F0 , $4BD , $9700 , $627D , $134 , $5C54 , $67F0 , $43E , $0 , $5C7C , $2E34 , $6187 , $665F , $6F6C
' 2EE0
  word $7475 , $B2 , $2B12 , $3414 , $A220 , $A0FD , $54A3 , $5CFD , $9CCB , $A0BD , $9ECC , $4BD , $9CCF , $87BD , $125 , $5C78
' 2F00
  word $A2CE , $4CBD , $9BF0 , $A0BD , $9A02 , $80FD , $A0CD , $4BD , $9AD0 , $4BD , $9B00 , $627D , $123 , $5C68 , $96CF , $BD
' 2F20
  word $9E01 , $80FD , $96D0 , $43D , $A31D , $E4FD , $9ECC , $43D , $54A4 , $5CFD , $61 , $5C7C , $2EDA , $6682 , $6C , $2812
' 2F40
  word $2674 , $E08 , $8D , $8 , $2824 , $46 , $D4 , $CBA , $2674 , $E46 , $1DCC , $19DE , $ED2 , $7C , $11E0 , $2824
' 2F60
  word $CC6 , $A6E , $E08 , $14C6 , $A60 , $E08 , $5D , $80 , $F74 , $ED2 , $A6E , $E46 , $D1A , $E08 , $CC6 , $79
' 2F80
  word $1430 , $1548 , $8D , $22 , $2B6C , $1522 , $8D , $10 , $CC6 , $1A6A , $F80 , $149C , $1500 , $46 , $8 , $ED2
' 2FA0
  word $A6E , $2EE2 , $46 , $20 , $2B6C , $8D , $12 , $CC6 , $1A6A , $FF8 , $CD6 , $2E , $2E3A , $46 , $A , $26
' 2FC0
  word $ED2 , $A6E , $2EE2 , $80 , $FFB8 , $ED2 , $A6E , $2EE2 , $ED2 , $A6E , $E08 , $1548 , $8D , $FFF0 , $15BC , $15BC
' 2FE0
  word $26 , $14B8 , $A6E , $E46 , $1DCC , $121C , $CC6 , $2674 , $E46 , $75 , $F68 , $8D , $26 , $105E , $15BC , $1DB0
' 3000
  word $1A48 , $6315 , $6168 , $6172 , $7463 , $7265 , $2073 , $766F , $7265 , $6C66 , $776F , $6465 , $15BC , $46 , $4 , $143E
' 3020
  word $61 , $2F3A , $5F87 , $6573 , $6972 , $6C61 , $B2 , $0 , $4D12 , $3561 , $8FF0 , $83F , $A330 , $A0FF , $A550 , $A0FF
' 3040
  word $A759 , $A0FF , $A971 , $A0FF , $AB86 , $A0FF , $ADA6 , $A0FF , $E9CB , $68BF , $EDCB , $68BF , $A1D1 , $5CBF , $95F2 , $623F
' 3060
  word $11C , $5C54 , $BA09 , $A0FF , $BDC8 , $A0BF , $BDF1 , $80BF , $BDC9 , $80BF , $A1D1 , $5CBF , $9BDE , $A0BF , $9BF1 , $84BF
' 3080
  word $9A00 , $C17F , $123 , $5C4C , $95F2 , $613F , $B801 , $30FF , $BB22 , $E4FF , $11C , $5C4C , $B817 , $28FF , $B8FF , $60FF
' 30A0
  word $8DDC , $A0BF , $11C , $5C7C , $A3D2 , $5CBF , $D1EB , $863F , $130 , $5C68 , $D880 , $68FF , $6DEC , $50BE , $BFC5 , $A0BF
' 30C0
  word $BFEC , $60BF , $BFED , $28BF , $A3D2 , $5CBF , $8A08 , $25FF , $D800 , $C8FF , $D87F , $60FF , $DA08 , $80FF , $D601 , $80FF
' 30E0
  word $D7FF , $60FF , $A3D2 , $5CBF , $BF00 , $68FF , $BE02 , $2CFF , $BE01 , $68FF , $C00B , $A0FF , $A3D2 , $5CBF , $C3F1 , $A0BF
' 3100
  word $BE01 , $29FF , $E9CB , $70BF , $C3C9 , $80BF , $A3D2 , $5CBF , $9BE1 , $A0BF , $9BF1 , $84BF , $9A00 , $C17F , $149 , $5C4C
' 3120
  word $C146 , $E4FF , $130 , $5C7C , $A5D0 , $5CBF , $A5D3 , $5CBF , $A5D0 , $5CBF , $A5D4 , $5CBF , $A5D0 , $5CBF , $A5D5 , $5CBF
' 3140
  word $A5D0 , $5CBF , $A5D6 , $5CBF , $150 , $5C7C , $A7D2 , $5CBF , $8D00 , $627F , $159 , $5C54 , $AFE2 , $A0BF , $AE01 , $80FF
' 3160
  word $AFFF , $60FF , $AFE5 , $863F , $159 , $5C68 , $A7D2 , $5CBF , $D1E3 , $54BE , $D3E3 , $54BE , $9BC6 , $A0BF , $8D00 , $A0FF
' 3180
  word $9BE4 , $2CBF , $9BC2 , $60BF , $C7C2 , $64BF , $C7CD , $68BF , $A7D2 , $5CBF , $8408 , $25FF , $C600 , $C8FF , $C67F , $60FF
' 31A0
  word $C808 , $80FF , $C5D7 , $A0BF , $159 , $5C7C , $A9D2 , $5CBF , $C5E5 , $863F , $171 , $5C68 , $9800 , $867F , $9FCC , $497
' 31C0
  word $9F00 , $6257 , $171 , $5C68 , $A9D2 , $5CBF , $F7E6 , $50BE , $9FC3 , $A0BF , $9FE6 , $60BF , $9FE7 , $28BF , $9FCC , $43F
' 31E0
  word $A9D2 , $5CBF , $8608 , $25FF , $CC00 , $C8FF , $CC7F , $60FF , $CE08 , $80FF , $CA01 , $80FF , $CBFF , $60FF , $171 , $5C7C
' 3200
  word $ABD2 , $5CBF , $B3F0 , $4BF , $B300 , $627F , $186 , $5C54 , $ABD2 , $5CBF , $B1E8 , $A0BF , $B001 , $80FF , $B1FF , $60FF
' 3220
  word $B1EB , $863F , $186 , $5C68 , $ABD2 , $5CBF , $D280 , $68FF , $2FE9 , $54BF , $31E9 , $54BF , $9BD9 , $A0BF , $9BEA , $2CBF
' 3240
  word $9BC4 , $60BF , $D3C4 , $64BF , $D3CD , $68BF , $ABD2 , $5CBF , $8808 , $25FF , $D200 , $C8FF , $D27F , $60FF , $D408 , $80FF
' 3260
  word $D1D8 , $A0BF , $ABD2 , $5CBF , $B20D , $867F , $B601 , $626B , $8FF0 , $417 , $9A0A , $A0EB , $9BF0 , $42B , $186 , $5C7C
' 3280
  word $ADD2 , $5CBF , $B5F0 , $A0BF , $B402 , $80FF , $99DA , $4BF , $ADD2 , $5CBF , $B4C2 , $80FF , $9FDA , $ABF , $1B4 , $5C68
' 32A0
  word $DDDA , $83F , $9E10 , $48FF , $E9CB , $64BF , $9FF1 , $80BF , $9E00 , $F8FF , $E9CB , $68BF , $ADD2 , $5CBF , $B404 , $80FF
' 32C0
  word $B7DA , $8BF , $1A6 , $5C7C , $3024 , $7386 , $7265 , $6169 , $6C , $14E2 , $10C8 , $FF8 , $2E2C , $ED2 , $14F0 , $14F0
' 32E0
  word $5D , $FF , $5D , $1C2 , $1430 , $42 , $149C , $1430 , $42 , $149C , $1430 , $42 , $149C , $1530 , $42 , $149C
' 3300
  word $5D , $100 , $FF8 , $1430 , $42 , $149C , $1530 , $42 , $149C , $1530 , $42 , $149C , $1530 , $42 , $149C , $FF8
' 3320
  word $2548 , $F68 , $42 , $149C , $FF8 , $2548 , $F68 , $42 , $149C , $5D , $1F0 , $FF8 , $79 , $CC6 , $1A5C , $42
' 3340
  word $80 , $FFF8 , $2644 , $5306 , $5245 , $4149 , $4C , $12B4 , $1934 , $12B4 , $12FE , $E46 , $5D , $4 , $13BA , $1590
' 3360
  word $CC6 , $1118 , $5D , $C4 , $F74 , $E2E , $CC6 , $1118 , $5D , $C8 , $F74 , $E2E , $302C , $61 , $32CA , $628F
' 3380
  word $6975 , $646C , $445F , $7665 , $654B , $6E72 , $6C65 , $4A , $1 , $337E , $7389 , $7265 , $6C66 , $6761 , $3F73 , $10E4
' 33A0
  word $5D , $C8 , $F74 , $DF0 , $61 , $3394 , $738B , $7265 , $6573 , $6674 , $616C , $7367 , $10E4 , $5D , $C8 , $F74
' 33C0
  word $E2E , $61 , $33AC , $738C , $7265 , $6573 , $646E , $7262 , $6165 , $6B , $10E4 , $5D , $C4 , $F74 , $E2E , $61
' 33E0
  word $33C6 , $248B , $5F43 , $5F61 , $6F64 , $6176 , $6C72 , $4A , $4D , $33E2 , $2490 , $5F43 , $5F61 , $785F , $7361 , $326D
' 3400
  word $313E , $4D49 , $734D , $4A , $13 , $33F4 , $248D , $5F43 , $5F61 , $785F , $7361 , $326D , $313E , $4A , $16 , $340C
' 3420
  word $248B , $5F43 , $5F61 , $6F64 , $6F63 , $6C6E , $4A , $52 , $3420 , $2488 , $5F43 , $7372 , $6F54 , $3F70 , $4A , $112
' 3440
  word $3432 , $2488 , $5F43 , $7473 , $6F54 , $D70 , $4A , $F2 , $3442 , $2488 , $5F43 , $7473 , $4F54 , $7253 , $4A , $CB
' 3460
  word $3452 , $2488 , $5F43 , $7372 , $7450 , $6572 , $4A , $CA , $3462 , $2488 , $5F43 , $7473 , $7450 , $3872 , $4A , $C9
' 3480
  word $3472 , $6C86 , $7361 , $6974 , $663F , $CCE , $28 , $5D , $2 , $28 , $149C , $EDE , $61 , $3482 , $2382 , $6543
' 34A0
  word $CBA , $138A , $1562 , $12DC , $E3A , $61 , $349C , $5F83 , $646E , $1322 , $E08 , $5D , $28 , $F68 , $F20 , $8D
' 34C0
  word $A , $5D , $6 , $46 , $6A , $5D , $F , $F68 , $F20 , $8D , $A , $5D , $8 , $46 , $56 , $5D
' 34E0
  word $9 , $F68 , $F20 , $8D , $A , $5D , $A , $46 , $42 , $5D , $7 , $F68 , $F20 , $8D , $A , $5D
' 3500
  word $B , $46 , $2E , $5D , $6 , $F68 , $F20 , $8D , $A , $5D , $C , $46 , $1A , $5D , $3 , $F68
' 3520
  word $F20 , $8D , $A , $5D , $10 , $46 , $6 , $5D , $20 , $1522 , $FF8 , $2E1E , $FF8 , $1472 , $8D , $4
' 3540
  word $149C , $61 , $34AE , $5F83 , $7466 , $5D , $4 , $1322 , $E08 , $5D , $8 , $5D , $A , $15A8 , $8D , $4
' 3560
  word $14AA , $1500 , $1D0C , $34B2 , $CC6 , $79 , $1D72 , $F68 , $1A5C , $149C , $FF8 , $2E1E , $26 , $1458 , $8D , $10
' 3580
  word $348A , $1458 , $8D , $8 , $5D , $5F , $34A0 , $80 , $FFDC , $1D1A , $1522 , $61 , $3546 , $5F83 , $6662 , $5D
' 35A0
  word $4 , $354A , $61 , $359A , $2E85 , $7962 , $6574 , $5D , $FF , $DD6 , $359E , $1A3C , $61 , $35A8 , $5F83 , $6677
' 35C0
  word $5D , $FFFF , $DD6 , $CD6 , $354A , $61 , $35BC , $2E85 , $6F77 , $6472 , $35C0 , $1A3C , $61 , $35CE , $5F83 , $666C
' 35E0
  word $CCE , $354A , $61 , $35DC , $2E85 , $6F6C , $676E , $35E0 , $1A3C , $61 , $35E8 , $3482 , $682D , $13 , $4 , $10F
' 3600
  word $61 , $35F6 , $3282 , $242A , $13 , $1 , $5F , $61 , $3604 , $3482 , $662F , $13 , $2 , $77 , $61 , $3612
' 3620
  word $6986 , $766E , $7265 , $2074 , $CBA , $F5A , $61 , $3620 , $6487 , $6365 , $6D69 , $6C61 , $5D , $A , $1322 , $E46
' 3640
  word $61 , $3630 , $6986 , $6F62 , $6E75 , $5064 , $CCE , $28 , $61 , $3644 , $5F86 , $6F77 , $6472 , $7473 , $CC6 , $7C
' 3660
  word $1AC8 , $1A48 , $4E26 , $4146 , $2820 , $6F46 , $7472 , $2F68 , $7341 , $206D , $6D49 , $656D , $6964 , $7461 , $2065 , $5865
' 3680
  word $6365 , $7475 , $2965 , $4E20 , $6D61 , $5365 , $1430 , $FF8 , $ED2 , $8D , $8 , $18A0 , $46 , $6 , $143E , $CBA
' 36A0
  word $8D , $8A , $75 , $ED2 , $1458 , $8D , $4 , $15BC , $149C , $5D , $3 , $DD6 , $7C , $ED2 , $35D4 , $15CC
' 36C0
  word $ED2 , $DFC , $ED2 , $5D , $80 , $DD6 , $8D , $A , $5D , $46 , $46 , $6 , $5D , $41 , $2C50 , $ED2
' 36E0
  word $5D , $40 , $DD6 , $8D , $A , $5D , $49 , $46 , $6 , $5D , $20 , $2C50 , $5D , $20 , $DD6 , $8D
' 3700
  word $A , $5D , $58 , $46 , $6 , $5D , $20 , $2C50 , $15CC , $ED2 , $1A1C , $ED2 , $DFC , $125E , $DD6 , $5D
' 3720
  word $15 , $FF8 , $F42 , $CC6 , $F2C , $15DC , $1AB8 , $ED2 , $1458 , $8D , $FF58 , $75 , $144C , $15BC , $61 , $3654
' 3740
  word $7785 , $726F , $7364 , $1C9C , $365C , $61 , $3740 , $7085 , $6E69 , $6E69 , $2548 , $3628 , $D0C , $33 , $DD6 , $D0C
' 3760
  word $42 , $61 , $374E , $7086 , $6E69 , $756F , $D74 , $2548 , $D0C , $33 , $F4E , $D0C , $42 , $61 , $3766 , $7085
' 3780
  word $6E69 , $6F6C , $2548 , $72 , $61 , $377E , $7085 , $6E69 , $6968 , $2548 , $71 , $61 , $378C , $7082 , $D78 , $FF8
' 37A0
  word $8D , $8 , $3792 , $46 , $4 , $3784 , $61 , $379A , $5F85 , $6473 , $6961 , $5D , $1D , $3754 , $61 , $37B0
' 37C0
  word $5F85 , $6473 , $6F61 , $5D , $1D , $376E , $61 , $37C0 , $5F85 , $6373 , $696C , $5D , $1C , $3754 , $61 , $37D0
' 37E0
  word $5F85 , $6373 , $6F6C , $5D , $1C , $376E , $61 , $37E0 , $5F85 , $6473 , $6C61 , $57 , $0 , $2000 , $72 , $61
' 3800
  word $37F0 , $5F85 , $6473 , $6861 , $57 , $D66 , $0 , $2000 , $71 , $61 , $3802 , $5F85 , $6373 , $6C6C , $57 , $4323
' 3820
  word $0 , $1000 , $72 , $61 , $3816 , $5F85 , $6373 , $686C , $57 , $6E0D , $0 , $1000 , $71 , $61 , $382A , $5F85
' 3840
  word $6473 , $3F61 , $57 , $3A0D , $0 , $2000 , $6E , $61 , $383E , $5F88 , $6565 , $7473 , $7261 , $6474 , $3830 , $37E6
' 3860
  word $3808 , $37C6 , $37F6 , $381C , $61 , $3852 , $5F87 , $6565 , $7473 , $706F , $3830 , $3808 , $381C , $37D6 , $37B6 , $61
' 3880
  word $386C , $3185 , $6F6C , $6B63 , $CCE , $1DF4 , $61 , $3882 , $3187 , $6E75 , $6F6C , $6B63 , $CCE , $1E88 , $61 , $3890
' 38A0
  word $658B , $7765 , $6972 , $6574 , $6170 , $6567 , $3888 , $CCE , $F2C , $F80 , $ED2 , $5D , $FF , $DD6 , $FF8 , $ED2
' 38C0
  word $5D , $8 , $FAE , $5D , $FF , $DD6 , $FF8 , $5D , $10 , $FAE , $5D , $7 , $DD6 , $CCE , $F16 , $385C
' 38E0
  word $5D , $A0 , $F4E , $2D70 , $FF8 , $2D70 , $F4E , $FF8 , $2D70 , $F4E , $1500 , $15FE , $79 , $1A5C , $DFC , $2D70
' 3900
  word $F4E , $80 , $FFF6 , $3874 , $5D , $A , $250A , $3898 , $61 , $38A0 , $4583 , $2157 , $FF8 , $1284 , $E46 , $1284
' 3920
  word $CD6 , $38AC , $8D , $8 , $5D , $A , $1124 , $61 , $3914 , $7389 , $7661 , $6665 , $726F , $6874 , $2644 , $7708
' 3940
  word $616C , $7473 , $666E , $2D61 , $1CB6 , $8D , $6C , $B02 , $E08 , $ED2 , $DFC , $F74 , $ED2 , $DFC , $149C , $FF8
' 3960
  word $E3A , $1B52 , $A60 , $E08 , $FF8 , $ED2 , $E08 , $F68 , $3918 , $14B8 , $ED2 , $5D , $3F , $DD6 , $1458 , $8D
' 3980
  word $FFEA , $79 , $364C , $1A5C , $F42 , $5D , $40 , $F38 , $ED2 , $1A5C , $ED2 , $F80 , $38AC , $8D , $8 , $5D
' 39A0
  word $A , $1124 , $13DE , $8D , $8 , $5D , $2E , $2C50 , $82 , $FFD2 , $46 , $4 , $26 , $13DE , $8D , $4
' 39C0
  word $15BC , $61 , $3932 , $7383 , $3F74 , $1A48 , $5304 , $3A54 , $3020 , $347C , $33 , $14B8 , $ED2 , $344C , $F20 , $8D
' 39E0
  word $40 , $344C , $FF8 , $F42 , $CC6 , $79 , $344C , $14C6 , $1A5C , $F42 , $33 , $ED2 , $1480 , $8D , $18 , $1322
' 3A00
  word $E08 , $5D , $A , $EDE , $8D , $A , $5D , $2D , $2C50 , $1014 , $35EE , $15CC , $80 , $FFD2 , $46 , $4
' 3A20
  word $26 , $15BC , $61 , $39C6 , $7382 , $5B63 , $344C , $347C , $33 , $F42 , $5D , $3 , $F42 , $13DE , $8D , $18
' 3A40
  word $ED2 , $1DB0 , $1A48 , $690D , $6574 , $736D , $6320 , $656C , $7261 , $6465 , $15BC , $ED2 , $148E , $8D , $10 , $CC6
' 3A60
  word $79 , $26 , $80 , $FFFC , $46 , $4 , $26 , $61 , $3A28 , $5F84 , $6E70 , $4661 , $ED2 , $35D4 , $5D , $3A
' 3A80
  word $2C50 , $E08 , $ED2 , $35D4 , $15CC , $1B52 , $1A1C , $15CC , $61 , $3A72 , $7084 , $6166 , $613F , $ED2 , $1B52 , $ED2
' 3AA0
  word $DFC , $ED2 , $5D , $80 , $DD6 , $1458 , $FF8 , $125E , $DD6 , $1472 , $F80 , $1AA4 , $F80 , $8D , $4 , $E08
' 3AC0
  word $F80 , $EDE , $DD6 , $61 , $3A94 , $7283 , $3F73 , $1A48 , $5204 , $3A53 , $7020 , $343C , $346C , $33 , $149C , $F42
' 3AE0
  word $CC6 , $79 , $343C , $14AA , $1A5C , $F42 , $33 , $ED2 , $14C6 , $E08 , $3A9A , $8D , $A , $14C6 , $3A78 , $46
' 3B00
  word $6 , $35EE , $15CC , $80 , $FFDC , $15BC , $61 , $3ACA , $6C85 , $636F , $3F6B , $5D , $8 , $CC6 , $79 , $1DE2
' 3B20
  word $1A5C , $F74 , $DFC , $ED2 , $5D , $4 , $FAE , $FF8 , $5D , $F , $DD6 , $1A48 , $4C06 , $636F , $3A6B , $6820
' 3B40
  word $1A5C , $1DB0 , $1430 , $5D , $8 , $F20 , $FF8 , $148E , $DD6 , $8D , $2E , $1A48 , $200F , $4C20 , $636F , $696B
' 3B60
  word $676E , $6320 , $676F , $203A , $1DB0 , $1A48 , $200E , $4C20 , $636F , $206B , $6F63 , $6E75 , $3A74 , $6320 , $1DB0 , $46
' 3B80
  word $4 , $143E , $15BC , $80 , $FF96 , $61 , $3B10 , $7688 , $7261 , $6169 , $6C62 , $6165 , $2812 , $1FD6 , $33EE , $2022
' 3BA0
  word $CC6 , $2070 , $20A2 , $2824 , $61 , $3B8E , $6388 , $6E6F , $7473 , $6E61 , $D74 , $2812 , $1FD6 , $342C , $2022 , $2070
' 3BC0
  word $20A2 , $2824 , $61 , $3BAC , $6183 , $7362 , $1C , $151 , $61 , $3BC8 , $6185 , $646E , $2143 , $ED2 , $DFC , $F80
' 3BE0
  word $DD6 , $FF8 , $E3A , $61 , $3BD4 , $7283 , $7665 , $16 , $79 , $61 , $3BEA , $7284 , $7665 , $6562 , $5D , $18
' 3C00
  word $3BEE , $61 , $3BF6 , $7083 , $3F78 , $2548 , $6E , $61 , $3C06 , $7787 , $6961 , $6374 , $746E , $16 , $1F1 , $61
' 3C20
  word $3C12 , $7787 , $6961 , $7074 , $7165 , $21 , $1E0 , $61 , $3C22 , $7787 , $6961 , $7074 , $656E , $21 , $1E8 , $61
' 3C40
  word $3C32 , $6A81 , $346C , $33 , $5D , $5 , $F74 , $33 , $61 , $3C42 , $7586 , $2F2A , $6F6D , $7564 , $1500 , $2850
' 3C60
  word $F80 , $289E , $61 , $3C54 , $7583 , $2F2A , $1500 , $2850 , $F80 , $289E , $1522 , $61 , $3C68 , $7384 , $6769 , $6E6E
' 3C80
  word $F5A , $57 , $0 , $8000 , $DD6 , $61 , $3C7A , $2A81 , $2850 , $26 , $61 , $3C8E , $2A85 , $6D2F , $646F , $1430
' 3CA0
  word $3C80 , $7C , $3BCC , $F80 , $ED2 , $75 , $3C80 , $7C , $3BCC , $F80 , $3BCC , $2850 , $F80 , $289E , $75 , $8D
' 3CC0
  word $A , $1014 , $FF8 , $1014 , $FF8 , $61 , $3C98 , $2A82 , $652F , $3C9E , $1522 , $61 , $3CCE , $2F84 , $6F6D , $7064
' 3CE0
  word $1430 , $3C80 , $7C , $3BCC , $FF8 , $3BCC , $FF8 , $2E1E , $75 , $8D , $A , $1014 , $FF8 , $1014 , $FF8 , $61
' 3D00
  word $3CDA , $2F81 , $3CE0 , $1522 , $61 , $3D02 , $2888 , $6F66 , $6772 , $7465 , $6829 , $ED2 , $8D , $30 , $1CB6 , $8D
' 3D20
  word $16 , $1B52 , $1A96 , $ED2 , $A60 , $E46 , $E08 , $A54 , $E46 , $46 , $12 , $13DE , $8D , $C , $1A3C , $5D
' 3D40
  word $3F , $2C50 , $15BC , $46 , $4 , $26 , $61 , $3D0C , $6686 , $726F , $6567 , $2074 , $1C9C , $3D16 , $61 , $3D50
' 3D60
  word $658A , $7265 , $6165 , $7064 , $6761 , $D65 , $3888 , $CCE , $F2C , $F80 , $ED2 , $5D , $FF , $DD6 , $FF8 , $ED2
' 3D80
  word $5D , $8 , $FAE , $5D , $FF , $DD6 , $FF8 , $5D , $10 , $FAE , $5D , $7 , $DD6 , $CCE , $F16 , $ED2
' 3DA0
  word $7C , $385C , $5D , $A0 , $F4E , $2D70 , $FF8 , $2D70 , $F4E , $FF8 , $2D70 , $F4E , $385C , $75 , $5D , $A1
' 3DC0
  word $F4E , $2D70 , $F4E , $1500 , $15FE , $79 , $348A , $2CE2 , $1A5C , $E3A , $80 , $FFF6 , $3874 , $3898 , $61 , $3D60
' 3DE0
  word $4583 , $4057 , $1284 , $CD6 , $3D6C , $8D , $8 , $5D , $B , $1124 , $1284 , $E08 , $61 , $3DE0 , $4583 , $4043
' 3E00
  word $3DE4 , $5D , $FF , $DD6 , $61 , $3DFC , $2887 , $7564 , $706D , $2962 , $15BC , $F68 , $35D4 , $15CC , $ED2 , $35D4
' 3E20
  word $22FE , $15FE , $61 , $3E0C , $2887 , $7564 , $706D , $296D , $15BC , $35D4 , $22FE , $61 , $3E28 , $2887 , $7564 , $706D
' 3E40
  word $2965 , $12A2 , $5D , $10 , $15FE , $79 , $1A5C , $DFC , $35AE , $15CC , $80 , $FFF6 , $5D , $2 , $15DC , $12A2
' 3E60
  word $5D , $10 , $15FE , $79 , $1A5C , $DFC , $ED2 , $CB0 , $5D , $7E , $15A8 , $3628 , $8D , $8 , $26 , $5D
' 3E80
  word $2E , $2C50 , $80 , $FFE2 , $61 , $3E3A , $6484 , $6D75 , $6170 , $3E14 , $79 , $1A5C , $3E30 , $1A5C , $12A2 , $5D
' 3EA0
  word $10 , $18F4 , $3E42 , $5D , $10 , $82 , $FFEA , $15BC , $61 , $3E8C , $6585 , $7564 , $706D , $3E14 , $79 , $1A5C
' 3EC0
  word $3E30 , $1A5C , $12A2 , $5D , $10 , $3D6C , $8D , $C , $12A2 , $5D , $10 , $CC6 , $1A78 , $3E42 , $5D , $10
' 3EE0
  word $82 , $FFDC , $15BC , $61 , $3EB4 , $6387 , $676F , $7564 , $706D , $15BC , $F68 , $35D4 , $15CC , $ED2 , $35D4 , $22FE
' 3F00
  word $15FE , $79 , $15BC , $1A5C , $35D4 , $22FE , $1A5C , $5D , $4 , $15FE , $79 , $1A5C , $33 , $35EE , $15CC , $80
' 3F20
  word $FFF6 , $5D , $4 , $82 , $FFDC , $15BC , $61 , $3EEA , $2E86 , $6F63 , $6367 , $6E68 , $ED2 , $CBA , $EDE , $8D
' 3F40
  word $10 , $143E , $1A48 , $5804 , $5828 , $7729 , $46 , $1A , $1D0C , $5D , $29 , $34A0 , $1D72 , $5D , $28 , $34A0
' 3F60
  word $26 , $1D72 , $1D1A , $1A3C , $61 , $3F30 , $698A , $3E6F , $6F63 , $6367 , $6168 , $686E , $ED2 , $B7C , $ED2 , $B1E
' 3F80
  word $5D , $3 , $F16 , $F74 , $15A8 , $8D , $22 , $B7C , $F42 , $B1E , $2E1E , $5D , $7 , $DD6 , $ED2 , $13F6
' 3FA0
  word $F80 , $5D , $4 , $2E2C , $F38 , $46 , $8 , $26 , $CBA , $ED2 , $61 , $3F6C , $6384 , $676F , $733F , $5D
' 3FC0
  word $8 , $CC6 , $79 , $1A48 , $4304 , $676F , $773A , $1A5C , $ED2 , $1DB0 , $1A48 , $200A , $6923 , $206F , $6863 , $6E61
' 3FE0
  word $6F3A , $ED2 , $13F6 , $1DB0 , $1310 , $E08 , $B02 , $E08 , $DFC , $F68 , $DFC , $F42 , $15DC , $1A3C , $1A5C , $10E4
' 4000
  word $1A5C , $13F6 , $CC6 , $79 , $1A5C , $14E2 , $F68 , $F74 , $14B8 , $E08 , $ED2 , $1458 , $8D , $8 , $26 , $46
' 4020
  word $16 , $15CC , $15CC , $3C44 , $1A5C , $3F38 , $1A48 , $2D02 , $6B3E , $3F78 , $3F38 , $80 , $FFD0 , $26 , $15BC , $80
' 4040
  word $FF86 , $61 , $3FB8 , $6286 , $6975 , $646C , $203F , $15BC , $2644 , $6206 , $6975 , $646C , $655F , $365C , $15BC , $B02
' 4060
  word $E08 , $1A3C , $15BC , $61 , $4046 , $6684 , $6572 , $7465 , $A6E , $E08 , $A60 , $E08 , $F42 , $1DB0 , $1A48 , $620D
' 4080
  word $7479 , $7365 , $6620 , $6572 , $2065 , $202D , $CE0 , $137A , $E08 , $F42 , $1DB0 , $1A48 , $630E , $676F , $6C20 , $6E6F
' 40A0
  word $7367 , $6620 , $6572 , $D65 , $15BC , $61 , $406A , $7283 , $646E , $CEA , $33 , $5D , $8 , $FAE , $CEA , $33
' 40C0
  word $F5A , $5D , $FF , $DD6 , $61 , $40AE , $7285 , $646E , $6674 , $40B2 , $5D , $7F , $EF2 , $61 , $40CC , $2E88
' 40E0
  word $6F63 , $776E , $6961 , $6574 , $B5A , $10E4 , $5D , $200 , $CC6 , $79 , $ED2 , $E08 , $5D , $100 , $DD6 , $8D
' 4100
  word $4 , $20D6 , $80 , $FFEE , $26 , $61 , $40DE , $2E88 , $6F63 , $656E , $696D , $6974 , $40E8 , $B5A , $10E4 , $E46
' 4120
  word $61 , $410E , $2E88 , $6F63 , $636E , $7473 , $2072 , $1638 , $ED2 , $8D , $14 , $15FE , $79 , $1A5C , $DFC , $4118
' 4140
  word $80 , $FFF8 , $46 , $4 , $143E , $61 , $4124 , $2E84 , $6F63 , $206E , $1D0C , $1D8E , $1D1A , $412E , $CB0 , $4118
' 4160
  word $61 , $414E , $2E86 , $6F63 , $636E , $6F72 , $5D , $D , $4118 , $61 , $4164 , $2E88 , $6F63 , $626E , $7479 , $D65
' 4180
  word $359E , $412E , $61 , $4176 , $2E88 , $6F63 , $776E , $726F , $5D64 , $35C0 , $412E , $61 , $4188 , $2E88 , $6F63 , $6C6E
' 41A0
  word $6E6F , $2067 , $35E0 , $412E , $61 , $419A , $2E87 , $6F63 , $736E , $3F74 , $2644 , $5304 , $3A54 , $5F20 , $412E , $347C
' 41C0
  word $33 , $14B8 , $ED2 , $344C , $F20 , $8D , $42 , $344C , $FF8 , $F42 , $CC6 , $79 , $344C , $14C6 , $1A5C , $F42
' 41E0
  word $33 , $ED2 , $1480 , $8D , $18 , $1322 , $E08 , $5D , $A , $EDE , $8D , $A , $5D , $2D , $4118 , $1014
' 4200
  word $41A4 , $CB0 , $4118 , $80 , $FFD0 , $46 , $4 , $26 , $416C , $61 , $41AC , $6F87 , $726E , $7365 , $7465 , $ED2
' 4220
  word $27F0 , $13DE , $FF8 , $ED2 , $1458 , $8D , $C , $2644 , $2003 , $6B6F , $46 , $1BA , $ED2 , $CCE , $EDE , $8D
' 4240
  word $1E , $2644 , $2014 , $414D , $4E49 , $5320 , $4154 , $4B43 , $4F20 , $4556 , $4652 , $4F4C , $3A57 , $46 , $194 , $ED2
' 4260
  word $5D , $2 , $EDE , $8D , $20 , $2644 , $2016 , $4552 , $5554 , $4E52 , $5320 , $4154 , $4B43 , $4F20 , $4556 , $4652
' 4280
  word $4F4C , $7557 , $46 , $16A , $ED2 , $5D , $3 , $EDE , $8D , $1E , $2644 , $2015 , $414D , $4E49 , $5320 , $4154
' 42A0
  word $4B43 , $5520 , $444E , $5245 , $4C46 , $574F , $46 , $142 , $ED2 , $5D , $4 , $EDE , $8D , $20 , $2644 , $2017
' 42C0
  word $4552 , $5554 , $4E52 , $5320 , $4154 , $4B43 , $5520 , $444E , $5245 , $4C46 , $574F , $46 , $118 , $ED2 , $5D , $5
' 42E0
  word $EDE , $8D , $1A , $2644 , $2011 , $554F , $2054 , $464F , $4620 , $4552 , $2045 , $4F43 , $5347 , $46 , $F4 , $ED2
' 4300
  word $5D , $6 , $EDE , $8D , $1E , $2644 , $2014 , $4F4C , $4B43 , $4320 , $554F , $544E , $4F20 , $4556 , $4652 , $4F4C
' 4320
  word $7057 , $46 , $CC , $ED2 , $5D , $7 , $EDE , $8D , $16 , $2644 , $200D , $4F4C , $4B43 , $5420 , $4D49 , $4F45
' 4340
  word $5455 , $46 , $AC , $ED2 , $5D , $8 , $EDE , $8D , $16 , $2644 , $200D , $4E55 , $4F4C , $4B43 , $4520 , $5252
' 4360
  word $524F , $46 , $8C , $ED2 , $5D , $9 , $EDE , $8D , $22 , $2644 , $2018 , $554F , $2054 , $464F , $4620 , $4552
' 4380
  word $2045 , $414D , $4E49 , $4D20 , $4D45 , $524F , $D59 , $46 , $60 , $ED2 , $5D , $A , $EDE , $8D , $1C , $2644
' 43A0
  word $2013 , $4545 , $5250 , $4D4F , $5720 , $4952 , $4554 , $4520 , $5252 , $524F , $46 , $3A , $ED2 , $5D , $B , $EDE
' 43C0
  word $8D , $1C , $2644 , $2012 , $4545 , $5250 , $4D4F , $5220 , $4145 , $2044 , $5245 , $4F52 , $2052 , $46 , $14 , $2644
' 43E0
  word $200F , $4E55 , $4E4B , $574F , $204E , $5245 , $4F52 , $2052 , $F80 , $8D , $88 , $13DE , $8D , $7C , $AF4 , $E08
' 4400
  word $1228 , $1934 , $AA2 , $E08 , $1D0C , $1D8E , $1D1A , $1228 , $1948 , $2644 , $2004 , $6F43 , $6C67 , $1228 , $1948 , $1DCC
' 4420
  word $1228 , $1978 , $2644 , $2016 , $4552 , $4553 , $2054 , $202D , $616C , $7473 , $7320 , $6174 , $7574 , $3A73 , $2020 , $1228
' 4440
  word $1948 , $FF8 , $1D0C , $1D8E , $1D1A , $1228 , $1948 , $1228 , $1948 , $1F32 , $416C , $2644 , $4304 , $4E4F , $203A , $412E
' 4460
  word $1228 , $412E , $416C , $15BC , $1228 , $1A3C , $15BC , $1F42 , $29F4 , $46 , $4 , $143E , $46 , $4 , $143E , $61

  word 0
' 4480
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 44C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4500
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4540
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4580
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 45C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4600
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4640
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4680
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 46C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4700
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4740
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4780
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 47C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4800
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4840
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4880
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 48C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4900
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4940
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4980
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 49C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4A00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4A40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4A80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4AC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4B00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4B40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4B80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4BC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4C00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4C40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4C80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4CC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4D00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4D40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4D80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4DC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4E00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4E40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4E80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4EC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4F00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4F40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4F80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 4FC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5000
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5040
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5080
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 50C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5100
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5140
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5180
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 51C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5200
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5240
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5280
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 52C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5300
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5340
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5380
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 53C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5400
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5440
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5480
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 54C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5500
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5540
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5580
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 55C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5600
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5640
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5680
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 56C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5700
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5740
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5780
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 57C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5800
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5840
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5880
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 58C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5900
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5940
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5980
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 59C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5A00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5A40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5A80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5AC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5B00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5B40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5B80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5BC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5C00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5C40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5C80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5CC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5D00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5D40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5D80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5DC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5E00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5E40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5E80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5EC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5F00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5F40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5F80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 5FC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6000
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6040
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6080
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 60C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6100
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6140
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6180
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 61C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6200
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6240
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6280
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 62C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6300
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6340
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6380
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 63C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6400
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6440
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6480
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 64C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6500
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6540
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6580
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 65C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6600
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6640
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6680
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 66C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6700
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6740
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6780
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 67C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6800
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6840
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6880
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 68C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6900
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6940
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6980
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 69C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6A00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6A40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6A80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6AC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6B00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6B40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6B80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6BC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6C00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6C40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6C80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6CC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6D00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6D40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6D80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6DC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6E00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6E40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6E80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6EC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6F00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6F40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6F80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 6FC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7000
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7040
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7080
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 70C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7100
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7140
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7180
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 71C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7200
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7240
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7280
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 72C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7300
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7340
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7380
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 73C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7400
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7440
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7480
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 74C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7500
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7540
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7580
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 75C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7600
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7640
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7680
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 76C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7700
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7740
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7780
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 77C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7800
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7840
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7880
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 78C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7900
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7940
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7980
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 79C0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7A00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7A40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7A80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7AC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7B00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7B40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7B80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7BC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7C00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7C40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7C80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7CC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7D00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7D40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7D80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7DC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7E00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7E40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7E80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7EC0
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7F00
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7F40
  word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
' 7F80
  word 0, 0, 0, 0, 0, 0, 0, 0, 0
