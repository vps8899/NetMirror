package session

import (
	"context"
	"encoding/json"
	"net"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/X-Zero-L/als/als/client"
	"github.com/X-Zero-L/als/als/timer"
	"github.com/X-Zero-L/als/config"
)

type sessionConfig struct {
	config.ALSConfig
	ClientIP string `json:"my_ip"`
}

// getRealClientIP extracts the real client IP from proxy headers
func getRealClientIP(c *gin.Context) string {
	// Check common proxy headers in order of preference
	headers := []string{
		"X-Forwarded-For",    // Standard forwarded header
		"X-Real-IP",          // Common nginx/frp header  
		"CF-Connecting-IP",   // Cloudflare
		"True-Client-IP",     // Cloudflare Enterprise
		"X-Client-IP",        // Generic client IP header
		"X-Forwarded",        // Less common but used
		"Forwarded-For",      // Less common
		"Forwarded",          // RFC 7239
	}
	
	for _, header := range headers {
		value := c.GetHeader(header)
		if value == "" {
			continue
		}
		
		// Handle comma-separated IPs (X-Forwarded-For can contain multiple IPs)
		ips := strings.Split(value, ",")
		for _, ip := range ips {
			ip = strings.TrimSpace(ip)
			if ip == "" {
				continue
			}
			
			// Parse IP to validate it
			if parsedIP := net.ParseIP(ip); parsedIP != nil {
				// Skip private/loopback IPs unless no other option
				if !isPrivateIP(parsedIP) {
					return ip
				}
			}
		}
	}
	
	// Fallback to Gin's ClientIP method
	return c.ClientIP()
}

// isPrivateIP checks if an IP is private/internal
func isPrivateIP(ip net.IP) bool {
	if ip.IsLoopback() || ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() {
		return true
	}
	
	// Check for private IPv4 ranges
	if ip4 := ip.To4(); ip4 != nil {
		// 10.0.0.0/8
		if ip4[0] == 10 {
			return true
		}
		// 172.16.0.0/12
		if ip4[0] == 172 && ip4[1] >= 16 && ip4[1] <= 31 {
			return true
		}
		// 192.168.0.0/16
		if ip4[0] == 192 && ip4[1] == 168 {
			return true
		}
		// 127.0.0.0/8 (localhost)
		if ip4[0] == 127 {
			return true
		}
	}
	
	// Check for private IPv6 ranges
	if ip.To4() == nil {
		// fc00::/7 (unique local)
		if len(ip) == 16 && (ip[0]&0xfe) == 0xfc {
			return true
		}
		// ::1 (localhost)
		if ip.Equal(net.IPv6loopback) {
			return true
		}
	}
	
	return false
}

func Handle(c *gin.Context) {
	uuid := uuid.New().String()
	// uuid := "1"
	channel := make(chan *client.Message)
	clientSession := &client.ClientSession{Channel: channel}
	client.Clients[uuid] = clientSession
	ctx, cancel := context.WithCancel(c.Request.Context())
	defer cancel()
	clientSession.SetContext(ctx)

	c.Writer.Header().Set("Content-Type", "text/event-stream")
	c.Writer.Header().Set("Cache-Control", "no-cache")
	c.Writer.Header().Set("Connection", "keep-alive")
	c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
	c.SSEvent("SessionId", uuid)
	_config := &sessionConfig{
		ALSConfig: *config.Config,
		ClientIP:  getRealClientIP(c),
	}

	configJson, _ := json.Marshal(_config)
	c.SSEvent("Config", string(configJson))
	c.Writer.Flush()
	interfaceCacheJson, _ := json.Marshal(timer.InterfaceCaches)
	c.SSEvent("InterfaceCache", string(interfaceCacheJson))
	c.Writer.Flush()

	for {
		select {
		case <-ctx.Done():
			goto FINISH
		case msg, ok := <-channel:
			if !ok {
				break
			}
			c.SSEvent(msg.Name, msg.Content)
			c.Writer.Flush()
		}
	}

FINISH:
	close(channel)
	delete(client.Clients, uuid)
}
