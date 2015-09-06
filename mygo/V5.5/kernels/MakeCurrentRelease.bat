rmdir ..\CurrentRelease /S /Q
rmdir ..\doc /S /Q
del ..\README.txt


mkdir ..\CurrentRelease
mkdir ..\CurrentRelease\PropForth

copy MAKE\results\outputFiles\DevKernel.spin           ..\CurrentRelease\PropForth

mkdir ..\CurrentRelease\PropForthIP
copy MAKE\results\outputFiles\IPKernel.spin            ..\CurrentRelease\PropForthIP


mkdir ..\CurrentRelease\PropForthEEprom
copy MAKE\results\outputFiles\EEpromKernel.spin        ..\CurrentRelease\PropForthEEProm
copy MAKE\src\optimize\fs\EEprom_boot.f                ..\CurrentRelease\PropForthEEProm

mkdir ..\CurrentRelease\PropForthEEpromIP
copy MAKE\results\outputFiles\EEpromIPKernel.spin      ..\CurrentRelease\PropForthEEPromIP
copy MAKE\src\optimize\fs\EEprom_boot.f                ..\CurrentRelease\PropForthEEPromIP

rem mkdir ..\CurrentRelease\PropForthEEpromHTTP
rem copy MAKE\results\outputFiles\EEpromHTTPKernel.spin    ..\CurrentRelease\PropForthEEPromHTTP
rem copy MAKE\src\optimize\fs\EEprom_boot.f                ..\CurrentRelease\PropForthEEPromHTTP

mkdir ..\CurrentRelease\PropForthSD
copy MAKE\results\outputFiles\SDKernel.spin            ..\CurrentRelease\PropForthSD
copy MAKE\src\optimize\fs\sd\sdfsInitScript.f          ..\CurrentRelease\PropForthSD

mkdir ..\CurrentRelease\Extensions
copy fl.f + MAKE\src\optimize\dev\lac.f                ..\CurrentRelease\Extensions\lac.f
copy fl.f + MAKE\src\optimize\dev\mcs.f                ..\CurrentRelease\Extensions\mcs.f
copy fl.f + MAKE\src\optimize\dev\norom.f              ..\CurrentRelease\Extensions\norom.f   
copy fl.f + MAKE\src\optimize\dev\mcsnorom.f           ..\CurrentRelease\Extensions\mcsnorom.f
copy fl.f + MAKE\src\optimize\dev\term.f               ..\CurrentRelease\Extensions\term.f  
copy fl.f + MAKE\src\optimize\dev\snet.f               ..\CurrentRelease\Extensions\snet.f
copy fl.f + MAKE\src\optimize\dev\wordlister.f         ..\CurrentRelease\Extensions\wordlister.f 
copy fl.f + MAKE\src\optimize\dev\DoubleMath.f         ..\CurrentRelease\Extensions\DoubleMath.f 
copy fl.f + MAKE\src\optimize\dev\time.f               ..\CurrentRelease\Extensions\time.f 
copy fl.f + MAKE\src\optimize\dev\float.f              ..\CurrentRelease\Extensions\float.f 
copy fl.f + MAKE\src\optimize\dev\math_ext.f           ..\CurrentRelease\Extensions\math_ext.f
copy fl.f + MAKE\src\optimize\dev\servo.f              ..\CurrentRelease\Extensions\servo.f 
copy fl.f + MAKE\src\optimize\dev\ds1302.f             ..\CurrentRelease\Extensions\ds1302.f 
copy fl.f + MAKE\src\optimize\dev\SR04.f               ..\CurrentRelease\Extensions\SR04.f 
copy fl.f + MAKE\src\optimize\dev\bmp085.f             ..\CurrentRelease\Extensions\bmp085.f 
copy fl.f + MAKE\src\optimize\dev\bmp085_alt.f         ..\CurrentRelease\Extensions\bmp085_alt.f 
copy MAKE\src\optimize\dev\halfdupSerial.f             ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\vga.f		       ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\bmp085.xlsx                 ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\BluetoothHC05-06.f          ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\build_boot.f                ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\QSboot.f                    ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\CCboot.f                    ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\VGAboot.f                   ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\bot.f                       ..\CurrentRelease\Extensions
copy MAKE\src\optimize\dev\848_sightBoot.f             ..\CurrentRelease\Extensions


copy fl.f + MAKE\src\optimize\asm.f                    ..\CurrentRelease\Extensions\asm.f


copy doc\GettingStartedPropForth.txt            ..\CurrentRelease\PropForth
copy doc\GettingStartedPropForthIP.txt          ..\CurrentRelease\PropForthIP
copy doc\GettingStartedPropForthEEprom.txt      ..\CurrentRelease\PropForthEEprom
copy doc\GettingStartedPropForthEEpromIP.txt    ..\CurrentRelease\PropForthEEpromIP
rem copy doc\GettingStartedPropForthEEpromHTTP.txt  ..\CurrentRelease\PropForthEEpromHTTP
copy doc\GettingStartedPropForthSD.txt          ..\CurrentRelease\PropForthSD


copy doc\README.txt                             ..\README.txt

mkdir ..\doc
mkdir ..\doc\PropForth_files

copy doc\PropForth.htm                          ..\doc\PropForth.htm
copy doc\PropForth_files\*.*                    ..\doc\PropForth_files
copy doc\ReleaseNotes.txt                       ..\doc\ReleaseNotes.txt

