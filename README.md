# NetMirror - A Modern Looking-glass Server
[![Docker Pulls](https://img.shields.io/docker/pulls/soyorins/netmirror)](https://hub.docker.com/r/soyorins/netmirror)
[![License](https://img.shields.io/badge/license-Apache%202.0%20%2B%20Commons%20Clause-blue)](LICENSE)

NetMirror is a modern, feature-rich looking-glass server with a beautiful web interface for network diagnostics and performance testing.

The demo server for this project is sponsored by [Verasel](https://verasel.com).

## 🆕 Recent Updates

### v2.2.0 - Auto Deployment Scripts (Latest)
- **⚡ One-Click Deployment**: Automated master and child node deployment script
- **🔑 API Key Management**: Auto-generation and validation of admin API keys
- **🐳 Docker Automation**: Automatic Docker installation and container management
- **📡 Auto Registration**: Child nodes automatically register with master nodes
- **✅ Validation System**: Connection and permission verification before deployment
- **🛠️ Error Handling**: Comprehensive error detection and troubleshooting guidance

### v2.1.0 - Node Management System
- **🎛️ Admin Panel**: New web-based admin interface with modern card layout
- **🔧 API Management**: Dynamic node management with API key authentication
- **📡 GET API Support**: Add nodes via simple GET requests for automation
- **🔄 Auto Migration**: Seamlessly migrate from environment variables to API management
- **🎨 Enhanced UI**: Beautiful animations, glass morphism effects, and responsive design
- **📱 Mobile Friendly**: Optimized interface for all device sizes
- **🔐 Dual Authentication**: Support both header (`X-Api-Key`) and query parameter authentication
- **📊 Real-time Stats**: Dashboard with node statistics and status indicators

### Key Features Added:
- **One-Click Deployment**: `netmirror-deploy.sh` script for instant setup
- **Master-Child Architecture**: Centralized node management with distributed deployment
- **Dynamic Node Management**: Add, edit, delete nodes through web interface
- **Automation Support**: `GET /api/admin/nodes/add` endpoint for scripting
- **Backward Compatibility**: Existing environment variable configs still work
- **Enhanced Security**: API key-based authentication with local storage
- **Improved UX**: Modern card-based interface replacing traditional tables

---

## ✨ Features

- **⚡ One-Click Deployment**: Automated deployment scripts for instant setup of master and child nodes.
- **🎛️ Node Management**: Web-based admin panel for dynamic node configuration and monitoring.
- **🌐 Network Tools**: A suite of tools including Ping, iPerf3, MTR, Traceroute, and Speedtest.
- **📊 Real-time Traffic**: Live monitoring of network interface traffic with beautiful visualizations.
- **🖥️ Interactive Shell**: A secure fake shell environment for basic diagnostics.
- **🔌 API Integration**: Comprehensive RESTful APIs for automation and scripting.
- **🐳 Easy Deployment**: Ships as a single Docker container with automated deployment scripts.
- **🎨 Modern UI**: A clean and responsive user interface built with Vue.js and Tailwind CSS.
- **⚙️ Customizable**: Configure features and server details via environment variables or web interface.

## 🚀 Quick Start

```
⚡ One-Click Execution
# English
curl -sL https://raw.githubusercontent.com/catcat-blog/NetMirror/refs/heads/main/scripts/netmirror-interactive.sh | bash

# Chinese
curl -sL https://raw.githubusercontent.com/catcat-blog/NetMirror/refs/heads/main/scripts/netmirror-interactive.sh | bash -s -cn

```

**Deploy Master Node:**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "Master Node" \
  --location "Your Location" \
  --port 3000 \
  --non-interactive
```

**Deploy Child Node:**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "Child Node Name" \
  --location "Child Location" \
  --port 3001 \
  --master "http://your-master-ip:3000" \
  --admin-key "your-api-key" \
  --non-interactive
```

The deployment script automatically:
- 🐳 Installs Docker if needed
- 🔑 Generates secure API keys (master nodes)
- ⚙️ Configures environment variables
- 🚀 Starts containers with optimal settings
- 📡 Registers child nodes with master node
- ✅ Validates connections and permissions

> **📖 For detailed deployment options and troubleshooting, see [scripts/README.md](scripts/README.md)**

### Manual Docker Compose Deployment

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Yuri-NagaSaki/NetMirror.git
    cd NetMirror
    ```

2.  **Create an environment file:**

    Copy the example environment file to create your own configuration.
    ```bash
    cp .env.example .env
    ```
    *Note: If `.env.example` does not exist, you can create a blank `.env` file and add the variables you need from the table below.*

3.  **Customize your configuration (optional):**

    Edit the `.env` file to set your server location, public IP addresses, and other options.

4.  **Start the server:**
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

The application will be accessible at `http://<your-server-ip>`. The default port is 3000, which can be changed via the `HTTP_PORT` environment variable.

> **🎛️ Admin Panel Access**: If you set `ADMIN_API_KEY` in your `.env` file, you can access the admin panel by clicking the floating action button (bottom-right corner) → settings icon (⚙️) on the web interface.

## 📦 Docker Images

Pre-built multi-architecture Docker images are available on DockerHub:

- **Supported architectures**: `linux/amd64`, `linux/arm64`
- **Image repository**: `soyorins/netmirror`
- **Available tags**: `latest`, version tags (e.g., `v1.0.0`), branch names

Images are automatically built and published via GitHub Actions when code is pushed to the main branch or when new tags are created.

## 🔧 Configuration

Configure NetMirror by setting environment variables in the `.env` file.

| Key | Example | Default | Description |
|---|---|---|---|
| `LISTEN_IP` | `127.0.0.1` | (All IPs) | IP address for the server to listen on. |
| `HTTP_PORT` | `8080` | `80` | Port for the server to listen on. |
| `SPEEDTEST_FILE_LIST` | `100MB 1GB` | `1MB 10MB 100MB 1GB` | Space-separated list of file sizes for speed testing. |
| `LOCATION` | `"New York, US"` | (Auto-detected via ipapi.co) | Text describing the server's location. |
| `PUBLIC_IPV4` | `1.1.1.1` | (Auto-detected) | The server's public IPv4 address. |
| `PUBLIC_IPV6` | `fe80::1` | (Auto-detected) | The server's public IPv6 address. |
| `DISPLAY_TRAFFIC` | `true` | `true` | Toggle for the real-time traffic display. |
| `ENABLE_SPEEDTEST` | `true` | `true` | Toggle for the speed test feature. |
| `UTILITIES_PING` | `true` | `true` | Toggle for the Ping utility. |
| `UTILITIES_SPEEDTESTDOTNET`| `true` | `true` | Toggle for the Speedtest.net utility. |
| `UTILITIES_FAKESHELL` | `true` | `true` | Toggle for the fake shell utility. |
| `UTILITIES_IPERF3` | `true` | `true` | Toggle for the iPerf3 server utility. |
| `UTILITIES_IPERF3_PORT_MIN` | `30000` | `30000` | iPerf3 server port range - start. |
| `UTILITIES_IPERF3_PORT_MAX` | `31000` | `31000` | iPerf3 server port range - end. |
| `SPONSOR_MESSAGE` | `"Hello"` | `''` | Display a sponsor message. Supports text, URL, or a file path within the container. |

### 🔄 Node Management

NetMirror supports both environment variable-based node configuration (legacy) and API-based node management (recommended).

> **💡 Quick Start**: Set `ADMIN_API_KEY` in your environment, restart the server, and click the settings icon in the web interface to access the admin panel!

#### Environment Variable Configuration (Legacy)

Configure nodes using environment variables for backward compatibility:

| Key | Example | Description |
|---|---|---|
| `LG_NODES` | `London\|London, UK\|https://lg1.example.com;Tokyo\|Tokyo, JP\|https://lg2.example.com` | Semi-colon separated list of nodes in format: `NAME\|LOCATION\|URL` |
| `LG_CURRENT_URL` | `https://lg1.example.com` | URL of the current node (marks it as "current" in the list) |
| `LG_CURRENT_NAME` | `London Node` | Display name of the current node |
| `LG_CURRENT_LOCATION` | `London, UK` | Location description of the current node |

#### API-Based Node Management (Recommended)

For dynamic node management, use the admin interface with API authentication:

| Key | Example | Description |
|---|---|---|
| `ADMIN_API_KEY` | `your-secret-api-key-here` | Secret key for admin API access (required for node management) |
| `DATA_DIR` | `/data` | Directory to store node configuration files (default: `./data`) |

**Using the Admin Interface:**

1. **Set up API Key**: Configure `ADMIN_API_KEY` in your environment
2. **Restart the Server**: The admin panel is only enabled when API key is set
3. **Access Admin Panel**: 
   - **Web Interface**: Click the settings icon (⚙️) in the floating action button (bottom right corner)
   - **Direct URL**: Not available - only accessible through the web interface for security
4. **Authenticate**: Enter your API key (it will be stored locally for convenience)
5. **Manage Nodes**: Add, edit, or delete nodes through the modern card-based interface

> **💡 Admin Panel Location**: The admin interface is integrated into the main application. Look for the floating action button in the bottom-right corner of the page, hover over it to reveal the settings icon, then click to access the admin panel.

**Admin Panel Features:**
- 🎛️ **Modern Card Layout**: Visual node management with real-time status
- 📊 **Dashboard Statistics**: Overview of total nodes, online status, and current node
- 🔍 **Connectivity Testing**: Test connection to all nodes with one click
- ✏️ **CRUD Operations**: Create, read, update, and delete nodes
- 📱 **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices

**API Endpoints:**

- `GET /nodes` - Public endpoint to list all nodes
- `GET /nodes/latency` - Test latency to current node
- `POST /api/admin/nodes` - Create new node (requires API key)
- `GET /api/admin/nodes/add` - Create new node via GET request (requires API key)
- `GET /api/admin/nodes/:id` - Get node details (requires API key)
- `PUT /api/admin/nodes/:id` - Update node (requires API key)
- `DELETE /api/admin/nodes/:id` - Delete node (requires API key)

**GET Request Node Creation:**

For automation and scripting, you can add nodes using a simple GET request:

```bash
# Add node using query parameters
curl "http://your-server:port/api/admin/nodes/add?api_key=your-api-key&name=Tokyo&location=Tokyo,%20JP&url=https://lg.tokyo.example.com"

# Or using header authentication
curl -H "X-Api-Key: your-api-key" "http://your-server:port/api/admin/nodes/add?name=Tokyo&location=Tokyo,%20JP&url=https://lg.tokyo.example.com"
```

**Required Parameters:**
- `name` - Node display name
- `location` - Node location description  
- `url` - Node endpoint URL

**Authentication Methods:**
1. **Header**: `X-Api-Key: your-api-key`
2. **Query Parameter**: `?api_key=your-api-key`

**Batch Node Addition Script:**

```bash
#!/bin/bash
API_KEY="your-secret-api-key-here"
SERVER="http://your-server:3000"

# Array of nodes to add
declare -a nodes=(
    "London|London, UK|https://lg.london.example.com"
    "Tokyo|Tokyo, JP|https://lg.tokyo.example.com"
    "Singapore|Singapore, SG|https://lg.singapore.example.com"
    "Frankfurt|Frankfurt, DE|https://lg.frankfurt.example.com"
)

# Add each node
for node in "${nodes[@]}"; do
    IFS='|' read -r name location url <<< "$node"
    echo "Adding node: $name"
    
    response=$(curl -s -H "X-Api-Key: $API_KEY" \
        "$SERVER/api/admin/nodes/add?name=$(echo "$name" | sed 's/ /%20/g')&location=$(echo "$location" | sed 's/ /%20/g;s/,/%2C/g')&url=$(echo "$url")")
    
    if echo "$response" | grep -q '"success":true'; then
        echo "✅ Successfully added $name"
    else
        echo "❌ Failed to add $name: $response"
    fi
done
```

**Node Configuration Format:**
```json
{
  "name": "London Node",
  "location": "London, UK", 
  "url": "https://lg.london.example.com"
}
```

#### Migration from Environment Variables

API-managed nodes take precedence over environment variable configuration. When API-managed nodes exist, environment variables are ignored. To migrate:

1. Set up `ADMIN_API_KEY`
2. Use the admin interface to add your existing nodes
3. Remove `LG_NODES` and related environment variables
4. Restart the service

## 🎛️ Admin Panel Access

**How to Access**: Click the floating action button (bottom-right corner) → Settings icon (⚙️)
**Component**: `/ui/src/components/Admin.vue`
**Authentication**: Requires `ADMIN_API_KEY` (stored locally after first login)

## 🏗️ Building from Source

### Prerequisites

- Go
- Node.js & npm
- Docker

### Build Steps

1.  **Build the Frontend:**
    ```bash
    cd ui
    npm install
    npm run build
    ```

2.  **Build the Backend:**
    ```bash
    cd ../backend
    go build -o ../NetMirror
    ```

3.  **Run the application:**

    The final binary will be in the project root. Before running, ensure any necessary environment variables are set.
    ```bash
    ./NetMirror
    ```

## 📄 License

Apache License, Version 2.0 and the Commons Clause Restriction.
