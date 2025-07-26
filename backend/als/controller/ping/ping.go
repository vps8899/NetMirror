package ping

import (
	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/client"
	"github.com/samlm0/go-ping"
)

func Handle(c *gin.Context) {
	ip, ok := c.GetQuery("ip")
	v, _ := c.Get("clientSession")
	clientSession := v.(*client.ClientSession)
	channel := clientSession.Channel
	if !ok || ip == "" {
		c.JSON(400, &gin.H{
			"success": false,
			"error":   "Invalid IP Address",
		})
		return
	}

	// Validate input to prevent any potential issues
	if !isValidIPOrHostname(ip) {
		c.JSON(400, &gin.H{
			"success": false,
			"error":   "Invalid IP address or hostname format",
		})
		return
	}

	p, err := ping.New(ip)
	if err != nil {
		c.JSON(400, &gin.H{
			"success": false,
			"error":   "Invaild IP Address",
		})
		return
	}

	p.Count = 10
	p.OnEvent = func(event *ping.PacketEvent, _ error) {
		content, err := json.Marshal(event)
		if err != nil {
			return
		}
		msg := &client.Message{
			Name:    "Ping",
			Content: string(content),
		}
		channel <- msg
	}
	ctx := clientSession.GetContext(c.Request.Context())
	p.Start(ctx)

	c.JSON(200, &gin.H{
		"success": true,
	})
}

// isValidIPOrHostname validates if the input is a valid IP address or hostname
func isValidIPOrHostname(input string) bool {
	// Check if it's a valid IP address (v4 or v6)
	if net.ParseIP(input) != nil {
		return true
	}
	
	// Check if it's a valid hostname
	// Allow only alphanumeric, dots, hyphens
	hostnameRegex := regexp.MustCompile(`^[a-zA-Z0-9.-]+$`)
	if !hostnameRegex.MatchString(input) {
		return false
	}
	
	// Additional checks for shell injection attempts
	dangerousPatterns := []string{
		";", "&", "|", "`", "$", "(", ")", "{", "}", "[", "]",
		"<", ">", "\\", "'", "\"", "\n", "\r", "\t", "\x00",
		"*", "?", "~", "!", "#", "%", "^", "=", "+", " ",
	}
	
	for _, pattern := range dangerousPatterns {
		if strings.Contains(input, pattern) {
			return false
		}
	}
	
	// Check length limits
	if len(input) > 255 {
		return false
	}
	
	// Check that hostname doesn't start or end with special chars
	if strings.HasPrefix(input, "-") || strings.HasSuffix(input, "-") ||
		strings.HasPrefix(input, ".") || strings.HasSuffix(input, ".") {
		return false
	}
	
	return true
}
