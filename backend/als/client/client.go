package client

import (
	"context"
	"sync"
)

var (
	Clients   = make(map[string]*ClientSession)
	ClientsMu sync.RWMutex
)

type Message struct {
	Name    string
	Content string
}

type ClientSession struct {
	Channel chan *Message
	ctx     context.Context
}

func (c *ClientSession) SetContext(ctx context.Context) {
	c.ctx = ctx
}

func (c *ClientSession) GetContext(requestCtx context.Context) context.Context {
	ctx, cancel := context.WithCancel(context.Background())

	go func() {
		select {
		case <-c.ctx.Done():
			cancel()
			break
		case <-requestCtx.Done():
			cancel()
			break
		}
	}()

	return ctx
}

// AddClient safely adds a client to the map
func AddClient(id string, client *ClientSession) {
	ClientsMu.Lock()
	defer ClientsMu.Unlock()
	Clients[id] = client
}

// RemoveClient safely removes a client from the map
func RemoveClient(id string) {
	ClientsMu.Lock()
	defer ClientsMu.Unlock()
	delete(Clients, id)
}

// GetClient safely gets a client from the map
func GetClient(id string) (*ClientSession, bool) {
	ClientsMu.RLock()
	defer ClientsMu.RUnlock()
	client, ok := Clients[id]
	return client, ok
}

func BroadCastMessage(name string, content string) {
	ClientsMu.RLock()
	defer ClientsMu.RUnlock()
	
	for _, client := range Clients {
		select {
		case client.Channel <- &Message{
			Name:    name,
			Content: content,
		}:
		default:
			// Channel is full or closed, skip this client
		}
	}
}
