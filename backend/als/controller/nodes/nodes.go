package nodes

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// Node represents a Looking Glass node
type Node struct {
	Name     string `json:"name"`
	Location string `json:"location"`
	URL      string `json:"url"`
	Current  bool   `json:"current"`
}

// LatencyResponse represents the latency test result
type LatencyResponse struct {
	Node    string `json:"node"`
	Latency int    `json:"latency"` // in milliseconds
	Status  string `json:"status"`  // "good", "medium", "high", "error"
}

// GetNodes returns the list of LG nodes from environment variable
func GetNodes(c *gin.Context) {
	// Get nodes from environment variable
	// Format: NAME1|LOCATION1|URL1;NAME2|LOCATION2|URL2;...
	// Example: London|London, UK|https://lon.lg.example.com;Singapore|Singapore, SG|https://sg.lg.example.com
	nodesEnv := os.Getenv("LG_NODES")
	currentNodeURL := os.Getenv("LG_CURRENT_URL") // URL of current node
	
	if nodesEnv == "" {
		// Return empty list if not configured
		c.JSON(200, gin.H{
			"success": true,
			"nodes":   []Node{},
		})
		return
	}
	
	var nodes []Node
	nodeStrings := strings.Split(nodesEnv, ";")
	
	for _, nodeStr := range nodeStrings {
		parts := strings.Split(nodeStr, "|")
		if len(parts) >= 3 {
			node := Node{
				Name:     parts[0],
				Location: parts[1],
				URL:      parts[2],
				Current:  parts[2] == currentNodeURL,
			}
			nodes = append(nodes, node)
		}
	}
	
	c.JSON(200, gin.H{
		"success": true,
		"nodes":   nodes,
	})
}

// TestLatency tests the latency to a specific node
func TestLatency(c *gin.Context) {
	// Get timestamp from client
	timestampStr, ok := c.GetQuery("timestamp")
	if !ok || timestampStr == "" {
		c.JSON(400, gin.H{
			"success": false,
			"error":   "timestamp parameter required",
		})
		return
	}
	
	// Parse timestamp
	clientTimestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		c.JSON(400, gin.H{
			"success": false,
			"error":   "Invalid timestamp format",
		})
		return
	}
	
	// Calculate latency (current time - client timestamp)
	currentTime := time.Now().UnixMilli()
	latency := int(currentTime - clientTimestamp)
	
	// Determine status based on latency
	status := "good"
	if latency > 300 {
		status = "high"
	} else if latency > 150 {
		status = "medium"
	}
	
	c.JSON(200, gin.H{
		"success": true,
		"latency": latency,
		"status":  status,
		"timestamp": currentTime,
	})
}

// GetNodeConfig returns the current node configuration
func GetNodeConfig(c *gin.Context) {
	// Get current node info from environment
	currentName := os.Getenv("LG_CURRENT_NAME")
	currentLocation := os.Getenv("LG_CURRENT_LOCATION")
	currentURL := os.Getenv("LG_CURRENT_URL")
	
	if currentName == "" {
		currentName = "Local"
	}
	if currentLocation == "" {
		currentLocation = "Local Server"
	}
	
	c.JSON(200, gin.H{
		"success": true,
		"current": Node{
			Name:     currentName,
			Location: currentLocation,
			URL:      currentURL,
			Current:  true,
		},
	})
}