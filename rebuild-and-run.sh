#!/bin/bash

# MiniCal 重新编译和启动脚本
# 用途：快速编译项目并重启应用，方便开发测试
# 使用: ./rebuild-and-run.sh [--clean]

set -e  # 遇到错误立即退出

# 获取脚本所在目录作为项目目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
APP_NAME="MiniCal"
SCHEME="MiniCal"
CONFIGURATION="Debug"

# 检查是否需要清理构建
CLEAN_BUILD=false
if [ "$1" == "--clean" ]; then
    CLEAN_BUILD=true
fi

echo "================================"
echo "MiniCal 重新编译和启动"
echo "================================"
echo "📁 项目目录: $PROJECT_DIR"
echo "🔧 配置: $CONFIGURATION"
if [ "$CLEAN_BUILD" == true ]; then
    echo "🧹 清理模式: 是"
fi
echo ""

# 1. 进入项目目录
cd "$PROJECT_DIR"

# 2. 清理旧的本地build目录（避免混淆）
if [ -d "$PROJECT_DIR/build" ]; then
    echo "🗑️  删除旧的本地build目录..."
    rm -rf "$PROJECT_DIR/build"
fi

if [ -d "$PROJECT_DIR/.build" ]; then
    echo "🗑️  删除旧的.build目录..."
    rm -rf "$PROJECT_DIR/.build"
fi

# 3. 清理Xcode构建缓存（如果指定了--clean）
if [ "$CLEAN_BUILD" == true ]; then
    echo "🧹 清理Xcode构建缓存..."
    xcodebuild clean -scheme "$SCHEME" -configuration "$CONFIGURATION"
    echo ""
fi

# 4. 编译项目（使用Xcode默认的DerivedData路径，与Xcode保持一致）
echo "🔨 开始编译项目..."
xcodebuild -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    build

if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

# 5. 获取Xcode的实际构建输出路径（使用CONFIGURATION_BUILD_DIR）
echo "🔍 获取构建路径..."
CONFIGURATION_BUILD_DIR=$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null | grep "CONFIGURATION_BUILD_DIR =" | head -1 | sed 's/.*= //')

if [ -z "$CONFIGURATION_BUILD_DIR" ]; then
    echo "❌ 无法获取构建目录"
    exit 1
fi

# 6. 构建应用完整路径
APP_PATH="${CONFIGURATION_BUILD_DIR}/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 找不到应用: $APP_PATH"
    echo ""
    echo "🔍 尝试查找应用..."
    find ~/Library/Developer/Xcode/DerivedData -name "$APP_NAME.app" -type d 2>/dev/null | head -3
    exit 1
fi

echo "📦 应用路径: $APP_PATH"
echo ""

# 7. 杀死正在运行的应用进程
echo "🔄 停止现有的 $APP_NAME 进程..."
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5  # 等待进程完全退出

# 8. 启动新编译的应用
echo "🚀 启动应用..."
open "$APP_PATH"

echo ""
echo "✅ 完成！应用已启动"
echo "================================"
echo ""
echo "💡 提示:"
echo "   - 应用位置: $APP_PATH"
echo "   - 清理构建: ./rebuild-and-run.sh --clean"
echo "   - 查看日志: log stream --predicate 'subsystem == \"com.aireels.MiniCal\"' --level debug"
echo ""
