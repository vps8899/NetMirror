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
	Logo     string `json:"logo"`
	LogoType string `json:"logo_type"`

	PublicIPv4 string `json:"public_ipv4"`
	PublicIPv6 string `json:"public_ipv6"`

	// Network information
	BGP string `json:"bgp"`
	ASN string `json:"asn"`

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
		Logo:            "",
		LogoType:        "auto",
		Iperf3StartPort: 30000,
		Iperf3EndPort:   31000,

		SpeedtestFileList: []string{"100MB", "1GB", "10GB"},
		PublicIPv4:        "",
		PublicIPv6:        "",
		BGP:               "",
		ASN:               "",

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
	LoadLogoType()
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

func LoadLogoType() {
	if Config.Logo == "" {
		return
	}

	// 如果用户已经指定了类型，就不要自动检测
	if Config.LogoType != "auto" {
		return
	}

	log.Default().Println("Detecting logo type...")

	content := Config.Logo

	// 检测是否为URL
	if strings.HasPrefix(content, "http://") || strings.HasPrefix(content, "https://") {
		Config.LogoType = "url"
		log.Default().Println("Logo type detected: url")
		return
	}

	// 检测是否为base64
	if strings.HasPrefix(content, "data:image/") {
		Config.LogoType = "base64"
		log.Default().Println("Logo type detected: base64")
		return
	}

	// 检测是否为SVG
	if strings.Contains(content, "<svg") && strings.Contains(content, "</svg>") {
		Config.LogoType = "svg"
		log.Default().Println("Logo type detected: svg")
		return
	}

	// 检测是否为emoji（简单检测Unicode范围）
	runes := []rune(content)
	if len(runes) <= 5 && len(runes) > 0 {
		for _, r := range runes {
			if r >= 0x1F600 && r <= 0x1F64F || // 表情符号
			   r >= 0x1F300 && r <= 0x1F5FF || // 其他符号
			   r >= 0x1F680 && r <= 0x1F6FF || // 交通和地图符号
			   r >= 0x2600 && r <= 0x26FF ||   // 杂项符号
			   r >= 0x2700 && r <= 0x27BF {    // 装饰符号
				Config.LogoType = "emoji"
				log.Default().Println("Logo type detected: emoji")
				return
			}
		}
	}

	// 默认当作纯文本处理
	Config.LogoType = "text"
	log.Default().Println("Logo type detected: text")
}
