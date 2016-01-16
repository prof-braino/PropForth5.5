PROPFORTH GY-80 IMU drivers and datalogger

This is phase 1 of the Propforth IMU project.

INSTRUCTIONS

1) Hardware:
1a) - Quickstart or other Prop board (Parallax P8X32A)
1b) - SD card - I'm using pins 16-21 as on Spinneret (default)
1c) - GY-80 - connected on EEPROM pins SDA and SCL
1d) (optional) HC05 blue tooth serial cable replacement (for Android as interface)

2) Software - SD kernel
Load propforthSD kernel (.spin) using PropTool etc as usual

3) Start the  terminal emulator program in the usual manner (described elsewhere) 

4) COPY/PASTE the following source code files into the terminal window in the usual manner (described elsewhere)  

5) - The file:

      00-sdfsInitScript.f

only needs be pasted in once, this initializes and setsup the SD card.
If you wish to delete the SD card contents (e.g. to start over clean)
reboot and paste this file into the terminal again. 

6) -These files may be copy/pasted into the terminal in their entirety:

      11-DoubleMath.f
      12-time.f

7) - This file creates all the driver files for the GY-80

       13- GY80-load D Application 20140608-1331 logger Graph FINAL.f

NOTICE that the file has many comment lines with 

\ fl

and that these come before each driver file definition. This is so you can re load individual drive files,
without having to erase the cared and start over every time you try a change. 
BEGIN the copy operation with the "fl" (do not include the comment designator "\" )
and paste the modified code into the termnal window as  usual.

8) - This file creates logboot.f on the SD card

15-loggerBootDailyFiles-GY-80-20140612-0001 LOGGER signed FASTER4- FINAL.f

9) - This file creates graphboot.f on the SD card

17-loggerBootDailyFiles-GY-80-20140614-1445 GRAPH-signed.f

NOTICE - you only need one or the other of logboot.f or graphboot.f

logboot.f loads the drivers for GY-80 (BMP085, ADXL345, L3G4, HCM5883) and for TIME (doublemath.f and time.f)
logboot.f does NOT include altimeter support

graphboot.f loads the drivers for GY-80 (BMP085, ADXL345, L3G4, HCM5883) and for the character based data graphing routines
graphboot.f does NOT include time support

(Sorry, there was't enough room for both without optimization in assembler, that is a later step)

10)  Load and run the application:

select either of the following:

-for logboot.f-

reboot - to clear the system

fload logboot.f   - to autoload all the drivers in the correct order

GY-80 - starts the non graphic numberic terminal display.  exit with the ESC key or reboot

mountusr ls  - mount the user data particion, and list the files

fread IMU2012-01-01 - display the contents of the default log file

2014 12 17 13 59 00 setLocalTime   -  set the time to December 17 2014, 1:59 PM; this creates a new logfile

fread IMU2014-12-17 - display the contents of the 

-for graphboot.f-

reboot - to clear the system

fload graphboot.f   - to autoload all the drivers in the correct order

GY-80 - starts the terminal graphic display.  exit with the ESC key or reboot

mountusr ls  - mount the user data particion, and list the files

fread IMUnoTIMExxxx - display the contents of the loag file














