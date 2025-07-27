package config

import (
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

var Config *ALSConfig
var IsInternalCall bool

type ALSConfig struct {
	ListenHost string `json:"-"`
	ListenPort string `json:"-"`

	Location string `json:"location"`

	PublicIPv4 string `json:"public_ipv4"`
	PublicIPv6 string `json:"public_ipv6"`

	Iperf3StartPort int `json:"-"`
	Iperf3EndPort   int `json:"-"`

	SpeedtestFileList []string `json:"speedtest_files"`

	SponsorMessage     string `json:"sponsor_message"`
	SponsorMessageType string `json:"sponsor_message_type"`

	FeaturePing            bool `json:"feature_ping"`
	FeatureShell           bool `json:"feature_shell"`
	FeatureLibrespeed      bool `json:"feature_librespeed"`
	FeatureFileSpeedtest   bool `json:"feature_filespeedtest"`
	FeatureSpeedtestDotNet bool `json:"feature_speedtest_dot_net"`
	FeatureIperf3          bool `json:"feature_iperf3"`
	FeatureMTR             bool `json:"feature_mtr"`
	FeatureTraceroute      bool `json:"feature_traceroute"`
	FeatureIfaceTraffic    bool `json:"feature_iface_traffic"`
}

func GetDefaultConfig() *ALSConfig {
	defaultConfig := &ALSConfig{
		ListenHost:      "0.0.0.0",
		ListenPort:      "80",
		Location:        "",
		Iperf3StartPort: 30000,
		Iperf3EndPort:   31000,

		SpeedtestFileList: []string{"100MB", "1GB", "10GB"},
		PublicIPv4:        "",
		PublicIPv6:        "",

		FeaturePing:            true,
		FeatureShell:           true,
		FeatureLibrespeed:      true,
		FeatureFileSpeedtest:   true,
		FeatureSpeedtestDotNet: true,
		FeatureIperf3:          true,
		FeatureMTR:             true,
		FeatureTraceroute:      true,
		FeatureIfaceTraffic:    true,
	}

	return defaultConfig
}

func Load() {
	// default config
	Config = GetDefaultConfig()
	LoadFromEnv()
}

func LoadWebConfig() {
	Load()
	LoadSponsorMessage()
	log.Default().Println("Loading config for web services...")

	_, err := exec.LookPath("iperf3")
	if err != nil {
		log.Default().Println("WARN: Disable iperf3 due to not found")
		Config.FeatureIperf3 = false
	}

	if Config.PublicIPv4 == "" && Config.PublicIPv6 == "" {
		go func() {
			updatePublicIP()
			if Config.Location == "" {
				updateLocation()
			}
		}()
	}

}

func LoadSponsorMessage() {
	if Config.SponsorMessage == "" {
		return
	}

	log.Default().Println("Loading sponsor message...")

	originalMessage := Config.SponsorMessage

	// 检查是否为本地文件路径
	if _, err := os.Stat(Config.SponsorMessage); err == nil {
		content, err := os.ReadFile(Config.SponsorMessage)
		if err == nil {
			Config.SponsorMessage = string(content)
			// 根据文件扩展名判断类型
			if strings.HasSuffix(strings.ToLower(originalMessage), ".md") {
				Config.SponsorMessageType = "markdown"
			} else if strings.HasSuffix(strings.ToLower(originalMessage), ".html") {
				Config.SponsorMessageType = "html"
			} else {
				Config.SponsorMessageType = "text"
			}
			return
		}
	}

	// 检查是否为URL
	if strings.HasPrefix(Config.SponsorMessage, "http://") || strings.HasPrefix(Config.SponsorMessage, "https://") {
		lowerURL := strings.ToLower(originalMessage)
		
		// 如果是.md链接，下载内容作为markdown
		if strings.HasSuffix(lowerURL, ".md") {
			resp, err := http.Get(Config.SponsorMessage)
			if err == nil {
				content, err := io.ReadAll(resp.Body)
				resp.Body.Close()
				if err == nil {
					log.Default().Println("Loaded sponsor message from markdown URL.")
					Config.SponsorMessage = string(content)
					Config.SponsorMessageType = "markdown"
					return
				}
			}
		} else {
			// 其他URL作为iframe处理
			log.Default().Println("Using sponsor message as iframe URL.")
			Config.SponsorMessageType = "iframe"
			return
		}
	}

	// 如果不是文件路径也不是URL，当作纯文本处理
	// 检测内容类型
	content := Config.SponsorMessage
	if strings.Contains(content, "<") && strings.Contains(content, ">") {
		// 包含HTML标签，判断为HTML
		Config.SponsorMessageType = "html"
	} else if strings.Contains(content, "#") || strings.Contains(content, "*") || strings.Contains(content, "[") {
		// 包含Markdown特征，判断为Markdown
		Config.SponsorMessageType = "markdown"
	} else {
		// 纯文本
		Config.SponsorMessageType = "text"
	}

	log.Default().Printf("Sponsor message type detected: %s", Config.SponsorMessageType)
}
