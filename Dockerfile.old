FROM node:lts-alpine AS buildernodejsache
ADD ui/package.json /app/package.json
WORKDIR /app
RUN npm i

FROM node:lts-alpine AS buildernodejs
ADD ui /app
WORKDIR /app
COPY --from=buildernodejsache /app/node_modules /app/node_modules
RUN npm run build \
    && chmod -R 644 /app/dist

FROM alpine:3 AS buildergolang
ADD backend /app
WORKDIR /app
COPY --from=buildernodejs /app/dist /app/embed/ui
RUN apk add --no-cache go 

RUN go build -o /usr/local/bin/als && \
    chmod +x /usr/local/bin/als

FROM alpine:3 AS builderenv
WORKDIR /app
ADD scripts /app
RUN sh /app/install-software.sh
RUN sh /app/install-speedtest.sh
RUN apk add --no-cache \
    iperf iperf3 \
    mtr \
    traceroute \
    iputils
RUN rm -rf /app

FROM alpine:3
COPY --from=builderenv / /
COPY --from=buildergolang /usr/local/bin/als /bin/als

CMD ["/bin/als"]