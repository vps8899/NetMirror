package config

import (
	"sync"
	"time"
)

// CacheEntry represents a cached BGP result with expiration
type CacheEntry struct {
	Data      interface{} `json:"data"`
	ExpiresAt time.Time   `json:"expires_at"`
}

// BGPCache holds cached BGP data with thread-safe access
type BGPCache struct {
	mu    sync.RWMutex
	cache map[string]CacheEntry
}

// Global BGP cache instance
var bgpCache = &BGPCache{
	cache: make(map[string]CacheEntry),
}

// Get retrieves cached data if it exists and hasn't expired
func (c *BGPCache) Get(key string) (interface{}, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	
	entry, exists := c.cache[key]
	if !exists {
		return nil, false
	}
	
	// Check if entry has expired
	if time.Now().After(entry.ExpiresAt) {
		// Clean up expired entry
		go c.Delete(key)
		return nil, false
	}
	
	return entry.Data, true
}

// Set stores data in cache with 24-hour TTL
func (c *BGPCache) Set(key string, data interface{}) {
	c.mu.Lock()
	defer c.mu.Unlock()
	
	c.cache[key] = CacheEntry{
		Data:      data,
		ExpiresAt: time.Now().Add(24 * time.Hour),
	}
}

// Delete removes an entry from cache
func (c *BGPCache) Delete(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	
	delete(c.cache, key)
}

// CleanExpired removes all expired entries from cache
func (c *BGPCache) CleanExpired() {
	c.mu.Lock()
	defer c.mu.Unlock()
	
	now := time.Now()
	for key, entry := range c.cache {
		if now.After(entry.ExpiresAt) {
			delete(c.cache, key)
		}
	}
}

// GetBGPInfoCached retrieves BGP info from cache or fetches new data
func GetBGPInfoCached(ip string) (*BGPInfo, error) {
	cacheKey := "bgp_info_" + ip
	
	// Try to get from cache first
	if cached, found := bgpCache.Get(cacheKey); found {
		if bgpInfo, ok := cached.(*BGPInfo); ok {
			return bgpInfo, nil
		}
	}
	
	// If not in cache or expired, fetch new data
	bgpInfo, err := getBGPInfoFromIPInfo(ip)
	if err != nil {
		// Try alternative API
		bgpInfo, err = getBGPInfoFromBGPView(ip)
		if err != nil {
			return nil, err
		}
	}
	
	// Cache the result
	if bgpInfo != nil {
		bgpCache.Set(cacheKey, bgpInfo)
	}
	
	return bgpInfo, nil
}

// GetBGPGraphCached retrieves BGP graph from cache or returns cache info
func GetBGPGraphCached(asn, graphType string) ([]byte, bool) {
	cacheKey := "bgp_graph_" + asn + "_" + graphType
	
	if cached, found := bgpCache.Get(cacheKey); found {
		if graphData, ok := cached.([]byte); ok {
			return graphData, true
		}
	}
	
	return nil, false
}

// SetBGPGraphCache stores BGP graph data in cache
func SetBGPGraphCache(asn, graphType string, data []byte) {
	cacheKey := "bgp_graph_" + asn + "_" + graphType
	bgpCache.Set(cacheKey, data)
}

// init starts a background goroutine to clean expired cache entries
func init() {
	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		
		for range ticker.C {
			bgpCache.CleanExpired()
		}
	}()
}