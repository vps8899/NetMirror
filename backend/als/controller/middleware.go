package controller

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/client"
)

func MiddlewareSessionOnHeader() gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionId := c.GetHeader("session")
		client, ok := client.Clients[sessionId]
		if !ok {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Invaild session",
			})
			c.Abort()
			return
		}
		c.Set("clientSession", client)
		c.Next()
	}
}

func MiddlewareSessionOnUrl() gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionId := c.Param("session")
		fmt.Printf("[Middleware] Session from URL: %s\n", sessionId)
		client, ok := client.Clients[sessionId]
		if !ok {
			fmt.Printf("[Middleware] Session not found in clients map\n")
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Invaild session",
			})
			c.Abort()
			return
		}
		c.Set("clientSession", client)
		c.Next()
	}
}
