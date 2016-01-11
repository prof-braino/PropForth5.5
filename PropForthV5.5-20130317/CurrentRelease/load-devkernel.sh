#bash
# this script is for linux 64 (Linux Mint 17.2 MATE)

# bash -v ./propeller-load -p /dev/ttyUSB0 -e PF5.5DevKernel.eeprom
# ./propeller-load -p /dev/ttyUSB0 -e PF5.5DevKernel.eeprom
# ./propeller-load -p /dev/ttyUSB0 -e /home/braino/PropForth5.5/mygo/V5.5/kernels/DevKernel.eeprom

./propeller-load -p /dev/ttyUSB0 -e -r ~/PropForth5.5/mygo/V5.5/kernels/MAKE/results/outputFiles/DevKernel.eeprom

