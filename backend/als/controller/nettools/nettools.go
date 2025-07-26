package nettools

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
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
			Args:    []string{"-r", "-c", "10"},
			IPv6:    false,
			Timeout: 60 * time.Second,
		},
		"mtr6": {
			Name:    "mtr6",
			Command: "mtr",
			Args:    []string{"-r", "-c", "10", "-6"},
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
		channel := clientSession.Channel

		tools := GetNetworkTools()
		tool, exists := tools[toolName]
		if !exists {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Tool not supported",
			})
			return
		}

		// Start the tool execution in a goroutine
		go func() {
			executeNetworkTool(tool, ip, channel, clientSession.GetContext(c.Request.Context()))
		}()

		c.JSON(200, &gin.H{
			"success": true,
		})
	}
}

// executeNetworkTool executes the network tool and sends output via channel
func executeNetworkTool(tool NetworkTool, target string, channel chan *client.Message, ctx context.Context) {
	// Create command with timeout
	cmdCtx, cancel := context.WithTimeout(ctx, tool.Timeout)
	defer cancel()

	// Build command arguments
	args := append(tool.Args, target)
	cmd := exec.CommandContext(cmdCtx, tool.Command, args...)

	// Send start message
	startMsg := &client.Message{
		Name:    "MethodOutput",
		Content: fmt.Sprintf(`{"output":"Starting %s to %s...\n","finished":false}`, tool.Name, target),
	}
	select {
	case channel <- startMsg:
	case <-ctx.Done():
		return
	}

	// Get stdout pipe
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		errorMsg := &client.Message{
			Name:    "MethodOutput",
			Content: fmt.Sprintf(`{"output":"Error creating stdout pipe: %s\n","finished":true}`, err.Error()),
		}
		select {
		case channel <- errorMsg:
		case <-ctx.Done():
		}
		return
	}

	// Get stderr pipe
	stderr, err := cmd.StderrPipe()
	if err != nil {
		errorMsg := &client.Message{
			Name:    "MethodOutput",
			Content: fmt.Sprintf(`{"output":"Error creating stderr pipe: %s\n","finished":true}`, err.Error()),
		}
		select {
		case channel <- errorMsg:
		case <-ctx.Done():
		}
		return
	}

	// Start the command
	if err := cmd.Start(); err != nil {
		errorMsg := &client.Message{
			Name:    "MethodOutput",
			Content: fmt.Sprintf(`{"output":"Error starting %s: %s\n","finished":true}`, tool.Name, err.Error()),
		}
		select {
		case channel <- errorMsg:
		case <-ctx.Done():
		}
		return
	}

	// Read stdout in goroutine
	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			if line != "" {
				output := fmt.Sprintf("%s\n", line)
				content, _ := json.Marshal(map[string]interface{}{
					"output":   output,
					"finished": false,
				})
				msg := &client.Message{
					Name:    "MethodOutput",
					Content: string(content),
				}
				select {
				case channel <- msg:
				case <-ctx.Done():
					return
				}
			}
		}
	}()

	// Read stderr in goroutine
	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			line := scanner.Text()
			if line != "" {
				output := fmt.Sprintf("ERROR: %s\n", line)
				content, _ := json.Marshal(map[string]interface{}{
					"output":   output,
					"finished": false,
				})
				msg := &client.Message{
					Name:    "MethodOutput",
					Content: string(content),
				}
				select {
				case channel <- msg:
				case <-ctx.Done():
					return
				}
			}
		}
	}()

	// Wait for command to finish
	err = cmd.Wait()
	
	// Send completion message
	var finishMsg string
	if err != nil {
		if strings.Contains(err.Error(), "context deadline exceeded") {
			finishMsg = fmt.Sprintf("\n%s operation timed out after %v\n", tool.Name, tool.Timeout)
		} else {
			finishMsg = fmt.Sprintf("\n%s completed with error: %s\n", tool.Name, err.Error())
		}
	} else {
		finishMsg = fmt.Sprintf("\n%s completed successfully.\n", tool.Name)
	}

	content, _ := json.Marshal(map[string]interface{}{
		"output":   finishMsg,
		"finished": true,
	})
	finalMsg := &client.Message{
		Name:    "MethodOutput",
		Content: string(content),
	}
	select {
	case channel <- finalMsg:
	case <-ctx.Done():
	}
}