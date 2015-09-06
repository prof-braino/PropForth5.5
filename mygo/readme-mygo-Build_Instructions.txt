HI

You only need the mygo directory if you are using the PropForth5.5 build and test scripts.

You only need the build and test scripts if you plan to generate the kernels from scratch.

You only need to generate the kernels from scratch if you modified the kernel source code. 

For the most part, you do NOT want to modify the kernel source code unless your name is Sal Sanci, Nick Lordi, or Peter Jakacki.  

If you do want to modify the kernel source and you are not known to me, please introduce yourself.

Also, you sould probably use the PropForth6 kernel. PF6 is funstionally equivalent to PF5.5, but the build process has been improved, and pooled multitaking option is introduced.  PF5.5 is added to GIT hub for completeness, but should not be used as it is no longer supported.

The instructions are very terse, if you still wish to play with PF5.5, you are pretty much on you own.

Instructions:

INSTALL

INSTALL GOLANG

Install go1.5 language from the golang.org website.  Do no use the go package provided in the ubuntu software manager, is different and or had issues. 

INSTALL GOTERM

cd to the scr/gomuxterm and scr/goterm directories, and compile build and install goterm and gomuxterm 

scr/goterm
go install goterm
../scr/gomuxterm
go install gomuxterm

Remember, if you compile, to DELETE any pre-existing executable goterm.exe and gotmuxterm.exe in mygo/bin
DELETE any pre-existing *.a files in mygo/pkg/windows_386 or mygo/pkg/windows_amd64,
as go only compiles the new file if the old file does not exist.

CONNECT THE PROP

The Parallax Propeller board or your chosing MUST be connected to your system (and powered on as applicable) for the com port to be properly detected. 

The scripts and tools will not work as described if the prop is not connected.

I use the Propeller Quickstart Rev B for these examples as this is cheapest and simplest. These instructions will also work with any standard prop configuration,and any custom configuration as long as the epprom and serial lines have not been changed.  If you have a custom board where the serial and or eeprom lines have been moved, please edit the scripts as necessary.  Everything will still work, or at least we haven't yet found one that doesn't.

GOSHELL.BAT

edit mygo/goshell.bat to suit your system. 
Typically you only hve to change the comport setting to match your physical PC virtual comport assignment, 
and the IP setting to match you internal network.  Also the IP setting is only used by the Parallax Spinerette board (or WIZNET5100 series equivalent).  I stopped using the spinerette so IP support is no longer well maintained, but it still is included since it exists and it worked last time we tried it. 

Run the goshell.bat script to set your environment variables.

This MUST be run in the termianl window where you will run the DOMAKE.BAT and DOTEST.BAT scripts.  If not run, the environment variable will not have been set, and the scripts will fail. 

DOMAKE.BAT

After running the GOSHELL.BAT script, cd to the directory mygo/V5.5/kernels

cd mygo/V5.5/kernels

Run the domake.bat script.  If set up correctly, the scripts should run for about an hour (depending on you physical PC resources). 
The domake.bat script creates spin and eepropm files suitable for loading onto a standard prop system.
The spin and eepron file output will be located at mygo/V5.5/MAKE/results/outputFiles

The script execution logs will be located at mygo/V5.5/MAKE/results/resultFiles
Check the logs if any errors occur, this will point to tthe file where the first (and subsequent) error was found, in points to the file to start debugging.

Notice that mygo/V5.5/MAKE/referenceResults has a previous copy of the mygo/V5.5/MAKE/results/ directory.
If you run the scripts and made not changes, you will get identical result as recorded in the reference results.

If you made any changes to the code (not comments), those changes will be reflect as a difference from the reference results.

When you are satisfied that your changes are correct, replace the old reference results with you new results, to establish a new reference results base line.  

DOTEST.BAT

To facilitate results verification, Sal made the dotest.bat script.  dotest.bat checks each file in the results directory, and compares it to the same file in the reference result directory.  The script will detect difference and ingnore or flag as error, as appropriate.

Timestamps:  Timestamps are by definition different for every run, so timestamps are not flagged.  You can still use these to check if something runs slower or faster than last time, a useful  check in debugging.

Outputpath:  The path should be the same unless you changed it. Bad paths often mean we forrgot to run the goshell.bat script in the termanal window. 

Echoed message:  The echoed message is whatt we are looking at.  If nothing changed, the message should be the same as last time, and the result should be the same as last time.   If something changed, you need to ensure it changed in the way you expected, and notice any other change cause in the build log, to insure nothing got broken.  This is very handy in locating secondary impacts that would otherwise become hidden bugs. 

Again, after running the GOSHELL.BAT script to set up the environment variables in the terminal window, run the DOTEST.BAT script. The script should run in about an hour depending on physical system resources.  The script will display any flagged changes on the screen while the script is running (in case you spot and erro and wish to terminate the script to fix it), and will also logany flgged changes to the logfile in mygo/V5.5/kernels/TEST/results

USE PF6 INSTEAD

The same as above is used in PF6, just better organized.  PF5.5 is for DOS only (windows XP dos window command line) with possible modifcation for Linux.  PF6 is designed and tested to be used with Windows, Linux, and OSX. 

  





