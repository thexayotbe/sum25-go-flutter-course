package chatcore

import (
	"context"
	"sync"
)

// Message represents a chat message
// Sender, Recipient, Content, Broadcast, Timestamp
// TODO: Add more fields if needed

type Message struct {
	Sender    string
	Recipient string
	Content   string
	Broadcast bool
	Timestamp int64
}

// Broker handles message routing between users
// Contains context, input channel, user registry, mutex, done channel

type Broker struct {
	ctx        context.Context
	input      chan Message            // Incoming messages
	users      map[string]chan Message // userID -> receiving channel
	usersMutex sync.RWMutex            // Protects users map
	done       chan struct{}           // For shutdown
	// TODO: Add more fields if needed
}

// NewBroker creates a new message broker
func NewBroker(ctx context.Context) *Broker {
	// TODO: Initialize broker fields
	return &Broker{
		ctx:   ctx,
		input: make(chan Message, 100),
		users: make(map[string]chan Message),
		done:  make(chan struct{}),
	}
}

// Run starts the broker event loop (goroutine)
func (b *Broker) Run() {
	// TODO: Implement event loop (fan-in/fan-out pattern)
	for {
		select {
		case msg := <-b.input:
			b.routeMessage(msg)
		case <-b.ctx.Done():
			return
		case <-b.done:
			return
		}
	}
}

// routeMessage routes a message to appropriate recipients
func (b *Broker) routeMessage(msg Message) {
	b.usersMutex.RLock()
	defer b.usersMutex.RUnlock()

	if msg.Broadcast {
		// Send to all users (including sender)
		for _, recvChan := range b.users {
			select {
			case recvChan <- msg:
			default:
				// Channel is full, skip
			}
		}
	} else {
		// Send private message
		if recvChan, exists := b.users[msg.Recipient]; exists {
			select {
			case recvChan <- msg:
			default:
				// Channel is full, skip
			}
		}
	}
}

// SendMessage sends a message to the broker
func (b *Broker) SendMessage(msg Message) error {
	select {
	case <-b.ctx.Done():
		return b.ctx.Err()
	default:
	}
	select {
	case b.input <- msg:
		return nil
	case <-b.ctx.Done():
		return b.ctx.Err()
	default:
		return context.DeadlineExceeded
	}
}

// RegisterUser adds a user to the broker
func (b *Broker) RegisterUser(userID string, recv chan Message) {
	// TODO: Register user and their receiving channel
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	b.users[userID] = recv
}

// UnregisterUser removes a user from the broker
func (b *Broker) UnregisterUser(userID string) {
	// TODO: Remove user from registry
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	delete(b.users, userID)
}
