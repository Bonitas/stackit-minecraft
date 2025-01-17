package common

import (
	"fmt"
	"github.com/fatih/color"
)

func PrintMixedGreen(format, value string) {
	green := color.New(color.FgGreen).SprintFunc()
	fmt.Printf(format, green(value))
}
