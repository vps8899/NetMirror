# 优化的多阶段构建 - 基于原有逻辑改进
# 前端依赖缓存层
FROM node:lts-alpine AS frontend-deps-cache
ADD ui/package.json /app/package.json
WORKDIR /app
RUN npm install

# 前端构建层
FROM node:lts-alpine AS frontend-builder
ADD ui /app
WORKDIR /app
COPY --from=frontend-deps-cache /app/node_modules /app/node_modules
RUN npm run build && chmod -R 644 /app/dist

# Go依赖缓存层
FROM alpine:3 AS go-deps-cache
RUN apk add --no-cache go git ca-certificates
WORKDIR /app
ADD backend/go.mod backend/go.sum ./
RUN go mod download

# Go构建层（嵌入前端文件）
FROM go-deps-cache AS go-builder
ADD backend /app
COPY --from=frontend-builder /app/dist /app/embed/ui
RUN go build -o /usr/local/bin/als && chmod +x /usr/local/bin/als

# 系统工具安装层（可复用）
FROM alpine:3 AS system-tools
WORKDIR /app
ADD scripts /app
RUN sh /app/install-software.sh && \
    sh /app/install-speedtest.sh && \
    apk add --no-cache \
        iperf iperf3 \
        mtr \
        traceroute \
        iputils && \
    rm -rf /app

# 最终运行镜像
FROM alpine:3
COPY --from=system-tools / /
COPY --from=go-builder /usr/local/bin/als /bin/als

CMD ["/bin/als"]