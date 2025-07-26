package main

import (
	"flag"

	"github.com/X-Zero-L/als/als"
	"github.com/X-Zero-L/als/config"
	"github.com/X-Zero-L/als/fakeshell"
)

var shell = flag.Bool("shell", false, "Start as fake shell")

func main() {
	flag.Parse()
	if *shell {
		config.IsInternalCall = true
		config.Load()
		fakeshell.HandleConsole()
		return
	}

	config.LoadWebConfig()

	als.Init()
}
