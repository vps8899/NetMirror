# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ALS (Another Looking-glass Server) is a modern network diagnostics and performance testing tool with a Vue.js frontend and Go backend. The project uses Docker for deployment and includes real-time Server-Sent Events (SSE) for live data streaming.

## Key Commands

### Development
```bash
# Quick start with Docker Compose
make dev                    # Start development environment
docker-compose up -d        # Start containers in detached mode
docker-compose down         # Stop and remove containers

# Building
make build                  # Build Docker images
make build-frontend         # Build only frontend (cd ui && npm run build)
make build-backend          # Build only backend (cd backend && go build -o als)

# Frontend development
cd ui && npm install        # Install dependencies
cd ui && npm run dev        # Start dev server (port 3000)
cd ui && npm run lint       # Run linting and fix issues

# Backend development
cd backend && go mod download    # Install dependencies
cd backend && go run main.go     # Start backend server
cd backend && go build -o als    # Build binary

# Testing and Quality
make test                   # Run all tests
make lint                   # Run linting checks
make lint-fix              # Fix linting issues
```

### Deployment
```bash
# Production deployment
docker-compose build && docker-compose up -d

# View logs
docker-compose logs -f looking-glass

# Restart container
docker-compose restart looking-glass
```

## Architecture

### Backend (Go)
- **Entry Point**: `backend/main.go`
- **HTTP Routes**: `backend/als/route.go` - All API endpoints and static file serving
- **Core Components**:
  - `als/client/`: WebSocket client management and message queuing
  - `als/controller/`: All API controllers
    - `ping/`: Native Go ping implementation (sends "Ping" events)
    - `nettools/`: System command wrappers (mtr, traceroute - sends "MethodOutput" events)
    - `iperf3/`: iPerf3 server integration
    - `speedtest/`: Speedtest.net CLI and LibreSpeed
    - `shell/`: WebSocket-based terminal emulation
  - `embed/`: Embedded UI files for single binary distribution
  - `fakeshell/`: Limited shell environment for security

### Frontend (Vue 3)
- **Entry Point**: `ui/src/main.js`
- **Key Components**:
  - `App.vue`: Main layout with theme handling
  - `components/Utilities.vue`: Looking Glass main interface
  - `components/Utilities/`: Individual tool components (Ping, IPerf3, etc.)
  - `stores/app.js`: Pinia store managing SSE connections and API calls

### Real-time Communication
- **SSE (Server-Sent Events)**: Used for real-time output from network tools
  - Different tools send different event types:
    - `ping` sends `"Ping"` events with packet data
    - `ping6`, `mtr`, `traceroute` send `"MethodOutput"` events with output/finished fields
  - Frontend must listen to correct event type based on selected method
- **WebSocket**: Used for interactive shell terminal

### Critical Implementation Details

1. **Event Handling Differences**:
   - Ping tool uses Go library with event callbacks, sends structured packet data
   - Other network tools execute system commands and stream output
   - Frontend must handle these differently in `executeTest()` method

2. **Output Streaming**:
   - Use direct byte streaming (`pipe.Read(buf)`) not line-based scanning
   - Avoid blocking with `cmd.Wait()` in main execution path
   - Handle command completion asynchronously

3. **Docker Environment**:
   - MTR requires `--raw` flag to work without terminal
   - Official Speedtest CLI (`speedtest`) not Python version (`speedtest-cli`)
   - All tools must be installed via `scripts/install-software.sh`

4. **Theme System**:
   - Primary color theme with Tailwind CSS
   - Dark/light mode support throughout
   - Consistent use of `primary-*` color classes

## Environment Variables

Key configuration via `.env` file:
- `HTTP_PORT`: Server port (default: 80)
- `LOCATION`: Server location string
- `UTILITIES_*`: Feature flags for enabling/disabling tools
- `SPEEDTEST_FILE_LIST`: Available test file sizes

## Common Issues and Solutions

1. **Network tools not showing output**: Check if using correct event type and streaming method
2. **WebSocket terminal not connecting**: Verify session ID and WebSocket URL construction
3. **Dark mode text visibility**: Ensure all inputs use `text-gray-900 dark:text-gray-100`
4. **Docker build failures**: Use `make build` which handles frontend embedding correctly

## Development Workflow

1. Frontend changes require rebuilding: `cd ui && npm run build`
2. Backend changes: Rebuild with proper UI embedding via `make build`
3. Test in Docker environment to match production: `docker-compose up -d`
4. Check logs for errors: `docker-compose logs -f looking-glass`