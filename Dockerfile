# 使用官方 Node.js 18 LTS 作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json（如果存在）
COPY package*.json ./

# 安装项目依赖
RUN npm install --production

# 复制项目文件
COPY . .

# 复制配置文件示例（如果 config/mqtt.json 不存在，则使用示例文件）
RUN if [ ! -f config/mqtt.json ]; then \
    cp config/mqtt.json.example config/mqtt.json; \
    fi

# 暴露端口
# 1883: MQTT TCP 端口
# 8884: UDP 端口
# 8007: 管理 API 端口
EXPOSE 1883 8884/udp 8007

# 设置默认环境变量
ENV PUBLIC_IP=mqtt.xiaozhi.me \
    MQTT_PORT=1883 \
    UDP_PORT=8884 \
    API_PORT=8007

# 启动应用
CMD ["node", "app.js"]
