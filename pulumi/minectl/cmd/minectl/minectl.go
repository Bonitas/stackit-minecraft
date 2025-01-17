package minectl

import (
	"fmt"
	"github.com/morikuni/aec"
	"github.com/spf13/cobra"
	"os"
)

var (
	// Version as per git repo
	Version string

	// GitCommit as per git repo
	GitCommit string
)

func init() {
	minectlCmd.AddCommand(versionCmd)
}

var minectlCmd = &cobra.Command{
	Use:   "minectl",
	Short: "Create Minecraft Server on differet cloud providern.",
	Long: `
minectl automates the task of creating..
`,
	Run: runMineCtl,
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Display the clients version information.",
	Run:   parseBaseCommand,
}

func getVersion() string {
	if len(Version) != 0 {
		return Version
	}
	return "dev"
}

func parseBaseCommand(_ *cobra.Command, _ []string) {
	printLogo()

	fmt.Println("Version:", getVersion())
	fmt.Println("Git Commit:", GitCommit)
	os.Exit(0)
}

func Execute(version, gitCommit string) error {

	Version = version
	GitCommit = gitCommit

	if err := minectlCmd.Execute(); err != nil {
		return err
	}
	return nil
}

func runMineCtl(cmd *cobra.Command, args []string) {
	printLogo()
	cmd.Help()
}

func printLogo() {
	minectlLogo := aec.WhiteF.Apply(minectlFigletStr)
	fmt.Println(minectlLogo)
}

const minectlFigletStr = `
 _______ _____ __   _ _______ _______ _______       
 |  |  |   |   | \  | |______ |          |    |     
 |  |  | __|__ |  \_| |______ |_____     |    |_____
`
