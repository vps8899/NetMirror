package speedtest

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/client"
)

var count = 1
var lock = sync.Mutex{}

func fakeQueue() {
	go func() {
		lock.Lock()
		count++
		lock.Unlock()
		ctx, cancel := context.WithCancel(context.TODO())
		client.WaitQueue(ctx, nil)
		fmt.Println(count)
		time.Sleep(time.Duration(count) * time.Second)
		cancel()
	}()
}

func HandleSpeedtestDotNet(c *gin.Context) {
	nodeId, ok := c.GetQuery("node_id")
	v, _ := c.Get("clientSession")
	clientSession := v.(*client.ClientSession)
	if !ok {
		nodeId = ""
	}
	fmt.Printf("[SpeedtestDotNet] Request received, node_id: %s\n", nodeId)
	
	// Check if speedtest binary exists
	if _, err := exec.LookPath("speedtest"); err != nil {
		fmt.Printf("[SpeedtestDotNet] ERROR: speedtest binary not found: %v\n", err)
		c.JSON(500, &gin.H{
			"success": false,
			"error":   "Speedtest CLI not installed",
		})
		return
	}
	closed := false
	timeout := time.Second * 60
	count = 1
	ctx, cancel := context.WithTimeout(clientSession.GetContext(c.Request.Context()), timeout)
	defer func() {
		cancel()
		closed = true
	}()
	go func() {
		<-ctx.Done()
		closed = true
	}()
	client.WaitQueue(ctx, func() {
		pos, totalPos := client.GetQueuePostitionByCtx(ctx)
		msg, _ := json.Marshal(gin.H{"type": "queue", "pos": pos, "totalPos": totalPos})
		if !closed {
			clientSession.Channel <- &client.Message{
				Name:    "SpeedtestStream",
				Content: string(msg),
			}
		}
	})
	args := []string{"--accept-license", "--accept-gdpr", "-f", "jsonl"}
	if nodeId != "" {
		args = append(args, "-s", nodeId)
	}
	cmd := exec.Command("speedtest", args...)
	fmt.Printf("[SpeedtestDotNet] Running command: speedtest %s\n", strings.Join(args, " "))

	go func() {
		<-ctx.Done()
		if cmd.Process != nil {
			cmd.Process.Kill()
		}
	}()

	writer := func(pipe io.ReadCloser, err error) {
		if err != nil {
			fmt.Printf("[SpeedtestDotNet] Pipe error: %v\n", err)
			return
		}
		
		remainingData := ""
		for {
			buf := make([]byte, 1024)
			n, err := pipe.Read(buf)
			if err != nil {
				return
			}
			
			// Process the data line by line
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
				line = strings.TrimSpace(line)
				if line == "" {
					continue
				}
				
				// Parse JSON line and forward it
				var jsonData map[string]interface{}
				if err := json.Unmarshal([]byte(line), &jsonData); err == nil {
					fmt.Printf("[SpeedtestDotNet] JSON data: %v\n", jsonData)
					if !closed {
						// Forward the parsed JSON as a string
						msg, _ := json.Marshal(jsonData)
						clientSession.Channel <- &client.Message{
							Name:    "SpeedtestStream",
							Content: string(msg),
						}
					}
				} else {
					fmt.Printf("[SpeedtestDotNet] Failed to parse JSON: %s\n", line)
				}
			}
		}
	}

	go writer(cmd.StdoutPipe())
	go writer(cmd.StderrPipe())

	if err := cmd.Run(); err != nil {
		fmt.Printf("[SpeedtestDotNet] Command error: %v\n", err)
	}
	fmt.Println("[SpeedtestDotNet] Command completed")
	c.JSON(200, &gin.H{
		"success": true,
	})
}
