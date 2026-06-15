# FMO-server-authrozier-service Docker 镜像

本镜像基于`BG5ESN/fmo-server-authrozier-service`项目构建,采用Alpine Linux作为基础镜像。

## 1. 镜像地址


拉取镜像：

```bash
docker pull ghcr.io/xjx00/fmo-sas:latest
```

## 2. 容器端口

容器内默认监听端口：

```text
8080
```

默认 HTTP 接口：

```text
/auth
```

如果将容器端口映射到宿主机 `8080`，访问地址为：

```text
http://宿主机IP:8080/auth
```

## 3. 数据目录

容器内配置目录：

```text
/home/sas/.sas
```

建议挂载为 Docker volume，避免容器重建后配置丢失：

```bash
-v fmo-sas-data:/home/sas/.sas
```

## 4. 环境变量

该镜像通过环境变量配置 SAS 服务。

| 环境变量 | 必填 | 默认值 | 说明 |
|---|---:|---|---|
| `SAS_SERVER_UID` | 是 | 无 | 服务器 UID |
| `SAS_SERVER_CALLSIGN` | 是 | 无 | 服务器呼号 |
| `SAS_MQTT_HOST` | 是 | 无 | 服务所需的主机地址配置 |
| `SAS_MQTT_PORT` | 建议 | 无 | 服务所需的端口配置 |
| `SAS_MQTT_USERNAME` | 否 | 无 | 用户名，可选 |
| `SAS_MQTT_PASSWORD` | 否 | 无 | 密码，可选 |
| `SAS_CERT_FINGERPRINT` | 是 | 无 | 证书指纹 |
| `SAS_HTTP_ADDR` | 否 | `0.0.0.0` | HTTP 服务监听地址 |
| `SAS_HTTP_PORT` | 否 | `8080` | HTTP 服务监听端口 |

## 5. 使用 Docker 运行

### 5.1 带用户名和密码的运行示例

```bash
docker run -d \
  --name fmo-sas \
  --restart unless-stopped \
  -p 8080:8080 \
  -v fmo-sas-data:/home/sas/.sas \
  -e SAS_SERVER_UID=12345 \
  -e SAS_SERVER_CALLSIGN=BI1QCF \
  -e SAS_MQTT_HOST=example.com \
  -e SAS_MQTT_PORT=1883 \
  -e SAS_MQTT_USERNAME=your_username \
  -e SAS_MQTT_PASSWORD=your_password \
  -e SAS_CERT_FINGERPRINT=your_cert_fingerprint \
  -e SAS_HTTP_ADDR=0.0.0.0 \
  -e SAS_HTTP_PORT=8080 \
  ghcr.io/example/fmo-sas:latest
```

## 6. 使用 Docker Compose 运行

创建 `docker-compose.yml`：

```yaml
services:
  fmo-sas:
    image: ghcr.io/example/fmo-sas:latest
    container_name: fmo-sas
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - fmo-sas-data:/home/sas/.sas
    environment:
      SAS_SERVER_UID: "12345"
      SAS_SERVER_CALLSIGN: "BI1QCF"
      SAS_MQTT_HOST: "example.com"
      SAS_MQTT_PORT: "1883"
      SAS_MQTT_USERNAME: ""
      SAS_MQTT_PASSWORD: ""
      SAS_CERT_FINGERPRINT: "your_cert_fingerprint"
      SAS_HTTP_ADDR: "0.0.0.0"
      SAS_HTTP_PORT: "8080"

volumes:
  fmo-sas-data:
```
`example`目录中提供了一个集成了emqx的`docker-compose.yml`，修改内部相应参数的占位符后即可启动。

启动：

```bash
docker compose up -d
```

查看日志：

```bash
docker compose logs -f
```

停止：

```bash
docker compose down
```

停止并删除数据卷：

```bash
docker compose down -v
```

注意：删除数据卷会清除 `/home/sas/.sas` 中保存的配置。

## 7. 验证服务

容器启动后，可以测试 `/auth` 接口：

```bash
curl -i -X POST http://127.0.0.1:8080/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"BI1OCF","password":"test"}'
```

如果服务正常运行但认证未通过，可能返回：

```json
{"result":"deny"}
```

这通常表示 HTTP 服务已经可以正常响应。

查看容器日志：

```bash
docker logs -f fmo-sas
```

查看容器状态：

```bash
docker ps
```

## 8. 不暴露 HTTP 端口的部署方式

如果该服务只需要被同一 Docker 网络内的其他容器访问，可以不映射宿主机端口。

示例：

```yaml
services:
  fmo-sas:
    image: ghcr.io/example/fmo-sas:latest
    container_name: fmo-sas
    restart: unless-stopped
    expose:
      - "8080"
    volumes:
      - fmo-sas-data:/home/sas/.sas
    environment:
      SAS_SERVER_UID: "12345"
      SAS_SERVER_CALLSIGN: "BG5ESN"
      SAS_MQTT_HOST: "example.com"
      SAS_MQTT_PORT: "1883"
      SAS_CERT_FINGERPRINT: "your_cert_fingerprint"

volumes:
  fmo-sas-data:
```

这种方式下，宿主机无法直接通过 `127.0.0.1:8080` 访问服务，但同一 Compose 网络中的其他容器可以通过容器名访问：

```text
http://fmo-sas:8080/auth
```

## 9. 更新镜像

拉取最新镜像：

```bash
docker pull ghcr.io/example/fmo-sas:latest
```

如果使用 Docker Compose：

```bash
docker compose pull
docker compose up -d
```

如果使用 `docker run` 手动部署，需要先删除旧容器：

```bash
docker stop fmo-sas
docker rm fmo-sas
```

然后重新执行 `docker run` 命令。

## 10. 常用维护命令

查看容器状态：

```bash
docker ps
```

查看日志：

```bash
docker logs -f fmo-sas
```

重启容器：

```bash
docker restart fmo-sas
```

停止容器：

```bash
docker stop fmo-sas
```

删除容器：

```bash
docker rm fmo-sas
```

删除数据卷：

```bash
docker volume rm fmo-sas-data
```

## 11. 常见问题

### 11.1 容器启动后马上退出

查看日志：

```bash
docker logs fmo-sas
```

常见原因：

1. 必填环境变量未设置；
2. 证书指纹配置错误；
3. 服务所需的地址或端口配置错误；
4. 容器端口被占用；
5. 数据目录权限异常。

### 11.2 `/auth` 无法访问

检查容器是否运行：

```bash
docker ps
```

检查端口映射是否存在：

```text
0.0.0.0:8080->8080/tcp
```

如果 Compose 文件中使用的是 `expose` 而不是 `ports`，则宿主机无法直接访问，这是正常现象。

### 11.3 认证一直返回 deny

需要检查：

1. `SAS_CERT_FINGERPRINT` 是否正确；
2. `SAS_SERVER_UID` 是否正确；
3. `SAS_SERVER_CALLSIGN` 是否正确；
4. 客户端提交的 `username` 和 `password` 是否正确；
5. 容器日志中是否存在异常信息。

### 11.4 数据没有持久化

确认运行命令中包含数据卷挂载：

```bash
-v fmo-sas-data:/home/sas/.sas
```

如果没有挂载数据卷，容器删除后内部配置也会丢失。

## 12. 推荐部署方式

推荐使用 Docker Compose 部署，并挂载 `/home/sas/.sas` 数据卷。

如果 HTTP 接口不需要被公网访问，建议不要使用：

```yaml
ports:
  - "8080:8080"
```

而使用：

```yaml
expose:
  - "8080"
```

