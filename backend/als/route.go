package als

import (
	"io/fs"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/controller"
	"github.com/X-Zero-L/als/als/controller/cache"
	"github.com/X-Zero-L/als/als/controller/iperf3"
	"github.com/X-Zero-L/als/als/controller/ping"
	"github.com/X-Zero-L/als/als/controller/session"
	"github.com/X-Zero-L/als/als/controller/shell"
	"github.com/X-Zero-L/als/als/controller/speedtest"
	"github.com/X-Zero-L/als/config"
	iEmbed "github.com/X-Zero-L/als/embed"
)

func SetupHttpRoute(e *gin.Engine) {
	e.GET("/session", session.Handle)
	v1 := e.Group("/method", controller.MiddlewareSessionOnHeader())
	{
		if config.Config.FeatureIperf3 {
			v1.GET("/iperf3/server", iperf3.Handle)
		}

		if config.Config.FeaturePing {
			v1.GET("/ping", ping.Handle)
		}

		if config.Config.FeatureSpeedtestDotNet {
			v1.GET("/speedtest_dot_net", speedtest.HandleSpeedtestDotNet)
		}

		if config.Config.FeatureIfaceTraffic {
			v1.GET("/cache/interfaces", cache.UpdateInterfaceCache)
		}
	}

	session := e.Group("/session/:session", controller.MiddlewareSessionOnUrl())
	{
		if config.Config.FeatureShell {
			session.GET("/shell", shell.HandleNewShell)
		}
	}

	speedtestRoute := session.Group("/speedtest", controller.MiddlewareSessionOnUrl())
	{
		if config.Config.FeatureFileSpeedtest {
			speedtestRoute.GET("/file/:filename", speedtest.HandleFakeFile)
		}

		if config.Config.FeatureLibrespeed {
			speedtestRoute.GET("/download", speedtest.HandleDownload)
			speedtestRoute.POST("/upload", speedtest.HandleUpload)
		}
	}

	e.Any("/assets/:filename", func(c *gin.Context) {
		filePath := c.Request.RequestURI
		filePath = filePath[1:]
		handleStatisFile(filePath, c)
	})

	e.GET("/css/:filename", func(c *gin.Context) {
		filePath := c.Request.RequestURI
		filePath = filePath[1:]
		handleStatisFile(filePath, c)
	})

	e.GET("/js/:filename", func(c *gin.Context) {
		filePath := c.Request.RequestURI
		filePath = filePath[1:]
		handleStatisFile(filePath, c)
	})

	e.GET("/", func(c *gin.Context) {
		filePath := "/index.html"
		filePath = filePath[1:]
		handleStatisFile(filePath, c)
	})

	e.GET("/speedtest_worker.js", func(c *gin.Context) {
		handleStatisFile("speedtest_worker.js", c)
	})

	e.GET("/favicon.ico", func(c *gin.Context) {
		handleStatisFile("favicon.ico", c)
	})
}

func handleStatisFile(filePath string, c *gin.Context) {
	uiFs := iEmbed.UIStaticFiles
	subFs, _ := fs.Sub(uiFs, "ui")
	httpFs := http.FileServer(http.FS(subFs))
	_, err := fs.ReadFile(subFs, filePath)
	if err != nil {
		c.String(404, "Not found")
		c.Abort()
		return
	}
	httpFs.ServeHTTP(c.Writer, c.Request)
}
