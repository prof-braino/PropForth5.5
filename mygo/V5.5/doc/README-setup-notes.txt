[Notes for setting up PropForth6 and tools, git and github]

These notes are DRAFT.  The might be broken into separate sections, for now it is one big list. The activities covered are:

1. Install and set up the Linux software tools.
2. Set up your Linux Environment variables
3. set up GIT so you can send your changes back out to the rest of us
4. set up the propforth build automation 
5. Set up GO environment 
6. run the pr.sh script to configure the terminal window as the build automation window
7. compile/install the goterm programs 
8. Connect the USB cable to the Physical Prop Board
9. Add/change the source code text files on your branch, and push tese back to github to share with the rest of the team

**************************************************
1. Install and set up the Linux software tools.
**************************************************

Setup the linux tools. You dont have to do much more than run several commands, these only take a couple minutes.
Copy/paste the follwing into a command line terminal window.  These install the terminal program minicon, the compiler to build the go communications programs, the go language support. 

[setup linux - install tools]
[code]
sudo apt-get install minicom
sudo adduser $USER dialout
sudo chmod a+rw /dev/ttyUSB0
[/code]

[minicom setup]
[code]
sudo minicom -o
[serial port sertup > a - serial device: /dev/ttyUSB0]
[screen and keyboard > p - add linefeed : yes]
[save as dfl]
[exit]
[/code]


[this installs compile basic support]
[code]
sudo apt-get install build-essential
[/code]

[**************************************]
install opensin - in progress
[clone the openspin git repository from github]
https://github.com/parallaxinc/OpenSpin.git
cd ~
git clone https://github.com/parallaxinc/OpenSpin.git
cd OpenSpin
[run the make comand, this automatically find the makefile and comples openspin]
make
you should many lines with g++ -Wall -g -static -o /home/....
this can take a while depending on your pc.
in the directory ~/OpenSpin/build
you should find an executable:
[code]
openspin
[/code]

you can copy this to the directory where it is needed below

command to produce an EEPROM file (using spin file in this directory) is
[code]
./openspin -e StartKernel.spin 
[/code]


[**************************************]
install propgcc - in progress
[**************************************]



[install go from https://golang.org/ website go1.5.1.linux-amd64.tar.gz]
[code]
sudo tar -C /usr/local -xzf go1.5.1.linux-amd64.tar.gz
[/code]

Notice: when you type "go" into the command prompt, the response is still "go is not currently installed"
We need to EXPORT the environment variable for the session.

*************************************************
2. Set up your Linux Environment variables for GO
*************************************************

You can run the following every time you open a new terminal window to compile the go code,
or you can add these lines to your /etc/profile (for a system-wide installation) or $HOME/.profile:

[To add line to your $HOME/.profile]
[code]
sudo edit /etc/profile
[/code]

[Add this line to the end of the file]
[code]
export PATH=$PATH:/usr/local/go/bin
[/code]
[save the changes to the file]

[EXPORT for this session only]
[code]
export PATH=$PATH:/usr/local/go/bin
[/code]

Notice: Now when you type "go" into the command prompt, the response is now the go help menu. Success!
If you start a later session and do not see the help menu you may need to EXPORT the environment variable for the session.

*********************************************************************
3. set up GIT so you can send your changes back out to the rest of us
*********************************************************************
[Git is install by default on most linux.  Install as needed on windows]

[Ensure your git user.name  and git user.email are set if you wish to contribute to github]
[code]
git config --list
[/code]

[set your github username and registration email if you wish to contribute back to a project]
git config --global user.name "John Doe"
git config --global user.email johndoe@example.com


[git commands]
[code]
git clone https://github.com/PropForth6/PropForth6.git
cd PropForth6/
[/code]

[display current branches]
[code]
git branch
[/code]
[display current branches with information]
[code]
git branch -v
[/code]

[checkout the devbranch as your starting point]
[code]
git checkout dev
[/code]

[create a new branch in the form YYYMMDD_topic]
[code]
git branch YYYYMMDD_topic 
[/code]
(example git branch 20151231_braino_fix_readme)

[checkout the branch]
[code]
git checkout YYYMMDD_topic
[/code]
(example git checkout 20151231_braino_fix_readme)

===========================================================
[OR you can do both create branch and checkout in one step]
[create a new branch by 'checking out' the new branch name]
git checkout -b YYYMMDD_topic
===========================================================

*********************************************************************************
4. edit the configuration files so the propforth build automation runs on your PC
*********************************************************************************

.............................................................................................................
before we start contributing any changes, we need to finish setting up the tools
The propforth repository we just cloned to our PC has 
automated build and test tools built in.  To finsih seting these up, we need to run the go language compiler.
.............................................................................................................

The propforth build automation relies primarily on Sal's terminal communications program written is go language.

All the work is done, all we have to do is run a script to build the programs on this PC. 

The following needs to be done only once on the PC, until something changes (which is rare). 

[CHECK----EDIT the serial_proxy.conf to /dev/ttyUSB0 ??????]
change
-s /dev/XXXXXXXXXXXx -S -P -A -b 230400 -a -e
into
-s /dev/ttyUSB0 -S -P -A -b 230400 -a -e

[compile the go serial at least once]
[code]
cd tools/
cd serial_proxy/
[/code]
[set build.sh executable, and run build.sh]
[code]
./build.sh
ls -alF
[/code]
[see that serial_proxy executable was created]

=========== begin script to set up tool environment variables =================

***********************************************************************************************
5. Set up GO environment and install (complie) the communication programs written in go language
***********************************************************************************************

----- this is the part that was missing. It comes from the go lang install instructions.....
 * Add /usr/local/go/bin to the PATH environment variable. You can do this by adding this line to your /etc/profile (for a system-wide installation) or $HOME/.profile:
[code]
sudo edit /etc/profile
[/code]
 * [Add this line to the end of the file]
[code]
export PATH=$PATH:/usr/local/go/bin
[/code]
 * [save the changes to the file]
----- this is the part that was missing. It comes from the go lang install instructions.....

Notice: when you type "go" into the command prompt after the environment variables are set, 
the response is no longer "go is not currently installed"; 
Now the response is  the "go" help context display. 

****************************************************************************************
6.  run the pr.sh script to configure the terminal window as the build automation window
****************************************************************************************

[This runs a script to set envirnment variables for GOTERM]
[ GOTERM is the routine that handles seriall communication to the prop]
[If you open another termainal, this will not be present until you run the ./pr.sh script]

[MUST run pr.sh in the terminal before the build and text script tools will work]
[pr.sh must be run again in any new windw. I.E. if something does't work, probably you didn't run the pr.sh in that terminal yet]

[display the environment variables, and notice that the PATH entries have s no propforth6 or go entries]
[code]
env
[/code]

[switch to the go surce directory and run the script to set up the environmaet variables]

[code]
cd ..
cd mygo/
./pr.sh
env
[/code]

[notice that a PropForth6 entry has been added the PATH environment variable]
[notice that the PropForth6 entry to the PATH environment variable is local to THIS TERMINAL WINDOW ONLY.]  
[If you open another termainal, this will not be present until you run the ./pr.sh script]

Notice: when you type "goterm" into the command prompt before the environment variables are set, 
(or before the goterm is compiled/installed)
the response is "goterm is not currently installed".

=========== end script to set up tool environment variables =================

**************************************
7. compile/install the goterm programs 
**************************************


============ begin build/install the go termnal communication programs === 

[install the go programs at least once]
[code]
go install goterm
go install goproxyterm
[/code]

[notice a bin directoy was created in mygo, containing executables for goterm and goproxyterm]
[code]
goterm
[/code]
[notice the goterm help message when gotern is executed without parameters]


Notice: when you type "goterm" into the command prompt after the environment variables are set, 
the response is no longer "goterm is not currently installed"; 
Now the response is  the "goterm" help context display. 

If you get a message "goterm not installed" when you know your've already done this,
it means you need to run the pr.sh script in this current termnal window

navigate to 
~/PropForth6/tools/mygo/pr.sh
and run the script from that directory.

============ end build/install the go termnal communication programs === 

============ physical connection of the Parallax Propeller P8X32A =====================

***************************************************
8. Connect the USB cable to the Physical Prop Board
***************************************************

[Move to the Linux directory...e.g /home/braino/PropForth6/Linux]
[code]
cd ..
cd ..
cd Linux
[/code]

[CONNECT the PROPELLER BOARD / VIRTUAL COMMPORT via USB cable]
[The cable must be connect/powered on for the PC to detect the virtual comm port]
[notice if you run the buildall script WITHOUT the board connected you get the goterrm help menu 17 times]

[Devices -> USB Devices -> Parallax Inc Propeller Quickstart [1000] ]   Quickstart Rev B
[Devices -> USB Devices -> FTDI FT231X USB UART [1000] ]                Quickstart Rev B
[Devices -> USB Devices -> FTDI FT232R USB UART [0600] ]  Quickstart Rev A

[code]
./build.sh
[/code]

[NOTE: BUILDALL.SH is NOT the top script, if things don't work, check you ran build.sh]

At this point the ./build.sh script should run, and build the proforth kernels from source. 
The entire process takes under an hour, about 45 minutes on my machines

The unmodified source code should generate files in  ./PropForth6/results
that are IDENTICAL to the files supplied in ./PropForth6/refResults

NOTE: the tools know to ignore things like timestamps, user names, and PC specific path names.
The source  code and image files will be identical if set up correctly.

Once you are satisfied the automation functions, you can start to modify the source to create custom kernels. 

************************************************************************************************************************
9. Add/change the source code text files on your branch, and push tese back to github to share with the rest of the team
************************************************************************************************************************

==============================================================================================================
Now we have all the Propforth environment and tools set up.  We can add or cnahge an files, 
and contribute those back into the project.
Start by create perhaps some documentation on how our function is going to work
==============================================================================================================

[create file, do some work; then add the file to the repository]
[first, check the status, see the new or changed file is untracked] 
[code]
git status
[/code]
[add the file ad all others (to the staging area so it can be sent to the repository)]
[code]
git add .
[/code]
[see that is is ready]
[code]
git status
[/code]
[commit the changed files to the branch]
[code]
git commit -m "messge that says what you are committing"
[/code]

===========================================================
[OR you can do both add and commit in one step]
git commit -a -m "messge that says what you are committing"
===========================================================

[Push the changed you committed to your branch up to github so the rest of the team can see it]
[code]
git push -u --all
[/code]
(this asks your github username and password)
(you must be registered to push to github, ad your  username must be part of the team)

[see that you are up to date]
[code]
git status
[/code]

================

[subsequent contribuation using the same branch, for example on aa later day]
[so a week went by since your last commit.  Check for new material from other contributors]
[the log is a scrollable list of the commits so far. exit the log using "q"]
[code]
git log
[/code]

[fetch the list of changes from the github repository]
[code]
git fetch 
[/code]

[pull the found changes to my machine]
[code]
git pull --all
[/code]

[now are are ready to continue development]

== end git new branch ================================================================================

















