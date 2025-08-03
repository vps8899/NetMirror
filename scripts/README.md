# NetMirror Deployment Scripts

This directory contains automated deployment scripts for NetMirror Looking Glass servers.

## 🚀 Quick Start

### One-Line Master Node Deployment

Deploy a master node with auto-generated API key:

**Basic deployment (uses auto-detected IP):**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "Master Node" \
  --location "Your Location" \
  --port 3000 \
  --non-interactive
```

**With custom domain/URL (recommended for production):**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "Master Node" \
  --location "Tokyo, JP" \
  --port 3000 \
  --node-url "https://lg-master.example.com" \
  --non-interactive
```

### One-Line Child Node Deployment

Deploy child nodes that automatically register with the master:

**Basic deployment (uses auto-detected IP):**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "Child Node Name" \
  --location "Child Location" \
  --port 3001 \
  --master "http://your-master-ip:3000" \
  --admin-key "your-api-key" \
  --non-interactive
```

**With custom domain/URL (recommended for production):**
```bash
curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \
  --name "Singapore Node" \
  --location "Singapore, SG" \
  --port 3001 \
  --master "http://your-master-ip:3000" \
  --admin-key "your-api-key" \
  --node-url "https://lg-singapore.example.com" \
  --non-interactive
```

> **💡 Important**: Use `--node-url` when you have a custom domain, reverse proxy, CDN, or any setup where the public-facing URL differs from `http://server-ip:port`. This URL is what gets registered in the master node and shown to users.

## 📋 Available Scripts

### `netmirror-deploy.sh`

**Main deployment script supporting both master and child node deployment.**

#### Features
- 🎛️ **Dual Mode**: Automatically detects master vs child node deployment
- 🔑 **API Key Management**: Auto-generation for master nodes, validation for child nodes
- 🐳 **Docker Integration**: Automatic Docker installation and container management
- 📡 **Auto Registration**: Child nodes automatically register with master node
- 🔧 **Configuration Management**: Downloads and processes environment templates
- ✅ **Validation**: Connection and permission verification before deployment

#### Usage

**Interactive Mode:**
```bash
./netmirror-deploy.sh
```

**Non-Interactive Mode:**
```bash
./netmirror-deploy.sh --name "Node Name" --location "Location" [OPTIONS]
```

#### Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `--name` | Node display name | Yes | - |
| `--location` | Node location description | Yes | - |
| `--port` | HTTP port | No | 3000 |
| `--dir` | Deployment directory | No | `./netmirror-node` |
| `--master` | Master node URL (for child nodes) | No | - |
| `--admin-key` | Admin API key | No | Auto-generated for master |
| `--node-url` | Custom node URL for registration | No | `http://localhost:PORT` |
| `--non-interactive` | Skip all prompts | No | false |

#### Examples

**Deploy Master Node:**
```bash
# Interactive
./netmirror-deploy.sh

# Non-interactive with auto-generated API key
./netmirror-deploy.sh \
  --name "Tokyo Master" \
  --location "Tokyo, JP" \
  --port 3000 \
  --non-interactive

# With custom domain (production setup)
./netmirror-deploy.sh \
  --name "Tokyo Master" \
  --location "Tokyo, JP" \
  --port 3000 \
  --node-url "https://lg-master.example.com" \
  --non-interactive

# With custom API key
./netmirror-deploy.sh \
  --name "Tokyo Master" \
  --location "Tokyo, JP" \
  --admin-key "your-custom-key" \
  --non-interactive
```

**Deploy Child Node:**
```bash
# Interactive (will prompt for master URL and API key)
./netmirror-deploy.sh \
  --name "Singapore Node" \
  --location "Singapore, SG"

# Non-interactive with master registration
./netmirror-deploy.sh \
  --name "Singapore Node" \
  --location "Singapore, SG" \
  --port 3001 \
  --master "http://master.example.com:3000" \
  --admin-key "master-api-key" \
  --non-interactive

# With custom domain (production setup)
./netmirror-deploy.sh \
  --name "Singapore Node" \
  --location "Singapore, SG" \
  --port 3001 \
  --master "http://master.example.com:3000" \
  --admin-key "master-api-key" \
  --node-url "https://lg-singapore.example.com" \
  --non-interactive

# Custom deployment directory
./netmirror-deploy.sh \
  --name "Frankfurt Node" \
  --location "Frankfurt, DE" \
  --dir "/opt/netmirror" \
  --master "http://master.example.com:3000" \
  --admin-key "master-api-key" \
  --non-interactive
```

## 🏗️ Deployment Process

### Master Node Deployment
1. **Docker Setup**: Install Docker if not present
2. **Environment Configuration**: Download and process `.env.example` template
3. **API Key Generation**: Create secure random API key
4. **Container Deployment**: Start NetMirror container with host networking
5. **Self Registration**: Add master node to its own API database
6. **Child Deployment Commands**: Display ready-to-use commands for child nodes

### Child Node Deployment
1. **Docker Setup**: Install Docker if not present
2. **Master Verification**: Test connection to master node
3. **API Key Validation**: Verify admin permissions
4. **Environment Configuration**: Configure environment with master node details
5. **Container Deployment**: Start NetMirror container
6. **Auto Registration**: Register with master node via API

## 🌐 Custom URL Configuration

### When to Use `--node-url`

The `--node-url` parameter is crucial for production deployments where the public-facing URL differs from the internal container URL. Use it when you have:

**Reverse Proxy Setup:**
```bash
# Behind Nginx/Apache/Caddy
--node-url "https://lg-singapore.example.com"
```

**CDN Integration:**
```bash
# CloudFlare/AWS CloudFront
--node-url "https://lg-fast.example.com"
```

**Custom Port with Domain:**
```bash
# Custom port with domain
--node-url "https://example.com:8443"
```

**Load Balancer:**
```bash
# Behind load balancer
--node-url "https://lg.example.com"
```

### What Happens Without `--node-url`

If you don't specify `--node-url`, the script will use:
- `http://localhost:PORT` - for child nodes
- `http://external-ip:PORT` - for master nodes (auto-detected)

This works for basic setups but **won't work** if users need to access your node through a different URL.

### Important Notes

- ⚠️ **The node-url is what gets registered** in the master node's database
- 🌐 **This URL is shown to users** in the node selection interface  
- 🔒 **Use HTTPS in production** for security and better user experience
- 🎯 **Must be accessible** from the internet for other nodes to connect
- 📝 **Can be changed later** through the admin panel if needed

### Example Production Setup

```bash
# 1. Deploy behind reverse proxy (internal port 3001)
./netmirror-deploy.sh \
  --name "Singapore Node" \
  --location "Singapore, SG" \
  --port 3001 \
  --master "https://master.example.com" \
  --admin-key "your-api-key" \
  --node-url "https://lg-singapore.example.com" \
  --non-interactive

# 2. Configure your reverse proxy to forward
# https://lg-singapore.example.com -> http://localhost:3001
```

## 🔧 Configuration

### Environment Variables

The script automatically generates `.env` files with the following key configurations:

**Master Node:**
```env
# Basic Configuration
HTTP_PORT=3000
LOCATION=Tokyo, JP
LG_CURRENT_NAME=Tokyo Master
LG_CURRENT_LOCATION=Tokyo, JP
LG_CURRENT_URL=http://localhost:3000

# Admin API Configuration
ADMIN_API_KEY=generated-secure-api-key

# Clear legacy nodes to prevent auto-migration
LG_NODES=
```

**Child Node:**
```env
# Basic Configuration
HTTP_PORT=3001
LOCATION=Singapore, SG
LG_CURRENT_NAME=Singapore Node
LG_CURRENT_LOCATION=Singapore, SG
LG_CURRENT_URL=http://localhost:3001

# Master Node Integration
MASTER_NODE_URL=http://master.example.com:3000
NODE_AUTO_REGISTER=true

# Admin API Configuration (for registration)
ADMIN_API_KEY=master-api-key
```

### Docker Configuration

The script creates a `docker-compose.yml` file using:
- **Image**: `soyorins/netmirror:latest`
- **Network Mode**: `host` (for optimal performance)
- **Volumes**: `./data:/data` for persistent storage
- **Health Check**: HTTP endpoint monitoring
- **Logging**: JSON file driver with rotation

## 🛠️ Troubleshooting

### Common Issues

**1. API Key Verification Failed**
- Ensure the master node is running and accessible
- Check if the API key is correct (no extra whitespace/newlines)
- Verify network connectivity between nodes

**2. Container Failed to Start**
- Check Docker installation: `docker --version`
- Verify port availability: `netstat -tlnp | grep :3000`
- Review container logs: `docker logs netmirror-node-3000`

**3. Node Registration Failed**
- Confirm master node is running and API is accessible
- Check API key permissions
- Verify network connectivity and firewall settings

**4. Permission Denied (Docker)**
- Add user to docker group: `sudo usermod -aG docker $USER`
- Logout and login again, or run: `newgrp docker`
- Alternatively, use `--allow-root` flag if running as root

### Debugging

**View Container Logs:**
```bash
# Using docker-compose
docker-compose logs -f

# Using docker directly
docker logs -f netmirror-node-3000
```

**Check Container Status:**
```bash
docker-compose ps
# or
docker ps | grep netmirror
```

**Test API Connectivity:**
```bash
# Test master node API
curl "http://master-ip:3000/api/admin/nodes/add?api_key=your-key"

# Should return HTTP 400 (missing parameters) if API key is valid
```

## 🔒 Security Considerations

- **API Keys**: Auto-generated keys use cryptographically secure random generation
- **Network Access**: Uses host networking for optimal performance
- **Input Validation**: All user inputs are validated and sanitized
- **Isolation**: Each deployment uses separate data directories and container names

## 🤝 Contributing

When modifying deployment scripts:

1. Test both master and child node deployments
2. Verify API key generation and validation
3. Test both interactive and non-interactive modes
4. Update documentation for any new parameters or features
5. Test error handling and edge cases

## 📝 License

Part of the NetMirror project - see main project license for details.