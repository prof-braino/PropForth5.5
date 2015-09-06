
set dosnettesterr=0

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SnetIPKernel.txt
if %ERRORLEVEL% neq 0 set dosnettesterr=1
if %dosnettesterr% neq 0 goto end


goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SnetEEpromIPKernel.txt
if %ERRORLEVEL% neq 0 set dosnettesterr=2
if %dosnettesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SnetEEpromHTTPKernel.txt
if %ERRORLEVEL% neq 0 set dosnettesterr=3
if %dosnettesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SnetEEpromHTTPTime.txt
if %ERRORLEVEL% neq 0 set dosnettesterr=4
if %dosnettesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SnetFsrdSDHTTPKernel.txt
if %ERRORLEVEL% neq 0 set dosnettesterr=5
if %dosnettesterr% neq 0 goto end

goterm %PROPCOMM% %PROPBAUD%  r TEST/scripts/SnetFsrdSDHTTPTime.txt
if %ERRORLEVEL% neq 0 set dosnettesterr=6
if %dosnettesterr% neq 0 goto end


:end
