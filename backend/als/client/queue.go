package client

import (
	"context"
	"sync"
)

var queueLine = make(map[context.Context]context.CancelFunc, 0)
var queueLock = sync.Mutex{}
var queueNotify = make(map[context.Context]func(), 0)
var queueWakeup = make(chan struct{})

func WaitQueue(ctx context.Context, cb func()) {
	queueCtx, cancel := context.WithCancel(ctx)
	
	queueLock.Lock()
	queueLine[ctx] = cancel
	if cb != nil {
		queueNotify[ctx] = cb
	}
	queueLock.Unlock()

	select {
	case queueWakeup <- struct{}{}:
	default:
	}

	select {
	case <-queueCtx.Done():
	case <-ctx.Done():
	}
}

func GetQueuePostitionByCtx(ctx context.Context) (int, int) {
	total := len(queueLine)

	found := false
	count := 0
	queueLock.Lock()
	for v, _ := range queueLine {
		count++
		if v == ctx {
			found = true
			break
		}
	}
	queueLock.Unlock()

	if !found {
		return 0, 0
	}

	return count, total
}

func HandleQueue() {
	for {
		<-queueWakeup
		queueLock.Lock()
		for ctx, notify := range queueLine {
			queueLock.Unlock()
			notify()
			<-ctx.Done()
			queueLock.Lock()
			delete(queueLine, ctx)
			delete(queueNotify, ctx)

			for _, callNotify := range queueNotify {
				callNotify()
			}
		}
		queueLock.Unlock()
	}
}
