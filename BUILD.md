# MiniCal 构建指南

## 快速开始

### 使用脚本编译并运行

```bash
# 常规编译并启动
./rebuild-and-run.sh

# 清理构建缓存后重新编译
./rebuild-and-run.sh --clean
```

### 使用Xcode

1. 打开 `MiniCal.xcodeproj`
2. 选择 Scheme: `MiniCal`
3. ⌘R 运行或 ⌘B 编译

## 构建输出

脚本和Xcode使用**相同的构建输出路径**:

```
~/Library/Developer/Xcode/DerivedData/MiniCal-[hash]/Build/Products/Debug/MiniCal.app
```

## 调试

### 查看应用日志

```bash
log stream --predicate 'subsystem == "com.aireels.MiniCal"' --level debug
```

### 查看特定类别日志

```bash
# 仅查看日历相关日志
log stream --predicate 'subsystem == "com.aireels.MiniCal" AND category == "Calendar"' --level debug

# 仅查看UI相关日志
log stream --predicate 'subsystem == "com.aireels.MiniCal" AND category == "UI"' --level debug
```

## 权限测试

### 重置日历权限

```bash
tccutil reset Calendar com.aireels.MiniCal
```

### 清理应用数据

```bash
# 删除偏好设置
rm ~/Library/Preferences/com.aireels.MiniCal.plist

# 删除应用支持文件
rm -rf ~/Library/Application\ Support/MiniCal

# 删除缓存
rm -rf ~/Library/Caches/com.aireels.MiniCal
```

## 故障排除

### 脚本编译结果与Xcode不一致

✅ **已修复**: 脚本现在使用与Xcode相同的DerivedData路径

### 旧的build目录导致混淆

脚本会自动清理项目根目录下的旧`build`和`.build`目录

### 找不到应用

如果脚本找不到应用,会自动搜索并显示可能的位置:

```bash
find ~/Library/Developer/Xcode/DerivedData -name "MiniCal.app" -type d
```

## 依赖

- Xcode 16+
- macOS 15+ (部署目标: macOS 14.0)
- Swift Package: KeyboardShortcuts

## 构建配置

- **Debug**: 包含调试符号,日志级别debug
- **Release**: 优化性能,日志级别warning

## 注意事项

⚠️ **不要手动修改DerivedData**: Xcode自动管理构建输出,手动修改可能导致编译问题

⚠️ **确保Bundle ID正确**: `com.aireels.MiniCal` - 用于权限管理和应用识别
