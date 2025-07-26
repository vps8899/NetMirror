package nettools

import (
	"context"
	"fmt"
	"io"
	"os/exec"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/client"
)

// NetworkTool represents a network diagnostic tool
type NetworkTool struct {
	Name     string
	Command  string
	Args     []string
	IPv6     bool
	Timeout  time.Duration
}

// GetNetworkTools returns available network tools
func GetNetworkTools() map[string]NetworkTool {
	return map[string]NetworkTool{
		"ping6": {
			Name:    "ping6",
			Command: "ping6",
			Args:    []string{"-c", "10"},
			IPv6:    true,
			Timeout: 30 * time.Second,
		},
		"mtr": {
			Name:    "mtr",
			Command: "mtr",
			Args:    []string{"--raw", "-c", "10"},
			IPv6:    false,
			Timeout: 60 * time.Second,
		},
		"mtr6": {
			Name:    "mtr6",
			Command: "mtr",
			Args:    []string{"--raw", "-c", "10", "-6"},
			IPv6:    true,
			Timeout: 60 * time.Second,
		},
		"traceroute": {
			Name:    "traceroute",
			Command: "traceroute",
			Args:    []string{},
			IPv6:    false,
			Timeout: 60 * time.Second,
		},
		"traceroute6": {
			Name:    "traceroute6",
			Command: "traceroute6",
			Args:    []string{},
			IPv6:    true,
			Timeout: 60 * time.Second,
		},
	}
}

// HandleNetworkTool handles network tool requests
func HandleNetworkTool(toolName string) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip, ok := c.GetQuery("ip")
		if !ok || ip == "" {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Invalid IP Address",
			})
			return
		}

		v, exists := c.Get("clientSession")
		if !exists {
			c.JSON(500, &gin.H{
				"success": false,
				"error":   "Client session not found",
			})
			return
		}

		clientSession := v.(*client.ClientSession)

		tools := GetNetworkTools()
		tool, exists := tools[toolName]
		if !exists {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Tool not supported",
			})
			return
		}

		// Create timeout context
		timeout := tool.Timeout
		ctx, cancel := context.WithTimeout(clientSession.GetContext(c.Request.Context()), timeout)
		defer cancel()

		// Build command
		args := append(tool.Args, ip)
		cmd := exec.CommandContext(ctx, tool.Command, args...)

		// Send start message
		clientSession.Channel <- &client.Message{
			Name:    "MethodOutput",
			Content: fmt.Sprintf(`{"output":"Starting %s to %s...\n","finished":false}`, tool.Name, ip),
		}

		// Writer function (exactly like iperf3)
		writer := func(pipe io.ReadCloser, err error) {
			if err != nil {
				return
			}
			for {
				buf := make([]byte, 1024)
				n, err := pipe.Read(buf)
				if err != nil {
					return
				}
				msg := &client.Message{
					Name:    "MethodOutput",
					Content: fmt.Sprintf(`{"output":%s,"finished":false}`, strconv.Quote(string(buf[:n]))),
				}
				clientSession.Channel <- msg
			}
		}

		go writer(cmd.StdoutPipe())
		go writer(cmd.StderrPipe())

		err := cmd.Start()
		if err != nil {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   err.Error(),
			})
			return
		}

		cmd.Wait()

		// Send completion message
		clientSession.Channel <- &client.Message{
			Name:    "MethodOutput",
			Content: fmt.Sprintf(`{"output":"\n%s completed.\n","finished":true}`, tool.Name),
		}

		c.JSON(200, &gin.H{
			"success": true,
		})
	}
}