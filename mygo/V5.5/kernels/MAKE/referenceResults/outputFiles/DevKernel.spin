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

CON
_clkmode= xtal1+pll16x
_xinfreq= 5_000_000
dlrS_cdsz= 224
dlrS_txpin= 30
dlrS_rxpin= 31
dlrS_baud= 57_600
dlrS_con= 7
startcog= 6
dlrS_sd_cs= 19
dlrS_sd_di= 20
dlrS_sd_clk= 21
dlrS_sd_do= 16
dlrS_ip_light= $FFFF
dlrS_ip_cog= 5
dlrS_ip_sockbufsize= $800
dlrS_ip_sockbufmask= $7FF
dlrS_ip_sockbufinit= $55
dlrS_ip_numsock= 4
dlrS_ip_numTelnet= 4
dlrS_ip_telnetport= 3020
dlrS_ip_httpport= 8080
dlrS_ip_gatewayhi= $C0_A8
dlrS_ip_gatewaylo= $00_01
dlrS_ip_subnetmaskhi= $FF_FF
dlrS_ip_subnetmasklo= $FF_00
dlrS_ip_addrhi= $C0_A8
dlrS_ip_addrlo= $00_81
dlrS_ip_machi= $00_0C
dlrS_ip_macmid= $29_8B
dlrS_ip_maclo= $00_70
  
  
VAR


OBJ

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
  word $0 , $7788 , $616C , $7473 , $666E , $61 , $4F , $4252 , $A4A , $6884 , $7265 , $65 
' A60 
  word $4F , $44BC , $A5A , $6487 , $6369 , $6574 , $646E , $4F , $7F94 , $A66 , $6D86 , $6D65 , $6E65 , $64 , $4F , $7F94 
' A80 
  word $A74 , $6290 , $6975 , $646C , $425F , $6F6F , $4B74 , $7265 , $656E , $6C , $4A , $1 , $A82 , $7086 , $6F72 , $6970 
' AA0 
  word $64 , $4F , $0 , $A9A , $2886 , $7270 , $706F , $29 , $2666 , $5004 , $6F72 , $70 , $61 , $AA8 , $2889 , $6576 
' AC0 
  word $7372 , $6F69 , $296E , $2666 , $5020 , $6F72 , $4670 , $726F , $6874 , $7620 , $2E35 , $2035 , $3032 , $3331 , $6546 , $3262 
' AE0 
  word $2030 , $3131 , $333A , $2030 , $30 , $61 , $ABC , $7084 , $6F72 , $70 , $4F , $AB2 , $AEE , $7687 , $7265 , $6973 
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
  word $B70 , $2485 , $5F48 , $7163 , $4A , $2666 , $B82 , $2485 , $5F48 , $7164 , $4A , $1A4C , $B8E , $2489 , $5F43 , $5F61 
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
  word $4A , $1F4 , $CFA , $6484 , $7269 , $61 , $4A , $1F6 , $D06 , $5FC5 , $6E63 , $7069 , $A60 , $DFA , $14CA , $EC4 
' D20 
  word $DFA , $F5A , $14CA , $E38 , $A60 , $E38 , $61 , $D12 , $5F0E , $6178 , $6D73 , $3E32 , $6C66 , $6761 , $4D49 , $4D 
' D40 
  word $1 , $D30 , $5F0B , $6178 , $6D73 , $3E32 , $6C66 , $6761 , $4 , $D44 , $5F0B , $6178 , $6D73 , $3E32 , $4931 , $4D4D 
' D60 
  word $13 , $D54 , $5F08 , $6178 , $6D73 , $3E32 , $31 , $16 , $D64 , $5F08 , $6178 , $6D73 , $3E31 , $31 , $1C , $D72 
' D80 
  word $5F08 , $6178 , $6D73 , $3E32 , $30 , $21 , $D80 , $6C05 , $6178 , $6D73 , $B2 , $D8E , $5F07 , $616D , $6B73 , $6E69 
' DA0 
  word $6E , $D98 , $5F0A , $616D , $6B73 , $756F , $6C74 , $6F , $72 , $DA4 , $5F0A , $616D , $6B73 , $756F , $6874 , $69 
' DC0 
  word $71 , $DB4 , $6183 , $646E , $16 , $C7 , $61 , $DC4 , $6184 , $646E , $6E , $16 , $CF , $61 , $DD0 , $4C82 
' DE0 
  word $40 , $1C , $17 , $61 , $DDE , $4382 , $40 , $1C , $7 , $61 , $DEA , $5782 , $40 , $1C , $9 , $61 
' E00 
  word $DF6 , $5203 , $4053 , $28 , $E02 , $5303 , $4054 , $2E , $E0A , $4304 , $474F , $40 , $33 , $E12 , $4C82 , $21 
' E20 
  word $21 , $10 , $61 , $E1C , $4382 , $21 , $21 , $0 , $61 , $E28 , $5782 , $21 , $21 , $8 , $61 , $E34 
' E40 
  word $5203 , $2153 , $37 , $E40 , $5303 , $2154 , $3D , $E48 , $4304 , $474F , $21 , $42 , $E50 , $6206 , $6172 , $636E 
' E60 
  word $68 , $46 , $E5A , $6886 , $6275 , $706F , $72 , $16 , $1F , $61 , $E66 , $6886 , $6275 , $706F , $66 , $4 
' E80 
  word $C01F , $61 , $E76 , $6406 , $636F , $6E6F , $77 , $4A , $E86 , $6406 , $636F , $6E6F , $6C , $52 , $E92 , $6406 
' EA0 
  word $766F , $7261 , $77 , $4F , $E9E , $6406 , $766F , $7261 , $6C , $4D , $EAA , $6404 , $6F72 , $70 , $26 , $EB6 
' EC0 
  word $6483 , $7075 , $5D , $0 , $2E , $61 , $EC0 , $3D81 , $4 , $A186 , $61 , $ECE , $6504 , $6978 , $74 , $61 
' EE0 
  word $ED8 , $3E81 , $4 , $1186 , $61 , $EE2 , $6C04 , $7469 , $77 , $5D , $EEC , $6C04 , $7469 , $6C , $57 , $EF6 
' F00 
  word $6C86 , $6873 , $6669 , $74 , $16 , $5F , $61 , $F00 , $3C81 , $4 , $C186 , $61 , $F10 , $6D83 , $7861 , $16 
' F20 
  word $87 , $61 , $F1A , $6D83 , $6E69 , $16 , $8F , $61 , $F26 , $2D81 , $16 , $10F , $61 , $F32 , $6F82 , $72 
' F40 
  word $16 , $D7 , $61 , $F3C , $7883 , $726F , $16 , $DF , $61 , $F48 , $6F84 , $6576 , $72 , $5D , $1 , $2E 
' F60 
  word $61 , $F54 , $2B81 , $16 , $107 , $61 , $F64 , $7283 , $746F , $5D , $2 , $2E , $5D , $2 , $2E , $5D 
' F80 
  word $2 , $2E , $5D , $3 , $3D , $5D , $3 , $3D , $CC6 , $3D , $61 , $F6E , $7286 , $6873 , $6669 , $74 
' FA0 
  word $16 , $57 , $61 , $F98 , $7202 , $3E , $75 , $FA8 , $3E02 , $72 , $7C , $FB0 , $3203 , $723E , $79 , $FB8 
' FC0 
  word $3007 , $7262 , $6E61 , $6863 , $8D , $FC0 , $2806 , $6F6C , $706F , $29 , $80 , $FCC , $2807 , $6C2B , $6F6F , $2970 
' FE0 
  word $82 , $FD8 , $7384 , $6177 , $70 , $CCE , $2E , $CCE , $2E , $CD6 , $3D , $CC6 , $3D , $61 , $FE4 , $6E86 
' 1000 
  word $6765 , $7461 , $65 , $1C , $14F , $61 , $FFE , $7286 , $6265 , $6F6F , $74 , $5D , $FF , $CC6 , $E6E , $61 
' 1020 
  word $100E , $6387 , $676F , $7473 , $706F , $EC4 , $5D , $3 , $E6E , $26 , $10D6 , $14D8 , $B1E , $14CA , $14CA , $CC6 
' 1040 
  word $1A7C , $61 , $1022 , $6388 , $676F , $6572 , $6573 , $74 , $5D , $7 , $DC8 , $EC4 , $1DD0 , $146A , $8D , $6 
' 1060 
  word $EC4 , $102A , $EC4 , $EC4 , $10D6 , $5D , $10 , $F08 , $B6A , $CD6 , $F08 , $F40 , $F40 , $CD6 , $E6E , $26 
' 1080 
  word $13D2 , $5D , $8000 , $CC6 , $79 , $EC4 , $DEE , $5D , $4 , $DC8 , $8D , $4 , $20DA , $80 , $FFEE , $26 
' 10A0 
  word $61 , $1046 , $7285 , $7365 , $7465 , $1DD0 , $1050 , $61 , $10A4 , $6387 , $6B6C , $7266 , $7165 , $CC6 , $DE2 , $61 
' 10C0 
  word $10B2 , $5F83 , $2B70 , $CE0 , $33 , $F66 , $61 , $10C2 , $6385 , $676F , $6F69 , $5D , $7 , $DC8 , $B1E , $3290 
' 10E0 
  word $B7C , $F66 , $61 , $10D0 , $6389 , $676F , $6F69 , $6863 , $6E61 , $F5A , $13FA , $14AE , $F2A , $14E6 , $FEA , $10D6 
' 1100 
  word $F66 , $61 , $10E8 , $6982 , $6F , $CE0 , $33 , $61 , $1106 , $4583 , $5252 , $20F0 , $13AE , $E2C , $10AA , $61 
' 1120 
  word $1112 , $2887 , $6F69 , $6964 , $2973 , $10F2 , $14BC , $EC4 , $DFA , $FEA , $CC6 , $FEA , $E38 , $EC4 , $8D , $E 
' 1140 
  word $CC6 , $FEA , $14BC , $E38 , $46 , $4 , $26 , $61 , $1122 , $6985 , $646F , $7369 , $CC6 , $112A , $61 , $1152 
' 1160 
  word $2888 , $6F69 , $6F63 , $6E6E , $29 , $1434 , $112A , $7C , $7C , $1434 , $112A , $75 , $75 , $10F2 , $1504 , $10F2 
' 1180 
  word $1434 , $14BC , $E38 , $FEA , $14BC , $E38 , $61 , $1160 , $6986 , $636F , $6E6F , $6E , $CC6 , $1534 , $116A , $61 
' 11A0 
  word $1190 , $2888 , $6F69 , $696C , $6B6E , $29 , $10F2 , $1504 , $10F2 , $FEA , $F5A , $14BC , $DFA , $F5A , $14BC , $E38 
' 11C0 
  word $FEA , $14BC , $E38 , $61 , $11A2 , $6986 , $6C6F , $6E69 , $6B , $CC6 , $1534 , $11AC , $61 , $11CA , $288A , $6F69 
' 11E0 
  word $6E75 , $696C , $6B6E , $29 , $10F2 , $14BC , $EC4 , $DFA , $14BC , $EC4 , $DFA , $F72 , $E38 , $CC6 , $FEA , $E38 
' 1200 
  word $61 , $11DC , $6988 , $756F , $6C6E , $6E69 , $6B , $CC6 , $11E8 , $61 , $1204 , $7083 , $6461 , $5D , $4 , $10C6 
' 1220 
  word $61 , $1216 , $6386 , $676F , $6170 , $64 , $10D6 , $14D8 , $61 , $1224 , $7086 , $6461 , $693E , $6E , $139C , $DFA 
' 1240 
  word $121A , $F66 , $61 , $1234 , $6E87 , $6D61 , $6D65 , $7861 , $4A , $1F , $1248 , $7087 , $6461 , $6973 , $657A , $4A 
' 1260 
  word $80 , $1256 , $5F83 , $636C , $5D , $83 , $10C6 , $61 , $1264 , $7482 , $30 , $5D , $84 , $10C6 , $61 , $1272 
' 1280 
  word $7482 , $31 , $5D , $86 , $10C6 , $61 , $1280 , $7484 , $7562 , $66 , $5D , $88 , $10C6 , $61 , $128E , $6E86 
' 12A0 
  word $6D75 , $6170 , $64 , $5D , $A8 , $10C6 , $61 , $129E , $6389 , $676F , $756E , $706D , $6461 , $10D6 , $5D , $A8 
' 12C0 
  word $F66 , $61 , $12B0 , $7087 , $6461 , $6F3E , $7475 , $138E , $DFA , $12A6 , $F66 , $61 , $12C6 , $6E8A , $6D75 , $6170 
' 12E0 
  word $7364 , $7A69 , $65 , $4A , $22 , $12DA , $6E87 , $6D75 , $6863 , $6E61 , $5D , $CA , $10C6 , $61 , $12EC , $6383 
' 1300 
  word $7364 , $5D , $D0 , $10C6 , $61 , $12FE , $6386 , $676F , $6463 , $73 , $10D6 , $5D , $D0 , $F66 , $61 , $130C 
' 1320 
  word $6284 , $7361 , $65 , $5D , $D2 , $10C6 , $61 , $1320 , $6588 , $6578 , $7763 , $726F , $64 , $5D , $D4 , $10C6 
' 1340 
  word $61 , $1330 , $6587 , $6578 , $7563 , $6574 , $EC4 , $C76 , $33 , $DC8 , $8D , $A , $C96 , $42 , $46 , $14 
' 1360 
  word $133A , $E38 , $BA4 , $133A , $14BC , $E38 , $133A , $C96 , $42 , $61 , $1344 , $6387 , $676F , $6568 , $6572 , $5D 
' 1380 
  word $D8 , $10C6 , $61 , $1376 , $3E84 , $756F , $74 , $5D , $DA , $10C6 , $61 , $1388 , $3E83 , $6E69 , $5D , $DC 
' 13A0 
  word $10C6 , $61 , $1398 , $6C87 , $7361 , $6574 , $7272 , $5D , $DE , $10C6 , $61 , $13A6 , $7385 , $6174 , $6574 , $5D 
' 13C0 
  word $DF , $10C6 , $61 , $13B8 , $6388 , $676F , $7473 , $7461 , $65 , $10D6 , $5D , $DF , $F66 , $61 , $13C8 , $5F83 
' 13E0 
  word $3F70 , $CD6 , $13BE , $DEE , $DC8 , $145C , $61 , $13DE , $6388 , $676F , $636E , $6168 , $6E , $10D6 , $5D , $CA 
' 1400 
  word $F66 , $DEE , $14A0 , $61 , $13F0 , $3E84 , $6F63 , $6E , $B5A , $1198 , $61 , $140A , $6388 , $6D6F , $6970 , $656C 
' 1420 
  word $3F , $13BE , $DEE , $CCE , $DC8 , $61 , $1418 , $3284 , $7564 , $70 , $F5A , $F5A , $61 , $142E , $3285 , $7264 
' 1440 
  word $706F , $26 , $26 , $61 , $143C , $3385 , $7264 , $706F , $1442 , $26 , $61 , $144A , $3082 , $3D , $1 , $0 
' 1460 
  word $A186 , $61 , $1458 , $3C82 , $3E , $4 , $5186 , $61 , $1466 , $3083 , $3E3C , $1 , $0 , $5186 , $61 , $1472 
' 1480 
  word $3082 , $3C , $1 , $0 , $C186 , $61 , $1480 , $3082 , $3E , $1 , $0 , $1186 , $61 , $148E , $3182 , $2B 
' 14A0 
  word $13 , $1 , $107 , $61 , $149C , $3182 , $2D , $13 , $1 , $10F , $61 , $14AA , $3282 , $2B , $13 , $2 
' 14C0 
  word $107 , $61 , $14B8 , $3282 , $2D , $13 , $2 , $10F , $61 , $14C6 , $3482 , $2B , $13 , $4 , $107 , $61 
' 14E0 
  word $14D4 , $3482 , $2A , $13 , $2 , $5F , $61 , $14E2 , $3282 , $2F , $13 , $1 , $77 , $61 , $14F0 , $7284 
' 1500 
  word $746F , $32 , $CD6 , $2E , $CD6 , $2E , $CD6 , $2E , $5D , $4 , $3D , $CCE , $3D , $CCE , $3D , $61 
' 1520 
  word $14FE , $6E83 , $7069 , $FEA , $26 , $61 , $1522 , $7484 , $6375 , $6B , $FEA , $F5A , $61 , $152E , $3E82 , $3D 
' 1540 
  word $4 , $3186 , $61 , $153C , $3C82 , $3D , $4 , $E186 , $61 , $1548 , $3083 , $3D3E , $1 , $0 , $3186 , $61 
' 1560 
  word $1554 , $5783 , $212B , $EC4 , $DFA , $F72 , $F66 , $FEA , $E38 , $61 , $1562 , $6F84 , $4372 , $21 , $EC4 , $DEE 
' 1580 
  word $F72 , $F40 , $FEA , $E2C , $61 , $1576 , $6186 , $646E , $436E , $21 , $EC4 , $DEE , $F72 , $DD6 , $FEA , $E2C 
' 15A0 
  word $61 , $158C , $6287 , $7465 , $6577 , $6E65 , $1504 , $F5A , $154C , $1504 , $1540 , $DC8 , $61 , $15A4 , $6382 , $72 
' 15C0 
  word $5D , $D , $2D24 , $61 , $15BC , $7385 , $6170 , $6563 , $CB0 , $2D24 , $61 , $15CA , $7386 , $6170 , $6563 , $73 
' 15E0 
  word $EC4 , $8D , $10 , $CC6 , $79 , $15D0 , $80 , $FFFC , $46 , $4 , $26 , $61 , $15D8 , $6286 , $756F , $646E 
' 1600 
  word $73 , $F5A , $F66 , $FEA , $61 , $15FA , $6186 , $696C , $6E67 , $6C , $5D , $3 , $F66 , $5D , $3 , $DD6 
' 1620 
  word $61 , $160C , $6186 , $696C , $6E67 , $77 , $14A0 , $CCE , $DD6 , $61 , $1624 , $4384 , $2B40 , $2B , $EC4 , $14A0 
' 1640 
  word $FEA , $DEE , $61 , $1636 , $7487 , $646F , $6769 , $7469 , $5D , $30 , $F34 , $EC4 , $5D , $9 , $EE4 , $8D 
' 1660 
  word $18 , $5D , $7 , $F34 , $EC4 , $5D , $A , $F12 , $8D , $6 , $26 , $CBA , $EC4 , $5D , $26 , $EE4 
' 1680 
  word $8D , $18 , $5D , $3 , $F34 , $EC4 , $5D , $27 , $F12 , $8D , $6 , $26 , $CBA , $61 , $1648 , $6987 
' 16A0 
  word $6473 , $6769 , $7469 , $1650 , $CC6 , $1326 , $DFA , $14AE , $15AC , $61 , $169E , $6989 , $7573 , $756E , $626D , $7265 
' 16C0 
  word $1602 , $CBA , $1504 , $79 , $1A60 , $DEE , $5D , $5F , $146A , $8D , $A , $1A60 , $DEE , $16A6 , $DC8 , $80 
' 16E0 
  word $FFE8 , $61 , $16B6 , $7587 , $756E , $626D , $7265 , $1602 , $CC6 , $1504 , $79 , $1A60 , $DEE , $5D , $5F , $146A 
' 1700 
  word $8D , $10 , $1326 , $DFA , $3290 , $1A60 , $DEE , $1650 , $F66 , $80 , $FFE2 , $61 , $16E6 , $6E86 , $6D75 , $6562 
' 1720 
  word $72 , $F5A , $DEE , $5D , $2D , $ED0 , $8D , $16 , $14AE , $CC6 , $F1E , $FEA , $14A0 , $FEA , $16EE , $1006 
' 1740 
  word $46 , $4 , $16EE , $61 , $171A , $5F84 , $6E78 , $75 , $1326 , $DFA , $7C , $1326 , $E38 , $14AE , $CC6 , $F1E 
' 1760 
  word $FEA , $14A0 , $FEA , $1722 , $75 , $1326 , $E38 , $61 , $174A , $7887 , $756E , $626D , $7265 , $F5A , $DEE , $5D 
' 1780 
  word $7A , $ED0 , $8D , $C , $5D , $40 , $1750 , $46 , $4A , $F5A , $DEE , $5D , $68 , $ED0 , $8D , $C 
' 17A0 
  word $5D , $10 , $1750 , $46 , $32 , $F5A , $DEE , $5D , $64 , $ED0 , $8D , $C , $5D , $A , $1750 , $46 
' 17C0 
  word $1A , $F5A , $DEE , $5D , $62 , $ED0 , $8D , $A , $CD6 , $1750 , $46 , $4 , $1722 , $61 , $1772 , $6988 
' 17E0 
  word $6E73 , $6D75 , $6562 , $72 , $F5A , $DEE , $5D , $2D , $ED0 , $8D , $E , $14AE , $CC6 , $F1E , $FEA , $14A0 
' 1800 
  word $FEA , $16C0 , $61 , $17DE , $5F84 , $6978 , $73 , $1326 , $DFA , $7C , $1326 , $E38 , $14AE , $CC6 , $F1E , $FEA 
' 1820 
  word $14A0 , $FEA , $17E8 , $75 , $1326 , $E38 , $61 , $1808 , $7889 , $7369 , $756E , $626D , $7265 , $F5A , $DEE , $5D 
' 1840 
  word $7A , $ED0 , $8D , $C , $5D , $40 , $180E , $46 , $4A , $F5A , $DEE , $5D , $68 , $ED0 , $8D , $C 
' 1860 
  word $5D , $10 , $180E , $46 , $32 , $F5A , $DEE , $5D , $64 , $ED0 , $8D , $C , $5D , $A , $180E , $46 
' 1880 
  word $1A , $F5A , $DEE , $5D , $62 , $ED0 , $8D , $A , $CD6 , $180E , $46 , $4 , $17E8 , $61 , $1830 , $6E84 
' 18A0 
  word $6670 , $78 , $18E8 , $F72 , $18E8 , $F72 , $1434 , $1540 , $8D , $24 , $F2A , $1602 , $79 , $163C , $1A60 , $DEE 
' 18C0 
  word $146A , $8D , $8 , $26 , $CC6 , $20DA , $80 , $FFEC , $1476 , $46 , $8 , $1442 , $1442 , $CC6 , $61 , $189E 
' 18E0 
  word $6E87 , $6D61 , $6C65 , $6E65 , $163C , $1250 , $DC8 , $61 , $18E0 , $6385 , $6F6D , $6576 , $EC4 , $1492 , $8D , $16 
' 1900 
  word $1602 , $79 , $163C , $1A60 , $E2C , $80 , $FFF8 , $26 , $46 , $4 , $1450 , $61 , $18F2 , $6E88 , $6D61 , $6365 
' 1920 
  word $706F , $79 , $F5A , $18E8 , $14A0 , $1526 , $18F8 , $61 , $191A , $6385 , $6F63 , $7970 , $F5A , $DEE , $14A0 , $18F8 
' 1940 
  word $61 , $1932 , $6387 , $7061 , $6570 , $646E , $EC4 , $163C , $F66 , $1504 , $F5A , $DEE , $F5A , $DEE , $F66 , $FEA 
' 1960 
  word $E2C , $EC4 , $DEE , $FEA , $14A0 , $1504 , $18F8 , $61 , $1944 , $6388 , $7061 , $6570 , $646E , $6E , $FEA , $1D10 
' 1980 
  word $1D92 , $1D1E , $FEA , $194C , $61 , $1972 , $2887 , $666E , $6F63 , $2967 , $CBA , $CBA , $5D , $8 , $CC6 , $79 
' 19A0 
  word $5D , $7 , $1A60 , $F34 , $EC4 , $13D2 , $DEE , $5D , $4 , $DC8 , $F5A , $10D6 , $DE2 , $5D , $100 , $ED0 
' 19C0 
  word $DC8 , $8D , $E , $1526 , $1526 , $CC6 , $20DA , $46 , $4 , $26 , $80 , $FFCA , $61 , $198C , $6E85 , $6366 
' 19E0 
  word $676F , $1994 , $8D , $8 , $5D , $5 , $1116 , $61 , $19DC , $6384 , $676F , $78 , $110A , $14BC , $DFA , $1504 
' 1A00 
  word $10D6 , $110A , $14BC , $E38 , $1A40 , $15C0 , $110A , $14BC , $E38 , $61 , $19F2 , $2E88 , $7473 , $6E72 , $6D61 , $65 
' 1A20 
  word $EC4 , $8D , $A , $18E8 , $2BBC , $46 , $A , $26 , $5D , $3F , $2D24 , $61 , $1A16 , $2E85 , $7363 , $7274 
' 1A40 
  word $163C , $2BBC , $61 , $1A3A , $6482 , $71 , $75 , $163C , $1434 , $F66 , $162C , $7C , $2BBC , $61 , $1A48 , $6981 
' 1A60 
  word $CD6 , $28 , $61 , $1A5E , $7384 , $7465 , $69 , $CD6 , $37 , $61 , $1A68 , $6684 , $6C69 , $6C , $1504 , $1602 
' 1A80 
  word $79 , $EC4 , $1A60 , $E2C , $80 , $FFF8 , $26 , $61 , $1A76 , $6E87 , $6166 , $6C3E , $6166 , $14CA , $61 , $1A92 
' 1AA0 
  word $6E87 , $6166 , $703E , $6166 , $18E8 , $F66 , $162C , $61 , $1AA0 , $6E88 , $6166 , $6E3E , $7865 , $74 , $1A9A , $DFA 
' 1AC0 
  word $61 , $1AB2 , $6C87 , $7361 , $6E74 , $6166 , $A54 , $DFA , $61 , $1AC4 , $698A , $6E73 , $6D61 , $6365 , $6168 , $72 
' 1AE0 
  word $5D , $21 , $5D , $7E , $15AC , $61 , $1AD4 , $5F8D , $6F66 , $7472 , $7068 , $6166 , $6E3E , $6166 , $14AE , $14AE 
' 1B00 
  word $EC4 , $DEE , $1AE0 , $145C , $8D , $FFF4 , $61 , $1AEE , $5F8B , $7361 , $706D , $6166 , $6E3E , $6166 , $1ACC , $1434 
' 1B20 
  word $1AA8 , $DFA , $ED0 , $F5A , $DEE , $5D , $80 , $DC8 , $145C , $DC8 , $8D , $8 , $CBA , $46 , $8 , $1ABC 
' 1B40 
  word $EC4 , $145C , $8D , $FFD8 , $1526 , $61 , $1B10 , $7087 , $6166 , $6E3E , $6166 , $EC4 , $C76 , $33 , $DC8 , $8D 
' 1B60 
  word $8 , $1AFC , $46 , $4 , $1B1C , $61 , $1B4E , $6186 , $6363 , $7065 , $74 , $2AC8 , $2AFA , $13BE , $DEE , $5D 
' 1B80 
  word $10 , $DC8 , $8D , $10 , $121A , $14A0 , $FEA , $2BBC , $15C0 , $46 , $4 , $26 , $61 , $1B6E , $7085 , $7261 
' 1BA0 
  word $6573 , $125E , $139C , $DFA , $154C , $8D , $8 , $CC6 , $46 , $7A , $EC4 , $1268 , $E2C , $CC6 , $1434 , $123C 
' 1BC0 
  word $F66 , $DEE , $1534 , $ED0 , $8D , $A , $26 , $CBA , $46 , $56 , $5D , $7E , $ED0 , $8D , $48 , $EC4 
' 1BE0 
  word $123C , $F66 , $EC4 , $14A0 , $5D , $3 , $1434 , $183A , $8D , $30 , $177A , $F5A , $E2C , $F5A , $CC6 , $79 
' 1C00 
  word $EC4 , $DEE , $F5A , $5D , $3 , $F66 , $E2C , $14AE , $80 , $FFEE , $26 , $5D , $3 , $139C , $1566 , $46 
' 1C20 
  word $4 , $1450 , $14A0 , $CC6 , $8D , $FF92 , $1526 , $61 , $1B9C , $6E88 , $7865 , $7774 , $726F , $64 , $125E , $139C 
' 1C40 
  word $DFA , $EE4 , $8D , $12 , $123C , $DEE , $139C , $DFA , $F66 , $14A0 , $139C , $E38 , $61 , $1C32 , $7089 , $7261 
' 1C60 
  word $6573 , $6F77 , $6472 , $2D62 , $1BA2 , $EC4 , $8D , $14 , $139C , $DFA , $14AE , $1434 , $121A , $F66 , $E2C , $139C 
' 1C80 
  word $E38 , $61 , $1C5C , $7087 , $7261 , $6573 , $6C62 , $CB0 , $1C66 , $1476 , $61 , $1C86 , $7087 , $7261 , $6573 , $776E 
' 1CA0 
  word $1C8E , $8D , $A , $123C , $1C3C , $46 , $4 , $CC6 , $61 , $1C98 , $6684 , $6E69 , $64 , $1ACC , $F5A , $2A5A 
' 1CC0 
  word $EC4 , $8D , $44 , $1526 , $EC4 , $1AA8 , $F5A , $DEE , $5D , $80 , $DC8 , $145C , $8D , $4 , $DFA , $FEA 
' 1CE0 
  word $DEE , $EC4 , $5D , $40 , $DC8 , $8D , $18 , $5D , $20 , $DC8 , $8D , $8 , $CD6 , $46 , $4 , $CCE 
' 1D00 
  word $46 , $6 , $26 , $CBA , $61 , $1CB4 , $3C82 , $23 , $12E6 , $138E , $E38 , $61 , $1D0C , $2382 , $3E , $26 
' 1D20 
  word $12E6 , $138E , $DFA , $F34 , $CBA , $138E , $1566 , $12CE , $E2C , $12CE , $61 , $1D1A , $7486 , $636F , $6168 , $72 
' 1D40 
  word $5D , $3F , $DC8 , $5D , $30 , $F66 , $EC4 , $5D , $39 , $EE4 , $8D , $8 , $5D , $7 , $F66 , $EC4 
' 1D60 
  word $5D , $5D , $EE4 , $8D , $8 , $5D , $3 , $F66 , $61 , $1D38 , $2381 , $1326 , $DFA , $329E , $FEA , $1D40 
' 1D80 
  word $CBA , $138E , $1566 , $12CE , $E2C , $61 , $1D74 , $2382 , $73 , $1D76 , $EC4 , $145C , $8D , $FFF8 , $61 , $1D8E 
' 1DA0 
  word $7582 , $2E , $1D10 , $1D92 , $1D1E , $1A40 , $15D0 , $61 , $1DA0 , $2E81 , $EC4 , $1484 , $8D , $A , $5D , $2D 
' 1DC0 
  word $2D24 , $1006 , $1DA4 , $61 , $1DB2 , $6385 , $676F , $6469 , $CBA , $CCE , $E6E , $61 , $1DCA , $5F8A , $6F6C , $6B63 
' 1DE0 
  word $7261 , $6172 , $79 , $4F , $F0F , $F0F , $F0F , $F0F , $1DDA , $6C84 , $636F , $6B , $5D , $7 , $DC8 , $EC4 
' 1E00 
  word $1DE6 , $F66 , $EC4 , $DEE , $EC4 , $5D , $F , $DC8 , $1DD0 , $ED0 , $8D , $26 , $5D , $10 , $F66 , $1534 
' 1E20 
  word $FEA , $E2C , $5D , $F0 , $DC8 , $145C , $8D , $8 , $5D , $6 , $1116 , $26 , $46 , $46 , $26 , $FEA 
' 1E40 
  word $CBA , $5D , $1000 , $5D , $8 , $F08 , $CC6 , $79 , $F5A , $5D , $6 , $E7E , $145C , $8D , $8 , $26 
' 1E60 
  word $CC6 , $20DA , $80 , $FFEA , $8D , $8 , $5D , $7 , $1116 , $26 , $1DD0 , $5D , $10 , $F66 , $FEA , $E2C 
' 1E80 
  word $61 , $1DF2 , $7586 , $6C6E , $636F , $6B , $5D , $7 , $DC8 , $EC4 , $1DE6 , $F66 , $EC4 , $DEE , $EC4 , $5D 
' 1EA0 
  word $F , $DC8 , $1DD0 , $ED0 , $8D , $36 , $5D , $10 , $F34 , $EC4 , $5D , $F0 , $DC8 , $145C , $8D , $18 
' 1EC0 
  word $26 , $5D , $F , $FEA , $E2C , $5D , $7 , $E7E , $26 , $46 , $8 , $FEA , $E2C , $26 , $46 , $8 
' 1EE0 
  word $5D , $8 , $1116 , $61 , $1E84 , $7589 , $6C6E , $636F , $616B , $6C6C , $5D , $8 , $CC6 , $79 , $1DE6 , $1A60 
' 1F00 
  word $F66 , $DEE , $5D , $F , $DC8 , $1DD0 , $ED0 , $8D , $18 , $5D , $F , $1DE6 , $1A60 , $F66 , $E2C , $1A60 
' 1F20 
  word $5D , $7 , $E7E , $26 , $80 , $FFD2 , $61 , $1EEA , $3285 , $6F6C , $6B63 , $CD6 , $1DF8 , $61 , $1F30 , $3287 
' 1F40 
  word $6E75 , $6F6C , $6B63 , $CD6 , $1E8C , $61 , $1F3E , $6389 , $6568 , $6B63 , $6964 , $7463 , $A60 , $DFA , $F66 , $A6E 
' 1F60 
  word $DFA , $1540 , $8D , $8 , $5D , $9 , $1116 , $61 , $1F4E , $288D , $7263 , $6165 , $6574 , $6562 , $6967 , $296E 
' 1F80 
  word $28E8 , $1FF6 , $A54 , $DFA , $A60 , $DFA , $EC4 , $14BC , $A54 , $E38 , $FEA , $F5A , $E38 , $14BC , $61 , $1F72 
' 1FA0 
  word $288B , $7263 , $6165 , $6574 , $6E65 , $2964 , $F5A , $1924 , $18E8 , $F66 , $162C , $A60 , $E38 , $28FA , $61 , $1FA0 
' 1FC0 
  word $6387 , $7263 , $6165 , $6574 , $1F80 , $FEA , $1FAC , $61 , $1FC0 , $6386 , $6572 , $7461 , $65 , $CB0 , $1C66 , $8D 
' 1FE0 
  word $A , $1F80 , $123C , $1FAC , $1C3C , $61 , $1FD2 , $6887 , $7265 , $7765 , $6C61 , $28E8 , $CD6 , $1F58 , $A60 , $DFA 
' 2000 
  word $162C , $A60 , $E38 , $28FA , $61 , $1FEE , $6185 , $6C6C , $746F , $28E8 , $EC4 , $1F58 , $A60 , $1566 , $28FA , $61 
' 2020 
  word $200C , $7782 , $2C , $28E8 , $1FF6 , $A60 , $DFA , $E38 , $CD6 , $2012 , $28FA , $61 , $2022 , $6382 , $2C , $28E8 
' 2040 
  word $A60 , $DFA , $E2C , $CCE , $2012 , $28FA , $61 , $203A , $6887 , $7265 , $6C65 , $6C61 , $28E8 , $5D , $4 , $1F58 
' 2060 
  word $A60 , $DFA , $1614 , $A60 , $E38 , $28FA , $61 , $2050 , $6C82 , $2C , $28E8 , $2058 , $A60 , $DFA , $E20 , $5D 
' 2080 
  word $4 , $2012 , $28FA , $61 , $2070 , $6F86 , $6C72 , $666E , $61 , $1ACC , $157C , $61 , $208A , $668A , $726F , $6874 
' 20A0 
  word $6E65 , $7274 , $79 , $5D , $80 , $2092 , $61 , $209A , $6989 , $6D6D , $6465 , $6169 , $6574 , $5D , $40 , $2092 
' 20C0 
  word $61 , $20B0 , $6584 , $6578 , $63 , $5D , $60 , $2092 , $61 , $20C4 , $6C85 , $6165 , $6576 , $CCE , $28 , $CD6 
' 20E0 
  word $37 , $61 , $20D4 , $6389 , $656C , $7261 , $656B , $7379 , $CCE , $13BE , $1594 , $CEA , $33 , $2C40 , $8D , $C 
' 2100 
  word $1442 , $CEA , $33 , $46 , $4 , $26 , $CEA , $33 , $F5A , $F34 , $10BA , $EE4 , $8D , $FFE0 , $61 , $20E6 
' 2120 
  word $7783 , $6C3E , $5D , $FFFF , $DC8 , $FEA , $5D , $10 , $F08 , $F40 , $61 , $2120 , $6C83 , $773E , $EC4 , $5D 
' 2140 
  word $10 , $FA0 , $FEA , $5D , $FFFF , $DC8 , $61 , $2138 , $3A81 , $28E8 , $1FDA , $5D , $3741 , $CCE , $13BE , $157C 
' 2160 
  word $61 , $2150 , $5F85 , $6D6D , $7363 , $13E2 , $8D , $26 , $1A4C , $4D1F , $5349 , $414D , $4354 , $4548 , $2044 , $4F43 
' 2180 
  word $544E , $4F52 , $204C , $5453 , $5552 , $5443 , $5255 , $2845 , $2953 , $15C0 , $20F0 , $61 , $2164 , $3BC1 , $BA4 , $2026 
' 21A0 
  word $CCE , $13BE , $1594 , $20A6 , $5D , $3741 , $146A , $8D , $4 , $216A , $28FA , $61 , $219A , $6486 , $746F , $6568 
' 21C0 
  word $6E , $213C , $EC4 , $5D , $1235 , $ED0 , $FEA , $5D , $1239 , $ED0 , $F40 , $8D , $14 , $EC4 , $A60 , $DFA 
' 21E0 
  word $FEA , $F34 , $FEA , $E38 , $46 , $4 , $216A , $61 , $21BA , $74C4 , $6568 , $6E , $21C2 , $61 , $21F2 , $74C5 
' 2200 
  word $6568 , $736E , $EC4 , $5D , $FFFF , $DC8 , $EC4 , $5D , $1235 , $ED0 , $FEA , $5D , $1239 , $ED0 , $F40 , $8D 
' 2220 
  word $A , $21C2 , $CC6 , $46 , $4 , $CBA , $8D , $FFD6 , $61 , $21FE , $69C2 , $66 , $C34 , $2026 , $A60 , $DFA 
' 2240 
  word $5D , $1235 , $2124 , $CC6 , $2026 , $61 , $2234 , $65C4 , $736C , $65 , $BDA , $2026 , $CC6 , $2026 , $21C2 , $A60 
' 2260 
  word $DFA , $14CA , $5D , $1239 , $2124 , $61 , $224E , $75C5 , $746E , $6C69 , $213C , $5D , $1317 , $ED0 , $8D , $12 
' 2280 
  word $C34 , $2026 , $A60 , $DFA , $F34 , $2026 , $46 , $4 , $216A , $61 , $226E , $62C5 , $6765 , $6E69 , $A60 , $DFA 
' 22A0 
  word $5D , $1317 , $2124 , $61 , $2296 , $6486 , $6C6F , $6F6F , $70 , $FEA , $213C , $5D , $2329 , $ED0 , $8D , $12 
' 22C0 
  word $FEA , $2026 , $A60 , $DFA , $F34 , $2026 , $46 , $4 , $216A , $61 , $22AA , $6CC4 , $6F6F , $70 , $C0C , $22B2 
' 22E0 
  word $61 , $22D6 , $2BC5 , $6F6C , $706F , $C20 , $22B2 , $61 , $22E4 , $64C2 , $6F , $BFA , $2026 , $A60 , $DFA , $5D 
' 2300 
  word $2329 , $2124 , $61 , $22F2 , $5F84 , $6365 , $73 , $5D , $3A , $2D24 , $15D0 , $61 , $2308 , $5F84 , $6475 , $66 
' 2320 
  word $1A4C , $550F , $444E , $4645 , $4E49 , $4445 , $5720 , $524F , $2044 , $61 , $231A , $5F83 , $7071 , $5D , $22 , $1BA2 
' 2340 
  word $14AE , $123C , $1434 , $E2C , $FEA , $14BC , $139C , $1566 , $61 , $2336 , $5F83 , $7073 , $2026 , $233A , $EC4 , $A60 
' 2360 
  word $DFA , $1938 , $DEE , $14A0 , $2012 , $1FF6 , $61 , $2354 , $2EC2 , $22 , $B94 , $2358 , $61 , $2370 , $6689 , $7369 
' 2380 
  word $756E , $626D , $7265 , $183A , $61 , $237C , $6687 , $756E , $626D , $7265 , $177A , $61 , $238C , $698C , $746E , $7265 
' 23A0 
  word $7270 , $7465 , $6170 , $64 , $CCE , $139C , $E38 , $CB0 , $1C66 , $8D , $D4 , $123C , $1C3C , $1CBA , $EC4 , $8D 
' 23C0 
  word $6C , $EC4 , $CBA , $ED0 , $8D , $18 , $26 , $1422 , $8D , $8 , $2026 , $46 , $4 , $134C , $CC6 , $46 
' 23E0 
  word $48 , $CD6 , $ED0 , $8D , $A , $134C , $CC6 , $46 , $38 , $1422 , $8D , $A , $134C , $CC6 , $46 , $2A 
' 2400 
  word $1B56 , $13E2 , $8D , $1C , $1A4C , $490F , $4D4D , $4445 , $4149 , $4554 , $5720 , $524F , $2044 , $1A20 , $15C0 , $46 
' 2420 
  word $4 , $26 , $20F0 , $CBA , $46 , $5A , $26 , $EC4 , $163C , $2386 , $8D , $30 , $163C , $2394 , $1422 , $8D 
' 2440 
  word $20 , $EC4 , $CC6 , $5D , $FFFF , $15AC , $8D , $C , $BEA , $2026 , $2026 , $46 , $8 , $C44 , $2026 , $2074 
' 2460 
  word $CC6 , $46 , $20 , $1422 , $8D , $4 , $28FA , $CCE , $13BE , $1594 , $13E2 , $8D , $8 , $2320 , $1A20 , $15C0 
' 2480 
  word $20F0 , $CBA , $46 , $4 , $CBA , $8D , $FF22 , $61 , $239A , $6989 , $746E , $7265 , $7270 , $7465 , $1B76 , $23A8 
' 24A0 
  word $61 , $2492 , $5F84 , $6377 , $31 , $28E8 , $1FDA , $BC8 , $2026 , $2026 , $20A6 , $1ACC , $28FA , $61 , $24A4 , $7789 
' 24C0 
  word $6F63 , $736E , $6174 , $746E , $24AA , $26 , $61 , $24BE , $7789 , $6176 , $6972 , $6261 , $656C , $28E8 , $1FDA , $BB6 
' 24E0 
  word $2026 , $CC6 , $2026 , $20A6 , $28FA , $61 , $24D0 , $6188 , $6D73 , $616C , $6562 , $6C , $28E8 , $1FDA , $2026 , $28FA 
' 2500 
  word $61 , $24EE , $6883 , $7865 , $5D , $10 , $1326 , $E38 , $61 , $2504 , $6485 , $6C65 , $736D , $57 , $FFFF , $7FFF 
' 2520 
  word $10BA , $5D , $3E8 , $32AC , $32AC , $F2A , $CCE , $F1E , $10BA , $5D , $3E8 , $32AC , $3290 , $CEA , $33 , $F66 
' 2540 
  word $EC4 , $CEA , $33 , $F34 , $1484 , $8D , $FFF4 , $26 , $61 , $2514 , $3E82 , $6D , $CCE , $FEA , $F08 , $61 
' 2560 
  word $2554 , $5CE1 , $125E , $139C , $E38 , $61 , $2562 , $5F83 , $6C64 , $2AC8 , $121A , $14A0 , $13BE , $DEE , $1504 , $5D 
' 2580 
  word $8 , $13BE , $157C , $5D , $10 , $13BE , $1594 , $13E2 , $8D , $A , $5D , $2E , $2D24 , $15C0 , $1B76 , $EC4 
' 25A0 
  word $DEE , $CD6 , $2E , $ED0 , $F5A , $14A0 , $DEE , $5D , $3 , $2E , $ED0 , $F40 , $8D , $FFD4 , $26 , $13E2 
' 25C0 
  word $8D , $A , $2D24 , $15C0 , $46 , $4 , $26 , $13BE , $E2C , $61 , $256E , $7BE1 , $5D , $7D , $2572 , $61 
' 25E0 
  word $25D6 , $7DE1 , $61 , $25E2 , $5F83 , $6669 , $145C , $8D , $8 , $5D , $5D , $2572 , $61 , $25E8 , $5BE3 , $6669 
' 2600 
  word $25EC , $61 , $25FC , $5BE6 , $6669 , $6564 , $66 , $1CA0 , $1CBA , $1526 , $25EC , $61 , $2606 , $5BE7 , $6669 , $646E 
' 2620 
  word $6665 , $1CA0 , $1CBA , $1526 , $145C , $25EC , $61 , $261A , $5DE1 , $61 , $2630 , $2EE3 , $2E2E , $61 , $2636 , $2781 
' 2640 
  word $1CA0 , $EC4 , $8D , $18 , $1CBA , $145C , $8D , $10 , $13E2 , $8D , $6 , $2320 , $15C0 , $26 , $CC6 , $61 
' 2660 
  word $263E , $6382 , $71 , $75 , $EC4 , $163C , $F66 , $162C , $7C , $61 , $2662 , $63E2 , $22 , $1422 , $8D , $A 
' 2680 
  word $B88 , $2358 , $46 , $4 , $233A , $61 , $2676 , $6687 , $5F6C , $6F6C , $6B63 , $4F , $0 , $268E , $6686 , $7473 
' 26A0 
  word $7261 , $74 

fstartPFA

  word $110A , $5D , $10 , $F08 , $B6A , $CD6 , $F08 , $F40 , $1DD0 , $F40 , $C8A , $42 , $13AE , $DEE 
' 26C0 
  word $5D , $100 , $110A , $E38 , $121A , $B1E , $5D , $4 , $F34 , $CC6 , $1A7C , $5D , $A , $1326 , $E38 , $3280 
' 26E0 
  word $28E8 , $B10 , $DFA , $145C , $8D , $46 , $CBA , $B10 , $E38 , $28FA , $CC6 , $2696 , $E38 , $AC6 , $B02 , $E38 
' 2700 
  word $AB0 , $AF4 , $E38 , $1DE6 , $5D , $8 , $1602 , $79 , $5D , $F , $1A60 , $E2C , $80 , $FFF6 , $2666 , $6F06 
' 2720 
  word $626E , $6F6F , $74 , $1CBA , $26 , $134C , $46 , $4 , $28FA , $2666 , $6F07 , $726E , $7365 , $7465 , $1294 , $1938 
' 2740 
  word $1DD0 , $1294 , $197C , $1294 , $1CBA , $8D , $8 , $134C , $46 , $14 , $26 , $2666 , $6F07 , $726E , $7365 , $7465 
' 2760 
  word $1CBA , $26 , $134C , $1422 , $145C , $8D , $2A , $13E2 , $8D , $24 , $1F36 , $AF4 , $DFA , $1A40 , $AA2 , $DFA 
' 2780 
  word $1DB4 , $1A4C , $4303 , $676F , $1DD0 , $1DB4 , $1A4C , $6F02 , $6B , $15C0 , $1F46 , $249C , $CC6 , $8D , $FFCA , $61 
' 27A0 
  word $269C , $7386 , $7265 , $6169 , $6C , $14E6 , $10BA , $FEA , $32AC , $EC4 , $14F4 , $14F4 , $5D , $FF , $5D , $1C2 
' 27C0 
  word $1434 , $42 , $14A0 , $1434 , $42 , $14A0 , $1434 , $42 , $14A0 , $1534 , $42 , $14A0 , $5D , $100 , $FEA , $1434 
' 27E0 
  word $42 , $14A0 , $1534 , $42 , $14A0 , $1534 , $42 , $14A0 , $1534 , $42 , $14A0 , $FEA , $2558 , $F5A , $42 , $14A0 
' 2800 
  word $FEA , $2558 , $F5A , $42 , $14A0 , $5D , $1F0 , $FEA , $79 , $CC6 , $1A60 , $42 , $80 , $FFF8 , $2666 , $5306 
' 2820 
  word $5245 , $4149 , $4C , $12A6 , $1938 , $12A6 , $1302 , $E38 , $5D , $4 , $13BE , $1594 , $CC6 , $110A , $5D , $C4 
' 2840 
  word $F66 , $E20 , $CC6 , $110A , $5D , $C8 , $F66 , $E20 , $2FD6 , $61 , $27A2 , $6987 , $696E , $6374 , $6E6F , $B2E 
' 2860 
  word $B3E , $B4C , $27AA , $61 , $2856 , $6F86 , $626E , $6F6F , $74 , $B5A , $1158 , $B5A , $1050 , $5D , $10 , $251A 
' 2880 
  word $2666 , $6907 , $696E , $6374 , $6E6F , $B5A , $19F8 , $5D , $100 , $251A , $1DD0 , $1410 , $5D , $8 , $CC6 , $79 
' 28A0 
  word $1A60 , $1DD0 , $146A , $1A60 , $B5A , $146A , $DC8 , $8D , $6 , $1A60 , $1050 , $80 , $FFE8 , $61 , $286A , $6F87 
' 28C0 
  word $726E , $3065 , $3130 , $1EF4 , $5D , $4 , $13BE , $157C , $B02 , $DFA , $1302 , $E38 , $26 , $61 , $28BE , $6C88 
' 28E0 
  word $636F , $646B , $6369 , $74 , $CC6 , $1DF8 , $61 , $28DE , $6688 , $6572 , $6465 , $6369 , $74 , $CC6 , $1E8C , $61 
' 2900 
  word $28F0 , $7583 , $3D3E , $4 , $310E , $61 , $2902 , $628D , $6975 , $646C , $425F , $6F6F , $4F74 , $7470 , $4A , $112 
' 2920 
  word $290E , $7583 , $2A6D , $B2 , $2112 , $3198 , $54A3 , $5CFD , $9A00 , $A0FD , $9C00 , $A0FD , $9E00 , $A0FD , $9601 , $2BFD 
' 2940 
  word $11B , $5C4C , $9ECC , $81BD , $9ACE , $C8BD , $9801 , $2DFD , $9C01 , $34FD , $117 , $5C54 , $96CF , $A0BD , $3695 , $5CFD 
' 2960 
  word $96CD , $A0BD , $61 , $5C7C , $2922 , $7586 , $2F6D , $6F6D , $64 , $B2 , $2312 , $31E4 , $54A3 , $5CFD , $A2CB , $A0BD 
' 2980 
  word $54A4 , $5CFD , $9C40 , $A0FD , $9A00 , $A0FD , $9601 , $2DFD , $A201 , $35FD , $9A01 , $35FD , $9ACC , $84B1 , $9ACC , $E18D 
' 29A0 
  word $9E01 , $34FD , $9D18 , $E4FD , $96CD , $A0BD , $3695 , $5CFD , $96CF , $A0BD , $61 , $5C7C , $296A , $6385 , $7473 , $3D72 
' 29C0 
  word $B2 , $0 , $1B12 , $3234 , $54A3 , $5CFD , $9ACC , $BD , $9A01 , $80FD , $9601 , $84FD , $9CCC , $BD , $9801 , $80FD 
' 29E0 
  word $9601 , $80FD , $9ECB , $BD , $9CCF , $863D , $9B17 , $E4E9 , $96C6 , $78BD , $61 , $5C7C , $29BA , $6E85 , $6D61 , $3D65 
' 2A00 
  word $B2 , $0 , $2512 , $3274 , $54A3 , $5CFD , $9ACC , $BD , $9A1F , $60FD , $9801 , $80FD , $9ECB , $BD , $9E1F , $60FD 
' 2A20 
  word $9CCD , $A0BD , $9A01 , $80FD , $120 , $5C7C , $9CCC , $BD , $9801 , $80FD , $9601 , $80FD , $9ECB , $BD , $9CCF , $863D 
' 2A40 
  word $9B1C , $E4E9 , $96C6 , $78BD , $61 , $5C7C , $29FA , $5F8B , $6964 , $7463 , $6573 , $7261 , $6863 , $B2 , $3312 , $32CC 
' 2A60 
  word $54A3 , $5CFD , $A0CC , $A0BD , $A2CB , $A0BD , $9ACC , $BD , $9A1F , $60FD , $9801 , $80FD , $9ECB , $BD , $9E1F , $60FD 
' 2A80 
  word $9CCD , $A0BD , $9A01 , $80FD , $122 , $5C7C , $9CCC , $BD , $9801 , $80FD , $9601 , $80FD , $9ECB , $BD , $9CCF , $863D 
' 2AA0 
  word $9B1E , $E4E9 , $96D1 , $A0BD , $61 , $5C68 , $A202 , $84FD , $96D1 , $6BD , $61 , $5C68 , $98D0 , $A0BD , $115 , $5C7C 
' 2AC0 
  word $2A4E , $7085 , $6461 , $6C62 , $B2 , $0 , $1312 , $333C , $A1F0 , $A0BD , $A004 , $80FD , $9C20 , $A0FD , $34D0 , $83E 
' 2AE0 
  word $A004 , $80FD , $9D16 , $E4FD , $61 , $5C7C , $2020 , $2020 , $2AC2 , $5F87 , $6361 , $6563 , $7470 , $B2 , $5D12 , $336C 
' 2B00 
  word $3695 , $5CFD , $9BF0 , $A0BD , $9A02 , $80FD , $A2CD , $4BD , $9ADD , $80FD , $98CD , $BD , $9808 , $627D , $A200 , $A0D5 
' 2B20 
  word $9ADA , $84FD , $96CD , $A0BD , $9C7E , $A0FD , $9FF0 , $4BD , $9F00 , $627D , $11E , $5C54 , $9900 , $A0FD , $99F0 , $43D 
' 2B40 
  word $9E0D , $867D , $9C01 , $A0E9 , $135 , $5C68 , $9E08 , $867D , $12C , $5C68 , $9E20 , $48FD , $9ECB , $3D , $9601 , $80FD 
' 2B60 
  word $135 , $5C7C , $7F39 , $5CFE , $9E20 , $A0FD , $7F39 , $5CFE , $9601 , $84FD , $96CD , $48BD , $9ECB , $3D , $9C02 , $80FD 
' 2B80 
  word $9C7E , $4CFD , $9E08 , $A0FD , $7F39 , $5CFE , $9D1E , $E4FD , $96CD , $84BD , $61 , $5C7C , $A200 , $867D , $13F , $5C68 
' 2BA0 
  word $98D1 , $4BD , $9900 , $627D , $13B , $5C68 , $9ED1 , $43D , $0 , $5C7C , $2AF2 , $2E84 , $7473 , $72 , $B2 , $0 
' 2BC0 
  word $2112 , $3430 , $54A3 , $5CFD , $9800 , $867D , $A3F0 , $A095 , $A202 , $80D5 , $9AD1 , $695 , $120 , $5C68 , $9ECB , $BD 
' 2BE0 
  word $9601 , $80FD , $9CCD , $4BD , $9D00 , $627D , $11B , $5C68 , $9ECD , $43D , $9919 , $E4FD , $54A4 , $5CFD , $61 , $5C7C 
' 2C00 
  word $2BB6 , $5F86 , $6B66 , $7965 , $3F , $B2 , $1712 , $347C , $98CB , $4BD , $9900 , $627D , $9AC6 , $78BD , $119 , $5C54 
' 2C20 
  word $9D00 , $A0FD , $9CCB , $43D , $96CC , $A0BD , $3695 , $5CFD , $96CD , $A0BD , $61 , $5C7C , $2C02 , $6685 , $656B , $3F79 
' 2C40 
  word $B2 , $0 , $1712 , $34B4 , $3695 , $5CFD , $97F0 , $4BD , $9700 , $627D , $98C6 , $78BD , $11A , $5C54 , $9D00 , $A0FD 
' 2C60 
  word $9DF0 , $43D , $3695 , $5CFD , $96CC , $A0BD , $61 , $5C7C , $2C3A , $6B83 , $7965 , $B2 , $1112 , $34E8 , $3695 , $5CFD 
' 2C80 
  word $97F0 , $4BD , $9700 , $627D , $114 , $5C54 , $9900 , $A0FD , $99F0 , $43D , $61 , $5C7C , $2C72 , $5F87 , $6566 , $696D 
' 2CA0 
  word $3F74 , $B2 , $1D12 , $3514 , $54A3 , $5CFD , $96FF , $60FD , $9ACC , $A0BD , $9A02 , $80FD , $9CCD , $6BD , $9EC6 , $78BD 
' 2CC0 
  word $11E , $5C68 , $9ACE , $4BD , $9B00 , $627D , $9EC6 , $7CBD , $96CE , $415 , $96CF , $A0BD , $61 , $5C7C , $2C9A , $6686 
' 2CE0 
  word $6D65 , $7469 , $3F , $B2 , $1B12 , $3558 , $96FF , $60FD , $9BF0 , $A0BD , $9A02 , $80FD , $9CCD , $6BD , $9EC6 , $78BD 
' 2D00 
  word $11D , $5C68 , $9ACE , $4BD , $9B00 , $627D , $9EC6 , $7CBD , $96CE , $415 , $96CF , $A0BD , $61 , $5C7C , $2CDE , $6584 
' 2D20 
  word $696D , $74 , $B2 , $0 , $1912 , $3598 , $54A3 , $5CFD , $98FF , $60FD , $9BF0 , $A0BD , $9A02 , $80FD , $9CCD , $6BD 
' 2D40 
  word $11D , $5C68 , $9ACE , $4BD , $9B00 , $627D , $119 , $5C68 , $98CE , $43D , $61 , $5C7C , $2D1E , $7386 , $696B , $6270 
' 2D60 
  word $6C , $B2 , $2512 , $35D4 , $99F0 , $A0BD , $98DC , $80FD , $9ACC , $4BD , $9A80 , $877D , $123 , $5C4C , $9C80 , $A0FD 
' 2D80 
  word $9CCD , $84BD , $9A04 , $80FD , $9BF0 , $80BD , $A0CD , $BD , $A020 , $867D , $9A01 , $80E9 , $9D1C , $E4E9 , $9A04 , $84FD 
' 2DA0 
  word $9BF0 , $84BD , $9ACC , $43D , $61 , $5C7C , $2D5A , $5F87 , $6565 , $6572 , $6461 , $B2 , $4112 , $3628 , $11A , $5C7C 
' 2DC0 
  word $0 , $2000 , $0 , $1000 , $D , $0 , $A316 , $A0BD , $A318 , $E4FD , $0 , $5C7C , $98CB , $A0BD , $9600 , $A0FD 
' 2DE0 
  word $ED14 , $64BF , $9C08 , $A0FD , $3317 , $5CFE , $29F2 , $613E , $9601 , $34FD , $E915 , $68BF , $3317 , $5CFE , $3317 , $5CFE 
' 2E00 
  word $E915 , $64BF , $3317 , $5CFE , $9D1E , $E4FD , $9800 , $867D , $E914 , $7CBF , $ED14 , $68BF , $3317 , $5CFE , $E915 , $68BF 
' 2E20 
  word $3317 , $5CFE , $3317 , $5CFE , $E915 , $64BF , $E914 , $64BF , $3317 , $5CFE , $61 , $5C7C , $2DAE , $5F88 , $6565 , $7277 
' 2E40 
  word $7469 , $65 , $B2 , $0 , $3F12 , $36B8 , $11A , $5C7C , $0 , $2000 , $0 , $1000 , $D , $0 , $A316 , $A0BD 
' 2E60 
  word $A318 , $E4FD , $0 , $5C7C , $9C08 , $A0FD , $9680 , $627D , $E914 , $7CBF , $3317 , $5CFE , $E915 , $68BF , $3317 , $5CFE 
' 2E80 
  word $3317 , $5CFE , $E915 , $64BF , $9601 , $2CFD , $3317 , $5CFE , $9D1B , $E4FD , $ED14 , $64BF , $29F2 , $623E , $96C6 , $7CBD 
' 2EA0 
  word $3317 , $5CFE , $E915 , $68BF , $3317 , $5CFE , $3317 , $5CFE , $E915 , $64BF , $3317 , $5CFE , $E914 , $64BF , $ED14 , $68BF 
' 2EC0 
  word $61 , $5C7C , $2E3A , $6185 , $635F , $6168 , $B2 , $0 , $4F12 , $3740 , $A2CB , $A0BD , $54A4 , $5CFD , $54A3 , $5CFD 
' 2EE0 
  word $965C , $867D , $11D , $5C54 , $7134 , $5CFE , $960D , $867D , $118 , $5C54 , $7134 , $5CFE , $116 , $5C7C , $967B , $867D 
' 2F00 
  word $123 , $5C54 , $7134 , $5CFE , $967D , $867D , $11F , $5C54 , $7134 , $5CFE , $9620 , $867D , $9609 , $8655 , $12A , $5C54 
' 2F20 
  word $7134 , $5CFE , $9620 , $867D , $9609 , $8655 , $126 , $5C68 , $12C , $5C7C , $7134 , $5CFE , $960D , $867D , $96CC , $3D 
' 2F40 
  word $9801 , $80FD , $98D1 , $853D , $12B , $5C50 , $96CC , $A0BD , $61 , $5C7C , $100 , $0 , $97F0 , $4BD , $9700 , $627D 
' 2F60 
  word $134 , $5C54 , $67F0 , $43E , $0 , $5C7C , $2EC6 , $6187 , $665F , $6F6C , $7475 , $B2 , $2B12 , $37E8 , $A220 , $A0FD 
' 2F80 
  word $54A3 , $5CFD , $9CCB , $A0BD , $9ECC , $4BD , $9CCF , $87BD , $125 , $5C78 , $A2CE , $4CBD , $9BF0 , $A0BD , $9A02 , $80FD 
' 2FA0 
  word $A0CD , $4BD , $9AD0 , $4BD , $9B00 , $627D , $123 , $5C68 , $96CF , $BD , $9E01 , $80FD , $96D0 , $43D , $A31D , $E4FD 
' 2FC0 
  word $9ECC , $43D , $54A4 , $5CFD , $61 , $5C7C , $2F6E , $5F87 , $6573 , $6972 , $6C61 , $B2 , $4D12 , $3849 , $8FF0 , $83F 
' 2FE0 
  word $A330 , $A0FF , $A550 , $A0FF , $A759 , $A0FF , $A971 , $A0FF , $AB86 , $A0FF , $ADA6 , $A0FF , $E9CB , $68BF , $EDCB , $68BF 
' 3000 
  word $A1D1 , $5CBF , $95F2 , $623F , $11C , $5C54 , $BA09 , $A0FF , $BDC8 , $A0BF , $BDF1 , $80BF , $BDC9 , $80BF , $A1D1 , $5CBF 
' 3020 
  word $9BDE , $A0BF , $9BF1 , $84BF , $9A00 , $C17F , $123 , $5C4C , $95F2 , $613F , $B801 , $30FF , $BB22 , $E4FF , $11C , $5C4C 
' 3040 
  word $B817 , $28FF , $B8FF , $60FF , $8DDC , $A0BF , $11C , $5C7C , $A3D2 , $5CBF , $D1EB , $863F , $130 , $5C68 , $D880 , $68FF 
' 3060 
  word $6DEC , $50BE , $BFC5 , $A0BF , $BFEC , $60BF , $BFED , $28BF , $A3D2 , $5CBF , $8A08 , $25FF , $D800 , $C8FF , $D87F , $60FF 
' 3080 
  word $DA08 , $80FF , $D601 , $80FF , $D7FF , $60FF , $A3D2 , $5CBF , $BF00 , $68FF , $BE02 , $2CFF , $BE01 , $68FF , $C00B , $A0FF 
' 30A0 
  word $A3D2 , $5CBF , $C3F1 , $A0BF , $BE01 , $29FF , $E9CB , $70BF , $C3C9 , $80BF , $A3D2 , $5CBF , $9BE1 , $A0BF , $9BF1 , $84BF 
' 30C0 
  word $9A00 , $C17F , $149 , $5C4C , $C146 , $E4FF , $130 , $5C7C , $A5D0 , $5CBF , $A5D3 , $5CBF , $A5D0 , $5CBF , $A5D4 , $5CBF 
' 30E0 
  word $A5D0 , $5CBF , $A5D5 , $5CBF , $A5D0 , $5CBF , $A5D6 , $5CBF , $150 , $5C7C , $A7D2 , $5CBF , $8D00 , $627F , $159 , $5C54 
' 3100 
  word $AFE2 , $A0BF , $AE01 , $80FF , $AFFF , $60FF , $AFE5 , $863F , $159 , $5C68 , $A7D2 , $5CBF , $D1E3 , $54BE , $D3E3 , $54BE 
' 3120 
  word $9BC6 , $A0BF , $8D00 , $A0FF , $9BE4 , $2CBF , $9BC2 , $60BF , $C7C2 , $64BF , $C7CD , $68BF , $A7D2 , $5CBF , $8408 , $25FF 
' 3140 
  word $C600 , $C8FF , $C67F , $60FF , $C808 , $80FF , $C5D7 , $A0BF , $159 , $5C7C , $A9D2 , $5CBF , $C5E5 , $863F , $171 , $5C68 
' 3160 
  word $9800 , $867F , $9FCC , $497 , $9F00 , $6257 , $171 , $5C68 , $A9D2 , $5CBF , $F7E6 , $50BE , $9FC3 , $A0BF , $9FE6 , $60BF 
' 3180 
  word $9FE7 , $28BF , $9FCC , $43F , $A9D2 , $5CBF , $8608 , $25FF , $CC00 , $C8FF , $CC7F , $60FF , $CE08 , $80FF , $CA01 , $80FF 
' 31A0 
  word $CBFF , $60FF , $171 , $5C7C , $ABD2 , $5CBF , $B3F0 , $4BF , $B300 , $627F , $186 , $5C54 , $ABD2 , $5CBF , $B1E8 , $A0BF 
' 31C0 
  word $B001 , $80FF , $B1FF , $60FF , $B1EB , $863F , $186 , $5C68 , $ABD2 , $5CBF , $D280 , $68FF , $2FE9 , $54BF , $31E9 , $54BF 
' 31E0 
  word $9BD9 , $A0BF , $9BEA , $2CBF , $9BC4 , $60BF , $D3C4 , $64BF , $D3CD , $68BF , $ABD2 , $5CBF , $8808 , $25FF , $D200 , $C8FF 
' 3200 
  word $D27F , $60FF , $D408 , $80FF , $D1D8 , $A0BF , $ABD2 , $5CBF , $B20D , $867F , $B601 , $626B , $8FF0 , $417 , $9A0A , $A0EB 
' 3220 
  word $9BF0 , $42B , $186 , $5C7C , $ADD2 , $5CBF , $B5F0 , $A0BF , $B402 , $80FF , $99DA , $4BF , $ADD2 , $5CBF , $B4C2 , $80FF 
' 3240 
  word $9FDA , $ABF , $1B4 , $5C68 , $DDDA , $83F , $9E10 , $48FF , $E9CB , $64BF , $9FF1 , $80BF , $9E00 , $F8FF , $E9CB , $68BF 
' 3260 
  word $ADD2 , $5CBF , $B404 , $80FF , $B7DA , $8BF , $1A6 , $5C7C , $2FCE , $698C , $696E , $5F74 , $6F63 , $6867 , $7265 , $65 
' 3280 
  word $5D , $140 , $137E , $E38 , $61 , $3272 , $7582 , $2A , $2926 , $26 , $61 , $328C , $7585 , $6D2F , $646F , $CC6 
' 32A0 
  word $FEA , $2972 , $61 , $3298 , $7582 , $2F , $329E , $1526 , $61 , $32A8 , $6682 , $6C , $28E8 , $2696 , $DFA , $8D 
' 32C0 
  word $8 , $28FA , $46 , $EE , $CBA , $2696 , $E38 , $1DD0 , $19E2 , $EC4 , $7C , $11D2 , $28FA , $CEA , $33 , $CC6 
' 32E0 
  word $A6E , $DFA , $14CA , $A60 , $DFA , $5D , $80 , $F66 , $EC4 , $A6E , $E38 , $1434 , $154C , $8D , $28 , $2C40 
' 3300 
  word $1526 , $8D , $16 , $CEA , $33 , $5D , $3 , $3D , $F72 , $14A0 , $1504 , $46 , $8 , $EC4 , $A6E , $2F76 
' 3320 
  word $46 , $26 , $2C40 , $8D , $18 , $FEA , $CD6 , $2E , $2ECC , $CEA , $33 , $5D , $3 , $3D , $46 , $A 
' 3340 
  word $26 , $EC4 , $A6E , $2F76 , $CEA , $33 , $5D , $4 , $2E , $F34 , $10BA , $EE4 , $8D , $FF9C , $EC4 , $A6E 
' 3360 
  word $2F76 , $EC4 , $A6E , $DFA , $154C , $8D , $FFF0 , $15C0 , $15C0 , $26 , $14BC , $A6E , $E38 , $1DD0 , $120E , $CC6 
' 3380 
  word $2696 , $E38 , $75 , $F5A , $8D , $26 , $1050 , $15C0 , $1DB4 , $1A4C , $6315 , $6168 , $6172 , $7463 , $7265 , $2073 
' 33A0 
  word $766F , $7265 , $6C66 , $776F , $6465 , $15C0 , $46 , $4 , $1442 , $26 , $61 , $32B4 , $628F , $6975 , $646C , $445F 
' 33C0 
  word $7665 , $654B , $6E72 , $6C65 , $4A , $1 , $33B8 , $7389 , $7265 , $6C66 , $6761 , $3F73 , $10D6 , $5D , $C8 , $F66 
' 33E0 
  word $DE2 , $61 , $33CE , $738B , $7265 , $6573 , $6674 , $616C , $7367 , $10D6 , $5D , $C8 , $F66 , $E20 , $61 , $33E6 
' 3400 
  word $738C , $7265 , $6573 , $646E , $7262 , $6165 , $6B , $10D6 , $5D , $C4 , $F66 , $E20 , $61 , $3400 , $248B , $5F43 
' 3420 
  word $5F61 , $6F64 , $6176 , $6C72 , $4A , $4D , $341C , $2490 , $5F43 , $5F61 , $785F , $7361 , $326D , $313E , $4D49 , $6E4D 
' 3440 
  word $4A , $13 , $342E , $248D , $5F43 , $5F61 , $785F , $7361 , $326D , $313E , $4A , $16 , $3446 , $248B , $5F43 , $5F61 
' 3460 
  word $6F64 , $6F63 , $6C6E , $4A , $52 , $345A , $2488 , $5F43 , $7372 , $6F54 , $2070 , $4A , $112 , $346C , $2488 , $5F43 
' 3480 
  word $7473 , $6F54 , $6970 , $4A , $F2 , $347C , $2488 , $5F43 , $7473 , $4F54 , $6753 , $4A , $CB , $348C , $2488 , $5F43 
' 34A0 
  word $7372 , $7450 , $D72 , $4A , $CA , $349C , $2488 , $5F43 , $7473 , $7450 , $3B72 , $4A , $C9 , $34AC , $6C86 , $7361 
' 34C0 
  word $6974 , $653F , $CCE , $28 , $5D , $2 , $28 , $14A0 , $ED0 , $61 , $34BC , $2382 , $7243 , $CBA , $138E , $1566 
' 34E0 
  word $12CE , $E2C , $61 , $34D6 , $5F83 , $646E , $1326 , $DFA , $5D , $28 , $F5A , $F12 , $8D , $A , $5D , $6 
' 3500 
  word $46 , $6A , $5D , $F , $F5A , $F12 , $8D , $A , $5D , $8 , $46 , $56 , $5D , $9 , $F5A , $F12 
' 3520 
  word $8D , $A , $5D , $A , $46 , $42 , $5D , $7 , $F5A , $F12 , $8D , $A , $5D , $B , $46 , $2E 
' 3540 
  word $5D , $6 , $F5A , $F12 , $8D , $A , $5D , $C , $46 , $1A , $5D , $3 , $F5A , $F12 , $8D , $A 
' 3560 
  word $5D , $10 , $46 , $6 , $5D , $20 , $1526 , $FEA , $329E , $FEA , $1476 , $8D , $4 , $14A0 , $61 , $34E8 
' 3580 
  word $5F83 , $7466 , $5D , $4 , $1326 , $DFA , $5D , $8 , $5D , $A , $15AC , $8D , $4 , $14AE , $1504 , $1D10 
' 35A0 
  word $34EC , $CC6 , $79 , $1D76 , $F5A , $1A60 , $14A0 , $FEA , $329E , $26 , $145C , $8D , $10 , $34C4 , $145C , $8D 
' 35C0 
  word $8 , $5D , $5F , $34DA , $80 , $FFDC , $1D1E , $1526 , $61 , $3580 , $5F83 , $6662 , $5D , $4 , $3584 , $61 
' 35E0 
  word $35D4 , $2E85 , $7962 , $6574 , $5D , $FF , $DC8 , $35D8 , $1A40 , $61 , $35E2 , $5F83 , $6677 , $5D , $FFFF , $DC8 
' 3600 
  word $CD6 , $3584 , $61 , $35F6 , $2E85 , $6F77 , $6472 , $35FA , $1A40 , $61 , $3608 , $5F83 , $666C , $CCE , $3584 , $61 
' 3620 
  word $3616 , $2E85 , $6F6C , $676E , $361A , $1A40 , $61 , $3622 , $3482 , $6E2D , $13 , $4 , $10F , $61 , $3630 , $3282 
' 3640 
  word $532A , $13 , $1 , $5F , $61 , $363E , $3482 , $432F , $13 , $2 , $77 , $61 , $364C , $6986 , $766E , $7265 
' 3660 
  word $6174 , $CBA , $F4C , $61 , $365A , $6487 , $6365 , $6D69 , $6C61 , $5D , $A , $1326 , $E38 , $61 , $366A , $6986 
' 3680 
  word $6F62 , $6E75 , $2064 , $CCE , $28 , $61 , $367E , $5F86 , $6F77 , $6472 , $5073 , $CC6 , $7C , $1ACC , $1A4C , $4E26 
' 36A0 
  word $4146 , $2820 , $6F46 , $7472 , $2F68 , $7341 , $206D , $6D49 , $656D , $6964 , $7461 , $2065 , $5865 , $6365 , $7475 , $2965 
' 36C0 
  word $4E20 , $6D61 , $D65 , $1434 , $FEA , $EC4 , $8D , $8 , $18A4 , $46 , $6 , $1442 , $CBA , $8D , $8A , $75 
' 36E0 
  word $EC4 , $145C , $8D , $4 , $15C0 , $14A0 , $5D , $3 , $DC8 , $7C , $EC4 , $360E , $15D0 , $EC4 , $DEE , $EC4 
' 3700 
  word $5D , $80 , $DC8 , $8D , $A , $5D , $46 , $46 , $6 , $5D , $41 , $2D24 , $EC4 , $5D , $40 , $DC8 
' 3720 
  word $8D , $A , $5D , $49 , $46 , $6 , $5D , $20 , $2D24 , $5D , $20 , $DC8 , $8D , $A , $5D , $58 
' 3740 
  word $46 , $6 , $5D , $20 , $2D24 , $15D0 , $EC4 , $1A20 , $EC4 , $DEE , $1250 , $DC8 , $5D , $15 , $FEA , $F34 
' 3760 
  word $CC6 , $F1E , $15E0 , $1ABC , $EC4 , $145C , $8D , $FF58 , $75 , $1450 , $15C0 , $61 , $368E , $7785 , $726F , $7364 
' 3780 
  word $1CA0 , $3696 , $61 , $377A , $7085 , $6E69 , $6E69 , $2558 , $3662 , $D0C , $33 , $DC8 , $D0C , $42 , $61 , $3788 
' 37A0 
  word $7086 , $6E69 , $756F , $6874 , $2558 , $D0C , $33 , $F40 , $D0C , $42 , $61 , $37A0 , $7085 , $6E69 , $6F6C , $2558 
' 37C0 
  word $72 , $61 , $37B8 , $7085 , $6E69 , $6968 , $2558 , $71 , $61 , $37C6 , $7082 , $6E78 , $FEA , $8D , $8 , $37CC 
' 37E0 
  word $46 , $4 , $37BE , $61 , $37D4 , $5F85 , $6473 , $6961 , $5D , $1D , $378E , $61 , $37EA , $5F85 , $6473 , $6F61 
' 3800 
  word $5D , $1D , $37A8 , $61 , $37FA , $5F85 , $6373 , $696C , $5D , $1C , $378E , $61 , $380A , $5F85 , $6373 , $6F6C 
' 3820 
  word $5D , $1C , $37A8 , $61 , $381A , $5F85 , $6473 , $6C61 , $57 , $2064 , $0 , $2000 , $72 , $61 , $382A , $5F85 
' 3840 
  word $6473 , $6861 , $57 , $3D30 , $0 , $2000 , $71 , $61 , $383E , $5F85 , $6373 , $6C6C , $57 , $6568 , $0 , $1000 
' 3860 
  word $72 , $61 , $3852 , $5F85 , $6373 , $686C , $57 , $695B , $0 , $1000 , $71 , $61 , $3866 , $5F85 , $6473 , $3F61 
' 3880 
  word $57 , $665F , $0 , $2000 , $6E , $61 , $387A , $5F88 , $6565 , $7473 , $7261 , $D74 , $386C , $3820 , $3844 , $3800 
' 38A0 
  word $3830 , $3858 , $61 , $388E , $5F87 , $6565 , $7473 , $706F , $386C , $3844 , $3858 , $3810 , $37F0 , $61 , $38A8 , $3185 
' 38C0 
  word $6F6C , $6B63 , $CCE , $1DF8 , $61 , $38BE , $3187 , $6E75 , $6F6C , $6B63 , $CCE , $1E8C , $61 , $38CC , $658B , $7765 
' 38E0 
  word $6972 , $6574 , $6170 , $6567 , $38C4 , $CCE , $F1E , $F72 , $EC4 , $5D , $FF , $DC8 , $FEA , $EC4 , $5D , $8 
' 3900 
  word $FA0 , $5D , $FF , $DC8 , $FEA , $5D , $10 , $FA0 , $5D , $7 , $DC8 , $CCE , $F08 , $3898 , $5D , $A0 
' 3920 
  word $F40 , $2E44 , $FEA , $2E44 , $F40 , $FEA , $2E44 , $F40 , $1504 , $1602 , $79 , $1A60 , $DEE , $2E44 , $F40 , $80 
' 3940 
  word $FFF6 , $38B0 , $5D , $A , $251A , $38D4 , $61 , $38DC , $4583 , $2157 , $FEA , $1276 , $E38 , $1276 , $CD6 , $38E8 
' 3960 
  word $8D , $8 , $5D , $A , $1116 , $61 , $3950 , $7389 , $7661 , $6665 , $726F , $6874 , $2666 , $7708 , $616C , $7473 
' 3980 
  word $666E , $3161 , $1CBA , $8D , $6C , $B02 , $DFA , $EC4 , $DEE , $F66 , $EC4 , $DEE , $14A0 , $FEA , $E2C , $1B56 
' 39A0 
  word $A60 , $DFA , $FEA , $EC4 , $DFA , $F5A , $3954 , $14BC , $EC4 , $5D , $3F , $DC8 , $145C , $8D , $FFEA , $79 
' 39C0 
  word $3686 , $1A60 , $F34 , $5D , $40 , $F2A , $EC4 , $1A60 , $EC4 , $F72 , $38E8 , $8D , $8 , $5D , $A , $1116 
' 39E0 
  word $13E2 , $8D , $8 , $5D , $2E , $2D24 , $82 , $FFD2 , $46 , $4 , $26 , $13E2 , $8D , $4 , $15C0 , $61 
' 3A00 
  word $396E , $7383 , $3F74 , $1A4C , $5304 , $3A54 , $2020 , $34B6 , $33 , $14BC , $EC4 , $3486 , $F12 , $8D , $40 , $3486 
' 3A20 
  word $FEA , $F34 , $CC6 , $79 , $3486 , $14CA , $1A60 , $F34 , $33 , $EC4 , $1484 , $8D , $18 , $1326 , $DFA , $5D 
' 3A40 
  word $A , $ED0 , $8D , $A , $5D , $2D , $2D24 , $1006 , $3628 , $15D0 , $80 , $FFD2 , $46 , $4 , $26 , $15C0 
' 3A60 
  word $61 , $3A02 , $7382 , $6263 , $3486 , $34B6 , $33 , $F34 , $5D , $3 , $F34 , $13E2 , $8D , $18 , $EC4 , $1DB4 
' 3A80 
  word $1A4C , $690D , $6574 , $736D , $6320 , $656C , $7261 , $6465 , $15C0 , $EC4 , $1492 , $8D , $10 , $CC6 , $79 , $26 
' 3AA0 
  word $80 , $FFFC , $46 , $4 , $26 , $61 , $3A64 , $5F84 , $6E70 , $2F61 , $EC4 , $360E , $5D , $3A , $2D24 , $DFA 
' 3AC0 
  word $EC4 , $360E , $15D0 , $1B56 , $1A20 , $15D0 , $61 , $3AAE , $7084 , $6166 , $6E3F , $EC4 , $1B56 , $EC4 , $DEE , $EC4 
' 3AE0 
  word $5D , $80 , $DC8 , $145C , $FEA , $1250 , $DC8 , $1476 , $F72 , $1AA8 , $F72 , $8D , $4 , $DFA , $F72 , $ED0 
' 3B00 
  word $DC8 , $61 , $3AD0 , $7283 , $3F73 , $1A4C , $5204 , $3A53 , $7220 , $3476 , $34A6 , $33 , $14A0 , $F34 , $CC6 , $79 
' 3B20 
  word $3476 , $14AE , $1A60 , $F34 , $33 , $EC4 , $14CA , $DFA , $3AD6 , $8D , $A , $14CA , $3AB4 , $46 , $6 , $3628 
' 3B40 
  word $15D0 , $80 , $FFDC , $15C0 , $61 , $3B06 , $6C85 , $636F , $3F6B , $5D , $8 , $CC6 , $79 , $1DE6 , $1A60 , $F66 
' 3B60 
  word $DEE , $EC4 , $5D , $4 , $FA0 , $FEA , $5D , $F , $DC8 , $1A4C , $4C06 , $636F , $3A6B , $6820 , $1A60 , $1DB4 
' 3B80 
  word $1434 , $5D , $8 , $F12 , $FEA , $1492 , $DC8 , $8D , $2E , $1A4C , $200F , $4C20 , $636F , $696B , $676E , $6320 
' 3BA0 
  word $676F , $203A , $1DB4 , $1A4C , $200E , $4C20 , $636F , $206B , $6F63 , $6E75 , $3A74 , $7420 , $1DB4 , $46 , $4 , $1442 
' 3BC0 
  word $15C0 , $80 , $FF96 , $61 , $3B4C , $7688 , $7261 , $6169 , $6C62 , $3565 , $28E8 , $1FDA , $3428 , $2026 , $CC6 , $2074 
' 3BE0 
  word $20A6 , $28FA , $61 , $3BCA , $6388 , $6E6F , $7473 , $6E61 , $3E74 , $28E8 , $1FDA , $3466 , $2026 , $2074 , $20A6 , $28FA 
' 3C00 
  word $61 , $3BE8 , $6183 , $7362 , $1C , $151 , $61 , $3C04 , $6185 , $646E , $2143 , $EC4 , $DEE , $F72 , $DC8 , $FEA 
' 3C20 
  word $E2C , $61 , $3C10 , $7283 , $7665 , $16 , $79 , $61 , $3C26 , $7284 , $7665 , $7362 , $5D , $18 , $3C2A , $61 
' 3C40 
  word $3C32 , $7083 , $3F78 , $2558 , $6E , $61 , $3C42 , $7787 , $6961 , $6374 , $746E , $16 , $1F1 , $61 , $3C4E , $7787 
' 3C60 
  word $6961 , $7074 , $7165 , $21 , $1E0 , $61 , $3C5E , $7787 , $6961 , $7074 , $656E , $21 , $1E8 , $61 , $3C6E , $6A81 
' 3C80 
  word $34A6 , $33 , $5D , $5 , $F66 , $33 , $61 , $3C7E , $7586 , $2F2A , $6F6D , $6164 , $1504 , $2926 , $F72 , $2972 
' 3CA0 
  word $61 , $3C90 , $7583 , $2F2A , $1504 , $2926 , $F72 , $2972 , $1526 , $61 , $3CA4 , $7384 , $6769 , $6F6E , $F4C , $57 
' 3CC0 
  word $0 , $8000 , $DC8 , $61 , $3CB6 , $2A81 , $2926 , $26 , $61 , $3CCA , $2A85 , $6D2F , $646F , $1434 , $3CBC , $7C 
' 3CE0 
  word $3C08 , $F72 , $EC4 , $75 , $3CBC , $7C , $3C08 , $F72 , $3C08 , $2926 , $F72 , $2972 , $75 , $8D , $A , $1006 
' 3D00 
  word $FEA , $1006 , $FEA , $61 , $3CD4 , $2A82 , $782F , $3CDA , $1526 , $61 , $3D0A , $2F84 , $6F6D , $6864 , $1434 , $3CBC 
' 3D20 
  word $7C , $3C08 , $FEA , $3C08 , $FEA , $329E , $75 , $8D , $A , $1006 , $FEA , $1006 , $FEA , $61 , $3D16 , $2F81 
' 3D40 
  word $3D1C , $1526 , $61 , $3D3E , $2888 , $6F66 , $6772 , $7465 , $D29 , $EC4 , $8D , $30 , $1CBA , $8D , $16 , $1B56 
' 3D60 
  word $1A9A , $EC4 , $A60 , $E38 , $DFA , $A54 , $E38 , $46 , $12 , $13E2 , $8D , $C , $1A40 , $5D , $3F , $2D24 
' 3D80 
  word $15C0 , $46 , $4 , $26 , $61 , $3D48 , $6686 , $726F , $6567 , $4374 , $1CA0 , $3D52 , $61 , $3D8C , $658A , $7265 
' 3DA0 
  word $6165 , $7064 , $6761 , $5F65 , $38C4 , $CCE , $F1E , $F72 , $EC4 , $5D , $FF , $DC8 , $FEA , $EC4 , $5D , $8 
' 3DC0 
  word $FA0 , $5D , $FF , $DC8 , $FEA , $5D , $10 , $FA0 , $5D , $7 , $DC8 , $CCE , $F08 , $EC4 , $7C , $3898 
' 3DE0 
  word $5D , $A0 , $F40 , $2E44 , $FEA , $2E44 , $F40 , $FEA , $2E44 , $F40 , $3898 , $75 , $5D , $A1 , $F40 , $2E44 
' 3E00 
  word $F40 , $1504 , $1602 , $79 , $34C4 , $2DB6 , $1A60 , $E2C , $80 , $FFF6 , $38B0 , $38D4 , $61 , $3D9C , $4583 , $4057 
' 3E20 
  word $1276 , $CD6 , $3DA8 , $8D , $8 , $5D , $B , $1116 , $1276 , $DFA , $61 , $3E1C , $4583 , $4043 , $3E20 , $5D 
' 3E40 
  word $FF , $DC8 , $61 , $3E38 , $2887 , $7564 , $706D , $2962 , $15C0 , $F5A , $360E , $15D0 , $EC4 , $360E , $230E , $1602 
' 3E60 
  word $61 , $3E48 , $2887 , $7564 , $706D , $296D , $15C0 , $360E , $230E , $61 , $3E64 , $2887 , $7564 , $706D , $2965 , $1294 
' 3E80 
  word $5D , $10 , $1602 , $79 , $1A60 , $DEE , $35E8 , $15D0 , $80 , $FFF6 , $5D , $2 , $15E0 , $1294 , $5D , $10 
' 3EA0 
  word $1602 , $79 , $1A60 , $DEE , $EC4 , $CB0 , $5D , $7E , $15AC , $3662 , $8D , $8 , $26 , $5D , $2E , $2D24 
' 3EC0 
  word $80 , $FFE2 , $61 , $3E76 , $6484 , $6D75 , $2070 , $3E50 , $79 , $1A60 , $3E6C , $1A60 , $1294 , $5D , $10 , $18F8 
' 3EE0 
  word $3E7E , $5D , $10 , $82 , $FFEA , $15C0 , $61 , $3EC8 , $6585 , $7564 , $706D , $3E50 , $79 , $1A60 , $3E6C , $1A60 
' 3F00 
  word $1294 , $5D , $10 , $3DA8 , $8D , $C , $1294 , $5D , $10 , $CC6 , $1A7C , $3E7E , $5D , $10 , $82 , $FFDC 
' 3F20 
  word $15C0 , $61 , $3EF0 , $6387 , $676F , $7564 , $706D , $15C0 , $F5A , $360E , $15D0 , $EC4 , $360E , $230E , $1602 , $79 
' 3F40 
  word $15C0 , $1A60 , $360E , $230E , $1A60 , $5D , $4 , $1602 , $79 , $1A60 , $33 , $3628 , $15D0 , $80 , $FFF6 , $5D 
' 3F60 
  word $4 , $82 , $FFDC , $15C0 , $61 , $3F26 , $2E86 , $6F63 , $6367 , $D68 , $EC4 , $CBA , $ED0 , $8D , $10 , $1442 
' 3F80 
  word $1A4C , $5804 , $5828 , $D29 , $46 , $1A , $1D10 , $5D , $29 , $34DA , $1D76 , $5D , $28 , $34DA , $26 , $1D76 
' 3FA0 
  word $1D1E , $1A40 , $61 , $3F6C , $698A , $3E6F , $6F63 , $6367 , $6168 , $776E , $EC4 , $B7C , $EC4 , $B1E , $5D , $3 
' 3FC0 
  word $F08 , $F66 , $15AC , $8D , $22 , $B7C , $F34 , $B1E , $329E , $5D , $7 , $DC8 , $EC4 , $13FA , $F72 , $5D 
' 3FE0 
  word $4 , $32AC , $F2A , $46 , $8 , $26 , $CBA , $EC4 , $61 , $3FA8 , $6384 , $676F , $203F , $5D , $8 , $CC6 
' 4000 
  word $79 , $1A4C , $4304 , $676F , $703A , $1A60 , $EC4 , $1DB4 , $1A4C , $200A , $6923 , $206F , $6863 , $6E61 , $653A , $EC4 
' 4020 
  word $13FA , $1DB4 , $1314 , $DFA , $B02 , $DFA , $DEE , $F5A , $DEE , $F34 , $15E0 , $1A40 , $1A60 , $10D6 , $1A60 , $13FA 
' 4040 
  word $CC6 , $79 , $1A60 , $14E6 , $F5A , $F66 , $14BC , $DFA , $EC4 , $145C , $8D , $8 , $26 , $46 , $16 , $15D0 
' 4060 
  word $15D0 , $3C80 , $1A60 , $3F74 , $1A4C , $2D02 , $6E3E , $3FB4 , $3F74 , $80 , $FFD0 , $26 , $15C0 , $80 , $FF86 , $61 
' 4080 
  word $3FF4 , $6286 , $6975 , $646C , $203F , $15C0 , $2666 , $6206 , $6975 , $646C , $675F , $3696 , $15C0 , $B02 , $DFA , $1A40 
' 40A0 
  word $15C0 , $61 , $4082 , $6684 , $6572 , $5B65 , $A6E , $DFA , $A60 , $DFA , $F34 , $1DB4 , $1A4C , $620D , $7479 , $7365 
' 40C0 
  word $6620 , $6572 , $2065 , $202D , $CE0 , $137E , $DFA , $F34 , $1DB4 , $1A4C , $630E , $676F , $6C20 , $6E6F , $7367 , $6620 
' 40E0 
  word $6572 , $6F65 , $15C0 , $61 , $40A6 , $7283 , $646E , $CEA , $33 , $5D , $8 , $FA0 , $CEA , $33 , $F4C , $5D 
' 4100 
  word $FF , $DC8 , $61 , $40EA , $7285 , $646E , $6674 , $40EE , $5D , $7F , $EE4 , $61 , $4108 , $2E88 , $6F63 , $776E 
' 4120 
  word $6961 , $5774 , $B5A , $10D6 , $5D , $200 , $CC6 , $79 , $EC4 , $DFA , $5D , $100 , $DC8 , $8D , $4 , $20DA 
' 4140 
  word $80 , $FFEE , $26 , $61 , $411A , $2E88 , $6F63 , $656E , $696D , $2D74 , $4124 , $B5A , $10D6 , $E38 , $61 , $414A 
' 4160 
  word $2E88 , $6F63 , $636E , $7473 , $7472 , $163C , $EC4 , $8D , $14 , $1602 , $79 , $1A60 , $DEE , $4154 , $80 , $FFF8 
' 4180 
  word $46 , $4 , $1442 , $61 , $4160 , $2E84 , $6F63 , $326E , $1D10 , $1D92 , $1D1E , $416A , $CB0 , $4154 , $61 , $418A 
' 41A0 
  word $2E86 , $6F63 , $636E , $6572 , $5D , $D , $4154 , $61 , $41A0 , $2E88 , $6F63 , $626E , $7479 , $7265 , $35D8 , $416A 
' 41C0 
  word $61 , $41B2 , $2E88 , $6F63 , $776E , $726F , $D64 , $35FA , $416A , $61 , $41C4 , $2E88 , $6F63 , $6C6E , $6E6F , $2067 
' 41E0 
  word $361A , $416A , $61 , $41D6 , $2E87 , $6F63 , $736E , $3F74 , $2666 , $5304 , $3A54 , $6920 , $416A , $34B6 , $33 , $14BC 
' 4200 
  word $EC4 , $3486 , $F12 , $8D , $42 , $3486 , $FEA , $F34 , $CC6 , $79 , $3486 , $14CA , $1A60 , $F34 , $33 , $EC4 
' 4220 
  word $1484 , $8D , $18 , $1326 , $DFA , $5D , $A , $ED0 , $8D , $A , $5D , $2D , $4154 , $1006 , $41E0 , $CB0 
' 4240 
  word $4154 , $80 , $FFD0 , $46 , $4 , $26 , $41A8 , $61 , $41E8 , $6F87 , $726E , $7365 , $7465 , $EC4 , $28C6 , $13E2 
' 4260 
  word $FEA , $EC4 , $145C , $8D , $C , $2666 , $2003 , $6B6F , $46 , $1BA , $EC4 , $CCE , $ED0 , $8D , $1E , $2666 
' 4280 
  word $2014 , $414D , $4E49 , $5320 , $4154 , $4B43 , $4F20 , $4556 , $4652 , $4F4C , $7457 , $46 , $194 , $EC4 , $5D , $2 
' 42A0 
  word $ED0 , $8D , $20 , $2666 , $2016 , $4552 , $5554 , $4E52 , $5320 , $4154 , $4B43 , $4F20 , $4556 , $4652 , $4F4C , $7457 
' 42C0 
  word $46 , $16A , $EC4 , $5D , $3 , $ED0 , $8D , $1E , $2666 , $2015 , $414D , $4E49 , $5320 , $4154 , $4B43 , $5520 
' 42E0 
  word $444E , $5245 , $4C46 , $574F , $46 , $142 , $EC4 , $5D , $4 , $ED0 , $8D , $20 , $2666 , $2017 , $4552 , $5554 
' 4300 
  word $4E52 , $5320 , $4154 , $4B43 , $5520 , $444E , $5245 , $4C46 , $574F , $46 , $118 , $EC4 , $5D , $5 , $ED0 , $8D 
' 4320 
  word $1A , $2666 , $2011 , $554F , $2054 , $464F , $4620 , $4552 , $2045 , $4F43 , $5347 , $46 , $F4 , $EC4 , $5D , $6 
' 4340 
  word $ED0 , $8D , $1E , $2666 , $2014 , $4F4C , $4B43 , $4320 , $554F , $544E , $4F20 , $4556 , $4652 , $4F4C , $6157 , $46 
' 4360 
  word $CC , $EC4 , $5D , $7 , $ED0 , $8D , $16 , $2666 , $200D , $4F4C , $4B43 , $5420 , $4D49 , $4F45 , $5455 , $46 
' 4380 
  word $AC , $EC4 , $5D , $8 , $ED0 , $8D , $16 , $2666 , $200D , $4E55 , $4F4C , $4B43 , $4520 , $5252 , $524F , $46 
' 43A0 
  word $8C , $EC4 , $5D , $9 , $ED0 , $8D , $22 , $2666 , $2018 , $554F , $2054 , $464F , $4620 , $4552 , $2045 , $414D 
' 43C0 
  word $4E49 , $4D20 , $4D45 , $524F , $2059 , $46 , $60 , $EC4 , $5D , $A , $ED0 , $8D , $1C , $2666 , $2013 , $4545 
' 43E0 
  word $5250 , $4D4F , $5720 , $4952 , $4554 , $4520 , $5252 , $524F , $46 , $3A , $EC4 , $5D , $B , $ED0 , $8D , $1C 
' 4400 
  word $2666 , $2012 , $4545 , $5250 , $4D4F , $5220 , $4145 , $2044 , $5245 , $4F52 , $6952 , $46 , $14 , $2666 , $200F , $4E55 
' 4420 
  word $4E4B , $574F , $204E , $5245 , $4F52 , $2052 , $F72 , $8D , $88 , $13E2 , $8D , $7C , $AF4 , $DFA , $121A , $1938 
' 4440 
  word $AA2 , $DFA , $1D10 , $1D92 , $1D1E , $121A , $194C , $2666 , $2004 , $6F43 , $6F67 , $121A , $194C , $1DD0 , $121A , $197C 
' 4460 
  word $2666 , $2016 , $4552 , $4553 , $2054 , $202D , $616C , $7473 , $7320 , $6174 , $7574 , $3A73 , $3420 , $121A , $194C , $FEA 
' 4480 
  word $1D10 , $1D92 , $1D1E , $121A , $194C , $121A , $194C , $1F36 , $41A8 , $2666 , $4304 , $4E4F , $693A , $416A , $121A , $416A 
' 44A0 
  word $41A8 , $15C0 , $121A , $1A40 , $15C0 , $1F46 , $2AC8 , $46 , $4 , $1442 , $46 , $4 , $1442 , $61 

  word 0, 0, 0
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


