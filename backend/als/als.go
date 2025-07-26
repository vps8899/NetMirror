package als

import (
	"log"

	"github.com/X-Zero-L/als/als/client"
	"github.com/X-Zero-L/als/als/timer"
	"github.com/X-Zero-L/als/config"
	alsHttp "github.com/X-Zero-L/als/http"
)

func Init() {
	aHttp := alsHttp.CreateServer()

	log.Default().Println("Listen on: " + config.Config.ListenHost + ":" + config.Config.ListenPort)
	aHttp.SetListen(config.Config.ListenHost + ":" + config.Config.ListenPort)

	SetupHttpRoute(aHttp.GetEngine())

	if config.Config.FeatureIfaceTraffic {
		go timer.SetupInterfaceBroadcast()
	}
	go timer.UpdateSystemResource()
	go client.HandleQueue()
	aHttp.Start()
}
