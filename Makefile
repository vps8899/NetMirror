.PHONY: help build dev clean test lint docker-build docker-run version check-deps

# 检查 Docker 和 Docker Compose
check-deps:
	@command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Aborting." >&2; exit 1; }

# 默认目标
help: ## 显示帮助信息
	@echo "ALS - Another Looking-glass Server"
	@echo "可用的命令:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 开发相关
dev: check-deps ## 启动开发环境
	docker-compose up --build

dev-backend: ## 仅启动后端开发服务器
	cd backend && go run main.go

dev-frontend: ## 仅启动前端开发服务器
	cd ui && npm run dev

# 构建相关
build: check-deps ## 构建版本
	docker-compose build

build-frontend: ## 构建前端
	cd ui && npm run build

build-backend: ## 构建后端
	cd backend && go build -o als

# Docker 相关
docker-build: check-deps ## 构建 Docker 镜像
	docker build -t als:latest .

docker-run: check-deps ## 运行 Docker 容器
	docker-compose up -d

docker-logs: ## 查看 Docker 日志
	docker-compose logs -f

docker-stop: ## 停止 Docker 容器
	docker-compose down

# 测试和质量检查
test: ## 运行测试
	@echo "Running backend tests..."
	cd backend && go test ./...
	@echo "Running frontend tests..."
	cd ui && npm test

lint: ## 运行代码检查
	@echo "Running backend linting..."
	cd backend && go vet ./...
	@echo "Running frontend linting..."
	cd ui && npm run lint:check

lint-fix: ## 修复代码格式问题
	cd ui && npm run lint

# 清理
clean: ## 清理构建产物
	@echo "Cleaning build artifacts..."
	rm -rf ui/dist
	rm -rf backend/als
	rm -rf backend/embed/ui
	rm -rf tmp/
	docker system prune -f

clean-all: clean ## 清理所有文件包括依赖
	@echo "Cleaning all files including dependencies..."
	rm -rf ui/node_modules
	rm -rf backend/vendor
	docker system prune -af

# 部署相关
deploy: check-deps ## 部署
	docker-compose up -d --build

# 初始化
init: ## 初始化项目
	@echo "Initializing project..."
	git submodule update --init --recursive
	cd ui && npm install
	cd backend && go mod download
	@echo "Project initialized successfully!"

# 更新依赖
update-deps: ## 更新依赖
	@echo "Updating dependencies..."
	cd ui && npm update
	cd backend && go get -u ./... && go mod tidy
	@echo "Dependencies updated!"

# 版本管理
version: ## 显示版本信息
	@echo "=== ALS Version Information ==="
	@echo "ALS Version: 2.0.0"
	@echo "Go Version: $$(go version 2>/dev/null || echo 'Go not found')"
	@echo "Node Version: $$(node --version 2>/dev/null || echo 'Node not found')"
	@echo "NPM Version: $$(npm --version 2>/dev/null || echo 'NPM not found')"
	@echo "Docker Version: $$(docker --version 2>/dev/null || echo 'Docker not found')"
	@echo "Docker Compose Version: $$(docker-compose --version 2>/dev/null || echo 'Docker Compose not found')"

# 状态检查
status: ## 检查服务状态
	@echo "=== Service Status ==="
	docker-compose ps 2>/dev/null || echo "No services running"

# 快速启动
quick-start: init build docker-run ## 快速启动（初始化+构建+运行）
	@echo "ALS is starting up..."
	@echo "Please wait for the services to be ready..."
	@sleep 10
	@echo "ALS should now be available at http://localhost"
