# ALS - Another Looking-glass Server

[![Docker Image Build](https://github.com/wikihost-opensource/als/actions/workflows/docker-image.yml/badge.svg)](https://github.com/wikihost-opensource/als/actions/workflows/docker-image.yml)
[![Release](https://img.shields.io/github/v/release/wikihost-opensource/als)](https://github.com/wikihost-opensource/als/releases)
[![License](https://img.shields.io/github/license/wikihost-opensource/als)](LICENSE)

Language: English | [简体中文](README_zh_CN.md)

A modern, feature-rich looking glass server with a beautiful web interface for network diagnostics and performance testing.

## ✨ Features

- 🎨 **Modern UI**: Beautiful, responsive interface with dark mode support
- 🌐 **Multi-language**: Support for multiple languages with i18n
- 📊 **Real-time Charts**: Interactive bandwidth monitoring and test results
- 🔧 **Network Tools**: Comprehensive set of network diagnostic tools
- 🚀 **High Performance**: Built with Go backend and Vue.js frontend
- 🐳 **Docker Ready**: Easy deployment with Docker containers
- 📱 **Mobile Friendly**: Fully responsive design for all devices

### Network Tools

- **Ping**: IPv4/IPv6 connectivity testing with real-time results
- **IPerf3**: Network bandwidth measurement server
- **Speedtest.net**: Internet speed testing integration
- **Interactive Shell**: Limited command-line interface for diagnostics
- **Traffic Monitoring**: Real-time network interface bandwidth graphs
- **File Download Tests**: Multiple file sizes for speed testing

### Additional Features

- **LibreSpeed Integration**: HTML5-based speed testing
- **NextTrace Support**: Advanced traceroute with AS information
- **Real-time Updates**: Server-sent events for live data
- **Customizable**: Extensive configuration options
- **Sponsor Messages**: Support for custom branding and messages

## 🚀 Quick Start

### Using Docker (Recommended)

\`\`\`bash
docker run -d \
  --name looking-glass \
  --restart always \
  --network host \
  wikihostinc/looking-glass-server:latest
\`\`\`

### Using Docker Compose

\`\`\`yaml
version: '3.8'
services:
  als:
    image: wikihostinc/looking-glass-server:latest
    container_name: looking-glass
    restart: always
    network_mode: host
    environment:
      - HTTP_PORT=8080
      - LOCATION=Your Server Location
    volumes:
      - ./data:/data
\`\`\`

### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/wikihost-opensource/als/releases)
2. Extract and run:

\`\`\`bash
chmod +x als-linux-amd64
./als-linux-amd64
\`\`\`

## 🔧 Configuration

### Environment Variables

| Variable | Example | Default | Description |
|----------|---------|---------|-------------|
| `LISTEN_IP` | `127.0.0.1` | `0.0.0.0` | IP address to bind to |
| `HTTP_PORT` | `8080` | `80` | HTTP port to listen on |
| `LOCATION` | `"New York, US"` | Auto-detected | Server location string |
| `PUBLIC_IPV4` | `1.1.1.1` | Auto-detected | Public IPv4 address |
| `PUBLIC_IPV6` | `2001:db8::1` | Auto-detected | Public IPv6 address |
| `SPEEDTEST_FILE_LIST` | `100MB 1GB` | `1MB 10MB 100MB 1GB` | Available test file sizes |
| `SPONSOR_MESSAGE` | `"Custom message"` | Empty | Sponsor/custom message |

### Feature Toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY_TRAFFIC` | `true` | Show real-time traffic graphs |
| `ENABLE_SPEEDTEST` | `true` | Enable LibreSpeed testing |
| `UTILITIES_PING` | `true` | Enable ping functionality |
| `UTILITIES_SPEEDTESTDOTNET` | `true` | Enable Speedtest.net integration |
| `UTILITIES_FAKESHELL` | `true` | Enable interactive shell |
| `UTILITIES_IPERF3` | `true` | Enable iPerf3 server |
| `UTILITIES_IPERF3_PORT_MIN` | `30000` | iPerf3 port range start |
| `UTILITIES_IPERF3_PORT_MAX` | `31000` | iPerf3 port range end |

### Example Configuration

\`\`\`bash
docker run -d \
  --name looking-glass \
  -e HTTP_PORT=8080 \
  -e LOCATION="Tokyo, Japan" \
  -e SPONSOR_MESSAGE="Powered by Example Hosting" \
  -e SPEEDTEST_FILE_LIST="10MB 100MB 1GB 10GB" \
  --restart always \
  --network host \
  wikihostinc/looking-glass-server:latest
\`\`\`

## 🏗️ Development

### Prerequisites

- Go 1.21+
- Node.js 18+
- Docker (optional)

### Backend Development

\`\`\`bash
cd backend
go mod download
go run main.go
\`\`\`

### Frontend Development

\`\`\`bash
cd ui
npm install
npm run dev
\`\`\`

The development server will start on `http://localhost:3000` with hot reload enabled.

### Building from Source

\`\`\`bash
# Build frontend
cd ui
npm install
npm run build

# Build backend
cd ../backend
go build -o als

# Run
./als
\`\`\`

### Docker Build

\`\`\`bash
docker build -t als:local .
\`\`\`

## 📊 System Requirements

### Minimum Requirements

- **RAM**: 32MB
- **CPU**: Any modern architecture (x86_64, ARM64, ARMv7)
- **Storage**: 50MB
- **Network**: Internet connection for external tools

### Recommended Requirements

- **RAM**: 128MB+
- **CPU**: Multi-core processor
- **Storage**: 200MB+
- **Network**: High-bandwidth connection for accurate testing

## 🌐 Browser Support

- Chrome/Chromium 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile browsers (iOS Safari, Chrome Mobile)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Reporting Issues

Please use the [GitHub Issues](https://github.com/wikihost-opensource/als/issues) page to report bugs or request features.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [LibreSpeed](https://github.com/librespeed/speedtest) - HTML5 speed testing
- [NextTrace](https://github.com/nxtrace/NTrace-core) - Advanced traceroute
- [JetBrains](https://www.jetbrains.com/) - Development tools

## 📈 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=wikihost-opensource/als&type=Date)](https://star-history.com/#wikihost-opensource/als&Date)

---

**Powered by WIKIHOST Opensource - ALS**

If you find this project helpful, please consider giving it a ⭐ on GitHub!
\`\`\`

## 🎉 完成总结

现在我们已经完成了 ALS (Another Looking-glass Server) 的完整现代化重新设计！这个项目现在包含：

### ✨ 主要改进

1. **现代化 UI/UX**
   - 全新的设计语言
   - 流畅的动画和过渡效果
   - 响应式设计
   - 深色模式支持

2. **技术栈升级**
   - Vue 3 + Composition API
   - Tailwind CSS
   - Motion/Vue 动画库
   - TypeScript 支持
   - 现代化构建工具

3. **功能增强**
   - 改进的网络工具界面
   - 实时图表和监控
   - 多语言支持
   - 移动端优化

4. **开发体验**
   - 完整的开发环境配置
   - 代码质量工具 (ESLint, Prettier)
   - 自动化构建流程
   - 详细的文档

5. **部署优化**
   - 改进的 Docker 配置
   - 优化的构建脚本
   - 生产环境优化

这个重新设计的版本提供了专业级的用户体验，同时保持了原有的所有功能。界面现在更加现代化、直观且易于使用，适合系统管理员和网络工程师的专业需求。
