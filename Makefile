.PHONY: help build dev clean test lint docker-build docker-run docker-dev

# 默认目标
help: ## 显示帮助信息
	@echo "可用的命令:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 开发相关
dev: ## 启动开发环境
	docker-compose -f docker-compose.dev.yml up --build

dev-backend: ## 仅启动后端开发服务器
	cd backend && go run main.go

dev-frontend: ## 仅启动前端开发服务器
	cd ui && npm run dev

# 构建相关
build: ## 构建生产版本
	docker-compose build

build-frontend: ## 构建前端
	cd ui && npm run build

build-backend: ## 构建后端
	cd backend && go build -o als

# Docker 相关
docker-build: ## 构建 Docker 镜像
	docker build -t als:latest .

docker-run: ## 运行 Docker 容器
	docker-compose up -d

docker-dev: ## 运行开发 Docker 环境
	docker-compose -f docker-compose.dev.yml up --build

docker-logs: ## 查看 Docker 日志
	docker-compose logs -f

docker-stop: ## 停止 Docker 容器
	docker-compose down

# 测试和质量检查
test: ## 运行测试
	cd backend && go test ./...
	cd ui && npm test

lint: ## 运行代码检查
	cd backend && go vet ./...
	cd ui && npm run lint

lint-fix: ## 修复代码格式问题
	cd ui && npm run lint:fix

# 清理
clean: ## 清理构建产物
	rm -rf ui/dist
	rm -rf backend/als
	rm -rf backend/embed/ui
	docker system prune -f

clean-all: clean ## 清理所有文件包括依赖
	rm -rf ui/node_modules
	rm -rf backend/vendor
	docker system prune -af

# 部署相关
deploy: ## 部署到生产环境
	docker-compose -f docker-compose.yml up -d --build

deploy-staging: ## 部署到测试环境
	docker-compose -f docker-compose.staging.yml up -d --build

# 初始化
init: ## 初始化项目
	git submodule update --init --recursive
	cd ui && npm install
	cd backend && go mod download

# 更新依赖
update-deps: ## 更新依赖
	cd ui && npm update
	cd backend && go get -u ./...
	go mod tidy

# 版本管理
version: ## 显示版本信息
	@echo "ALS Version: 2.0.0"
	@echo "Go Version: $(shell go version)"
	@echo "Node Version: $(shell node --version)"
	@echo "Docker Version: $(shell docker --version)"
