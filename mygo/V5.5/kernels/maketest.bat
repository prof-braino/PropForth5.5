set domakeerr=9999
set dotesterr=9999
set dosnettesterr=9999


call domake.bat
echo domake.bat result: %domakeerr%
if %domakeerr% neq 0 goto end

call dotest.bat
echo dotest.bat result: %dotesterr%
if %dotesterr% neq 0 goto end

call dosnettest.bat
echo dosnettest.bat result: %dosnettesterr%
if %dosnettesterr% neq 0 goto end

:end
echo domake.bat result: %domakeerr%
echo dotest.bat result: %dotesterr%
echo dosnettest.bat result: %dosnettesterr%


