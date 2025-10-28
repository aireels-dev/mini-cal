# MiniCal 应用图标设计说明

## 设计理念

**核心元素**: 日历 + 简洁

## 图标规格

根据macOS HIG要求，需要以下尺寸：

| 尺寸 | 用途 |
|------|------|
| 16x16 @1x, @2x | 菜单栏、小图标 |
| 32x32 @1x, @2x | 列表视图 |
| 128x128 @1x, @2x | 系统偏好设置 |
| 256x256 @1x, @2x | Dock图标 |
| 512x512 @1x, @2x | App Store、系统显示 |

## 设计方案

### 方案1：日历页面（推荐）

```
┌─────────────┐
│ M  T  W  T  │  <- 星期简写
│             │
│    28       │  <- 今天日期（大号）
│             │
│ ●  ●        │  <- 事件圆点（可选）
└─────────────┘
```

**颜色方案**：
- 背景：白色/浅灰（#FFFFFF / #F5F5F5）
- 日期数字：深灰/黑色（#1C1C1E）
- 装饰元素：系统蓝色（#007AFF）
- 阴影：微妙的投影增加立体感

### 方案2：月历网格（备选）

```
┌─────────────┐
│ 10  2024    │  <- 月份和年份
├─────────────┤
│ 日 一 二 三 │
│ 1  2  3  4  │
│ 5  6  7  ●8 │  <- 今天标记
│ 9 10 11 12  │
└─────────────┘
```

## 实施步骤

### 1. 使用设计工具创建

**推荐工具**：
- Sketch / Figma（矢量设计）
- SF Symbols App（系统图标参考）

### 2. 导出规格

从1024x1024主图标导出所有需要的尺寸：

```bash
# 使用sips命令行工具批量导出
sips -z 16 16 icon-1024.png --out icon-16.png
sips -z 32 32 icon-1024.png --out icon-32@1x.png
sips -z 64 64 icon-1024.png --out icon-32@2x.png
sips -z 128 128 icon-1024.png --out icon-128@1x.png
sips -z 256 256 icon-1024.png --out icon-128@2x.png
sips -z 256 256 icon-1024.png --out icon-256@1x.png
sips -z 512 512 icon-1024.png --out icon-256@2x.png
sips -z 512 512 icon-1024.png --out icon-512@1x.png
sips -z 1024 1024 icon-1024.png --out icon-512@2x.png
```

### 3. 添加到Xcode

将图标文件拖放到 `Assets.xcassets/AppIcon.appiconset/` 目录

## 临时方案

当前使用Xcode默认图标。正式发布前需要提供专业设计的图标。

## 设计检查清单

- [ ] 所有尺寸图标已生成
- [ ] 图标在浅色/深色背景下都清晰可见
- [ ] 图标在16x16小尺寸下依然可识别
- [ ] 遵循macOS图标设计规范（圆角、阴影、渐变）
- [ ] 与其他macOS系统图标风格协调
- [ ] 通过App Store审核标准

## 参考资料

- [macOS Human Interface Guidelines - App Icon](https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/app-icon/)
- [SF Symbols App](https://developer.apple.com/sf-symbols/)
