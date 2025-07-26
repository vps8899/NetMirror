# 多阶段构建 Dockerfile
FROM node:lts-alpine as ui-builder

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY ui/package*.json ./

# 安装依赖
RUN npm install --no-audit --no-fund

# 复制源代码
COPY ui/ ./

# 构建前端
RUN npm run build

# Go 构建阶段
FROM golang:1.24-alpine as go-builder

# 安装构建依赖
RUN apk add --no-cache git ca-certificates tzdata

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件和 air 配置
COPY backend/go.mod backend/go.sum ./.air.toml ./

# 下载依赖
RUN go mod download

# 复制后端源代码
COPY backend/ ./

# 复制前端构建产物
COPY --from=ui-builder /app/dist ./embed/ui/

# 构建 Go 应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o als .

# 软件安装阶段
FROM alpine:3.18 as software-installer

# 安装基础工具
RUN apk add --no-cache \
   bash \
   wget \
   curl \
   ca-certificates \
   tzdata

# 复制安装脚本
COPY scripts/ /tmp/scripts/

# 运行软件安装脚本
RUN cd /tmp && bash scripts/install-software.sh

# 最终运行阶段
FROM alpine:3.18

LABEL maintainer="ALS Team <als@example.com>"
LABEL description="Another Looking-glass Server - Network diagnostic tools"
LABEL version="2.0.0"

# 安装运行时依赖
RUN apk add --no-cache \
   ca-certificates \
   tzdata \
   bash

# 从软件安装阶段复制已安装的工具
COPY --from=software-installer /usr/local/bin/ /usr/local/bin/
COPY --from=software-installer /usr/bin/ /usr/bin/
COPY --from=software-installer /bin/ /bin/

# 从构建阶段复制应用程序
COPY --from=go-builder /app/als /bin/als

# 创建非 root 用户
RUN addgroup -g 1001 -S als && \
   adduser -u 1001 -S als -G als

# 创建数据目录
RUN mkdir -p /data && chown als:als /data

# 设置用户
USER als

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
   CMD wget --quiet --tries=1 --spider http://localhost:${HTTP_PORT:-80}/ || exit 1

# 启动命令
CMD ["/bin/als"]

# 开发阶段（可选）
FROM go-builder as development

# 安装开发工具
RUN apk add --no-cache \
   git \
   make \
   gcc \
   musl-dev

# 安装 air 用于热重载
RUN go install github.com/air-verse/air@latest

# .air.toml 已经在 go-builder 阶段复制了，这里直接继承

# 暴露端口
EXPOSE 8080

# 开发模式启动命令
CMD ["air", "-c", ".air.toml"]
