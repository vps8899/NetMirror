# NetMirror - 一个现代化的 Looking-glass 服务器

NetMirror 是一个功能丰富的现代 Looking-glass 服务器，拥有一个美观的 Web 界面，用于网络诊断和性能测试。

## ✨ 功能特性

- **现代 UI**: 基于 Vue.js 构建的简洁、响应式用户界面。
- **网络工具**: 集成了 Ping、iPerf3 和 Speedtest 等一套工具。
- **实时流量**: 实时监控网络接口流量。
- **交互式 Shell**: 用于基本诊断的模拟 Shell 环境。
- **轻松部署**: 以单个 Docker 容器的形式提供。
- **可定制**: 通过环境变量配置功能和服务器详情。

## 🚀 快速开始 (使用 Docker Compose)

1.  **克隆仓库:**
    ```bash
    git clone https://github.com/Yuri-NagaSaki/NetMirror.git
    cd NetMirror
    ```

2.  **创建环境文件:**

    复制环境文件示例以创建您自己的配置。
    ```bash
    cp .env.example .env
    ```
    *注意: 如果 `.env.example` 文件不存在，您可以创建一个空的 `.env` 文件，并从下表中添加您需要的变量。*

3.  **自定义您的配置 (可选):**

    编辑 `.env` 文件以设置您的服务器位置、公网 IP 地址和其他选项。

4.  **启动服务:**
    ```bash
    docker-compose up -d
    ```

应用将可以通过 `http://<您的服务器IP>` 访问。默认端口是 3000，可以通过 `HTTP_PORT` 环境变量进行更改。

## 🔧 配置

通过在 `.env` 文件中设置环境变量来配置 NetMirror。

| 键 | 示例 | 默认值 | 描述 |
|---|---|---|---|
| `LISTEN_IP` | `127.0.0.1` | (所有 IP) | 服务器监听的 IP 地址。 |
| `HTTP_PORT` | `8080` | `80` | 服务器监听的端口。 |
| `SPEEDTEST_FILE_LIST` | `100MB 1GB` | `1MB 10MB 100MB 1GB` | 用于速度测试的文件大小列表，以空格分隔。 |
| `LOCATION` | `"美国, 纽约"` | (通过 ipapi.co 自动检测) | 描述服务器位置的文本。 |
| `PUBLIC_IPV4` | `1.1.1.1` | (自动检测) | 服务器的公网 IPv4 地址。 |
| `PUBLIC_IPV6` | `fe80::1` | (自动检测) | 服务器的公网 IPv6 地址。 |
| `DISPLAY_TRAFFIC` | `true` | `true` | 实时流量显示的开关。 |
| `ENABLE_SPEEDTEST` | `true` | `true` | 速度测试功能的开关。 |
| `UTILITIES_PING` | `true` | `true` | Ping 功能的开关。 |
| `UTILITIES_SPEEDTESTDOTNET`| `true` | `true` | Speedtest.net 功能的开关。 |
| `UTILITIES_FAKESHELL` | `true` | `true` | 模拟 Shell 功能的开关。 |
| `UTILITIES_IPERF3` | `true` | `true` | iPerf3 服务器功能的开关。 |
| `UTILITIES_IPERF3_PORT_MIN` | `30000` | `30000` | iPerf3 服务器端口范围 - 起始。 |
| `UTILITIES_IPERF3_PORT_MAX` | `31000` | `31000` | iPerf3 服务器端口范围 - 结束。 |
| `SPONSOR_MESSAGE` | `"你好"` | `''` | 显示赞助商信息。支持文本、URL 或容器内的文件路径。 |

## 🏗️ 从源码构建

### 环境要求

- Go
- Node.js & npm
- Docker

### 构建步骤

1.  **构建前端:**
    ```bash
    cd ui
    npm install
    npm run build
    ```

2.  **构建后端:**
    ```bash
    cd ../backend
    go build -o ../NetMirror
    ```

3.  **运行应用:**

    最终的可执行文件将位于项目根目录。在运行前，请确保已设置所有必要的环境变量。
    ```bash
    ./NetMirror
    ```

## 📄 许可证

本项目基于 MIT 许可证。
