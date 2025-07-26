package ping

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/client"
)

// Ping6Response represents a single ping response
type Ping6Response struct {
	From      string `json:"from"`
	Seq       int    `json:"seq"`
	TTL       int    `json:"ttl"`
	Latency   int64  `json:"latency"`
	IsTimeout bool   `json:"is_timeout"`
}

// HandlePing6 handles IPv6 ping requests
func HandlePing6(c *gin.Context) {
	ip, ok := c.GetQuery("ip")
	if !ok || ip == "" {
		// Get client session first to send error message
		v, exists := c.Get("clientSession")
		if exists {
			clientSession := v.(*client.ClientSession)
			// Send error message through WebSocket
			errorResp := Ping6Response{
				From:      "Error: No IP provided",
				Seq:       1,
				TTL:       0,
				Latency:   0,
				IsTimeout: true,
			}
			jsonData, _ := json.Marshal(errorResp)
			clientSession.Channel <- &client.Message{
				Name:    "Ping6",
				Content: string(jsonData),
			}
		}
		
		c.JSON(400, &gin.H{
			"success": false,
			"error":   "Invalid IP Address",
		})
		return
	}

	// Validate input to prevent command injection
	// Allow only valid IPv6 addresses or hostnames
	if !isValidIPv6OrHostname(ip) {
		// Get client session first to send error message
		v, exists := c.Get("clientSession")
		if exists {
			clientSession := v.(*client.ClientSession)
			// Send error message through WebSocket
			errorResp := Ping6Response{
				From:      "Error: Invalid input",
				Seq:       1,
				TTL:       0,
				Latency:   0,
				IsTimeout: true,
			}
			jsonData, _ := json.Marshal(errorResp)
			clientSession.Channel <- &client.Message{
				Name:    "Ping6",
				Content: string(jsonData),
			}
		}
		
		c.JSON(400, &gin.H{
			"success": false,
			"error":   "Invalid IPv6 address or hostname",
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

	fmt.Printf("[Ping6] Request received for IP: %s\n", ip)

	// Create timeout context
	timeout := 30 * time.Second
	ctx, cancel := context.WithTimeout(clientSession.GetContext(c.Request.Context()), timeout)
	defer cancel()

	// Build ping6 command - Alpine uses ping -6 instead of ping6
	var cmd *exec.Cmd
	if _, err := exec.LookPath("ping6"); err == nil {
		cmd = exec.CommandContext(ctx, "ping6", "-c", "10", ip)
		fmt.Println("[Ping6] Using ping6 command")
	} else {
		// Alpine Linux uses ping with -6 flag
		cmd = exec.CommandContext(ctx, "ping", "-6", "-c", "10", ip)
		fmt.Println("[Ping6] Using ping -6 command (Alpine)")
	}

	// Start the command
	output, err := cmd.StdoutPipe()
	if err != nil {
		// Send error message through WebSocket
		errorResp := Ping6Response{
			From:      fmt.Sprintf("Error: %s", err.Error()),
			Seq:       1,
			TTL:       0,
			Latency:   0,
			IsTimeout: true,
		}
		jsonData, _ := json.Marshal(errorResp)
		clientSession.Channel <- &client.Message{
			Name:    "Ping6",
			Content: string(jsonData),
		}
		
		c.JSON(400, &gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	err = cmd.Start()
	if err != nil {
		fmt.Printf("[Ping6] Failed to start command: %v\n", err)
		c.JSON(400, &gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Send initial message
	fmt.Printf("[Ping6] Command started successfully\n")

	// Read output in a goroutine but don't block with cmd.Wait()
	// Let the goroutine handle the output and the handler can return
	go func() {
		defer func() {
			if cmd.Process != nil {
				cmd.Process.Kill()
			}
		}()

		buf := make([]byte, 1024)
		remainingData := ""
		seq := 0

		for {
			n, err := output.Read(buf)
			if err != nil {
				fmt.Printf("[Ping6] Read error: %v\n", err)
				return
			}

			data := remainingData + string(buf[:n])
			lines := strings.Split(data, "\n")

			// Keep the last incomplete line for next iteration
			if !strings.HasSuffix(data, "\n") && len(lines) > 1 {
				remainingData = lines[len(lines)-1]
				lines = lines[:len(lines)-1]
			} else {
				remainingData = ""
			}

			for _, line := range lines {
				if strings.TrimSpace(line) == "" {
					continue
				}

				fmt.Printf("[Ping6] Output line: %s\n", line)

				// Parse ping output
				// Example: "64 bytes from 2001:db8::1: icmp_seq=1 ttl=64 time=0.456 ms"
				if strings.Contains(line, "bytes from") && strings.Contains(line, "icmp_seq=") {
					seq++
					resp := Ping6Response{
						Seq:       seq,
						IsTimeout: false,
					}

					// Extract from address
					fromRegex := regexp.MustCompile(`from ([^\s:]+)`)
					if matches := fromRegex.FindStringSubmatch(line); len(matches) > 1 {
						resp.From = matches[1]
					}

					// Extract TTL
					ttlRegex := regexp.MustCompile(`ttl=(\d+)`)
					if matches := ttlRegex.FindStringSubmatch(line); len(matches) > 1 {
						if ttl, err := strconv.Atoi(matches[1]); err == nil {
							resp.TTL = ttl
						}
					}

					// Extract time in ms and convert to nanoseconds
					timeRegex := regexp.MustCompile(`time=([\d.]+) ms`)
					if matches := timeRegex.FindStringSubmatch(line); len(matches) > 1 {
						if timeMs, err := strconv.ParseFloat(matches[1], 64); err == nil {
							resp.Latency = int64(timeMs * 1000000) // Convert ms to ns
						}
					}

					// Send the response
					jsonData, _ := json.Marshal(resp)
					// Use select to avoid blocking if context is cancelled
					select {
					case clientSession.Channel <- &client.Message{
						Name:    "Ping6",
						Content: string(jsonData),
					}:
					case <-ctx.Done():
						return
					}
				} else if strings.Contains(line, "no answer yet") || strings.Contains(line, "Request timeout") {
					// Handle timeout
					seq++
					resp := Ping6Response{
						Seq:       seq,
						IsTimeout: true,
					}

					jsonData, _ := json.Marshal(resp)
					clientSession.Channel <- &client.Message{
						Name:    "Ping6",
						Content: string(jsonData),
					}
				}
			}
		}
	}()

	// Return immediately to let the goroutine handle output
	c.JSON(200, &gin.H{
		"success": true,
	})
}

// isValidIPv6OrHostname validates if the input is a valid IPv6 address or hostname
func isValidIPv6OrHostname(input string) bool {
	// Check if it's a valid IPv6 address
	if net.ParseIP(input) != nil {
		return true
	}
	
	// Check if it's a valid hostname (DNS name)
	// Allow only alphanumeric, dots, hyphens, and underscores
	// Must not contain shell special characters
	hostnameRegex := regexp.MustCompile(`^[a-zA-Z0-9.-]+$`)
	if !hostnameRegex.MatchString(input) {
		return false
	}
	
	// Additional checks for shell injection attempts
	dangerousPatterns := []string{
		";", "&", "|", "`", "$", "(", ")", "{", "}", "[", "]",
		"<", ">", "\\", "'", "\"", "\n", "\r", "\t",
		"*", "?", "~", "!", "#", "%", "^", "=", "+",
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
	
	return true
}