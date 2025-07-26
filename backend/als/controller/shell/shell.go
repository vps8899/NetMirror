package shell

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/creack/pty"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/X-Zero-L/als/als/client"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  4096,
	WriteBufferSize: 4096,
}

func HandleNewShell(c *gin.Context) {
	fmt.Println("[Shell] WebSocket connection request received")
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		fmt.Printf("[Shell] WebSocket upgrade error: %v\n", err)
		return
	}
	defer conn.Close()
	v, _ := c.Get("clientSession")
	clientSession := v.(*client.ClientSession)
	fmt.Printf("[Shell] Client session established, starting shell...\n")
	handleNewConnection(conn, clientSession, c)
}

func handleNewConnection(conn *websocket.Conn, session *client.ClientSession, ginC *gin.Context) {
	ctx, cancel := context.WithCancel(session.GetContext(ginC.Request.Context()))
	defer cancel()

	ex, _ := os.Executable()
	fmt.Printf("[Shell] Starting shell process: %s --shell\n", ex)
	c := exec.Command(ex, "--shell")
	ptmx, err := pty.Start(c)
	if err != nil {
		fmt.Printf("[Shell] Failed to start PTY: %v\n", err)
		return
	}
	defer ptmx.Close()

	// context aware
	go func() {
		<-ctx.Done()
		if c.Process != nil {
			c.Process.Kill()
		}
	}()

	// cmd -> websocket
	go func() {
		defer cancel()
		buf := make([]byte, 4096)
		for {
			n, err := ptmx.Read(buf)
			if err != nil {
				break
			}
			conn.WriteMessage(websocket.BinaryMessage, buf[:n])
		}
	}()

	// websocket -> cmd
	go func() {
		defer cancel()
		fmt.Println("[Shell] WebSocket reader started")
		for {
			_, buf, err := conn.ReadMessage()
			if err != nil {
				fmt.Printf("[Shell] WebSocket read error: %v\n", err)
				break
			}
			index := string(buf[:1])
			switch index {
			case "1":
				// normal input
				ptmx.Write(buf[1:])
			case "2":
				// win resize
				args := strings.Split(string(buf[1:]), ";")
				h, _ := strconv.Atoi(args[0])
				w, _ := strconv.Atoi(args[1])
				pty.Setsize(ptmx, &pty.Winsize{
					Rows: uint16(h),
					Cols: uint16(w),
				})
			}
		}
	}()
	c.Wait()
	fmt.Println("[Shell] Shell process exited")
}
