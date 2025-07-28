package http

import (
	"github.com/gin-gonic/gin"
)

type Server struct {
	engine *gin.Engine
	listen string
}

func CreateServer() *Server {
	gin.SetMode(gin.ReleaseMode)
	engine := gin.Default()
	
	// Configure trusted proxies to handle frp and other reverse proxies
	// This allows ClientIP() to properly parse X-Forwarded-For and X-Real-IP headers
	engine.SetTrustedProxies([]string{"127.0.0.1", "::1", "0.0.0.0/0"})
	
	e := &Server{
		engine: engine,
		listen: ":8080",
	}
	return e
}

func (e *Server) GetEngine() *gin.Engine {
	return e.engine
}

func (e *Server) SetListen(listen string) {
	e.listen = listen
}

func (e *Server) Start() {
	e.engine.Run(e.listen)
}
