rmdir MAKE\results /S /Q
mkdir MAKE\results
mkdir MAKE\results\runLogs
mkdir MAKE\results\resultFiles
mkdir MAKE\results\outputFiles

set domakeerr=0

propellent /PORT %PROPCOMM% /EEPROM MAKE/src/StartKernel.eeprom
if %ERRORLEVEL% neq 0 set domakeerr=1
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeAsmKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=2
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeStartKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=3
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/StartKernel.eeprom MAKE/results/outputFiles/StartKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=4
if not exist MAKE/results/outputFiles/StartKernel.eeprom set domakeerr=4
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeOptsym.txt
if %ERRORLEVEL% neq 0 set domakeerr=5
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeBootKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=6
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/BootKernel.eeprom MAKE/results/outputFiles/BootKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=7
if not exist MAKE/results/outputFiles/BootKernel.eeprom set domakeerr=7
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeBootOptimize.txt
if %ERRORLEVEL% neq 0 set domakeerr=8
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeBootOptimizeKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=9
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/BootOptimizeKernel.eeprom MAKE/results/outputFiles/BootOptimizeKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=10
if not exist MAKE/results/outputFiles/BootOptimizeKernel.eeprom set domakeerr=10
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeDevKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=11
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/DevKernel.eeprom MAKE/results/outputFiles/DevKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=12
if not exist MAKE/results/outputFiles/DevKernel.eeprom set domakeerr=12
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeFsrdKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=13
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/FsrdKernel.eeprom MAKE/results/outputFiles/FsrdKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=14
if not exist MAKE/results/outputFiles/FsrdKernel.eeprom set domakeerr=14
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeEEpromKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=15
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/EEpromKernel.eeprom MAKE/results/outputFiles/EEpromKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=16
if not exist MAKE/results/outputFiles/EEpromKernel.eeprom set domakeerr=16
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeSDcommon.txt
if %ERRORLEVEL% neq 0 set domakeerr=17
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeSDKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=18
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/SDKernel.eeprom MAKE/results/outputFiles/SDKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=19
if not exist MAKE/results/outputFiles/SDKernel.eeprom set domakeerr=19
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeIP.txt
if %ERRORLEVEL% neq 0 set domakeerr=20
if %domakeerr% neq 0 goto end
goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeIPConfig.txt
if %ERRORLEVEL% neq 0 set domakeerr=21
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeIPKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=22
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/IPKernel.eeprom MAKE/results/outputFiles/IPKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=23
if not exist MAKE/results/outputFiles/IPKernel.eeprom set domakeerr=23
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeEEpromIPKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=24
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/EEpromIPKernel.eeprom MAKE/results/outputFiles/EEpromIPKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=25
if not exist MAKE/results/outputFiles/EEpromIPKernel.eeprom set domakeerr=25
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/MakeEEpromHTTPKernel.txt
if %ERRORLEVEL% neq 0 set domakeerr=26
if %domakeerr% neq 0 goto end
propellent /COMPILE /GUI OFF /SAVEEEPROM /IMAGE MAKE/results/outputFiles/EEpromHTTPKernel.eeprom MAKE/results/outputFiles/EEpromHTTPKernel.spin
if %ERRORLEVEL% neq 0 set domakeerr=27
if not exist MAKE/results/outputFiles/EEpromHTTPKernel.eeprom set domakeerr=27
if %domakeerr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD% r MAKE/scripts/CheckKernels.txt
if %ERRORLEVEL% neq 0 set domakeerr=28
if %domakeerr% neq 0 goto end


:end


