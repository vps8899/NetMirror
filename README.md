# NetMirror - 现代化的 Looking-glass 服务器
[![Docker Pulls](https://img.shields.io/docker/pulls/soyorins/netmirror)](https://hub.docker.com/r/soyorins/netmirror)
[![License](https://img.shields.io/badge/license-Apache%202.0%20%2B%20Commons%20Clause-blue)](LICENSE)

NetMirror 是一个功能丰富的现代 Looking-glass 服务器，拥有美观的 Web 界面，用于网络诊断和性能测试。

本项目的演示服务器由 [Verasel](https://verasel.com) 赞助。

## 🆕 最新更新

### v2.2.0 - 自动部署脚本（最新版）
- **⚡ 一键部署**：自动化的主节点和子节点部署脚本
- **🔑 API 密钥管理**：管理员 API 密钥的自动生成和验证
- **🐳 Docker 自动化**：自动 Docker 安装和容器管理
- **📡 自动注册**：子节点自动向主节点注册
- **✅ 验证系统**：部署前的连接和权限验证
- **🛠️ 错误处理**：全面的错误检测和故障排除指导

### v2.1.0 - 节点管理系统
- **🎛️ 管理面板**：全新的网页版管理界面，采用现代卡片布局
- **🔧 API 管理**：基于 API 密钥认证的动态节点管理
- **📡 GET API 支持**：通过简单的 GET 请求添加节点，便于自动化
- **🔄 自动迁移**：从环境变量无缝迁移到 API 管理
- **🎨 增强 UI**：美观的动画效果、玻璃拟态设计和响应式界面
- **📱 移动友好**：针对所有设备尺寸优化的界面
- **🔐 双重认证**：支持头部（`X-Api-Key`）和查询参数认证
- **📊 实时统计**：包含节点统计和状态指示器的仪表板

### 主要新增功能：
- **一键部署**：`netmirror-deploy.sh` 脚本实现即时设置
- **主从架构**：集中式节点管理与分布式部署
- **动态节点管理**：通过 Web 界面添加、编辑、删除节点
- **自动化支持**：`GET /api/admin/nodes/add` 端点用于脚本化
- **向后兼容**：现有环境变量配置仍然有效
- **增强安全性**：基于 API 密钥的认证与本地存储
- **改进用户体验**：现代卡片式界面替代传统表格

---

## ✨ 功能特性

- **⚡ 一键部署**：自动化部署脚本，即时设置主节点和子节点。
- **🎛️ 节点管理**：基于 Web 的管理面板，用于动态节点配置和监控。
- **🌐 网络工具**：包含 Ping、iPerf3、MTR、Traceroute 和 Speedtest 等工具套件。
- **📊 实时流量**：具有美观可视化效果的实时网络接口流量监控。
- **🖥️ 交互式 Shell**：用于基本诊断的安全模拟 Shell 环境。
- **🔌 API 集成**：用于自动化和脚本化的全面 RESTful API。
- **🐳 轻松部署**：以单个 Docker 容器形式提供，配备自动化部署脚本。
- **🎨 现代 UI**：基于 Vue.js 和 Tailwind CSS 构建的简洁响应式用户界面。
- **⚙️ 可定制**：通过环境变量或 Web 界面配置功能和服务器详情。

## 🚀 快速开始

### ⚡ 一键部署（推荐）

```
# English
curl -sL https:// | bash

# Chinese
curl -sL https:// | bash -s -- -cn
```

**部署主节点：**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "主节点" \
  --location "您的位置" \
  --port 3000 \
  --non-interactive
```

**部署子节点：**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "子节点名称" \
  --location "子节点位置" \
  --port 3001 \
  --master "http://您的主节点IP:3000" \
  --admin-key "您的API密钥" \
  --non-interactive
```

部署脚本会自动：
- 🐳 根据需要安装 Docker
- 🔑 生成安全 API 密钥（主节点）
- ⚙️ 配置环境变量
- 🚀 使用最佳设置启动容器
- 📡 将子节点注册到主节点
- ✅ 验证连接和权限

> **📖 有关详细部署选项和故障排除，请参阅 [scripts/README.md](scripts/README.md)**

### 手动 Docker Compose 部署

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
services:
  als:
    image: soyorins/netmirror:latest
    container_name: looking-glass-e
    restart: always
    network_mode: host
    user: root
    env_file:
      - .env
    volumes:
      - ./data:/data
      - ./.air.toml:/app/.air.toml
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:${HTTP_PORT:-80}/"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

应用将可以通过 `http://<您的服务器IP>` 访问。默认端口是 3000，可以通过 `HTTP_PORT` 环境变量进行更改。

> **🎛️ 管理面板访问**：如果您在 `.env` 文件中设置了 `ADMIN_API_KEY`，您可以通过点击浮动操作按钮（右下角）→ 设置图标（⚙️）来访问管理面板。

## 📦 Docker 镜像

预构建的多架构 Docker 镜像可在 DockerHub 上获取：

- **支持的架构**: `linux/amd64`, `linux/arm64`
- **镜像仓库**: `soyorins/netmirror`
- **可用标签**: `latest`、版本标签（如 `v1.0.0`）、分支名称

当代码推送到主分支或创建新标签时，镜像会通过 GitHub Actions 自动构建和发布。

## 🔧 配置

通过在 `.env` 文件中设置环境变量来配置 NetMirror。

| 键 | 示例 | 默认值 | 描述 |
|---|---|---|---|
| `LISTEN_IP` | `127.0.0.1` | (所有 IP) | 服务器监听的 IP 地址。 |
| `HTTP_PORT` | `8080` | `80` | 服务器监听的端口。 |
| `SPEEDTEST_FILE_LIST` | `100MB 1GB` | `1MB 10MB 100MB 1GB` | 用于速度测试的文件大小列表，以空格分隔。 |
| `LOCATION` | `"中国，北京"` | (通过 ipapi.co 自动检测) | 描述服务器位置的文本。 |
| `PUBLIC_IPV4` | `1.1.1.1` | (自动检测) | 服务器的公网 IPv4 地址。 |
| `PUBLIC_IPV6` | `fe80::1` | (自动检测) | 服务器的公网 IPv6 地址。 |
| `DISPLAY_TRAFFIC` | `true` | `true` | 实时流量显示的开关。 |
| `ENABLE_SPEEDTEST` | `true` | `true` | 速度测试功能的开关。 |
| `UTILITIES_PING` | `true` | `true` | Ping 工具的开关。 |
| `UTILITIES_SPEEDTESTDOTNET`| `true` | `true` | Speedtest.net 工具的开关。 |
| `UTILITIES_FAKESHELL` | `true` | `true` | 模拟 Shell 工具的开关。 |
| `UTILITIES_IPERF3` | `true` | `true` | iPerf3 服务器工具的开关。 |
| `UTILITIES_IPERF3_PORT_MIN` | `30000` | `30000` | iPerf3 服务器端口范围 - 起始。 |
| `UTILITIES_IPERF3_PORT_MAX` | `31000` | `31000` | iPerf3 服务器端口范围 - 结束。 |
| `SPONSOR_MESSAGE` | `"欢迎"` | `''` | 显示赞助商信息。支持文本、URL 或容器内的文件路径。 |

### 🔄 节点管理

NetMirror 支持基于环境变量的节点配置（传统）和基于 API 的节点管理（推荐）。

> **💡 快速开始**：在环境中设置 `ADMIN_API_KEY`，重启服务器，然后点击 Web 界面中的设置图标即可访问管理面板！

#### 环境变量配置（传统）

使用环境变量配置节点以保证向后兼容性：

| 键 | 示例 | 描述 |
|---|---|---|
| `LG_NODES` | `伦敦\\|英国，伦敦\\|https://lg1.example.com;东京\\|日本，东京\\|https://lg2.example.com` | 以分号分隔的节点列表，格式：`名称\\|位置\\|URL` |
| `LG_CURRENT_URL` | `https://lg1.example.com` | 当前节点的 URL（在列表中标记为"当前"） |
| `LG_CURRENT_NAME` | `伦敦节点` | 当前节点的显示名称 |
| `LG_CURRENT_LOCATION` | `英国，伦敦` | 当前节点的位置描述 |

#### 基于 API 的节点管理（推荐）

使用带有 API 认证的管理界面进行动态节点管理：

| 键 | 示例 | 描述 |
|---|---|---|
| `ADMIN_API_KEY` | `your-secret-api-key-here` | 管理员 API 访问的密钥（节点管理必需） |
| `DATA_DIR` | `/data` | 存储节点配置文件的目录（默认：`./data`） |

**使用管理界面：**

1. **设置 API 密钥**：在环境中配置 `ADMIN_API_KEY`
2. **重启服务器**：管理面板仅在设置 API 密钥时启用
3. **访问管理面板**：
   - **Web 界面**：点击浮动操作按钮（右下角）中的设置图标（⚙️）
   - **直接 URL**：不可用 - 出于安全考虑，仅可通过 Web 界面访问
4. **身份验证**：输入您的 API 密钥（将存储在本地以便使用）
5. **管理节点**：通过现代卡片式界面添加、编辑或删除节点

> **💡 管理面板位置**：管理界面集成在主应用程序中。在页面右下角查找浮动操作按钮，悬停显示设置图标，然后点击访问管理面板。

**管理面板功能：**
- 🎛️ **现代卡片布局**：具有实时状态的可视化节点管理
- 📊 **仪表板统计**：总节点数、在线状态和当前节点概览
- 🔍 **连接测试**：一键测试所有节点的连接
- ✏️ **CRUD 操作**：创建、读取、更新和删除节点
- 📱 **响应式设计**：在桌面、平板和移动设备上完美运行

**API 端点：**

- `GET /nodes` - 列出所有节点的公共端点
- `GET /nodes/latency` - 测试当前节点的延迟
- `POST /api/admin/nodes` - 创建新节点（需要 API 密钥）
- `GET /api/admin/nodes/add` - 通过 GET 请求创建新节点（需要 API 密钥）
- `GET /api/admin/nodes/:id` - 获取节点详情（需要 API 密钥）
- `PUT /api/admin/nodes/:id` - 更新节点（需要 API 密钥）
- `DELETE /api/admin/nodes/:id` - 删除节点（需要 API 密钥）

**GET 请求节点创建：**

用于自动化和脚本化，您可以使用简单的 GET 请求添加节点：

```bash
# 使用查询参数添加节点
curl "http://您的服务器:端口/api/admin/nodes/add?api_key=您的API密钥&name=东京&location=日本，东京&url=https://lg.tokyo.example.com"

# 或使用头部认证
curl -H "X-Api-Key: 您的API密钥" "http://您的服务器:端口/api/admin/nodes/add?name=东京&location=日本，东京&url=https://lg.tokyo.example.com"
```

**必需参数：**
- `name` - 节点显示名称
- `location` - 节点位置描述  
- `url` - 节点端点 URL

**认证方式：**
1. **头部认证**：`X-Api-Key: 您的API密钥`
2. **查询参数认证**：`?api_key=您的API密钥`

**批量节点添加脚本：**

```bash
#!/bin/bash
API_KEY="您的密钥"
SERVER="http://您的服务器:3000"

# 要添加的节点数组
declare -a nodes=(
    "伦敦|英国，伦敦|https://lg.london.example.com"
    "东京|日本，东京|https://lg.tokyo.example.com"
    "新加坡|新加坡|https://lg.singapore.example.com"
    "法兰克福|德国，法兰克福|https://lg.frankfurt.example.com"
)

# 添加每个节点
for node in "${nodes[@]}"; do
    IFS='|' read -r name location url <<< "$node"
    echo "添加节点: $name"
    
    response=$(curl -s -H "X-Api-Key: $API_KEY" \
        "$SERVER/api/admin/nodes/add?name=$(echo "$name" | sed 's/ /%20/g')&location=$(echo "$location" | sed 's/ /%20/g;s/,/%2C/g')&url=$(echo "$url")")
    
    if echo "$response" | grep -q '"success":true'; then
        echo "✅ 成功添加 $name"
    else
        echo "❌ 添加 $name 失败: $response"
    fi
done
```

**节点配置格式：**
```json
{
  "name": "伦敦节点",
  "location": "英国，伦敦", 
  "url": "https://lg.london.example.com"
}
```

#### 从环境变量迁移

API 管理的节点优先于环境变量配置。当存在 API 管理的节点时，环境变量将被忽略。要迁移：

1. 设置 `ADMIN_API_KEY`
2. 使用管理界面添加现有节点
3. 移除 `LG_NODES` 和相关环境变量
4. 重启服务

## 🎛️ 管理面板访问

**如何访问**：点击浮动操作按钮（右下角）→ 设置图标（⚙️）
**组件位置**：`/ui/src/components/Admin.vue`
**身份验证**：需要 `ADMIN_API_KEY`（首次登录后存储在本地）

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

Apache License, Version 2.0 and the Commons Clause Restriction.
