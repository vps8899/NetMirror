# NetMirror - A Modern Looking-glass Server

NetMirror is a modern, feature-rich looking-glass server with a beautiful web interface for network diagnostics and performance testing.

## ✨ Features

- **Modern UI**: A clean and responsive user interface built with Vue.js.
- **Network Tools**: A suite of tools including Ping, iPerf3, and Speedtest.
- **Real-time Traffic**: Live monitoring of network interface traffic.
- **Interactive Shell**: A fake shell environment for basic diagnostics.
- **Easy Deployment**: Ships as a single Docker container.
- **Customizable**: Configure features and server details via environment variables.

## 🚀 Quick Start (Docker Compose)

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
    docker compose up -d
    ```

The application will be accessible at `http://<your-server-ip>`. The default port is 3000, which can be changed via the `HTTP_PORT` environment variable.

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

This project is licensed under the MIT License.
