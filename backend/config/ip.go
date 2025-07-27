package config

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"strings"

	"github.com/miekg/dns"
)

// BGPInfo represents BGP and ASN information
type BGPInfo struct {
	ASN      string `json:"asn"`
	ASNName  string `json:"asn_name"`
	Country  string `json:"country"`
	Prefixes []string `json:"prefixes"`
}

func updatePublicIP() {
	log.Default().Println("Updating IP address from internet...")
	// get ipv4
	go func() {
		addr, err := getPublicIPv4ViaDNS()
		if err == nil {
			Config.PublicIPv4 = addr
			log.Printf("Public IPv4 address: %s\n", addr)
			// Get BGP info for IPv4
			go updateBGPInfo(addr)
			return
		}

		addr, err = getPublicIPv4ViaHttp()
		if err == nil {
			Config.PublicIPv4 = addr
			log.Printf("Public IPv4 address: %s\n", addr)
			// Get BGP info for IPv4
			go updateBGPInfo(addr)
			return
		}
	}()

	// get ipv6
	go func() {
		addr, err := getPublicIPv6ViaDNS()
		if err == nil {
			Config.PublicIPv6 = addr
			log.Printf("Public IPv6 address: %s\n", addr)
			return
		}
	}()
}

// updateBGPInfo fetches BGP and ASN information for the given IP
func updateBGPInfo(ip string) {
	log.Default().Printf("Fetching BGP info for IP: %s", ip)
	
	bgpInfo, err := getBGPInfoFromIPInfo(ip)
	if err != nil {
		log.Default().Printf("Failed to get BGP info from ipinfo.io: %v", err)
		// Try alternative API
		bgpInfo, err = getBGPInfoFromBGPView(ip)
		if err != nil {
			log.Default().Printf("Failed to get BGP info from bgpview.io: %v", err)
			return
		}
	}
	
	if bgpInfo != nil {
		Config.ASN = bgpInfo.ASN
		if bgpInfo.ASNName != "" {
			Config.BGP = fmt.Sprintf("%s (%s)", bgpInfo.ASN, bgpInfo.ASNName)
		} else {
			Config.BGP = bgpInfo.ASN
		}
		log.Printf("BGP Info - ASN: %s, BGP: %s", Config.ASN, Config.BGP)
	}
}

// getBGPInfoFromIPInfo fetches BGP info from ipinfo.io
func getBGPInfoFromIPInfo(ip string) (*BGPInfo, error) {
	url := fmt.Sprintf("https://ipinfo.io/%s/json", ip)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d", resp.StatusCode)
	}
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	var result struct {
		Org     string `json:"org"`
		Country string `json:"country"`
	}
	
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	
	// Parse org field which has format "AS15169 Google LLC"
	if result.Org == "" {
		return nil, fmt.Errorf("no org info found")
	}
	
	// Extract ASN and name from org field
	parts := strings.Fields(result.Org)
	if len(parts) == 0 {
		return nil, fmt.Errorf("invalid org format")
	}
	
	asn := parts[0] // "AS15169"
	var asnName string
	if len(parts) > 1 {
		asnName = strings.Join(parts[1:], " ") // "Google LLC"
	}
	
	return &BGPInfo{
		ASN:     asn,
		ASNName: asnName,
		Country: result.Country,
	}, nil
}

// getBGPInfoFromBGPView fetches BGP info from bgpview.io (alternative)
func getBGPInfoFromBGPView(ip string) (*BGPInfo, error) {
	url := fmt.Sprintf("https://api.bgpview.io/ip/%s", ip)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d", resp.StatusCode)
	}
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	var result struct {
		Status string `json:"status"`
		Data   struct {
			Prefixes []struct {
				ASN struct {
					ID   int    `json:"asn"`
					Name string `json:"name"`
				} `json:"asn"`
				Country string `json:"country_code"`
			} `json:"prefixes"`
		} `json:"data"`
	}
	
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	
	if result.Status != "ok" || len(result.Data.Prefixes) == 0 {
		return nil, fmt.Errorf("no BGP data found")
	}
	
	prefix := result.Data.Prefixes[0]
	return &BGPInfo{
		ASN:     fmt.Sprintf("AS%d", prefix.ASN.ID),
		ASNName: prefix.ASN.Name,
		Country: prefix.Country,
	}, nil
}

func getPublicIPv4ViaDNS() (string, error) {
	m := new(dns.Msg)
	m.SetQuestion("myip.opendns.com.", dns.TypeA)

	in, err := dns.Exchange(m, "resolver1.opendns.com:53")
	if err != nil {
		return "", err
	}

	if len(in.Answer) < 1 {
		return "", fmt.Errorf("no answer")
	}

	record, ok := in.Answer[0].(*dns.A)
	if !ok {
		return "", fmt.Errorf("not A record")
	}
	return record.A.String(), nil
}

func getPublicIPv6ViaDNS() (string, error) {
	m := new(dns.Msg)
	m.SetQuestion("myip.opendns.com.", dns.TypeAAAA)

	in, err := dns.Exchange(m, "resolver1.opendns.com:53")
	if err != nil {
		return "", err
	}

	if len(in.Answer) < 1 {
		return "", fmt.Errorf("no answer")
	}

	record, ok := in.Answer[0].(*dns.AAAA)
	if !ok {
		return "", fmt.Errorf("not A record")
	}

	return record.AAAA.String(), nil
}

func getPublicIPViaHttp(client *http.Client) (string, error) {
	lists := []string{
		"https://myexternalip.com/raw",
		"https://ifconfig.co/ip",
	}

	for _, url := range lists {
		resp, err := client.Get(url)
		if err != nil {
			continue
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return "", err
		}

		addr := net.ParseIP(string(body))
		if addr != nil {
			return addr.String(), nil
		}
	}

	return "", fmt.Errorf("no answer")
}

func getPublicIPv4ViaHttp() (string, error) {
	client := &http.Client{
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				var dialer net.Dialer
				return dialer.DialContext(ctx, "tcp4", addr)
			},
		},
	}
	return getPublicIPViaHttp(client)
}
