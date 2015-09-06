

{{

Copyright (c) 2010 Sal Sanci

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

-----------------------------------------------------------------------------
NOTICE:
20100905 Propforth 3.4 - 2010 sept 05 
the comments in this block have not been updated and may only apply to v2.4
See GOOGLE CODE for newer documentation and to ask questions
-----------------------------------------------------------------------------

Yet Another Forth

PropForth is built on SpinForth and is really rev 2 of SpinForth. There have been many changes. As opposed to describing
them all, suffice it to say PropForth is really tuned to freeing up as many cog longs as possible. Found this was the
resource that was of most limit. Of course this is always traded against performance, and the performance considered
was compile performance.

This forth is case sensitive!!!!!! BIG CHANGE!

By default there are now 161 longs free in the cog. The stacks are still in the cogs, and this takes up 64 longs,
32 for the data stack and 32 for the return stack. Found this tradeoff to be worth it.

The core of function is kept small, and functions like debugging can be loaded in if they are needed.

There is a forth time slicer available for background tasks, and it can respond to items that are need service
on the order of hundreds of milliseconds or more.

It is a cooperative time slicer and works by long running routines calling _fslice. The forth kernel words
key? emit?  all call _fslice.

When PropForth starts, cog 0 is the spin cog which starts everything up, and then loads the serial driver (57.6Kb if you need
different modify in the main spin startup routine), in cog 7 and starts cogs 5 and 6 as a PropForth cogs.


There is a coopreative time slicer for the assembler, aslicer.

57.6K Baud is ok no delays necessary.

THIS IS NOT AN ANSI FORTH!
It is a minimal forth tuned for the propeller. However most words adhere to the ANSI standard.

Locks 0 - 1 are allocated by the spin startup code are by forth.
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
Memory accesses in forth are ! (store) and @ (fetch). All memory access to the cog are long. They are done via ! and @

Naming conventions:

cog:
  a_xxx - a forth word, an address poiting to code which can be executed as forth word
  c_xxx - cog code, point to code, but can not be executed as a forth word, for instance a subroutine
  v_xxx - a cog long, points to a variable

The execption to this is the special cog registers, which are named exactly as they are in the propeller
documentation. eg par, phsa, ctra, etc.

Of course given the nature of self-modifying code, these names may be used otherwise


cogdata:

Each cog has a 256 byte area assigned to it, and this area is used forth cog specific data. Though this are is in
main memory there is an agreed upon isolation. When a cog is started the par register points to this 256 byte area.

The forth dictionary is stored in main memory and is shared. So updating the dictionary requires it be
locked so only one cog at a time can update the dictionary. Variables can be defined in the dictionary
or in the cog.

In the cog, there is only a long variable accessed via COG@ and COG!

In main memory, variables can be a long (32 bits), a word (16 bits). The most efficient
are words. This forth is implemented using words. Longs need to be long aligned and can waste bytes.


main memory:

Main memory can be accessed as a long, L! L@, a word, W! W@, and as a character C! C@ ,

There is an area of main memory reserved for each cog, the cogdata area. The PAR register is
initialized with the start of the 256 bytes allocated to each cog. This area is where IO communcation is done,
and system variables for each cog are stored.                   
              
There is stack and return stack checking for overflow and underflow.
For the stack, this only occurs on words which access more then the top item on the stack.
So using c@ with an empty stack will return a value and not trigger stack checking. However
c! with an empty stack will trigger a stack underflow.
Trade between size performance and error checking, seemed reasonable.

EEPROM is accessed as words with EW@ and EW! byte can be read from eepron via EC@


}}
CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _cogDataSize = 256
  _wordMASK = $FFFF
  _buffer_length = 256                 'can be 2, 4, 8, 16, 32, 64, 128, 256
  _buffer_mask   = _buffer_length - 1



VAR

OBJ
' for the vgahires text driver
  vgatext : "vga_hires_text"
PUB Main | tmp
{{
Start the serial port rx pin - 31, tx pin - 30, 115KBaud                                                  
If ok start forth, providing we can can a lock resource
}}
' allocate locks 0 and 1 for PropForth 
  tmp := locknew
  tmp := locknew
' initialize the cog variables
  stPtr := ((@stTop - @a_base) /4) - 1
  rsPtr := ((@rsTop - @a_base) /4) - 1
  IP := WORD[ @dlrH_fstartPFA + 2]

' and the memory variables
  if WORD[ @herePFA + 2] == 0
    WORD[ @herePFA + 2] := @wfreespacestart
  WORD[ @_forthinitializedPFA + 2] := 0
  
'  WORD[ @dictendPFA + 2] := @ForthDictEnd
'  WORD[ @memendPFA + 2] := @ForthMemoryEnd

  WORD[ @dictendPFA + 2] := $6000
  WORD[ @memendPFA + 2] := $6000
  
' start up the serial driver on cog 7 
  v_bitticks := clkfreq / 57600
  v_rxmask := 1 << 31 
  v_txmask := 1 << 30
  v_rxbuff := @serentryPFA
  v_in := @inCONPFA + 2
  v_out := @outCONPFA + 2
  coginit(7, @serentryPFA, @cogdataPFA + (7 * _cogDataSize))
  
' start 2 forth cogs
  WORD[ @_fcogPFA + 2] := 5
  WORD[ @_lcogPFA + 2] := 6
  coginit(6, @entryPFA, @cogdataPFA + (6 * _cogDataSize))
  coginit(5, @entryPFA, @cogdataPFA + (5 * _cogDataSize))

'set up colors  BACKGROUND FOREGROUND
'               RRGGBB00   RRGGBB00
'               00001100   11111100  $0CFC blue/white
  wordfill( @cogdataPFA + _cogDataSize, $0CFC, 64)

'start vga text driver, cogs 1 & 2, cog 0 will be restarted as a forth cog
'
' screen at $6000
' color map at cogdata area 1
' sync long at cogdata area 1 +$80
' font pointer at cogdata area 1 +$84
' cx0,cx1 long at cogdata area 1 + $86 - $89 & $96 - $99
' 16 word colorsmap at cogdata area 1 + $A6 ($A6 - $C6)
' 
  WORD[ @cogdataPFA+_cogDataSize+$84] := @font 
  WORD[ @cogdataPFA+_cogDataSize+$A6] := $FC00 ' white/black 
  WORD[ @cogdataPFA+_cogDataSize+$A8] := $FCC0 ' white/red 
  WORD[ @cogdataPFA+_cogDataSize+$AA] := $FC30 ' white/green 
  WORD[ @cogdataPFA+_cogDataSize+$AC] := $FC0C ' white/blue 
  WORD[ @cogdataPFA+_cogDataSize+$AE] := $00FC ' black/white 
  WORD[ @cogdataPFA+_cogDataSize+$B0] := $00C0 ' black/red 
  WORD[ @cogdataPFA+_cogDataSize+$B2] := $0030 ' black/green 
  WORD[ @cogdataPFA+_cogDataSize+$B4] := $000C ' black/blue 
  WORD[ @cogdataPFA+_cogDataSize+$B6] := $0CFC ' dark blue/white 
  WORD[ @cogdataPFA+_cogDataSize+$B8] := $50F0 ' brown/yellow 
  WORD[ @cogdataPFA+_cogDataSize+$BA] := $0088 ' black/magenta 
  WORD[ @cogdataPFA+_cogDataSize+$BC] := $FC54 ' white/grey 
  WORD[ @cogdataPFA+_cogDataSize+$BE] := $143C ' dark cyan/cyan 
  WORD[ @cogdataPFA+_cogDataSize+$C0] := $B820 ' grey green/green 
  WORD[ @cogdataPFA+_cogDataSize+$C2] := $D440 ' pink/red 
  WORD[ @cogdataPFA+_cogDataSize+$C4] := $3C0C ' cyan/blue 
  WORD[ @_scogPFA + 2] := 3

' select first pin for VGA output

' demoboad pinout 16:23
  vgatext.start(16, $6000, @cogdataPFA+_cogDataSize,@cogdataPFA+_cogDataSize+$86,@cogdataPFA+_cogDataSize+$80,@font)
' HIVE pinout 8:15
'  vgatext.start(8, $6000, @cogdataPFA+_cogDataSize,@cogdataPFA+_cogDataSize+$86,@cogdataPFA+_cogDataSize+$80,@font)

  coginit(0, @entryPFA, @cogdataPFA)

{  
' this word should be set to the last spin cog +1, 0 means there are no spin cogs   
  WORD[ @_scogPFA + 2] := 0
' stop the spin cog 
  cogstop( 0)
}    

DAT

' 8 x 12 font - characters 0..127
'
' Each long holds four scan lines of a single character. The longs are arranged into
' groups of 128 which represent all characters (0..127). There are three groups which
' each contain a vertical third of all characters. They are ordered top, middle, and
' bottom.

font  long

long  $0C080000,$30100000,$7E3C1800,$18181800,$81423C00,$99423C00,$8181FF00,$E7C3FF00  'top
long  $1E0E0602,$1C000000,$00000000,$00000000,$18181818,$18181818,$00000000,$18181818
long  $00000000,$18181818,$18181818,$18181818,$18181818,$00FFFF00,$CC993366,$66666666
long  $AA55AA55,$0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$00000000,$00000000,$00000000
long  $00000000,$3C3C1800,$77666600,$7F363600,$667C1818,$46000000,$1B1B0E00,$1C181800
long  $0C183000,$180C0600,$66000000,$18000000,$00000000,$00000000,$00000000,$60400000
long  $73633E00,$1E181000,$66663C00,$60663C00,$3C383000,$06067E00,$060C3800,$63637F00
long  $66663C00,$66663C00,$1C000000,$00000000,$18306000,$00000000,$180C0600,$60663C00
long  $63673E00,$66663C00,$66663F00,$63663C00,$66361F00,$06467F00,$06467F00,$63663C00
long  $63636300,$18183C00,$30307800,$36666700,$06060F00,$7F776300,$67636300,$63361C00
long  $66663F00,$63361C00,$66663F00,$66663C00,$185A7E00,$66666600,$66666600,$63636300
long  $66666600,$66666600,$31637F00,$0C0C3C00,$03010000,$30303C00,$361C0800,$00000000
long  $0C000000,$00000000,$06060700,$00000000,$30303800,$00000000,$0C6C3800,$00000000
long  $06060700,$00181800,$00606000,$06060700,$18181E00,$00000000,$00000000,$00000000
long  $00000000,$00000000,$00000000,$00000000,$0C080000,$00000000,$00000000,$00000000
long  $00000000,$00000000,$00000000,$18187000,$18181800,$18180E00,$73DBCE00,$18180000

long  $080C7E7E,$10307E7E,$18181818,$7E181818,$81818181,$99BDBDBD,$81818181,$E7BD99BD  'middle
long  $1E3E7E3E,$1C3E3E3E,$30F0C000,$0C0F0300,$00C0F030,$00030F0C,$00FFFF00,$18181818
long  $18FFFF00,$00FFFF18,$18F8F818,$181F1F18,$18FFFF18,$00FFFF00,$CC993366,$66666666
long  $AA55AA55,$FFFF0F0F,$F0F00F0F,$0F0F0F0F,$00000F0F,$FFFF0000,$F0F00000,$0F0F0000
long  $00000000,$0018183C,$00000033,$7F363636,$66603C06,$0C183066,$337B5B0E,$0000000C
long  $0C060606,$18303030,$663CFF3C,$18187E18,$00000000,$00007E00,$00000000,$060C1830
long  $676F6B7B,$18181818,$0C183060,$60603860,$307F3336,$60603E06,$66663E06,$0C183060
long  $66763C6E,$60607C66,$1C00001C,$00001C1C,$180C060C,$007E007E,$18306030,$00181830
long  $033B7B7B,$66667E66,$66663E66,$63030303,$66666666,$06263E26,$06263E26,$63730303
long  $63637F63,$18181818,$33333030,$36361E36,$66460606,$63636B7F,$737B7F6F,$63636363
long  $06063E66,$7B636363,$66363E66,$66301C06,$18181818,$66666666,$66666666,$366B6B63
long  $663C183C,$18183C66,$43060C18,$0C0C0C0C,$30180C06,$30303030,$00000063,$00000000
long  $0030381C,$333E301E,$6666663E,$0606663C,$3333333E,$067E663C,$0C0C3E0C,$3333336E
long  $66666E36,$1818181C,$60606070,$361E3666,$18181818,$6B6B6B3F,$6666663E,$6666663C
long  $6666663B,$3333336E,$066E7637,$300C663C,$0C0C0C7E,$33333333,$66666666,$6B6B6363
long  $1C1C3663,$66666666,$0C30627E,$180C060C,$18181818,$18306030,$00000000,$0018187E

long  $00000000,$00000000,$00001818,$0000183C,$00003C42,$00003C42,$0000FF81,$0000FFC3  'bottom
long  $0002060E,$00000000,$18181818,$18181818,$00000000,$00000000,$00000000,$18181818
long  $18181818,$00000000,$18181818,$18181818,$18181818,$00FFFF00,$CC993366,$66666666
long  $AA55AA55,$FFFFFFFF,$F0F0F0F0,$0F0F0F0F,$00000000,$FFFFFFFF,$F0F0F0F0,$0F0F0F0F
long  $00000000,$00001818,$00000000,$00003636,$0018183E,$00006266,$00006E3B,$00000000
long  $00003018,$0000060C,$00000000,$00000000,$0C181C1C,$00000000,$00001C1C,$00000103
long  $00003E63,$00007E18,$00007E66,$00003C66,$00007830,$00003C66,$00003C66,$00000C0C
long  $00003C66,$00001C30,$0000001C,$0C181C1C,$00006030,$00000000,$0000060C,$00001818
long  $00003E07,$00006666,$00003F66,$00003C66,$00001F36,$00007F46,$00000F06,$00007C66
long  $00006363,$00003C18,$00001E33,$00006766,$00007F66,$00006363,$00006363,$00001C36
long  $00000F06,$00603C36,$00006766,$00003C66,$00003C18,$00003C66,$0000183C,$00003636
long  $00006666,$00003C18,$00007F63,$00003C0C,$00004060,$00003C30,$00000000,$FFFF0000
long  $00000000,$00006E33,$00003B66,$00003C66,$00006E33,$00003C66,$00001E0C,$1E33303E
long  $00006766,$00007E18,$3C666660,$00006766,$00007E18,$00006B6B,$00006666,$00003C66
long  $0F063E66,$78303E33,$00000F06,$00003C66,$0000386C,$00006E33,$0000183C,$00003636
long  $00006336,$1C30607C,$00007E46,$00007018,$00001818,$00000E18,$00000000,$0000007E

'***********************************
'* Assembly language serial driver *
'***********************************

                        org     0
'
'
' Entry
'
serentryPFA
                        mov     task1Ptr,#transmit
                        mov     task2Ptr,#task2Code
                        or dira , v_txmask
'
' Receive
'
receive                 jmpret  task0Ptr, task1Ptr         'run a chunk of transmit code, then return

                        test    v_rxmask , ina  wz
              if_nz     jmp     # receive

                        mov     rxbits , # 9             'ready to receive byte
                        mov     rxcnt , v_bitticks
                        mov     rxcnt , cnt             '+ the current clock             

:bit                    add     rxcnt , v_bitticks        'ready for the middle of the bit period

:wait                   jmpret  task0Ptr, task1Ptr         'run a chuck of transmit code, then return

                        mov     t1 , rxcnt              'check if bit receive period done
                        sub     t1 , cnt
                        cmps    t1 , # 0           wc
        if_nc           jmp     #:wait

                        test    v_rxmask , ina      wc    'receive bit on rx pin into carry
                        rcr     rxdata , # 1             'shift carry into receiver
                        djnz    rxbits , # :bit          'go get another bit till done

        if_nc           jmp     # receive              'abort if no stop bit

                        shr     rxdata , # 32-9          'justify and trim received byte
                        and     rxdata , # $FF

                        add     v_rxh , v_rxbuff             'plus the buffer offset
                        wrbyte  rxdata , v_rxh             'write the byte
                        sub     v_rxh , v_rxbuff
                        add     v_rxh ,# 1                 'update rx_head
                        and     v_rxh , # _buffer_mask

                        jmp     # receive              'byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  task1Ptr, task2Ptr         'run a chunk of receive code, then return
                        rdword  txdata, v_in
                        test    txdata, #$100 wz
        if_nz           jmp     #transmit                        
                        mov     t1 , #$100
                        wrword  t1 , v_in

                        or      txdata,#$100          'or in a stop bit
                        shl     txdata,#2
                        or      txdata,#1             'or in a idle line state and a start bit
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                     shr     txdata,#1       wc
                         muxc    outa , v_txmask        
                         add     txcnt , v_bitticks        'ready next cnt

:wait                   jmpret  task1Ptr, task2Ptr         'run a chunk of receive code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

                        jmp     #transmit             'byte done, transmit next byte

task2Code
                        jmpret  task2Ptr, task0Ptr
                        cmp     v_rxh , v_rxt   wz
              if_z      jmp     #task2Code
                        mov     t1 , v_out
                        rdword  t2 , t1         wz
              if_nz     rdword  t3 , t2
              if_nz     test    t3 , # $100     wz
              if_z      jmp     #task2Code

                        add     v_rxt , v_rxbuff             'plus the buffer offset
                        rdbyte  t3 , v_rxt             'write the byte
                        sub     v_rxt , v_rxbuff
                        add     v_rxt ,# 1
                        wrword  t3 , t2                 'update rx_head
                        and     v_rxt , # _buffer_mask        
                        jmp     #task2Code

v_rxh                   long    0
v_rxt                   long    0
v_bitticks              long    0
v_rxmask                long    0
v_txmask                long    0
v_rxbuff                long    0
v_in                    long    0
v_out                   long    0
'
' Uninitialized data
'
                                                
task0Ptr      res     1
task1Ptr      res     1
task2Ptr      res     1
t1                      res     1
t2                      res     1
t3                      res     1

rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1


txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1


a_base 
                        org     0
{{

Assembler Code                        
entry - abs is effectively a nop on stTOS initialized to zero

Assembler routines which correspond to forth words are documented in the forth area

}}                                                                                              
entryPFA

                        jmp     #a_next
a__execasmtwogtone
                        rdword  treg1, IP
                        movi    a__execasmtwogtonei, treg1
                        add     IP, #2
                        call    #a_stpoptreg
a__execasmtwogtonei                        
                        and     stTOS, treg1
                        jmp     #a_next

a__execasmonegtone
                        rdword  treg1, IP
                        movi    a__execasmonegtonei, treg1
                        add     IP, #2
a__execasmonegtonei                        
                        abs     stTOS, stTOS
                        jmp     #a_next

a__execasmtwogtz
                        rdword  treg1, IP
                        movi    a__execasmtwogtzi, treg1
                        add     IP, #2
                        call    #a_stpoptreg
a__execasmtwogtzi                        
                        abs     stTOS, treg1
a_drop
                        call    #a_stPop
                        jmp     #a_next
                        
a_COGat
                        movs    a_COGatget, stTOS
                        nop                             ' necessary, really needs to be documented
a_COGatget              mov     stTOS, stTOS
                        jmp     #a_next           
a_COGbang
                        movd    a_COGbangput, stTOS
                        call    #a_stPop
a_COGbangput            mov     stTOS, stTOS    
                        jmp     #a_drop
a_branch
                        rdword  treg1,IP        ' the next word
                        add     IP, treg1       ' add the offset
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
a_litl               
                        call    #a_stPush
                        add     IP, #3
                        andn    IP, #3          ' align to a long boundary
                        rdlong  stTOS, IP
                        add     IP, #4
                        jmp     #a_next
a_doconl                 
                        call    #a_stPush
                        add     IP, #3
                        andn    IP, #3          ' align to a long boundary
                        rdlong  stTOS, IP
                        jmp     #a_exit
a_dup
                        call    #a_stPush
                        jmp     #a_next

' treg1 - cstr2 (name)
' stTOS - cstr1 (name)
' uses treg2, treg4, and treg5
' z flag set if strings are equal

c_streq
c_streq5
                        mov     treg4 , # $1F
' length of cstr2 (name)
                        rdbyte  treg2 , treg1   wz
' length of cstr2 (name) - truncate to appropriate length
              if_nz     and     treg2 , treg4   wz
' length of cstr1 (name)
              if_nz     rdbyte  treg5 , stTOS   wz
' length of cstr1 (name) - truncate to appropriate length
              if_nz     and     treg5 , treg4   wz
' if either length is 0, move -1 into length of cstr1 to cause a mismatch
              if_z      mov     treg5 , fLongMask
                        cmp     treg2 , treg5   wz
              if_nz     jmp     # c_streq7
a_cstreqloop
                        add     stTOS , # 1
                        rdbyte  treg4 , stTOS
                        add     treg1 , # 1
a_cstreqlp
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        rdbyte  treg5 , treg1
                        cmp     treg4 , treg5   wz
              if_z      djnz    treg2 , # a_cstreqloop
c_streq7
c_streq_ret
                        ret

' a_nameeq (name name -- t/f)
a_nameeq
                        movs    c_streq5 , # $1F
                        jmp     # a_nameeq4
' a_cstreq (cstr1 cstr2 -- t/f)
a_cstreq
                        movs    c_streq5 , # $FF
a_nameeq4
                        call    #a_stpoptreg
' treg1 - cstr2
' stTOS - dict cstr1
                        jmpret  c_streq_ret , # c_streq
                        muxz    stTOS , fLongMask
                        jmp     # a_next

a__dictsearch  
                        call    #a_stpoptreg
                        mov     treg6 , treg1
                        mov     treg3 , stTOS
                        movs    c_streq5 , # $1F
' treg6 - cstr
' treg3 - nfa
a__dictsearchlp
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
' treg1 - nfa
' stTOS - cstr
                        mov     treg1 , treg6
                        mov     stTOS , treg3
                        jmpret  c_streq_ret , # c_streq
              if_nz     jmp     # a__dictsearch2
a__dictsearch1
                        mov     stTOS , treg3
                        jmp     # a_next
a__dictsearch2
                        mov     treg2 , treg3
                        sub     treg2 , # 2
                        rdword  treg3 , treg2   wz
              if_z      jmp     # a__dictsearch1
                        jmp     # a__dictsearchlp
                        
a_eq 
                        call    #a_stpoptreg
                        cmp     treg1, stTOS    wz, wc
                        muxz    stTOS, fLongMask 
                        jmp     #a_next
a_gt
                                                '( n1 n2 -- flag )
                        call    #a_stpoptreg   ' flag is true if and only if n1 is greater than n2
                        cmps    stTOS, treg1    wz, wc
        if_a            neg     stTOS, #1
        if_be           mov     stTOS, #0       
                        jmp     #a_next
a_hubop
                        call    #a_stpoptreg
                        hubop   stTOS, treg1    wr,wc
                        muxc    treg1, fLongMask
                        call    #a_stPush
                        mov     stTOS, treg1
                        jmp     #a_next                                                
a_litw
                        call    #a_stPush       
                        rdword  stTOS, IP
a_litw1                        
                        add     IP, #2
                        jmp     #a_next
a_lt
                                                '( n1 n2 -- flag )
                        call    #a_stpoptreg   ' flag is true if and only if n1 is less than n2
                        cmps    stTOS, treg1    wz, wc
        if_b            neg     stTOS, #1
        if_ae           mov     stTOS, #0
                        jmp     #a_next
a_exit
                        call    #a_rsPop
                        mov     IP, treg5
'                        jmp     #a_next        SINCE WE ARE ALREADY There
a_next
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
a_debugonoff        
        if_never        jmpret a_dum_ret, # a_dum         ' when debug is loaded this address will be patched
                                                
                        rdword  treg1,IP                ' the next word
                        test    treg1, fMask    wz
        if_z            add     IP, #2                  ' if the one of the hi bits is not set, it is an assembler word,  inc IP
        if_z            jmp     treg1
                        rdword  treg1, IP               ' otherwise it is a forth word 
                        mov     treg5, IP
                        add     treg5, #2
                        mov     IP, treg1       
                        call    #a_rsPush
                        jmp     #a_next
a_over
                        call    #a_stpoptreg
                        mov     treg2, stTOS    
                        call    #a_stPush
                        mov     stTOS, treg1
                        call    #a_stPush
                        mov     stTOS, treg2
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
                                                
a_rot
                        call    #a_stpoptreg
                        mov     treg2, stTOS
                        call    #a_stPop
                        mov     treg3, stTOS
                        
                        mov     stTOS, treg2
                        call    #a_stPush
                        mov     stTOS, treg1
                        call    #a_stPush
                        mov     stTOS, treg3
                        jmp     #a_next         
a_rgt
                        call    #a_rsPop
                        call    #a_stPush
                        mov     stTOS, treg5
                        jmp     #a_next
a_twogtr
                        mov     treg5, stTOS
                        call    #a_stPop
                        call    #a_rsPush       
a_gtr
                        mov     treg5, stTOS
                        call    #a_stPop
                        call    #a_rsPush
                        jmp     #a_next
a_lparenlooprparen
                        mov     treg1, #1
                        jmp     #a_lparenpluslooprparen1
a_lparenpluslooprparen
                        call    #a_stpoptreg        
a_lparenpluslooprparen1
                        call    #a_rsPop
                        mov     treg2, treg5
                        call    #a_rsPop
                        add     treg5, treg1
                        cmp     treg2, treg5       wc ,wz
                if_a    call    #a_rsPush               ' branch
                if_a    mov     treg5, treg2            ' branch
                if_a    call    #a_rsPush               ' branch
                if_a    jmp     #a_branch
                        jmp     #a_litw1        

a_swap
                        call    #a_stpoptreg
                        mov     treg2, stTOS
                        mov     stTOS, treg1
                        call    #a_stPush
                        mov     stTOS, treg2
                        jmp     #a_next
                        
a_umstar
                        call    #a_stpoptreg
                        mov     treg4, #0
                        mov     treg2, #0
                        mov     treg3, #0
a_umstarlp                        
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        shr     stTOS, #1      wz,wc 
        if_nc           jmp     #a_umstar1
                        add     treg4, treg1   wc
                        addx    treg2, treg3
a_umstar1                                                
                        shl     treg1, #1      wc
                        rcl     treg3, #1
        if_nz           jmp     #a_umstarlp
                        mov     stTOS, treg4
                        call    #a_stPush                        
                        mov     stTOS, treg2
                        jmp     #a_next
a_umslashmod
                        call    #a_stpoptreg                        
                        mov     treg6, stTOS
                        call    #a_stPop                        
                        mov     treg3, #$40
                        mov     treg2, #0
a_umslashmodlp
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        shl     stTOS, #1       wc      ' dividend
                        rcl     treg6, #1       wc
                                                
                        rcl     treg2, #1       wc               ' hi bit from dividend

        if_c            sub     treg2, treg1                        
        if_nc           cmpsub  treg2, treg1    wc      ' cmp divisor
                                               
                        rcl     treg4, #1               ' treg1 - quotient
                        djnz    treg3, #a_umslashmodlp 
                        mov     stTOS, treg2
                        call    #a_stPush
                        mov     stTOS, treg4
                        jmp     #a_next
a_zbranch
                        call    #a_stpoptreg
                        cmp     treg1, #0       wz      ' is the TOS zero?
                if_z    jmp     #a_branch 
                        jmp     #a_litw1

a_reset
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses will be patched
                        wrlong  fLongMask , par
                        wrword  treg6 , par  
                        coginit resetDreg
                        
{{                        

a_stPush - push stTOS on to stack

}}
a_stPush
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        movd    a_stPush1, stPtr    
                        cmp     stPtr, #stBot           wc
              if_b      mov     treg6 , # $11
              if_b      jmp     # a_reset
a_stPush1               mov     stPtr, stTOS               
                        sub     stPtr, #1
a_stPush_ret                        
                        ret                                  
{{

a_rsPush - push treg5 on to return stack

}}
a_rsPush
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        movd    a_rsPush1, rsPtr    
                        cmp     rsPtr, #rsBot           wc
              if_b      mov     treg6 , # $12
              if_b      jmp     # a_reset
a_rsPush1               mov     treg1, treg5              
                        sub     rsPtr, #1
a_rsPush_ret                        
                        ret

{{

a_stpoptreg - move stTOS to treg1, and pop stTOS from stack

}}
a_stpoptreg                                                    
                        mov     treg1, stTOS    
{{

a_stPop - pop stTOS from stack

}}
a_stPop
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        add     stPtr, #1       
                        movs    a_stPop1, stPtr    
                        cmp     stPtr, #stTop           wc,wz
              if_ae     mov     treg6 , # $21
              if_ae     jmp     # a_reset
a_stPop1                mov     stTOS, stPtr
a_stPop_ret
a_stpoptreg_ret
                        ret                       
                               
{{

a_rsPop - pop treg5 from return stack

}}
a_rsPop
        if_never        jmpret a_stPop_ret, # a_stPop_ret        ' when task manager is loaded these addresses wil be patched
                        add     rsPtr, #1
                        movs    a_rsPop1, rsPtr    
                        cmp     rsPtr, #rsTop           wc,wz
              if_ae     mov     treg6 , # $22
              if_ae     jmp     # a_reset
a_rsPop1
a_dum
                        mov     treg5, treg1
a_dum_ret
a_rsPop_ret                        
                        ret

                               
'
' variables used by the forth interpreter, do not change the order or size -- or if you do, be really careful and update the forth code
'
varStart
fMask                   long    $FE00           ' 0
fAddrMask               long    $7FFF           ' 1
fLongMask               long    $FFFFFFFF       ' 2
resetDreg               long    0               ' 3
IP                      long    0               ' 4
stPtr                   long    0               ' 5
rsPtr                   long    0               ' 6
stTOS                   long    0               ' 7

treg1                   long    0               ' 8 working reg
treg2                   long    0               ' 9 working reg
treg3                   long    0               ' a working reg
treg4                   long    0               ' b working reg
treg5                   long    0               ' c working reg / call parameter reg
treg6                   long    0               ' d working reg
stBot                                           ' e
{{
These variables are overlapped with the cog data area variables to save space
}}
cogdataPFA
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

This data area is used for 2 purposes.
The first is for inByte, outByte, debugCmd and debugValue - these are used to commincate with the spin program
which routes IO to/from the serial port. They can also be used between forths running on different cogs.

The second purpose is for variables which are unique to each instance of forth, like >in, pad, etc...

Variables can be defined here for each forth or in cog memory. Since cog memory is at a premium, "slow" variables
are defined here.

}}
'cogdataPFA              long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 0  
'                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
'                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
'                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 1  
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 2  
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 3  
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 4  
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 5  
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 6  
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0 
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0
                        long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0         ' 256 bytes cog 7  
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
                        -  bit 4 ($20) set if it is an eXecute word - execute this word in interactive mode as well
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
hereNFA                 byte    $84,"here"
herePFA                 word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @hereNFA + $10
dictendNFA              byte    $87,"dictend"
dictendPFA              word    (@a_dovarw - @a_base)/4
                        word    $7EDC

                        word    @dictendNFA + $10
memendNFA               byte    $86,"memend"
memendPFA               word    (@a_dovarw - @a_base)/4
                        word    $7EDC

                        word    @memendNFA + $10
_forthinitializedNFA    byte    $91,"_forthinitialized"
_forthinitializedPFA    word    (@a_dovarw - @a_base)/4
                        word    $FFFF

                        word    @_forthinitializedNFA + $10
_scogNFA                byte    $85,"_scog"
_scogPFA                word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @_scogNFA + $10
_fcogNFA                byte    $85,"_fcog"
_fcogPFA                word    (@a_dovarw - @a_base)/4
                        word    $0005

                        word    @_fcogNFA + $10
_lcogNFA                byte    $85,"_lcog"
_lcogPFA                word    (@a_dovarw - @a_base)/4
                        word    $0006

                        word    @_lcogNFA + $10
dlrH_serentryNFA        byte    $8B,"$H_serentry"
dlrH_serentryPFA        word    (@a_doconw - @a_base)/4
                        word    @serentryPFA  + $10

                        word    @dlrH_serentryNFA + $10
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
dlrC_a_dovarlNFA        byte    $8B,"$C_a_dovarl"
dlrC_a_dovarlPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_dovarl - @a_base)/4

                        word    @dlrC_a_dovarlNFA + $10
dlrC_a_doconlNFA        byte    $8B,"$C_a_doconl"
dlrC_a_doconlPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_doconl - @a_base)/4

                        word    @dlrC_a_doconlNFA + $10
dlrC_a_litlNFA          byte    $89,"$C_a_litl"
dlrC_a_litlPFA          word    (@a_doconw - @a_base)/4
                        word    (@a_litl - @a_base)/4

                        word    @dlrC_a_litlNFA + $10
dlrC_a_debugonoffNFA    byte    $8F,"$C_a_debugonoff"
dlrC_a_debugonoffPFA    word    (@a_doconw - @a_base)/4
                        word    (@a_debugonoff - @a_base)/4

                        word    @dlrC_a_debugonoffNFA + $10
dlrC_a_resetNFA         byte    $8A,"$C_a_reset"
dlrC_a_resetPFA         word    (@a_doconw - @a_base)/4
                        word    (@a_reset - @a_base)/4

                        word    @dlrC_a_resetNFA + $10
dlrC_a__execasmtwogtoneNFA byte    $90,"$C_a__execasm2>1"
dlrC_a__execasmtwogtonePFA word    (@a_doconw - @a_base)/4
                        word    (@a__execasmtwogtone - @a_base)/4

                        word    @dlrC_a__execasmtwogtoneNFA + $10
dlrC_a__execasmonegtoneNFA byte    $90,"$C_a__execasm1>1"
dlrC_a__execasmonegtonePFA word    (@a_doconw - @a_base)/4
                        word    (@a__execasmonegtone - @a_base)/4

                        word    @dlrC_a__execasmonegtoneNFA + $10
dlrC_a__execasmtwogtzNFA byte    $90,"$C_a__execasm2>0"
dlrC_a__execasmtwogtzPFA word    (@a_doconw - @a_base)/4
                        word    (@a__execasmtwogtz - @a_base)/4

                        word    @dlrC_a__execasmtwogtzNFA + $10
dlrC_a_umstarlpNFA      byte    $8D,"$C_a_umstarlp"
dlrC_a_umstarlpPFA      word    (@a_doconw - @a_base)/4
                        word    (@a_umstarlp - @a_base)/4

                        word    @dlrC_a_umstarlpNFA + $10
dlrC_a_umslashmodlpNFA  byte    $91,"$C_a_umslashmodlp"
dlrC_a_umslashmodlpPFA  word    (@a_doconw - @a_base)/4
                        word    (@a_umslashmodlp - @a_base)/4

                        word    @dlrC_a_umslashmodlpNFA + $10
dlrC_a_cstreqlpNFA      byte    $8D,"$C_a_cstreqlp"
dlrC_a_cstreqlpPFA      word    (@a_doconw - @a_base)/4
                        word    (@a_cstreqlp - @a_base)/4

                        word    @dlrC_a_cstreqlpNFA + $10
dlrC_a__dictsearchlpNFA byte    $92,"$C_a__dictsearchlp"
dlrC_a__dictsearchlpPFA word    (@a_doconw - @a_base)/4
                        word    (@a__dictsearchlp - @a_base)/4

                        word    @dlrC_a__dictsearchlpNFA + $10
dlrC_a_stpushNFA        byte    $8B,"$C_a_stpush"
dlrC_a_stpushPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_stpush - @a_base)/4

                        word    @dlrC_a_stpushNFA + $10
dlrC_a_stpush_retNFA    byte    $8F,"$C_a_stpush_ret"
dlrC_a_stpush_retPFA    word    (@a_doconw - @a_base)/4
                        word    (@a_stpush_ret - @a_base)/4

                        word    @dlrC_a_stpush_retNFA + $10
dlrC_a_rspushNFA        byte    $8B,"$C_a_rspush"
dlrC_a_rspushPFA        word    (@a_doconw - @a_base)/4
                        word    (@a_rspush - @a_base)/4

                        word    @dlrC_a_rspushNFA + $10
dlrC_a_rspush_retNFA    byte    $8F,"$C_a_rspush_ret"
dlrC_a_rspush_retPFA    word    (@a_doconw - @a_base)/4
                        word    (@a_rspush_ret - @a_base)/4

                        word    @dlrC_a_rspush_retNFA + $10
dlrC_a_stpopNFA         byte    $8A,"$C_a_stpop"
dlrC_a_stpopPFA         word    (@a_doconw - @a_base)/4
                        word    (@a_stpop - @a_base)/4

                        word    @dlrC_a_stpopNFA + $10
dlrC_a_stpoptregNFA     byte    $8E,"$C_a_stpoptreg"
dlrC_a_stpoptregPFA     word    (@a_doconw - @a_base)/4
                        word    (@a_stpoptreg - @a_base)/4

                        word    @dlrC_a_stpoptregNFA + $10
dlrC_a_stpop_retNFA     byte    $8E,"$C_a_stpop_ret"
dlrC_a_stpop_retPFA     word    (@a_doconw - @a_base)/4
                        word    (@a_stpop_ret - @a_base)/4

                        word    @dlrC_a_stpop_retNFA + $10
dlrC_a_stpoptreg_retNFA byte    $92,"$C_a_stpoptreg_ret"
dlrC_a_stpoptreg_retPFA word    (@a_doconw - @a_base)/4
                        word    (@a_stpoptreg_ret - @a_base)/4

                        word    @dlrC_a_stpoptreg_retNFA + $10
dlrC_a_rspopNFA         byte    $8A,"$C_a_rspop"
dlrC_a_rspopPFA         word    (@a_doconw - @a_base)/4
                        word    (@a_rspop - @a_base)/4

                        word    @dlrC_a_rspopNFA + $10
dlrC_a_rspop_retNFA     byte    $8E,"$C_a_rspop_ret"
dlrC_a_rspop_retPFA     word    (@a_doconw - @a_base)/4
                        word    (@a_rspop_ret - @a_base)/4

                        word    @dlrC_a_rspop_retNFA + $10
dlrC_a_nextNFA          byte    $89,"$C_a_next"
dlrC_a_nextPFA          word    (@a_doconw - @a_base)/4
                        word    (@a_next - @a_base)/4

                        word    @dlrC_a_nextNFA + $10
dlrC_varstartNFA        byte    $8B,"$C_varstart"
dlrC_varstartPFA        word    (@a_doconw - @a_base)/4
                        word    (@varstart - @a_base)/4

                        word    @dlrC_varstartNFA + $10
dlrC_varendNFA          byte    $89,"$C_varend"
dlrC_varendPFA          word    (@a_doconw - @a_base)/4
                        word    (@varend - @a_base)/4

                        word    @dlrC_varendNFA + $10
_cvNFA                  byte    $83,"_cv"
_cvPFA                  word    @dlrC_varstartPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_cvNFA + $10
_fmaskNFA               byte    $86,"_fmask"
_fmaskPFA               word    @zPFA + $10
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fmaskNFA + $10
_faddrmaskNFA           byte    $8A,"_faddrmask"
_faddrmaskPFA           word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_faddrmaskNFA + $10
_flongmaskNFA           byte    $8A,"_flongmask"
_flongmaskPFA           word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_flongmaskNFA + $10
_resetdregNFA           byte    $8A,"_resetdreg"
_resetdregPFA           word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_resetdregNFA + $10
ipNFA                   byte    $82,"ip"
ipPFA                   word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ipNFA + $10
_stptrNFA               byte    $86,"_stptr"
_stptrPFA               word    (@a_litw - @a_base)/4
                        word    $0005
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_stptrNFA + $10
_rsptrNFA               byte    $86,"_rsptr"
_rsptrPFA               word    (@a_litw - @a_base)/4
                        word    $0006
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_rsptrNFA + $10
_sttosNFA               byte    $86,"_sttos"
_sttosPFA               word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_sttosNFA + $10
_tregoneNFA             byte    $86,"_treg1"
_tregonePFA             word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_tregoneNFA + $10
_stbotNFA               byte    $86,"_stbot"
_stbotPFA               word    (@a_litw - @a_base)/4
                        word    $000E
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_stbotNFA + $10
_sttopNFA               byte    $86,"_sttop"
_sttopPFA               word    (@a_litw - @a_base)/4
                        word    $002E
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_sttopNFA + $10
_rsbotNFA               byte    $86,"_rsbot"
_rsbotPFA               word    @_sttopPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_rsbotNFA + $10
_rstopNFA               byte    $86,"_rstop"
_rstopPFA               word    (@a_litw - @a_base)/4
                        word    $004E
                        word    @_cvPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_rstopNFA + $10
blNFA                   byte    $82,"bl"
blPFA                   word    (@a_doconw - @a_base)/4
                        word    $0020

                        word    @blNFA + $10
minusoneNFA             byte    $82,"-1"
minusonePFA             word    (@a_doconl - @a_base)/4
                        long    $FFFFFFFF

                        word    @minusoneNFA + $10
zNFA                    byte    $81,"0"
zPFA                    word    (@a_doconw - @a_base)/4
                        word    $0000

                        word    @zNFA + $10
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
ctraNFA                 byte    $84,"ctra"
ctraPFA                 word    (@a_doconw - @a_base)/4
                        word    $01F8

                        word    @ctraNFA + $10
ctrbNFA                 byte    $84,"ctrb"
ctrbPFA                 word    (@a_doconw - @a_base)/4
                        word    $01F9

                        word    @ctrbNFA + $10
frqaNFA                 byte    $84,"frqa"
frqaPFA                 word    (@a_doconw - @a_base)/4
                        word    $01FA

                        word    @frqaNFA + $10
frqbNFA                 byte    $84,"frqb"
frqbPFA                 word    (@a_doconw - @a_base)/4
                        word    $01FB

                        word    @frqbNFA + $10
phsaNFA                 byte    $84,"phsa"
phsaPFA                 word    (@a_doconw - @a_base)/4
                        word    $01FC

                        word    @phsaNFA + $10
phsbNFA                 byte    $84,"phsb"
phsbPFA                 word    (@a_doconw - @a_base)/4
                        word    $01FD

                        word    @phsbNFA + $10
vcfgNFA                 byte    $84,"vcfg"
vcfgPFA                 word    (@a_doconw - @a_base)/4
                        word    $01FE

                        word    @vcfgNFA + $10
vsclNFA                 byte    $84,"vscl"
vsclPFA                 word    (@a_doconw - @a_base)/4
                        word    $01FF

                        word    @vsclNFA + $10
_wkeytoNFA              byte    $87,"_wkeyto"
_wkeytoPFA              word    (@a_dovarw - @a_base)/4
                        word    $2000

                        word    @_wkeytoNFA + $10
_cnipNFA                byte    $C5,"_cnip"
_cnipPFA                word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @twominusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @WatPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @twominusPFA + $10
                        word    @WbangPFA + $10
                        word    @herePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_cnipNFA + $10
_execasmtwogtoneNFA     byte    $0B,"_execasm2>1"
_execasmtwogtonePFA     word    (@a__execasmtwogtone - @a_base)/4

                        word    @_execasmtwogtoneNFA + $10
_execasmonegtoneNFA     byte    $0B,"_execasm1>1"
_execasmonegtonePFA     word    (@a__execasmonegtone - @a_base)/4

                        word    @_execasmonegtoneNFA + $10
_execasmtwogtzNFA       byte    $0B,"_execasm2>0"
_execasmtwogtzPFA       word    (@a__execasmtwogtz - @a_base)/4

                        word    @_execasmtwogtzNFA + $10
_dictsearchNFA          byte    $0B,"_dictsearch"
_dictsearchPFA          word    (@a__dictsearch - @a_base)/4

                        word    @_dictsearchNFA + $10
_maskinNFA              byte    $07,"_maskin"
_maskinPFA              word    (@a__maskin - @a_base)/4

                        word    @_maskinNFA + $10
_maskoutloNFA           byte    $0A,"_maskoutlo"
_maskoutloPFA           word    (@a__maskoutlo - @a_base)/4

                        word    @_maskoutloNFA + $10
_maskouthiNFA           byte    $0A,"_maskouthi"
_maskouthiPFA           word    (@a__maskouthi - @a_base)/4

                        word    @_maskouthiNFA + $10
nameeqNFA               byte    $05,"name="
nameeqPFA               word    (@a_nameeq - @a_base)/4

                        word    @nameeqNFA + $10
cstreqNFA               byte    $05,"cstr="
cstreqPFA               word    (@a_cstreq - @a_base)/4

                        word    @cstreqNFA + $10
absNFA                  byte    $83,"abs"
absPFA                  word    (@a__execasmonegtone - @a_base)/4
                        word    $0151
                        word    (@a_exit - @a_base)/4

                        word    @absNFA + $10
andNFA                  byte    $83,"and"
andPFA                  word    (@a__execasmtwogtone - @a_base)/4
                        word    $00C1
                        word    (@a_exit - @a_base)/4

                        word    @andNFA + $10
andnNFA                 byte    $84,"andn"
andnPFA                 word    (@a__execasmtwogtone - @a_base)/4
                        word    $00C9
                        word    (@a_exit - @a_base)/4

                        word    @andnNFA + $10
bangdestinationNFA      byte    $8C,"!destination"
bangdestinationPFA      word    (@a__execasmtwogtone - @a_base)/4
                        word    $00A9
                        word    (@a_exit - @a_base)/4

                        word    @bangdestinationNFA + $10
banginstructionNFA      byte    $8C,"!instruction"
banginstructionPFA      word    (@a__execasmtwogtone - @a_base)/4
                        word    $00B1
                        word    (@a_exit - @a_base)/4

                        word    @banginstructionNFA + $10
bangsourceNFA           byte    $87,"!source"
bangsourcePFA           word    (@a__execasmtwogtone - @a_base)/4
                        word    $00A1
                        word    (@a_exit - @a_base)/4

                        word    @bangsourceNFA + $10
LatNFA                  byte    $82,"L@"
LatPFA                  word    (@a__execasmonegtone - @a_base)/4
                        word    $0011
                        word    (@a_exit - @a_base)/4

                        word    @LatNFA + $10
CatNFA                  byte    $82,"C@"
CatPFA                  word    (@a__execasmonegtone - @a_base)/4
                        word    $0001
                        word    (@a_exit - @a_base)/4

                        word    @CatNFA + $10
WatNFA                  byte    $82,"W@"
WatPFA                  word    (@a__execasmonegtone - @a_base)/4
                        word    $0009
                        word    (@a_exit - @a_base)/4

                        word    @WatNFA + $10
COGatNFA                byte    $04,"COG@"
COGatPFA                word    (@a_COGat - @a_base)/4

                        word    @COGatNFA + $10
LbangNFA                byte    $82,"L!"
LbangPFA                word    (@a__execasmtwogtz - @a_base)/4
                        word    $0010
                        word    (@a_exit - @a_base)/4

                        word    @LbangNFA + $10
CbangNFA                byte    $82,"C!"
CbangPFA                word    (@a__execasmtwogtz - @a_base)/4
                        word    $0000
                        word    (@a_exit - @a_base)/4

                        word    @CbangNFA + $10
WbangNFA                byte    $82,"W!"
WbangPFA                word    (@a__execasmtwogtz - @a_base)/4
                        word    $0008
                        word    (@a_exit - @a_base)/4

                        word    @WbangNFA + $10
COGbangNFA              byte    $04,"COG!"
COGbangPFA              word    (@a_COGbang - @a_base)/4

                        word    @COGbangNFA + $10
branchNFA               byte    $06,"branch"
branchPFA               word    (@a_branch - @a_base)/4

                        word    @branchNFA + $10
hubopNFA                byte    $05,"hubop"
hubopPFA                word    (@a_hubop - @a_base)/4

                        word    @hubopNFA + $10
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
dupNFA                  byte    $03,"dup"
dupPFA                  word    (@a_dup - @a_base)/4

                        word    @dupNFA + $10
eqNFA                   byte    $01,"="
eqPFA                   word    (@a_eq - @a_base)/4

                        word    @eqNFA + $10
exitNFA                 byte    $04,"exit"
exitPFA                 word    (@a_exit - @a_base)/4

                        word    @exitNFA + $10
gtNFA                   byte    $01,">"
gtPFA                   word    (@a_gt - @a_base)/4

                        word    @gtNFA + $10
litwNFA                 byte    $04,"litw"
litwPFA                 word    (@a_litw - @a_base)/4

                        word    @litwNFA + $10
litlNFA                 byte    $04,"litl"
litlPFA                 word    (@a_litl - @a_base)/4

                        word    @litlNFA + $10
lshiftNFA               byte    $86,"lshift"
lshiftPFA               word    (@a__execasmtwogtone - @a_base)/4
                        word    $0059
                        word    (@a_exit - @a_base)/4

                        word    @lshiftNFA + $10
ltNFA                   byte    $01,"<"
ltPFA                   word    (@a_lt - @a_base)/4

                        word    @ltNFA + $10
maxNFA                  byte    $83,"max"
maxPFA                  word    (@a__execasmtwogtone - @a_base)/4
                        word    $0081
                        word    (@a_exit - @a_base)/4

                        word    @maxNFA + $10
minNFA                  byte    $83,"min"
minPFA                  word    (@a__execasmtwogtone - @a_base)/4
                        word    $0089
                        word    (@a_exit - @a_base)/4

                        word    @minNFA + $10
minusNFA                byte    $81,"-"
minusPFA                word    (@a__execasmtwogtone - @a_base)/4
                        word    $0109
                        word    (@a_exit - @a_base)/4

                        word    @minusNFA + $10
orNFA                   byte    $82,"or"
orPFA                   word    (@a__execasmtwogtone - @a_base)/4
                        word    $00D1
                        word    (@a_exit - @a_base)/4

                        word    @orNFA + $10
overNFA                 byte    $04,"over"
overPFA                 word    (@a_over - @a_base)/4

                        word    @overNFA + $10
plusNFA                 byte    $81,"+"
plusPFA                 word    (@a__execasmtwogtone - @a_base)/4
                        word    $0101
                        word    (@a_exit - @a_base)/4

                        word    @plusNFA + $10
rotNFA                  byte    $03,"rot"
rotPFA                  word    (@a_rot - @a_base)/4

                        word    @rotNFA + $10
ratNFA                  byte    $82,"r@"
ratPFA                  word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @twoplusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @ratNFA + $10
rshiftNFA               byte    $86,"rshift"
rshiftPFA               word    (@a__execasmtwogtone - @a_base)/4
                        word    $0051
                        word    (@a_exit - @a_base)/4

                        word    @rshiftNFA + $10
rashiftNFA              byte    $87,"rashift"
rashiftPFA              word    (@a__execasmtwogtone - @a_base)/4
                        word    $0071
                        word    (@a_exit - @a_base)/4

                        word    @rashiftNFA + $10
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
swapNFA                 byte    $04,"swap"
swapPFA                 word    (@a_swap - @a_base)/4

                        word    @swapNFA + $10
umstarNFA               byte    $03,"um*"
umstarPFA               word    (@a_umstar - @a_base)/4

                        word    @umstarNFA + $10
umslashmodNFA           byte    $06,"um/mod"
umslashmodPFA           word    (@a_umslashmod - @a_base)/4

                        word    @umslashmodNFA + $10
uslashmodNFA            byte    $85,"u/mod"
uslashmodPFA            word    @zPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_umslashmod - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @uslashmodNFA + $10
xorNFA                  byte    $83,"xor"
xorPFA                  word    (@a__execasmtwogtone - @a_base)/4
                        word    $00D9
                        word    (@a_exit - @a_base)/4

                        word    @xorNFA + $10
waitcntNFA              byte    $87,"waitcnt"
waitcntPFA              word    (@a__execasmtwogtone - @a_base)/4
                        word    $01F1
                        word    (@a_exit - @a_base)/4

                        word    @waitcntNFA + $10
waitpeqNFA              byte    $87,"waitpeq"
waitpeqPFA              word    (@a__execasmtwogtz - @a_base)/4
                        word    $01E0
                        word    (@a_exit - @a_base)/4

                        word    @waitpeqNFA + $10
waitpneNFA              byte    $87,"waitpne"
waitpnePFA              word    (@a__execasmtwogtz - @a_base)/4
                        word    $01E8
                        word    (@a_exit - @a_base)/4

                        word    @waitpneNFA + $10
vfcogNFA                byte    $85,"vfcog"
vfcogPFA                word    (@a_dup - @a_base)/4
                        word    @_fcogPFA + $10
                        word    @WatPFA + $10
                        word    @_lcogPFA + $10
                        word    @WatPFA + $10
                        word    @betweenPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_drop - @a_base)/4
                        word    @_fcogPFA + $10
                        word    @WatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @vfcogNFA + $10
rebootNFA               byte    $86,"reboot"
rebootPFA               word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @zPFA + $10
                        word    (@a_hubop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @rebootNFA + $10
cogstopNFA              byte    $87,"cogstop"
cogstopPFA              word    (@a_litw - @a_base)/4
                        word    $0003
                        word    (@a_hubop - @a_base)/4
                        word    @twodropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogstopNFA + $10
cogresetNFA             byte    $88,"cogreset"
cogresetPFA             word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @cogidPFA + $10
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    (@a_dup - @a_base)/4
                        word    @cogstopPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @cogdPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @zPFA + $10
                        word    @fillPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @cogdPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @lshiftPFA + $10
                        word    @dlrH_entryPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @lshiftPFA + $10
                        word    @orPFA + $10
                        word    @orPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_hubop - @a_base)/4
                        word    @twodropPFA + $10
                        word    @cogdebugvaluePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $8000
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @LatPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @cogresetNFA + $10
resetNFA                byte    $85,"reset"
resetPFA                word    @mydictlockPFA + $10
                        word    @WatPFA + $10
                        word    @zgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @mydictlockPFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    @cogidPFA + $10
                        word    @cogresetPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @resetNFA + $10
disioNFA                byte    $85,"disio"
disioPFA                word    @cogemitptrPFA + $10
                        word    @zPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @disioNFA + $10
connioNFA               byte    $86,"connio"
connioPFA               word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @coginbytePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    @cogemitptrPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @connioNFA + $10
gtconNFA                byte    $84,">con"
gtconPFA                word    @cogconPFA + $10
                        word    @WatPFA + $10
                        word    @disioPFA + $10
                        word    @inconPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @cogemitptrPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @coginbytePFA + $10
                        word    @outconPFA + $10
                        word    @WbangPFA + $10
                        word    @cogconPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtconNFA + $10
cogconNFA               byte    $86,"cogcon"
cogconPFA               word    (@a_dovarw - @a_base)/4
                        word    $0006

                        word    @cogconNFA + $10
inconNFA                byte    $85,"incon"
inconPFA                word    (@a_dovarw - @a_base)/4
                        word    $0100

                        word    @inconNFA + $10
outconNFA               byte    $86,"outcon"
outconPFA               word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @outconNFA + $10
ctlconNFA               byte    $86,"ctlcon"
ctlconPFA               word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @ctlconNFA + $10
clkfreqNFA              byte    $87,"clkfreq"
clkfreqPFA              word    @zPFA + $10
                        word    @LatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @clkfreqNFA + $10
paratNFA                byte    $85,"parat"
paratPFA                word    @parPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @paratNFA + $10
cogdNFA                 byte    $84,"cogd"
cogdPFA                 word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @lshiftPFA + $10
                        word    @dlrH_cogdataPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogdNFA + $10
inbyteNFA               byte    $86,"inbyte"
inbytePFA               word    @zPFA + $10
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @inbyteNFA + $10
coginbyteNFA            byte    $89,"coginbyte"
coginbytePFA            word    @cogdPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @coginbyteNFA + $10
emitptrNFA              byte    $87,"emitptr"
emitptrPFA              word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @emitptrNFA + $10
cogemitptrNFA           byte    $8A,"cogemitptr"
cogemitptrPFA           word    @cogdPFA + $10
                        word    @twoplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogemitptrNFA + $10
stateNFA                byte    $85,"state"
statePFA                word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @stateNFA + $10
compileqNFA             byte    $88,"compile?"
compileqPFA             word    @statePFA + $10
                        word    @WatPFA + $10
                        word    @zltgtPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @compileqNFA + $10
debugcmdNFA             byte    $88,"debugcmd"
debugcmdPFA             word    (@a_litw - @a_base)/4
                        word    $0006
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @debugcmdNFA + $10
cogdebugcmdNFA          byte    $8B,"cogdebugcmd"
cogdebugcmdPFA          word    @cogdPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0006
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogdebugcmdNFA + $10
debugvalueNFA           byte    $8A,"debugvalue"
debugvaluePFA           word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @debugvalueNFA + $10
cogdebugvalueNFA        byte    $8D,"cogdebugvalue"
cogdebugvaluePFA        word    @cogdPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogdebugvalueNFA + $10
baseNFA                 byte    $84,"base"
basePFA                 word    (@a_litw - @a_base)/4
                        word    $000C
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @baseNFA + $10
coghereNFA              byte    $87,"coghere"
cogherePFA              word    (@a_litw - @a_base)/4
                        word    $000E
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @coghereNFA + $10
execwordNFA             byte    $88,"execword"
execwordPFA             word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @execwordNFA + $10
executeNFA              byte    $87,"execute"
executePFA              word    (@a_dup - @a_base)/4
                        word    @_fmaskPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @ipPFA + $10
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
                        word    @ipPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @executeNFA + $10
gtoutNFA                byte    $84,">out"
gtoutPFA                word    (@a_litw - @a_base)/4
                        word    $0014
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtoutNFA + $10
gtinNFA                 byte    $83,">in"
gtinPFA                 word    (@a_litw - @a_base)/4
                        word    $0016
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtinNFA + $10
mydictlockNFA           byte    $8A,"mydictlock"
mydictlockPFA           word    (@a_litw - @a_base)/4
                        word    $0018
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @mydictlockNFA + $10
fsliceptrNFA            byte    $89,"fsliceptr"
fsliceptrPFA            word    (@a_litw - @a_base)/4
                        word    $001A
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fsliceptrNFA + $10
lastcntNFA              byte    $87,"lastcnt"
lastcntPFA              word    (@a_litw - @a_base)/4
                        word    $001C
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lastcntNFA + $10
fslicecntNFA            byte    $89,"fslicecnt"
fslicecntPFA            word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fslicecntNFA + $10
_fSlicerNFA             byte    $88,"_fSlicer"
_fSlicerPFA             word    @cntPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @lastcntPFA + $10
                        word    @LatPFA + $10
                        word    @plusPFA + $10
                        word    @fslicecntPFA + $10
                        word    @LatPFA + $10
                        word    @maxPFA + $10
                        word    @fslicecntPFA + $10
                        word    @LbangPFA + $10
                        word    @negatePFA + $10
                        word    @lastcntPFA + $10
                        word    @LbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_fSlicerNFA + $10
_fSliceNFA              byte    $87,"_fSlice"
_fSlicePFA              word    @fsliceptrPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @executePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_fSliceNFA + $10
padNFA                  byte    $83,"pad"
padPFA                  word    (@a_litw - @a_base)/4
                        word    $0024
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padNFA + $10
cogpadNFA               byte    $86,"cogpad"
cogpadPFA               word    @cogdPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0024
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogpadNFA + $10
cogpadclrNFA            byte    $89,"cogpadclr"
cogpadclrPFA            word    @cogpadPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @padsizePFA + $10
                        word    @plusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_litl - @a_base)/4
                        long    $20202020
                        word    @iPFA + $10
                        word    @LbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFEE
                        word    (@a_exit - @a_base)/4

                        word    @cogpadclrNFA + $10
padgtinNFA              byte    $86,"pad>in"
padgtinPFA              word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @padPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padgtinNFA + $10
namemaxNFA              byte    $87,"namemax"
namemaxPFA              word    (@a_litw - @a_base)/4
                        word    $001F
                        word    (@a_exit - @a_base)/4

                        word    @namemaxNFA + $10
padsizeNFA              byte    $87,"padsize"
padsizePFA              word    (@a_litw - @a_base)/4
                        word    $0080
                        word    (@a_exit - @a_base)/4

                        word    @padsizeNFA + $10
tzNFA                   byte    $82,"t0"
tzPFA                   word    (@a_litw - @a_base)/4
                        word    $00A4
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tzNFA + $10
toneNFA                 byte    $82,"t1"
tonePFA                 word    (@a_litw - @a_base)/4
                        word    $00A6
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @toneNFA + $10
tbufNFA                 byte    $84,"tbuf"
tbufPFA                 word    (@a_litw - @a_base)/4
                        word    $00A8
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tbufNFA + $10
numpadNFA               byte    $86,"numpad"
numpadPFA               word    (@a_litw - @a_base)/4
                        word    $00C0
                        word    @paratPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @numpadNFA + $10
padgtoutNFA             byte    $87,"pad>out"
padgtoutPFA             word    @gtoutPFA + $10
                        word    @WatPFA + $10
                        word    @numpadPFA + $10
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padgtoutNFA + $10
numpadsizeNFA           byte    $8A,"numpadsize"
numpadsizePFA           word    (@a_litw - @a_base)/4
                        word    $0030
                        word    (@a_exit - @a_base)/4

                        word    @numpadsizeNFA + $10
keytoNFA                byte    $85,"keyto"
keytoPFA                word    @zPFA + $10
                        word    @_wkeytoPFA + $10
                        word    @WatPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @keyqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_drop - @a_base)/4
                        word    @keyPFA + $10
                        word    @minusonePFA + $10
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF0
                        word    (@a_exit - @a_base)/4

                        word    @keytoNFA + $10
emitqNFA                byte    $85,"emit?"
emitqPFA                word    @_fSlicePFA + $10
                        word    @emitptrPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @andPFA + $10
                        word    @zltgtPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @emitqNFA + $10
emitNFA                 byte    $84,"emit"
emitPFA                 word    @emitqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFFC
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    @emitptrPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @WbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @twodropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @emitNFA + $10
keyqNFA                 byte    $84,"key?"
keyqPFA                 word    @_fSlicePFA + $10
                        word    @inbytePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @keyqNFA + $10
keyNFA                  byte    $83,"key"
keyPFA                  word    @keyqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFFC
                        word    @inbytePFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @inbytePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @keyNFA + $10
fkeyqNFA                byte    $85,"fkey?"
fkeyqPFA                word    @inbytePFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @inbytePFA + $10
                        word    @WbangPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fkeyqNFA + $10
nipNFA                  byte    $83,"nip"
nipPFA                  word    (@a_swap - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @nipNFA + $10
tuckNFA                 byte    $84,"tuck"
tuckPFA                 word    (@a_swap - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @tuckNFA + $10
twodupNFA               byte    $84,"2dup"
twodupPFA               word    (@a_over - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @twodupNFA + $10
twodropNFA              byte    $85,"2drop"
twodropPFA              word    (@a_drop - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @twodropNFA + $10
threedropNFA            byte    $85,"3drop"
threedropPFA            word    (@a_drop - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @threedropNFA + $10
uslashNFA               byte    $82,"u/"
uslashPFA               word    @uslashmodPFA + $10
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @uslashNFA + $10
ustarNFA                byte    $82,"u*"
ustarPFA                word    (@a_umstar - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @ustarNFA + $10
signNFA                 byte    $84,"sign"
signPFA                 word    @xorPFA + $10
                        word    (@a_litl - @a_base)/4
                        long    $80000000
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @signNFA + $10
starNFA                 byte    $81,"*"
starPFA                 word    (@a_umstar - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @starNFA + $10
starslashmodNFA         byte    $85,"*/mod"
starslashmodPFA         word    @twodupPFA + $10
                        word    @signPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @absPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_rgt - @a_base)/4
                        word    @signPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @absPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @absPFA + $10
                        word    (@a_umstar - @a_base)/4
                        word    (@a_rot - @a_base)/4
                        word    (@a_umslashmod - @a_base)/4
                        word    (@a_rgt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @negatePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @negatePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @starslashmodNFA + $10
starslashNFA            byte    $82,"*/"
starslashPFA            word    @starslashmodPFA + $10
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @starslashNFA + $10
slashmodNFA             byte    $84,"/mod"
slashmodPFA             word    @twodupPFA + $10
                        word    @signPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @absPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @absPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @uslashmodPFA + $10
                        word    (@a_rgt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @negatePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @negatePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @slashmodNFA + $10
slashNFA                byte    $81,"/"
slashPFA                word    @slashmodPFA + $10
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @slashNFA + $10
invertNFA               byte    $86,"invert"
invertPFA               word    @minusonePFA + $10
                        word    @xorPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @invertNFA + $10
negateNFA               byte    $86,"negate"
negatePFA               word    (@a__execasmonegtone - @a_base)/4
                        word    $0149
                        word    (@a_exit - @a_base)/4

                        word    @negateNFA + $10
zeqNFA                  byte    $82,"0="
zeqPFA                  word    @zPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @zeqNFA + $10
ltgtNFA                 byte    $82,"<>"
ltgtPFA                 word    (@a_eq - @a_base)/4
                        word    @invertPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ltgtNFA + $10
zltgtNFA                byte    $83,"0<>"
zltgtPFA                word    @zeqPFA + $10
                        word    @invertPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @zltgtNFA + $10
zltNFA                  byte    $82,"0<"
zltPFA                  word    @zPFA + $10
                        word    (@a_lt - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @zltNFA + $10
zgtNFA                  byte    $82,"0>"
zgtPFA                  word    @zPFA + $10
                        word    (@a_gt - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @zgtNFA + $10
oneplusNFA              byte    $82,"1+"
oneplusPFA              word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @oneplusNFA + $10
oneminusNFA             byte    $82,"1-"
oneminusPFA             word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @minusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @oneminusNFA + $10
twoplusNFA              byte    $82,"2+"
twoplusPFA              word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twoplusNFA + $10
fourplusNFA             byte    $82,"4+"
fourplusPFA             word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fourplusNFA + $10
twominusNFA             byte    $82,"2-"
twominusPFA             word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @minusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twominusNFA + $10
twostarNFA              byte    $82,"2*"
twostarPFA              word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @lshiftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twostarNFA + $10
twoslashNFA             byte    $82,"2/"
twoslashPFA             word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @rashiftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @twoslashNFA + $10
rottwoNFA               byte    $84,"rot2"
rottwoPFA               word    (@a_rot - @a_base)/4
                        word    (@a_rot - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @rottwoNFA + $10
gteqNFA                 byte    $82,">="
gteqPFA                 word    @twodupPFA + $10
                        word    (@a_gt - @a_base)/4
                        word    @rottwoPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gteqNFA + $10
lteqNFA                 byte    $82,"<="
lteqPFA                 word    @twodupPFA + $10
                        word    (@a_lt - @a_base)/4
                        word    @rottwoPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lteqNFA + $10
zgteqNFA                byte    $83,"0>="
zgteqPFA                word    (@a_dup - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_gt - @a_base)/4
                        word    (@a_swap - @a_base)/4
                        word    @zeqPFA + $10
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @zgteqNFA + $10
WplusbangNFA            byte    $83,"W+!"
WplusbangPFA            word    (@a_dup - @a_base)/4
                        word    @WatPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @plusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @WplusbangNFA + $10
orCbangNFA              byte    $84,"orC!"
orCbangPFA              word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @orPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @orCbangNFA + $10
andCbangNFA             byte    $85,"andC!"
andCbangPFA             word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @andCbangNFA + $10
betweenNFA              byte    $87,"between"
betweenPFA              word    @rottwoPFA + $10
                        word    (@a_over - @a_base)/4
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
spacesPFA               word    (@a_dup - @a_base)/4
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
dothexNFA               byte    $84,".hex"
dothexPFA               word    (@a_litw - @a_base)/4
                        word    $000F
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0030
                        word    @plusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0039
                        word    (@a_gt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @plusPFA + $10
                        word    @emitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dothexNFA + $10
dotbyteNFA              byte    $85,".byte"
dotbytePFA              word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @rshiftPFA + $10
                        word    @dothexPFA + $10
                        word    @dothexPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotbyteNFA + $10
dotwordNFA              byte    $85,".word"
dotwordPFA              word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @rshiftPFA + $10
                        word    @dotbytePFA + $10
                        word    @dotbytePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotwordNFA + $10
dotlongNFA              byte    $85,".long"
dotlongPFA              word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @rshiftPFA + $10
                        word    @dotwordPFA + $10
                        word    @dotwordPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotlongNFA + $10
boundsNFA               byte    $86,"bounds"
boundsPFA               word    (@a_over - @a_base)/4
                        word    @plusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @boundsNFA + $10
alignlNFA               byte    $86,"alignl"
alignlPFA               word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    (@a_litl - @a_base)/4
                        long    $FFFFFFFC
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @alignlNFA + $10
alignwNFA               byte    $86,"alignw"
alignwPFA               word    @oneplusPFA + $10
                        word    (@a_litl - @a_base)/4
                        long    $FFFFFFFE
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @alignwNFA + $10
CatplusplusNFA          byte    $84,"C@++"
CatplusplusPFA          word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @CatplusplusNFA + $10
ctolowerNFA             byte    $88,"ctolower"
ctolowerPFA             word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0041
                        word    (@a_litw - @a_base)/4
                        word    $005A
                        word    @betweenPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ctolowerNFA + $10
ctoupperNFA             byte    $88,"ctoupper"
ctoupperPFA             word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0061
                        word    (@a_litw - @a_base)/4
                        word    $007A
                        word    @betweenPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $00DF
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ctoupperNFA + $10
todigitNFA              byte    $87,"todigit"
todigitPFA              word    @ctoupperPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0030
                        word    @minusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    (@a_gt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @minusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    (@a_lt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @todigitNFA + $10
isdigitNFA              byte    $87,"isdigit"
isdigitPFA              word    @todigitPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @zgteqPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @basePFA + $10
                        word    @WatPFA + $10
                        word    (@a_lt - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @isdigitNFA + $10
isunumberNFA            byte    $89,"isunumber"
isunumberPFA            word    @boundsPFA + $10
                        word    @minusonePFA + $10
                        word    @rottwoPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @isdigitPFA + $10
                        word    @andPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    (@a_exit - @a_base)/4

                        word    @isunumberNFA + $10
unumberNFA              byte    $87,"unumber"
unumberPFA              word    @boundsPFA + $10
                        word    @zPFA + $10
                        word    @rottwoPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @basePFA + $10
                        word    @WatPFA + $10
                        word    @ustarPFA + $10
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @todigitPFA + $10
                        word    @plusPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF0
                        word    (@a_exit - @a_base)/4

                        word    @unumberNFA + $10
numberNFA               byte    $86,"number"
numberPFA               word    (@a_over - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    @oneminusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @unumberPFA + $10
                        word    @negatePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @unumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @numberNFA + $10
isnumberNFA             byte    $88,"isnumber"
isnumberPFA             word    (@a_over - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    @oneminusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @isunumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @isnumberNFA + $10
dotstrNFA               byte    $84,".str"
dotstrPFA               word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0020
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @maxPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $007F
                        word    @minPFA + $10
                        word    @emitPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEC
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @twodropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotstrNFA + $10
npfxNFA                 byte    $84,"npfx"
npfxPFA                 word    @namelenPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @namelenPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @twodupPFA + $10
                        word    (@a_gt - @a_base)/4
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
cmovePFA                word    (@a_dup - @a_base)/4
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @threedropPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0010
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    @iPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF8
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @cmoveNFA + $10
namecopyNFA             byte    $88,"namecopy"
namecopyPFA             word    (@a_over - @a_base)/4
                        word    @namelenPFA + $10
                        word    @oneplusPFA + $10
                        word    @nipPFA + $10
                        word    @cmovePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @namecopyNFA + $10
ccopyNFA                byte    $85,"ccopy"
ccopyPFA                word    (@a_over - @a_base)/4
                        word    @CatPFA + $10
                        word    @oneplusPFA + $10
                        word    @cmovePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ccopyNFA + $10
cappendNFA              byte    $87,"cappend"
cappendPFA              word    (@a_dup - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    @oneplusPFA + $10
                        word    @rottwoPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @CbangPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneplusPFA + $10
                        word    @rottwoPFA + $10
                        word    @cmovePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cappendNFA + $10
cappendcNFA             byte    $88,"cappendc"
cappendcPFA             word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @CbangPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cappendcNFA + $10
cappendnNFA             byte    $88,"cappendn"
cappendnPFA             word    (@a_swap - @a_base)/4
                        word    @lthashPFA + $10
                        word    @hashsPFA + $10
                        word    @hashgtPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @cappendPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cappendnNFA + $10
cappendncNFA            byte    $89,"cappendnc"
cappendncPFA            word    (@a_swap - @a_base)/4
                        word    @lthashPFA + $10
                        word    @hashsPFA + $10
                        word    @hashgtPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @cappendPFA + $10
                        word    @blPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @cappendcPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cappendncNFA + $10
cogxNFA                 byte    $84,"cogx"
cogxPFA                 word    @vfcogPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @coginbytePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF4
                        word    @rottwoPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @cogpadclrPFA + $10
                        word    @cogpadPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_swap - @a_base)/4
                        word    @cmovePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $000D
                        word    (@a_swap - @a_base)/4
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogxNFA + $10
cogxoNFA                byte    $85,"cogxo"
cogxoPFA                word    @zPFA + $10
                        word    @outconPFA + $10
                        word    @WbangPFA + $10
                        word    @cogidPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @oneplusPFA + $10
                        word    @vfcogPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_rot - @a_base)/4
                        word    @connioPFA + $10
                        word    @cogxPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogxoNFA + $10
qqqNFA                  byte    $83,"???"
qqqPFA                  word    @dqPFA + $10
                        byte    $03,"???"
                        word    (@a_exit - @a_base)/4

                        word    @qqqNFA + $10
dotstrnameNFA           byte    $88,".strname"
dotstrnamePFA           word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @namelenPFA + $10
                        word    @dotstrPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @qqqPFA + $10
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
iPFA                    word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @iNFA + $10
jNFA                    byte    $81,"j"
jPFA                    word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0005
                        word    @plusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @jNFA + $10
iboundNFA               byte    $86,"ibound"
iboundPFA               word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @twoplusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @iboundNFA + $10
lastiqNFA               byte    $86,"lasti?"
lastiqPFA               word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @twoplusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @oneminusPFA + $10
                        word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_eq - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lastiqNFA + $10
setiNFA                 byte    $84,"seti"
setiPFA                 word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @plusPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @setiNFA + $10
eolqNFA                 byte    $84,"eol?"
eolqPFA                 word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $000A
                        word    (@a_eq - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $000D
                        word    (@a_eq - @a_base)/4
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @eolqNFA + $10
bsqNFA                  byte    $83,"bs?"
bsqPFA                  word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    (@a_eq - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $007F
                        word    (@a_eq - @a_base)/4
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @bsqNFA + $10
fillNFA                 byte    $84,"fill"
fillPFA                 word    @rottwoPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_dup - @a_base)/4
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
nfagtpfaPFA             word    (@a_litw - @a_base)/4
                        word    $7FFF
                        word    @andPFA + $10
                        word    @namelenPFA + $10
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
isnamecharPFA           word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    (@a_gt - @a_base)/4
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $007F
                        word    (@a_lt - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @isnamecharNFA + $10
_forthpfagtnfaNFA       byte    $8D,"_forthpfa>nfa"
_forthpfagtnfaPFA       word    (@a_litw - @a_base)/4
                        word    $7FFF
                        word    @andPFA + $10
                        word    @oneminusPFA + $10
                        word    @oneminusPFA + $10
                        word    (@a_dup - @a_base)/4
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
                        word    (@a_eq - @a_base)/4
                        word    (@a_over - @a_base)/4
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
                        word    (@a_dup - @a_base)/4
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFD8
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_asmpfagtnfaNFA + $10
pfagtnfaNFA             byte    $87,"pfa>nfa"
pfagtnfaPFA             word    (@a_dup - @a_base)/4
                        word    @_fmaskPFA + $10
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
acceptPFA               word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @maxPFA + $10
                        word    @twodupPFA + $10
                        word    @blPFA + $10
                        word    @fillPFA + $10
                        word    @oneminusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @boundsPFA + $10
                        word    @zPFA + $10
                        word    @keyPFA + $10
                        word    @eolqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @crPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0052
                        word    @bsqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $002E
                        word    (@a_drop - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0020
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @emitPFA + $10
                        word    @blPFA + $10
                        word    @emitPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @emitPFA + $10
                        word    @oneminusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneminusPFA + $10
                        word    @blPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @CbangPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0020
                        word    @blPFA + $10
                        word    @maxPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @emitPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_gtr - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    @CbangPFA + $10
                        word    @oneplusPFA + $10
                        word    @twodupPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_rgt - @a_base)/4
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $FF9C
                        word    @nipPFA + $10
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @acceptNFA + $10
parseNFA                byte    $85,"parse"
parsePFA                word    @padsizePFA + $10
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0020
                        word    @zPFA + $10
                        word    @twodupPFA + $10
                        word    @padgtinPFA + $10
                        word    @plusPFA + $10
                        word    @CatPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    @oneplusPFA + $10
                        word    @zPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFE6
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @parseNFA + $10
skipblNFA               byte    $86,"skipbl"
skipblPFA               word    @padgtinPFA + $10
                        word    @CatPFA + $10
                        word    @blPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    @padsizePFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFDC
                        word    (@a_exit - @a_base)/4

                        word    @skipblNFA + $10
nextwordNFA             byte    $88,"nextword"
nextwordPFA             word    @padsizePFA + $10
                        word    @gtinPFA + $10
                        word    @WatPFA + $10
                        word    (@a_gt - @a_base)/4
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
                        word    (@a_dup - @a_base)/4
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
padnwNFA                byte    $85,"padnw"
padnwPFA                word    @nextwordPFA + $10
                        word    @parseblPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @padnwNFA + $10
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
padclrNFA               byte    $86,"padclr"
padclrPFA               word    @padnwPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFFA
                        word    (@a_exit - @a_base)/4

                        word    @padclrNFA + $10
findNFA                 byte    $84,"find"
findPFA                 word    @lastnfaPFA + $10
                        word    (@a_over - @a_base)/4
                        word    (@a__dictsearch - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0048
                        word    @nipPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @nfagtpfaPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @WatPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $001C
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_litw - @a_base)/4
                        word    $0001
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
                        word    $001F
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0030
                        word    @plusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0039
                        word    (@a_gt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @plusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tocharNFA + $10
hashNFA                 byte    $81,"#"
hashPFA                 word    @basePFA + $10
                        word    @WatPFA + $10
                        word    @uslashmodPFA + $10
                        word    (@a_swap - @a_base)/4
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
                        word    (@a_dup - @a_base)/4
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF8
                        word    (@a_exit - @a_base)/4

                        word    @hashsNFA + $10
dotNFA                  byte    $81,"."
dotPFA                  word    (@a_dup - @a_base)/4
                        word    @zltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @emitPFA + $10
                        word    @negatePFA + $10
                        word    @lthashPFA + $10
                        word    @hashsPFA + $10
                        word    @hashgtPFA + $10
                        word    @dotcstrPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @emitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotNFA + $10
cogidNFA                byte    $85,"cogid"
cogidPFA                word    @minusonePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    (@a_hubop - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @cogidNFA + $10
locknewNFA              byte    $87,"locknew"
locknewPFA              word    @minusonePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    (@a_hubop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @locknewNFA + $10
lockretNFA              byte    $87,"lockret"
lockretPFA              word    (@a_litw - @a_base)/4
                        word    $0005
                        word    (@a_hubop - @a_base)/4
                        word    @twodropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lockretNFA + $10
locksetNFA              byte    $87,"lockset"
locksetPFA              word    (@a_litw - @a_base)/4
                        word    $0006
                        word    (@a_hubop - @a_base)/4
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @locksetNFA + $10
lockclrNFA              byte    $87,"lockclr"
lockclrPFA              word    (@a_litw - @a_base)/4
                        word    $0007
                        word    (@a_hubop - @a_base)/4
                        word    @nipPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lockclrNFA + $10
lockdictqNFA            byte    $89,"lockdict?"
lockdictqPFA            word    @mydictlockPFA + $10
                        word    @WatPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @mydictlockPFA + $10
                        word    @WplusbangPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $001C
                        word    @zPFA + $10
                        word    @locksetPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @mydictlockPFA + $10
                        word    @WbangPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lockdictqNFA + $10
freedictNFA             byte    $88,"freedict"
freedictPFA             word    @mydictlockPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $001A
                        word    @oneminusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @mydictlockPFA + $10
                        word    @WbangPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    @lockclrPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @freedictNFA + $10
lockdictNFA             byte    $88,"lockdict"
lockdictPFA             word    @lockdictqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFFC
                        word    (@a_exit - @a_base)/4

                        word    @lockdictNFA + $10
_eoomNFA                byte    $85,"_eoom"
_eoomPFA                word    @dqPFA + $10
                        byte    $0D,"Out of memory"
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_eoomNFA + $10
checkdictNFA            byte    $89,"checkdict"
checkdictPFA            word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @plusPFA + $10
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    @crPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @dotPFA + $10
                        word    @dictendPFA + $10
                        word    @dotPFA + $10
                        word    @_eoomPFA + $10
                        word    @clearkeysPFA + $10
                        word    @resetPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @checkdictNFA + $10
lparencreatebeginrparenNFA byte    $8D,"(createbegin)"
lparencreatebeginrparenPFA word    @lockdictPFA + $10
                        word    @wlastnfaPFA + $10
                        word    @WatPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @twoplusPFA + $10
                        word    @wlastnfaPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    @WbangPFA + $10
                        word    @twoplusPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparencreatebeginrparenNFA + $10
lparencreateendrparenNFA byte    $8B,"(createend)"
lparencreateendrparenPFA word    (@a_over - @a_base)/4
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
                        word    (@a_swap - @a_base)/4
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
clabelNFA               byte    $86,"clabel"
clabelPFA               word    @lockdictPFA + $10
                        word    @ccreatePFA + $10
                        word    @dlrC_a_doconwPFA + $10
                        word    @wcommaPFA + $10
                        word    @cogherePFA + $10
                        word    @WatPFA + $10
                        word    @wcommaPFA + $10
                        word    @forthentryPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @clabelNFA + $10
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
herewalNFA              byte    $87,"herewal"
herewalPFA              word    @lockdictPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
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
                        word    (@a_dup - @a_base)/4
                        word    @checkdictPFA + $10
                        word    @herePFA + $10
                        word    @WplusbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @allotNFA + $10
aallotNFA               byte    $86,"aallot"
aallotPFA               word    @cogherePFA + $10
                        word    @WplusbangPFA + $10
                        word    @cogherePFA + $10
                        word    @WatPFA + $10
                        word    @parPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @_eoomPFA + $10
                        word    @resetPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @aallotNFA + $10
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
cogcommaNFA             byte    $84,"cog,"
cogcommaPFA             word    @cogherePFA + $10
                        word    @WatPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @aallotPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogcommaNFA + $10
wcommaNFA               byte    $82,"w,"
wcommaPFA               word    @lockdictPFA + $10
                        word    @herewalPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @allotPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @wcommaNFA + $10
ccommaNFA               byte    $82,"c,"
ccommaPFA               word    @lockdictPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @allotPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ccommaNFA + $10
orlnfaNFA               byte    $86,"orlnfa"
orlnfaPFA               word    @lockdictPFA + $10
                        word    @lastnfaPFA + $10
                        word    @orCbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @orlnfaNFA + $10
forthentryNFA           byte    $8A,"forthentry"
forthentryPFA           word    @lockdictPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @orlnfaPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @forthentryNFA + $10
immediateNFA            byte    $89,"immediate"
immediatePFA            word    @lockdictPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @orlnfaPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @immediateNFA + $10
execNFA                 byte    $84,"exec"
execPFA                 word    @lockdictPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0060
                        word    @orlnfaPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @execNFA + $10
leaveNFA                byte    $85,"leave"
leavePFA                word    (@a_rgt - @a_base)/4
                        word    (@a_rgt - @a_base)/4
                        word    (@a_rgt - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_gtr - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @leaveNFA + $10
clearkeysNFA            byte    $89,"clearkeys"
clearkeysPFA            word    @zPFA + $10
                        word    @statePFA + $10
                        word    @WbangPFA + $10
                        word    @minusonePFA + $10
                        word    @_wkeytoPFA + $10
                        word    @WatPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @keyqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @keyPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEE
                        word    (@a_zbranch - @a_base)/4
                        word    $FFE0
                        word    (@a_exit - @a_base)/4

                        word    @clearkeysNFA + $10
wgtlNFA                 byte    $83,"w>l"
wgtlPFA                 word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @andPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @lshiftPFA + $10
                        word    @orPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @wgtlNFA + $10
lgtwNFA                 byte    $83,"l>w"
lgtwPFA                 word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @rshiftPFA + $10
                        word    (@a_swap - @a_base)/4
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
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @statePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @colonNFA + $10
_mmcsNFA                byte    $85,"_mmcs"
_mmcsPFA                word    @dqPFA + $10
                        byte    $1F,"MISMATCHED conTROL STRUCTURE(S)"
                        word    @crPFA + $10
                        word    @clearkeysPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_mmcsNFA + $10
_scolonNFA              byte    $82,"_;"
_scolonPFA              word    @wcommaPFA + $10
                        word    @zPFA + $10
                        word    @statePFA + $10
                        word    @WbangPFA + $10
                        word    @forthentryPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $3741
                        word    @ltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @_mmcsPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_scolonNFA + $10
scolonscolonNFA         byte    $C2,";;"
scolonscolonPFA         word    @dlrC_a_exitPFA + $10
                        word    @_scolonPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @scolonscolonNFA + $10
scolonNFA               byte    $C1,";"
scolonPFA               word    @dlrC_a_exitPFA + $10
                        word    @_scolonPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @scolonNFA + $10
dothenNFA               byte    $86,"dothen"
dothenPFA               word    @lgtwPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $1235
                        word    (@a_eq - @a_base)/4
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $1239
                        word    (@a_eq - @a_base)/4
                        word    @orPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    (@a_dup - @a_base)/4
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @minusPFA + $10
                        word    (@a_swap - @a_base)/4
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
thensPFA                word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    @andPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $1235
                        word    (@a_eq - @a_base)/4
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $1239
                        word    (@a_eq - @a_base)/4
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
                        word    (@a_eq - @a_base)/4
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
doloopPFA               word    (@a_swap - @a_base)/4
                        word    @lgtwPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $2329
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    (@a_swap - @a_base)/4
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
dotquoteNFA             byte    $C2,".",$22
dotquotePFA             word    @dlrH_dqPFA + $10
                        word    @wcommaPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @parsePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @ccommaPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @padgtinPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @cmovePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @allotPFA + $10
                        word    @oneplusPFA + $10
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    @herewalPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotquoteNFA + $10
fisnumberNFA            byte    $89,"fisnumber"
fisnumberPFA            word    @isnumberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fisnumberNFA + $10
fnumberNFA              byte    $87,"fnumber"
fnumberPFA              word    @numberPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fnumberNFA + $10
interpretpadNFA         byte    $8C,"interpretpad"
interpretpadPFA         word    @zPFA + $10
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    @blPFA + $10
                        word    @parsewordPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $00BE
                        word    @padgtinPFA + $10
                        word    @nextwordPFA + $10
                        word    @findPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0062
                        word    (@a_dup - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_eq - @a_base)/4
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
                        word    $003E
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @executePFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $002C
                        word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @executePFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $001E
                        word    @pfagtnfaPFA + $10
                        word    @dqPFA + $10
                        byte    $0F,"IMMEDIATE WORD "
                        word    @dotstrnamePFA + $10
                        word    @clearkeysPFA + $10
                        word    @crPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $004E
                        word    (@a_drop - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    @fisnumberPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0030
                        word    @CatplusplusPFA + $10
                        word    @fnumberPFA + $10
                        word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0020
                        word    (@a_dup - @a_base)/4
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
                        word    $0014
                        word    @zPFA + $10
                        word    @statePFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    @_udfPFA + $10
                        word    @dotstrnamePFA + $10
                        word    @crPFA + $10
                        word    @clearkeysPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FF38
                        word    (@a_exit - @a_base)/4

                        word    @interpretpadNFA + $10
interpretNFA            byte    $89,"interpret"
interpretPFA            word    @padPFA + $10
                        word    @padsizePFA + $10
                        word    @acceptPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @interpretpadPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @interpretNFA + $10
variableNFA             byte    $88,"variable"
variablePFA             word    @lockdictPFA + $10
                        word    @createPFA + $10
                        word    @dlrC_a_dovarlPFA + $10
                        word    @wcommaPFA + $10
                        word    @zPFA + $10
                        word    @lcommaPFA + $10
                        word    @forthentryPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @variableNFA + $10
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
cogvariableNFA          byte    $8B,"cogvariable"
cogvariablePFA          word    @cogherePFA + $10
                        word    @WatPFA + $10
                        word    @_wconePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @aallotPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogvariableNFA + $10
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
decimalNFA              byte    $87,"decimal"
decimalPFA              word    (@a_litw - @a_base)/4
                        word    $000A
                        word    @basePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @decimalNFA + $10
_wordsNFA               byte    $86,"_words"
_wordsPFA               word    @zPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    @lastnfaPFA + $10
                        word    @dqPFA + $10
                        byte    $26,"NFA (Forth/Asm Immediate eXecute) Name"
                        word    @twodupPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @npfxPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    @twodropPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $008A
                        word    (@a_rgt - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @crPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @andPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @dotwordPFA + $10
                        word    @spacePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0046
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_litw - @a_base)/4
                        word    $0041
                        word    @emitPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0049
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @emitPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    (@a_litw - @a_base)/4
                        word    $0058
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @emitPFA + $10
                        word    @spacePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotstrnamePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @namemaxPFA + $10
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0015
                        word    (@a_swap - @a_base)/4
                        word    @minusPFA + $10
                        word    @zPFA + $10
                        word    @maxPFA + $10
                        word    @spacesPFA + $10
                        word    @nfagtnextPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FF58
                        word    (@a_rgt - @a_base)/4
                        word    @threedropPFA + $10
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_wordsNFA + $10
wordsNFA                byte    $85,"words"
wordsPFA                word    @parsenwPFA + $10
                        word    @_wordsPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @wordsNFA + $10
delmsNFA                byte    $85,"delms"
delmsPFA                word    (@a_litl - @a_base)/4
                        long    $7FFFFFFF
                        word    @clkfreqPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $03E8
                        word    @uslashPFA + $10
                        word    @uslashPFA + $10
                        word    @minPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @maxPFA + $10
                        word    @clkfreqPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $03E8
                        word    @uslashPFA + $10
                        word    @ustarPFA + $10
                        word    @cntPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @plusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @cntPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @minusPFA + $10
                        word    @zltPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF4
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @delmsNFA + $10
delsecNFA               byte    $86,"delsec"
delsecPFA               word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @uslashmodPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $3E80
                        word    @delmsPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF8
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $03E8
                        word    @delmsPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF8
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @delsecNFA + $10
gtmNFA                  byte    $82,">m"
gtmPFA                  word    (@a_litw - @a_base)/4
                        word    $0001
                        word    (@a_swap - @a_base)/4
                        word    @lshiftPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @gtmNFA + $10
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
pxPFA                   word    (@a_swap - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @pinhiPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @pinloPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @pxNFA + $10
pxqNFA                  byte    $83,"px?"
pxqPFA                  word    @gtmPFA + $10
                        word    (@a__maskin - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @pxqNFA + $10
_sclNFA                 byte    $84,"_scl"
_sclPFA                 word    (@a_doconw - @a_base)/4
                        word    $001C

                        word    @_sclNFA + $10
_sdaNFA                 byte    $84,"_sda"
_sdaPFA                 word    (@a_doconw - @a_base)/4
                        word    $001D

                        word    @_sdaNFA + $10
_sclmNFA                byte    $85,"_sclm"
_sclmPFA                word    (@a_doconl - @a_base)/4
                        long    $10000000

                        word    @_sclmNFA + $10
_sdamNFA                byte    $85,"_sdam"
_sdamPFA                word    (@a_doconl - @a_base)/4
                        long    $20000000

                        word    @_sdamNFA + $10
_sdaiNFA                byte    $85,"_sdai"
_sdaiPFA                word    @_sdaPFA + $10
                        word    @pininPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_sdaiNFA + $10
_sdaoNFA                byte    $85,"_sdao"
_sdaoPFA                word    @_sdaPFA + $10
                        word    @pinoutPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_sdaoNFA + $10
_scliNFA                byte    $85,"_scli"
_scliPFA                word    @_sclPFA + $10
                        word    @pininPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_scliNFA + $10
_scloNFA                byte    $85,"_sclo"
_scloPFA                word    @_sclPFA + $10
                        word    @pinoutPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_scloNFA + $10
_sdalNFA                byte    $85,"_sdal"
_sdalPFA                word    @_sdamPFA + $10
                        word    (@a__maskoutlo - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sdalNFA + $10
_sdahNFA                byte    $85,"_sdah"
_sdahPFA                word    @_sdamPFA + $10
                        word    (@a__maskouthi - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sdahNFA + $10
_scllNFA                byte    $85,"_scll"
_scllPFA                word    @_sclmPFA + $10
                        word    (@a__maskoutlo - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_scllNFA + $10
_sclhNFA                byte    $85,"_sclh"
_sclhPFA                word    @_sclmPFA + $10
                        word    (@a__maskouthi - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sclhNFA + $10
_sdaqNFA                byte    $85,"_sda?"
_sdaqPFA                word    @_sdamPFA + $10
                        word    (@a__maskin - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @_sdaqNFA + $10
_eeinitNFA              byte    $87,"_eeinit"
_eeinitPFA              word    @_sclhPFA + $10
                        word    @_scloPFA + $10
                        word    @_sdaiPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0009
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @_scllPFA + $10
                        word    @_sclhPFA + $10
                        word    @_sdaqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF2
                        word    (@a_exit - @a_base)/4

                        word    @_eeinitNFA + $10
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
                        word    @_scliPFA + $10
                        word    @_sdaiPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_eestopNFA + $10
_eewriteNFA             byte    $88,"_eewrite"
_eewritePFA             word    (@a_litw - @a_base)/4
                        word    $0080
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @twodupPFA + $10
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @_sdahPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @_sdalPFA + $10
                        word    @_sclhPFA + $10
                        word    @_scllPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @rshiftPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFE4
                        word    @twodropPFA + $10
                        word    @_sdaiPFA + $10
                        word    @_sclhPFA + $10
                        word    @_sdaqPFA + $10
                        word    @_scllPFA + $10
                        word    @_sdalPFA + $10
                        word    @_sdaoPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_eewriteNFA + $10
_eereadNFA              byte    $87,"_eeread"
_eereadPFA              word    @_sdaiPFA + $10
                        word    @zPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @lshiftPFA + $10
                        word    @_sclhPFA + $10
                        word    @_sdaqPFA + $10
                        word    @_scllPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @orPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFE8
                        word    (@a_swap - @a_base)/4
                        word    @_sdaPFA + $10
                        word    @pxPFA + $10
                        word    @_sdaoPFA + $10
                        word    @_sclhPFA + $10
                        word    @_scllPFA + $10
                        word    @_sdalPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_eereadNFA + $10
eereadpageNFA           byte    $8A,"eereadpage"
eereadpagePFA           word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @locksetPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF6
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @maxPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @rshiftPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @rshiftPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @lshiftPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_gtr - @a_base)/4
                        word    @_eestartPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00A0
                        word    @orPFA + $10
                        word    @_eewritePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    (@a_swap - @a_base)/4
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
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @lockclrPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @eereadpageNFA + $10
eewritepageNFA          byte    $8B,"eewritepage"
eewritepagePFA          word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @locksetPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFF6
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @maxPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @rshiftPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @rshiftPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0007
                        word    @andPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @lshiftPFA + $10
                        word    @_eestartPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00A0
                        word    @orPFA + $10
                        word    @_eewritePFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    @rottwoPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @_eewritePFA + $10
                        word    @orPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    @_eestopPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @delmsPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @lockclrPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @eewritepageNFA + $10
eeerrNFA                byte    $85,"eeerr"
eeerrPFA                word    @dqPFA + $10
                        byte    $0C,"eeProm error"
                        word    (@a_exit - @a_base)/4

                        word    @eeerrNFA + $10
EWatNFA                 byte    $83,"EW@"
EWatPFA                 word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @eereadpagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @eeerrPFA + $10
                        word    @crPFA + $10
                        word    @tzPFA + $10
                        word    @WatPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @EWatNFA + $10
EWbangNFA               byte    $83,"EW!"
EWbangPFA               word    (@a_swap - @a_base)/4
                        word    @tzPFA + $10
                        word    @WbangPFA + $10
                        word    @tzPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @eewritepagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @eeerrPFA + $10
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @EWbangNFA + $10
ECatNFA                 byte    $83,"EC@"
ECatPFA                 word    @EWatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00FF
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @ECatNFA + $10
eecopyNFA               byte    $86,"eecopy"
eecopyPFA               word    (@a_litw - @a_base)/4
                        word    $003F
                        word    @invertPFA + $10
                        word    @andPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $003F
                        word    @invertPFA + $10
                        word    @andPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $003F
                        word    @invertPFA + $10
                        word    @andPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    @iPFA + $10
                        word    @plusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotPFA + $10
                        word    @padPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @eereadpagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @eeerrPFA + $10
                        word    @leavePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @iPFA + $10
                        word    @plusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotPFA + $10
                        word    @padPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @eewritepagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @eeerrPFA + $10
                        word    @leavePFA + $10
                        word    @iPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $03FF
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @crPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFB6
                        word    @twodropPFA + $10
                        word    @cogidPFA + $10
                        word    @cogpadclrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @eecopyNFA + $10
lparendumpbeginrparenNFA byte    $8B,"(dumpbegin)"
lparendumpbeginrparenPFA word    @crPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @dotwordPFA + $10
                        word    @spacePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotwordPFA + $10
                        word    @_ecsPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparendumpbeginrparenNFA + $10
lparendumpmidrparenNFA  byte    $89,"(dumpmid)"
lparendumpmidrparenPFA  word    @crPFA + $10
                        word    @dotwordPFA + $10
                        word    @_ecsPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparendumpmidrparenNFA + $10
lparendumpendrparenNFA  byte    $89,"(dumpend)"
lparendumpendrparenPFA  word    @tbufPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    @dotbytePFA + $10
                        word    @spacePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @spacesPFA + $10
                        word    @tbufPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @dotstrPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @lparendumpendrparenNFA + $10
dumpNFA                 byte    $84,"dump"
dumpPFA                 word    @lparendumpbeginrparenPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @lparendumpmidrparenPFA + $10
                        word    @iPFA + $10
                        word    @tbufPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @cmovePFA + $10
                        word    @lparendumpendrparenPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFEA
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dumpNFA + $10
edumpNFA                byte    $85,"edump"
edumpPFA                word    @lparendumpbeginrparenPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @lparendumpmidrparenPFA + $10
                        word    @iPFA + $10
                        word    @tbufPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @eereadpagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @tbufPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @zPFA + $10
                        word    @fillPFA + $10
                        word    @lparendumpendrparenPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFDC
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @edumpNFA + $10
cogdumpNFA              byte    $87,"cogdump"
cogdumpPFA              word    @crPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @dotwordPFA + $10
                        word    @spacePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotwordPFA + $10
                        word    @_ecsPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @crPFA + $10
                        word    @iPFA + $10
                        word    @dotwordPFA + $10
                        word    @_ecsPFA + $10
                        word    @iPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @dotlongPFA + $10
                        word    @spacePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    (@a_litw - @a_base)/4
                        word    $0004
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFDC
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogdumpNFA + $10
bsNFA                   byte    $E1,"\"
bsPFA                   word    @padsizePFA + $10
                        word    @gtinPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @bsNFA + $10
tickNFA                 byte    $81,"'"
tickPFA                 word    @parseblPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $001A
                        word    @padgtinPFA + $10
                        word    @nextwordPFA + $10
                        word    @findPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @_udfPFA + $10
                        word    @crPFA + $10
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @tickNFA + $10
cqNFA                   byte    $82,"cq"
cqPFA                   word    (@a_rgt - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @CatplusplusPFA + $10
                        word    @plusPFA + $10
                        word    @alignwPFA + $10
                        word    (@a_gtr - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @cqNFA + $10
cquoteNFA               byte    $E2,"c",$22
cquotePFA               word    @compileqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0034
                        word    @dlrH_cqPFA + $10
                        word    @wcommaPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @parsePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @ccommaPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @padgtinPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @cmovePFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @allotPFA + $10
                        word    @oneplusPFA + $10
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    @herewalPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0018
                        word    (@a_litw - @a_base)/4
                        word    $0022
                        word    @parsePFA + $10
                        word    @oneminusPFA + $10
                        word    @padgtinPFA + $10
                        word    @twodupPFA + $10
                        word    @CbangPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @twoplusPFA + $10
                        word    @gtinPFA + $10
                        word    @WplusbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cquoteNFA + $10
fl_baseNFA              byte    $87,"fl_base"
fl_basePFA              word    (@a_dovarw - @a_base)/4
                        word    $6D90

                        word    @fl_baseNFA + $10
fl_countNFA             byte    $88,"fl_count"
fl_countPFA             word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @fl_countNFA + $10
fl_topNFA               byte    $86,"fl_top"
fl_topPFA               word    (@a_dovarw - @a_base)/4
                        word    $7EDC

                        word    @fl_topNFA + $10
fl_inNFA                byte    $85,"fl_in"
fl_inPFA                word    (@a_dovarw - @a_base)/4
                        word    $7E74

                        word    @fl_inNFA + $10
fl_lockNFA              byte    $87,"fl_lock"
fl_lockPFA              word    (@a_dovarw - @a_base)/4
                        word    $0000

                        word    @fl_lockNFA + $10
fl_bufNFA               byte    $86,"fl_buf"
fl_bufPFA               word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @minusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @minusPFA + $10
                        word    @zPFA + $10
                        word    @fl_countPFA + $10
                        word    @WbangPFA + $10
                        word    @lockdictPFA + $10
                        word    @fl_lockPFA + $10
                        word    @WatPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @freedictPFA + $10
                        word    @crPFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $000C
                        word    @minusonePFA + $10
                        word    @fl_lockPFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $00EE
                        word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @fl_topPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @minusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @fl_basePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @fl_inPFA + $10
                        word    @WbangPFA + $10
                        word    @oneminusPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @_wkeytoPFA + $10
                        word    @WatPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @fkeyqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $008E
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $005C
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $001E
                        word    (@a_drop - @a_base)/4
                        word    @keytoPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $000D
                        word    (@a_eq - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFEC
                        word    (@a_branch - @a_base)/4
                        word    $0060
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $007B
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $001E
                        word    (@a_drop - @a_base)/4
                        word    @keytoPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    (@a_litw - @a_base)/4
                        word    $007D
                        word    (@a_eq - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFEC
                        word    (@a_branch - @a_base)/4
                        word    $0038
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0005
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    (@a_drop - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $005C
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @CbangPFA + $10
                        word    @oneplusPFA + $10
                        word    @fl_inPFA + $10
                        word    @WatPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @fl_topPFA + $10
                        word    @WatPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @_eoomPFA + $10
                        word    @clearkeysPFA + $10
                        word    @resetPFA + $10
                        word    @fl_inPFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FF68
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FF64
                        word    (@a_swap - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $FF50
                        word    (@a_dup - @a_base)/4
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $05,"chars"
                        word    @crPFA + $10
                        word    @fl_countPFA + $10
                        word    @WbangPFA + $10
                        word    @minusonePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    (@a_drop - @a_base)/4
                        word    @zPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fl_bufNFA + $10
fl_skeysNFA             byte    $88,"fl_skeys"
fl_skeysPFA             word    @fl_lockPFA + $10
                        word    @WatPFA + $10
                        word    @fl_countPFA + $10
                        word    @WatPFA + $10
                        word    @zltgtPFA + $10
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0036
                        word    @fl_basePFA + $10
                        word    @WatPFA + $10
                        word    @fl_countPFA + $10
                        word    @WatPFA + $10
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @emitPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF2
                        word    @fl_topPFA + $10
                        word    @WatPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    @fl_countPFA + $10
                        word    @WbangPFA + $10
                        word    @lockdictPFA + $10
                        word    @zPFA + $10
                        word    @fl_lockPFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @fl_skeysNFA + $10
flNFA                   byte    $82,"fl"
flPFA                   word    @fl_bufPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0042
                        word    @cqPFA + $10
                        byte    $08,"fl_skeys"
                        word    @tbufPFA + $10
                        word    @ccopyPFA + $10
                        word    @tbufPFA + $10
                        word    @cqPFA + $10
                        byte    $04," cr "
                        word    (@a_over - @a_base)/4
                        word    @cappendPFA + $10
                        word    @cogidPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @cappendncPFA + $10
                        word    @cqPFA + $10
                        byte    $11,"0 emitptr W! >con"
                        word    (@a_swap - @a_base)/4
                        word    @cappendPFA + $10
                        word    @tbufPFA + $10
                        word    @cogxoPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @flNFA + $10
versionNFA              byte    $87,"version"
versionPFA              word    @cqPFA + $10
'                        byte    $20,"PropForth v3.5 2010OCT09 20:00 0"
                        byte    $34,"PropForth v3.5c Demoboard HiResVGA 20101017 15:33  0"

                        word    (@a_exit - @a_base)/4

                        word    @versionNFA + $10
freeNFA                 byte    $84,"free"
freePFA                 word    @dictendPFA + $10
                        word    @WatPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    @minusPFA + $10
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $0D,"bytes free - "
                        word    @parPFA + $10
                        word    @cogherePFA + $10
                        word    @WatPFA + $10
                        word    @minusPFA + $10
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $0E,"cog longs free"
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @freeNFA + $10
saveforthNFA            byte    $89,"saveforth"
saveforthPFA            word    @cqPFA + $10
                        byte    $04,"here"
                        word    @findPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0060
                        word    @versionPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @plusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    @oneplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @CbangPFA + $10
                        word    @pfagtnfaPFA + $10
                        word    @herePFA + $10
                        word    @WatPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @WatPFA + $10
                        word    (@a_over - @a_base)/4
                        word    @EWbangPFA + $10
                        word    @twoplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $003F
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFEA
                        word    (@a_twogtr - @a_base)/4
                        word    @iboundPFA + $10
                        word    @iPFA + $10
                        word    @minusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0040
                        word    @minPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @iPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_rot - @a_base)/4
                        word    @eewritepagePFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @leavePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002E
                        word    @emitPFA + $10
                        word    (@a_lparenpluslooprparen - @a_base)/4
                        word    $FFDC
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @saveforthNFA + $10
lparenforgetrparenNFA   byte    $88,"(forget)"
lparenforgetrparenPFA   word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0026
                        word    @findPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0016
                        word    @pfagtnfaPFA + $10
                        word    @nfagtlfaPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @herePFA + $10
                        word    @WbangPFA + $10
                        word    @WatPFA + $10
                        word    @wlastnfaPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0008
                        word    @dotcstrPFA + $10
                        word    @qqqPFA + $10
                        word    @crPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lparenforgetrparenNFA + $10
forgetNFA               byte    $86,"forget"
forgetPFA               word    @parsenwPFA + $10
                        word    @lparenforgetrparenPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @forgetNFA + $10
dotconemitNFA           byte    $88,".conemit"
dotconemitPFA           word    (@a_litw - @a_base)/4
                        word    $0200
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @inconPFA + $10
                        word    @WatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @leavePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEE
                        word    @inconPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotconemitNFA + $10
dotconcstrNFA           byte    $88,".concstr"
dotconcstrPFA           word    @CatplusplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0020
                        word    @boundsPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @CatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @maxPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $007F
                        word    @minPFA + $10
                        word    @dotconemitPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFEC
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @twodropPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotconcstrNFA + $10
dotconNFA               byte    $84,".con"
dotconPFA               word    @lthashPFA + $10
                        word    @hashsPFA + $10
                        word    @hashgtPFA + $10
                        word    @dotconcstrPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0020
                        word    @dotconemitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotconNFA + $10
dotconcrNFA             byte    $86,".concr"
dotconcrPFA             word    (@a_litw - @a_base)/4
                        word    $000D
                        word    @dotconemitPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @dotconcrNFA + $10
dlrH_fstartNFA          byte    $89,"$H_fstart"
dlrH_fstartPFA          word    (@a_doconw - @a_base)/4
                        word    @fstartPFA  + $10

                        word    @dlrH_fstartNFA + $10
fstartNFA               byte    $86,"fstart"
fstartPFA               word    @cogidPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @coginbytePFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @lshiftPFA + $10
                        word    @dlrH_entryPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0002
                        word    @lshiftPFA + $10
                        word    @orPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @orPFA + $10
                        word    @_resetdregPFA + $10
                        word    (@a_COGbang - @a_base)/4
                        word    @inbytePFA + $10
                        word    @LatPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0100
                        word    @inbytePFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    @emitptrPFA + $10
                        word    @WbangPFA + $10
                        word    @_fmaskPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @debugcmdPFA + $10
                        word    @WbangPFA + $10
                        word    @parPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0008
                        word    @plusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $00F8
                        word    @zPFA + $10
                        word    @fillPFA + $10
                        word    @hexPFA + $10
                        word    @dlrC_varendPFA + $10
                        word    @cogherePFA + $10
                        word    @WbangPFA + $10
                        word    @lockdictPFA + $10
                        word    @_forthinitializedPFA + $10
                        word    @WatPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $002C
                        word    @zPFA + $10
                        word    @fl_lockPFA + $10
                        word    @WbangPFA + $10
                        word    @minusonePFA + $10
                        word    @_forthinitializedPFA + $10
                        word    @WbangPFA + $10
                        word    @freedictPFA + $10
                        word    @cqPFA + $10
                        byte    $06,"onboot"
                        word    @findPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @executePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    @freedictPFA + $10
                        word    @_rstopPFA + $10
                        word    @oneminusPFA + $10
                        word    @_rsptrPFA + $10
                        word    (@a_COGbang - @a_base)/4
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
                        word    $001C
                        word    (@a_drop - @a_base)/4
                        word    @cqPFA + $10
                        byte    $07,"onreset"
                        word    @findPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @executePFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    @minusonePFA + $10
                        word    @compileqPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0018
                        word    @lockdictPFA + $10
                        word    @dqPFA + $10
                        byte    $03,"Cog"
                        word    @cogidPFA + $10
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $02,"ok"
                        word    @crPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0008
                        word    @minusonePFA + $10
                        word    @debugvaluePFA + $10
                        word    @LbangPFA + $10
                        word    @interpretPFA + $10
                        word    @zPFA + $10
                        word    @zPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $FFD0
                        word    (@a_exit - @a_base)/4

                        word    @fstartNFA + $10
onbootNFA               byte    $86,"onboot"
onbootPFA               word    @cogidPFA + $10
                        word    @gtconPFA + $10
                        word    @lockdictPFA + $10
                        word    @dotconcrPFA + $10
                        word    @cqPFA + $10
                        byte    $11,"PROPELLER REBOOT "
                        word    @dotconcstrPFA + $10
                        word    @versionPFA + $10
                        word    @dotconcstrPFA + $10
                        word    @dotconcrPFA + $10
                        word    @freedictPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @onbootNFA + $10
onresetNFA              byte    $87,"onreset"
onresetPFA              word    @lockdictPFA + $10
                        word    @dotconcrPFA + $10
                        word    @cqPFA + $10
                        byte    $04,"COG "
                        word    @dotconcstrPFA + $10
                        word    @cogidPFA + $10
                        word    @dotconPFA + $10
                        word    @cqPFA + $10
                        byte    $15,"RESET - last status: "
                        word    @dotconcstrPFA + $10
                        word    @lgtwPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $FFFF
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $005E
                        word    (@a_litw - @a_base)/4
                        word    $0001
                        word    (@a_over - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0014
                        word    @cqPFA + $10
                        byte    $0B,"MAIN STACK "
                        word    (@a_branch - @a_base)/4
                        word    $0012
                        word    @cqPFA + $10
                        byte    $0D,"RETURN STACK "
                        word    @dotconcstrPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0010
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    @cqPFA + $10
                        byte    $08,"OVERFLOW"
                        word    (@a_branch - @a_base)/4
                        word    $000E
                        word    @cqPFA + $10
                        byte    $09,"UNDERFLOW"
                        word    @dotconcstrPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $000C
                        word    (@a_drop - @a_base)/4
                        word    @cqPFA + $10
                        byte    $02,"OK"
                        word    @dotconcstrPFA + $10
                        word    @dotconcrPFA + $10
                        word    @freedictPFA + $10
                        word    @cogidPFA + $10
                        word    @cogconPFA + $10
                        word    @WatPFA + $10
                        word    (@a_eq - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0006
                        word    @cogidPFA + $10
                        word    @gtconPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @onresetNFA + $10
cogqNFA                 byte    $84,"cog?"
cogqPFA                 word    @dqPFA + $10
                        byte    $14,"        Forth cogs: "
                        word    @_scogPFA + $10
                        word    @WatPFA + $10
                        word    @dotPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @emitPFA + $10
                        word    @spacePFA + $10
                        word    @_lcogPFA + $10
                        word    @WatPFA + $10
                        word    @dotPFA + $10
                        word    @crPFA + $10
                        word    @dqPFA + $10
                        byte    $14,"Running Forth cogs: "
                        word    @_fcogPFA + $10
                        word    @WatPFA + $10
                        word    @dotPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @emitPFA + $10
                        word    @spacePFA + $10
                        word    @_lcogPFA + $10
                        word    @WatPFA + $10
                        word    @dotPFA + $10
                        word    @crPFA + $10
                        word    @dqPFA + $10
                        byte    $14,"         Spin cogs: "
                        word    @_scogPFA + $10
                        word    @WatPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    @dqPFA + $10
                        byte    $04,"NONE"
                        word    (@a_branch - @a_base)/4
                        word    $0016
                        word    @zPFA + $10
                        word    @dotPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $002D
                        word    @emitPFA + $10
                        word    @spacePFA + $10
                        word    @_scogPFA + $10
                        word    @WatPFA + $10
                        word    @oneminusPFA + $10
                        word    @dotPFA + $10
                        word    @crPFA + $10
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogqNFA + $10
forthonlyNFA            byte    $89,"forthonly"
forthonlyPFA            word    @_scogPFA + $10
                        word    @WatPFA + $10
                        word    @zltgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0012
                        word    @_scogPFA + $10
                        word    @WatPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @iPFA + $10
                        word    @cogstopPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFFA
                        word    (@a_litw - @a_base)/4
                        word    $7FFF
                        word    (@a_dup - @a_base)/4
                        word    @memendPFA + $10
                        word    @WbangPFA + $10
                        word    @dictendPFA + $10
                        word    @WbangPFA + $10
                        word    @zPFA + $10
                        word    @_scogPFA + $10
                        word    @WbangPFA + $10
                        word    @cogqPFA + $10
                        word    @freePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @forthonlyNFA + $10
lparencogplusrparenNFA  byte    $86,"(cog+)"
lparencogplusrparenPFA  word    @_fcogPFA + $10
                        word    @WatPFA + $10
                        word    @oneminusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @_scogPFA + $10
                        word    @WatPFA + $10
                        word    @gteqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000E
                        word    (@a_dup - @a_base)/4
                        word    @_fcogPFA + $10
                        word    @WbangPFA + $10
                        word    @cogresetPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lparencogplusrparenNFA + $10
lparencogminusrparenNFA byte    $86,"(cog-)"
lparencogminusrparenPFA word    @_fcogPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @cogidPFA + $10
                        word    @ltgtPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @oneplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @_lcogPFA + $10
                        word    @WatPFA + $10
                        word    @lteqPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $0010
                        word    (@a_dup - @a_base)/4
                        word    @oneminusPFA + $10
                        word    @cogstopPFA + $10
                        word    @_fcogPFA + $10
                        word    @WbangPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lparencogminusrparenNFA + $10
cogplusNFA              byte    $84,"cog+"
cogplusPFA              word    @lparencogplusrparenPFA + $10
                        word    @cogqPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogplusNFA + $10
cogminusNFA             byte    $84,"cog-"
cogminusPFA             word    @lparencogminusrparenPFA + $10
                        word    @cogqPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @cogminusNFA + $10
stqNFA                  byte    $83,"st?"
stqPFA                  word    @dqPFA + $10
                        byte    $04,"ST: "
                        word    @_stptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @twoplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @_sttopPFA + $10
                        word    (@a_lt - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0022
                        word    @_sttopPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @minusPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @_sttopPFA + $10
                        word    @twominusPFA + $10
                        word    @iPFA + $10
                        word    @minusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @dotlongPFA + $10
                        word    @spacePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF0
                        word    (@a_branch - @a_base)/4
                        word    $0004
                        word    (@a_drop - @a_base)/4
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @stqNFA + $10
scNFA                   byte    $82,"sc"
scPFA                   word    @_sttopPFA + $10
                        word    @_stptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @minusPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $0003
                        word    @minusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotPFA + $10
                        word    @dqPFA + $10
                        byte    $0D,"items cleared"
                        word    @crPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @zgtPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000C
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    (@a_drop - @a_base)/4
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFFC
                        word    (@a_exit - @a_base)/4

                        word    @scNFA + $10
_pnaNFA                 byte    $84,"_pna"
_pnaPFA                 word    (@a_dup - @a_base)/4
                        word    @dotwordPFA + $10
                        word    (@a_litw - @a_base)/4
                        word    $003A
                        word    @emitPFA + $10
                        word    @WatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @dotwordPFA + $10
                        word    @spacePFA + $10
                        word    @pfagtnfaPFA + $10
                        word    @dotstrnamePFA + $10
                        word    @spacePFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @_pnaNFA + $10
pfaqNFA                 byte    $84,"pfa?"
pfaqPFA                 word    (@a_dup - @a_base)/4
                        word    @pfagtnfaPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @CatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    (@a_litw - @a_base)/4
                        word    $0080
                        word    @andPFA + $10
                        word    @zeqPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @namemaxPFA + $10
                        word    @andPFA + $10
                        word    @zltgtPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    @nfagtpfaPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_zbranch - @a_base)/4
                        word    $0004
                        word    @WatPFA + $10
                        word    (@a_rot - @a_base)/4
                        word    (@a_eq - @a_base)/4
                        word    @andPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @pfaqNFA + $10
rsqNFA                  byte    $83,"rs?"
rsqPFA                  word    @dqPFA + $10
                        byte    $04,"RS: "
                        word    @_rstopPFA + $10
                        word    @_rsptrPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    @oneplusPFA + $10
                        word    @minusPFA + $10
                        word    @zPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @_rstopPFA + $10
                        word    @oneminusPFA + $10
                        word    @iPFA + $10
                        word    @minusPFA + $10
                        word    (@a_COGat - @a_base)/4
                        word    (@a_dup - @a_base)/4
                        word    @twominusPFA + $10
                        word    @WatPFA + $10
                        word    @pfaqPFA + $10
                        word    (@a_zbranch - @a_base)/4
                        word    $000A
                        word    @twominusPFA + $10
                        word    @_pnaPFA + $10
                        word    (@a_branch - @a_base)/4
                        word    $0006
                        word    @dotlongPFA + $10
                        word    @spacePFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFDC
                        word    @crPFA + $10
                        word    (@a_exit - @a_base)/4

                        word    @rsqNFA + $10
lasmNFA                 byte    $84,"lasm"
lasmPFA                 word    @fourplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @LatPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    @fourplusPFA + $10
                        word    (@a_swap - @a_base)/4
                        word    (@a_over - @a_base)/4
                        word    @LatPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @cogherePFA + $10
                        word    @WbangPFA + $10
                        word    (@a_twogtr - @a_base)/4
                        word    @fourplusPFA + $10
                        word    (@a_dup - @a_base)/4
                        word    @LatPFA + $10
                        word    @cogcommaPFA + $10
                        word    (@a_lparenlooprparen - @a_base)/4
                        word    $FFF6
                        word    (@a_drop - @a_base)/4
                        word    (@a_exit - @a_base)/4

                        word    @lasmNFA + $10
wlastnfaNFA             byte    $88,"wlastnfa"
wlastnfaPFA             word    (@a_dovarw - @a_base) /4
                        word    @wlastnfaNFA + $10
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

ForthDictEnd
ForthMemoryEnd