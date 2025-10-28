#!/bin/bash

# MiniCal 重新编译和启动脚本
# 用途：快速编译项目并重启应用，方便开发测试

set -e  # 遇到错误立即退出

PROJECT_DIR="/Users/lixingmao/Documents/Developer/WebSpace/mini-cal/MiniCal"
APP_NAME="MiniCal"
SCHEME="MiniCal"

echo "================================"
echo "MiniCal 重新编译和启动"
echo "================================"

# 1. 进入项目目录
cd "$PROJECT_DIR"

# 2. 清理之前的构建（可选，如需要完全重建可取消注释）
# echo "🧹 清理之前的构建..."
# xcodebuild clean -scheme "$SCHEME" -configuration Debug

# 3. 编译项目
echo "🔨 开始编译项目..."
xcodebuild -scheme "$SCHEME" \
    -configuration Debug \
    -derivedDataPath build \
    build

if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

# 4. 查找构建的应用路径
APP_PATH="$PROJECT_DIR/build/Build/Products/Debug/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 找不到应用: $APP_PATH"
    exit 1
fi

# 5. 杀死正在运行的应用进程
echo "🔄 停止现有的 $APP_NAME 进程..."
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5  # 等待进程完全退出

# 6. 启动新编译的应用
echo "🚀 启动应用..."
open "$APP_PATH"

echo "✅ 完成！应用已启动"
echo "================================"
