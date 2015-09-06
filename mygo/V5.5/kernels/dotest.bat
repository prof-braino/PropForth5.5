rmdir TEST\results /S /Q
mkdir TEST\results
mkdir TEST\results\runLogs
mkdir TEST\results\resultFiles

set dotesterr=0

propellent /PORT %PROPCOMM% /EEPROM MAKE/src/StartKernel.eeprom
if %ERRORLEVEL% neq 0 set dotesterr=1
if %dotesterr% neq 0 goto end


goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/StartKernel.txt
if %ERRORLEVEL% neq 0 set dotesterr=2
if %dotesterr% neq 0 goto end
if %dotesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/BootKernel.txt
if %ERRORLEVEL% neq 0 set dotesterr=3
if %dotesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/BootOptimizeKernel.txt
if %ERRORLEVEL% neq 0 set dotesterr=4
if %dotesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/DevKernel.txt
if %ERRORLEVEL% neq 0 set dotesterr=5
if %dotesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/EEpromKernel.txt
if %ERRORLEVEL% neq 0 set dotesterr=6
if %dotesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SDKernel.txt
if %ERRORLEVEL% neq 0 set dotesterr=7
if %dotesterr% neq 0 goto end

:end


