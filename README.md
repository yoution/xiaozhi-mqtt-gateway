# MQTT+UDP 到 WebSocket 桥接服务

## 项目概述

本项目是基于虾哥开源的 [MQTT+UDP 到 WebSocket 桥接服务](https://github.com/78/xiaozhi-mqtt-gateway)，进行了修改，以适应[xiaozhi-esp32-server](https://github.com/xinnan-tech/xiaozhi-esp32-server)。

## 部署使用

### Docker 部署（推荐）

#### 本地部署快速开始

1. **获取本地 IP 地址**：
```bash
# Mac/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig

# 记下你的局域网 IP，例如：192.168.1.100
```

2. **准备配置文件**：
```bash
# 复制配置文件示例
cp config/mqtt.json.example config/mqtt.json

# 编辑配置文件，填写你的 WebSocket 服务器地址
# 本地部署示例：ws://192.168.1.100:8000/xiaozhi/v1/?from=mqtt_gateway
vim config/mqtt.json
```

3. **创建环境变量文件** `.env`：
```bash
# 复制环境变量示例
cp .env.example .env

# 编辑 .env 文件
vim .env
```

配置示例：
```bash
# 【本地部署】填写你的局域网 IP
PUBLIC_IP=192.168.1.100

# 【必须配置】设置一个强密码
MQTT_SIGNATURE_KEY=YourStrongKey123

# 可选配置（有默认值）
MQTT_PORT=1883
UDP_PORT=8884
API_PORT=8007
```

4. **使用 Docker Compose 启动**：
```bash
# 拉取并启动服务
docker compose up -d

# 查看日志（会显示当日的 API 临时密钥）
docker compose logs -f

# 停止服务
docker compose down
```

#### 使用 Docker 命令启动（本地部署）

```bash
docker run -d \
  --name xiaozhi-mqtt-gateway \
  -p 1883:1883 \
  -p 8884:8884/udp \
  -p 8007:8007 \
  -e PUBLIC_IP=192.168.1.100 \
  -e MQTT_SIGNATURE_KEY=YourStrongKey123 \
  -v $(pwd)/config/mqtt.json:/app/config/mqtt.json:ro \
  --restart unless-stopped \
  ghcr.io/yoution/xiaozhi-mqtt-gateway:latest
```

#### ESP32 设备配置

在本地部署模式下，ESP32 设备需要连接到你的局域网 MQTT 服务器：

- **MQTT 服务器地址**：`192.168.1.100`（你的局域网 IP）
- **MQTT 端口**：`1883`
- **确保设备和服务器在同一局域网**

**注意**：
- 本地部署不需要开放公网端口，只要设备和服务器在同一局域网即可
- `MQTT_SIGNATURE_KEY` 必须至少8位，包含大小写字母，不能包含弱密码如 `test`、`1234` 等
- 确保 `config/mqtt.json` 配置正确的 WebSocket 服务器地址
- 如果 WebSocket 服务器也在本地，使用局域网 IP 访问（如 `ws://192.168.1.100:8000`）

### 传统部署方式

部署使用请[参考这里](https://github.com/xinnan-tech/xiaozhi-esp32-server/blob/main/docs/mqtt-gateway-integration.md)。

## 设备管理接口说明

### 接口认证

API请求需要在请求头中包含有效的`Authorization: Bearer xxx`令牌，令牌生成规则如下：

1. 获取当前日期，格式为`yyyy-MM-dd`（例如：2025-09-15）
2. 获取.env文件中配置的`MQTT_SIGNATURE_KEY`值
3. 将日期字符串与MQTT_SIGNATURE_KEY连接（格式：`日期+MQTT_SIGNATURE_KEY`）
4. 对连接后的字符串进行SHA256哈希计算
5. 哈希结果即为当日有效的Bearer令牌

**注意**：服务启动时会自动计算并打印当日的临时密钥，方便测试使用。


### 接口1 设备指令下发API，支持MCP指令并返回设备响应
``` shell
curl --location --request POST 'http://localhost:8007/api/commands/lichuang-dev@@@a0_85_e3_f4_49_34@@@aeebef32-f0ef-4bce-9d8a-894d91bc6932' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer your_daily_token' \
--data-raw '{"type": "mcp", "payload": {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "self.get_device_status", "arguments": {}}}}'
```

### 接口2 设备状态查询API，支持查询设备是否在线

``` shell
curl --location --request POST 'http://localhost:8007/api/devices/status' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer your_daily_token' \
--data-raw '{
    "deviceIds": [
        "lichuang-dev@@@a0_85_e3_f4_49_34@@@aeebef32-f0ef-4bce-9d8a-894d91bc6932"
    ]
}'
```