package main

import "fmt"
import "rpiGPIO"

func main() {
	if rpiGPIO.InitErr != nil {
		fmt.Println( rpiGPIO.InitErr)
	} else {
		rpiGPIO.CogReset()
	}


}

