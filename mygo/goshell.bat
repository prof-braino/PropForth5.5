set PATH=%PATH%;%HOME%\mygo\bin
set GOPATH=%HOME%\mygo


rem
rem TEST PARAMETERS - used by the test scripts
rem
set PROPCOMM=com5
set PROPBAUD=230400
set PROPTELNET0=192.168.0.129:3020
set PROPTELNET1=192.168.0.129:3021
set PROPTELNET2=192.168.0.129:3022
set PROPTELNET3=192.168.0.129:3023
set PROPHTTP=192.168.0.129:8080

rem
rem
rem BUILD PARAMETERS - insterted into all the appropriate build sources
rem
   
set _clkmode=xtal1+pll16x
set _xinfreq=5_000_000

REM	$S_cdsz forth word 
REM	$S_txpin forth word 
REM	$S_rxpin forth word 
REM	$S_baud forth word - the actual baud rate will be 4 times this number
REM	$S_con forth word

  
set dlrS_cdsz=224
set dlrS_txpin=30
set dlrS_rxpin=31
set dlrS_baud=57_600
set dlrS_con=7
set startcog=6

REM	
REM	This SD pin configuration is for the spinneret board
REM
	  
REM	$S_sd_cs forth word
REM	$S_sd_di forth word
REM	$S_sd_clk forth word
REM	$S_sd_do forth word

set dlrS_sd_cs=19
set dlrS_sd_di=20
set dlrS_sd_clk=21
set dlrS_sd_do=16

REM	
REM	 This SD pin configuration is for a test board (Prototype board with an sd card added)
REM	
 
REM	dlrS_sd_cs = 0            ' $S_sd_cs forth word
REM	dlrS_sd_di = 1            ' $S_sd_di forth word
REM	dlrS_sd_clk = 2           ' $S_sd_clk forth word
REM	dlrS_sd_do = 3            ' $S_sd_do forth word

REM	
REM	 This SD pin configuration is for the gadget gangster propeller platform
REM	
 
REM	dlrS_sd_cs = 4            ' $S_sd_cs forth word
REM	dlrS_sd_di = 3            ' $S_sd_di forth word
REM	dlrS_sd_clk = 2           ' $S_sd_clk forth word
REM	dlrS_sd_do = 1            ' $S_sd_do forth word

REM	
REM	The IP configuration
REM	

REM	dlrS_ip_sockbufsize = $800
REM	dlrS_ip_sockbufmask = $7FF
REM	dlrS_ip_sockbufinit = $55
REM	dlrS_ip_ipnumsock= 4
  
REM	dlrS_ip_sockbufsize = $1000
REM	dlrS_ip_sockbufmask = $FFF
REM	dlrS_ip_sockbufinit = $0A
REM	dlrS_ip_ipnumsock= 2

REM	dlrS_ip_sockbufsize = $2000
REM	dlrS_ip_sockbufmask = $1FFF
REM	dlrS_ip_sockbufinit = $03
REM	dlrS_ip_ipnumsock= 1


set dlrS_ip_light=$FFFF
set dlrS_ip_cog=5

set dlrS_ip_sockbufsize=$800
set dlrS_ip_sockbufmask=$7FF
set dlrS_ip_sockbufinit=$55
set dlrS_ip_numsock=4

set dlrS_ip_numTelnet=4

set dlrS_ip_telnetport=3020

set dlrS_ip_httpport=8080

REM					192.168.0.1
set dlrS_ip_gatewayhi=$C0_A8
set dlrS_ip_gatewaylo=$00_01
REM					255.255.255.0
set dlrS_ip_subnetmaskhi=$FF_FF
set dlrS_ip_subnetmasklo=$FF_00
REM					192.168.0.129
set dlrS_ip_addrhi=$C0_A8
set dlrS_ip_addrlo=$00_81
REM					00:0c:29:8b:00:70
set dlrS_ip_machi=$00_0C
set dlrS_ip_macmid=$29_8B
set dlrS_ip_maclo=$00_70

cmd

