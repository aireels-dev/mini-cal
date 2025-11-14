# KeyboardShortcuts 集成方案

## 方案概述

基于对 macOS 快捷键录制最佳实践的研究，我们采用 **KeyboardShortcuts** by sindresorhus 作为标准解决方案。

### 为什么选择 KeyboardShortcuts？

1. ✅ **现代化**：纯 Swift + SwiftUI，与项目技术栈完美匹配
2. ✅ **简洁**：API 设计优雅，代码量极少（相比当前实现减少 80% 代码）
3. ✅ **安全**：自动检测快捷键冲突并警告用户
4. ✅ **维护良好**：活跃维护，支持最新 macOS（10.15+）
5. ✅ **生产验证**：被 Dato、Jiffy、Plash、Lungo 等商业应用使用
6. ✅ **Mac App Store 兼容**：完全支持沙盒环境

### 对比其他方案

| 特性 | KeyboardShortcuts | ShortcutRecorder | 当前自定义实现 |
|-----|-------------------|------------------|---------------|
| 语言 | Swift | Objective-C | Swift |
| SwiftUI 支持 | ✅ 原生 | ❌ 需要桥接 | ✅ 自定义 |
| 冲突检测 | ✅ 自动 | ✅ 手动 | ❌ 无 |
| 代码量 | ~10 行 | ~50 行 | ~190 行 |
| 键盘焦点问题 | ✅ 已解决 | ✅ 已解决 | ❌ **当前问题** |
| 维护状态 | ✅ 活跃 | ⚠️ 较慢 | ⚠️ 需自维护 |

---

## 实施步骤

### 步骤 1: 添加 Swift Package 依赖（Xcode GUI 操作）

1. 打开 `MiniCal.xcodeproj` 项目
2. 在项目导航器中选择项目根节点 "MiniCal"
3. 选择 `Package Dependencies` 标签页
4. 点击左下角的 `+` 按钮
5. 在搜索框中输入：
   ```
   https://github.com/sindresorhus/KeyboardShortcuts
   ```
6. 选择版本规则：
   - **Dependency Rule**: `Up to Next Major Version`
   - **Version**: `2.0.0`
7. 点击 `Add Package`
8. 在弹出的目标选择窗口中，确保 `MiniCal` target 被勾选
9. 点击 `Add Package` 完成

**验证安装**：
- 在项目导航器中应该能看到 `Package Dependencies` 分组
- 展开后应显示 `KeyboardShortcuts`

---

### 步骤 2: 添加快捷键名称定义文件

**文件已创建**：`MiniCal/Models/KeyboardShortcutNames.swift`

```swift
//  KeyboardShortcutNames.swift

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// 全局快捷键：显示/隐藏日历
    static let toggleCalendar = Self("toggleCalendar", default: .init(.x, modifiers: [.command, .shift]))
}
```

**说明**：
- 定义快捷键名称 `.toggleCalendar`
- 默认值：`⇧⌘X` (Shift + Command + X)
- KeyboardShortcuts 会自动将快捷键保存到 UserDefaults

---

### 步骤 3: 更新快捷键录制器视图

**需要替换的文件**：`MiniCal/Views/HotkeyRecorder.swift`

**新实现（仅 30 行，替换原有 192 行）**：

```swift
//  HotkeyRecorder.swift

import SwiftUI
import KeyboardShortcuts

/// 快捷键录制器视图
struct HotkeyRecorder: View {
    var body: some View {
        HStack {
            Text("快捷键")
                .foregroundColor(.secondary)

            Spacer()

            // 使用 KeyboardShortcuts 提供的 AppKit 录制器
            KeyboardShortcutRecorderView()
                .frame(height: 28)
        }
    }
}

// MARK: - NSViewRepresentable Wrapper

/// 将 KeyboardShortcuts.RecorderCocoa 包装为 SwiftUI View
struct KeyboardShortcutRecorderView: NSViewRepresentable {
    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleCalendar)
        return recorder
    }

    func updateNSView(_ nsView: KeyboardShortcuts.RecorderCocoa, context: Context) {
        // RecorderCocoa 自动处理更新
    }
}
```

**关键改进**：
- ✅ 自动处理键盘焦点（解决当前问题）
- ✅ 自动检测快捷键冲突
- ✅ 自动保存到 UserDefaults
- ✅ macOS 原生 UI 样式
- ❌ 移除复杂的模态窗口和事件监听代码

---

### 步骤 4: 简化 SettingsView 集成

**需要修改的文件**：`MiniCal/Views/SettingsView.swift`

**修改 MenuBarSettingsView 中的快捷键部分**：

**之前的代码（复杂）**：
```swift
if localSettings.globalHotkeyEnabled {
    HotkeyRecorder(
        hotkeyString: $localSettings.globalHotkeyKey,
        onHotkeyChanged: { newHotkey in
            var updated = settingsManager.currentSettings
            updated.globalHotkeyKey = newHotkey
            updated.lastUpdated = Date()
            settingsManager.saveSettings(updated)
            // 更新快捷键
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.updateGlobalHotkey(enabled: true, keyString: newHotkey)
            }
        }
    )
}
```

**修改后的代码（简洁）**：
```swift
if localSettings.globalHotkeyEnabled {
    HotkeyRecorder()
}
```

**说明**：
- KeyboardShortcuts 自动管理快捷键存储
- 不再需要手动保存到 UserDefaults
- 不再需要 `globalHotkeyKey` 字段

---

### 步骤 5: 简化 AppDelegate 全局快捷键监听

**需要修改的文件**：`MiniCal/App/AppDelegate.swift`

**移除整个 GlobalHotkeyManager**：
- 删除 `MiniCal/Services/GlobalHotkeyManager.swift` 文件
- 在 AppDelegate 中移除相关代码

**新的实现（在 AppDelegate 中）**：

```swift
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    // ... 其他属性

    // ❌ 移除这些
    // private var hotkeyManager = GlobalHotkeyManager.shared

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // ... 其他初始化代码

        setupGlobalHotkey()  // 简化后的设置
    }

    // 简化的全局快捷键设置
    private func setupGlobalHotkey() {
        KeyboardShortcuts.onKeyUp(for: .toggleCalendar) { [weak self] in
            self?.toggleCalendar()
        }
    }

    @objc private func toggleCalendar() {
        menuBarController.togglePopover(nil)
    }
}
```

**移除的方法**：
- ❌ `updateGlobalHotkey(enabled:keyString:)`
- ❌ 整个 `GlobalHotkeyManager` 类（~200 行代码）

---

### 步骤 6: 清理 UserSettings 模型

**需要修改的文件**：`MiniCal/Models/UserSettings.swift`

**移除不再需要的字段**：

```swift
struct UserSettings: Codable, Equatable {
    // ... 其他字段

    // MARK: - 全局快捷键设置

    /// 是否启用全局快捷键
    var globalHotkeyEnabled: Bool

    // ❌ 移除这个字段（KeyboardShortcuts 自动管理）
    // var globalHotkeyKey: String

    static let `default` = UserSettings(
        // ... 其他参数
        globalHotkeyEnabled: true,
        // ❌ 移除这个参数
        // globalHotkeyKey: "⇧⌘X",
    )
}
```

---

### 步骤 7: 测试新实现

#### 测试清单

1. **快捷键录制**：
   - [ ] 打开设置 → 菜单栏 → 应用设置
   - [ ] 点击快捷键录制器
   - [ ] 按下新的组合键（如 `⌘⌥C`）
   - [ ] 快捷键应立即更新（无需点击确认）
   - [ ] 尝试设置系统已占用的快捷键（如 `⌘C`），应显示警告

2. **全局快捷键触发**：
   - [ ] 在任意应用中按下设置的快捷键
   - [ ] 日历浮窗应立即显示/隐藏
   - [ ] 切换到其他应用后再次测试

3. **设置持久化**：
   - [ ] 修改快捷键
   - [ ] 退出应用
   - [ ] 重新启动应用
   - [ ] 快捷键设置应被保留

4. **冲突检测**：
   - [ ] 尝试设置 `⌘C`（系统复制快捷键）
   - [ ] 应显示冲突警告
   - [ ] 尝试设置应用菜单中已使用的快捷键
   - [ ] 应显示冲突警告

---

## 代码统计

### 代码量对比

| 组件 | 之前 | 之后 | 减少 |
|-----|-----|-----|-----|
| HotkeyRecorder.swift | 192 行 | 30 行 | -84% |
| GlobalHotkeyManager.swift | ~200 行 | 0 行（删除） | -100% |
| AppDelegate 快捷键相关 | ~50 行 | ~10 行 | -80% |
| SettingsView 快捷键部分 | ~20 行 | ~5 行 | -75% |
| UserSettings 快捷键字段 | 5 行 | 3 行 | -40% |
| **总计** | **~467 行** | **~48 行** | **-90%** |

### 功能提升

| 功能 | 之前 | 之后 |
|-----|-----|-----|
| 键盘焦点问题 | ❌ 存在问题 | ✅ 自动处理 |
| 快捷键冲突检测 | ❌ 无 | ✅ 自动检测并警告 |
| UI 样式 | ⚠️ 自定义（需维护） | ✅ macOS 原生 |
| 代码复杂度 | ⚠️ 高 | ✅ 低 |
| 维护成本 | ⚠️ 高（自维护） | ✅ 低（库维护） |

---

## 迁移路径

对于已有用户的快捷键设置迁移：

```swift
// 在 AppDelegate 首次启动时执行一次
private func migrateOldHotkeySettings() {
    let defaults = UserDefaults.standard

    // 检查是否已迁移
    guard !defaults.bool(forKey: "hasmigratedToKeyboardShortcuts") else { return }

    // 读取旧的快捷键字符串（如果存在）
    if let oldHotkeyString = defaults.string(forKey: "globalHotkeyKey") {
        // 解析旧格式并设置到 KeyboardShortcuts
        // 注意：KeyboardShortcuts 使用自己的存储格式
        // 用户需要重新设置快捷键（一次性操作）
        Logger.info("Found old hotkey setting: \(oldHotkeyString), please reconfigure in settings", category: Logger.app)
    }

    // 标记已迁移
    defaults.set(true, forKey: "hasMigratedToKeyboardShortcuts")
}
```

**建议**：
- 不做自动迁移，让用户重新设置一次（更安全）
- 在设置界面显示提示："快捷键已升级，请重新设置"
- 默认值 `⇧⌘X` 会自动生效

---

## 常见问题

### Q: KeyboardShortcuts 库的大小？
A: 约 100KB，非常轻量。

### Q: 是否支持沙盒环境？
A: 是的，完全支持 Mac App Store 沙盒。

### Q: 是否支持多个快捷键？
A: 是的，可以定义多个 `KeyboardShortcuts.Name`。

### Q: 快捷键存储在哪里？
A: 自动存储在 `UserDefaults`，key 为 `"KeyboardShortcuts_toggleCalendar"`。

### Q: 如何禁用快捷键？
A: 使用 `KeyboardShortcuts.disable(.toggleCalendar)`。

---

## 参考资料

- [KeyboardShortcuts GitHub](https://github.com/sindresorhus/KeyboardShortcuts)
- [API 文档](https://sindresorhus.com/KeyboardShortcuts/)
- [示例项目](https://github.com/sindresorhus/KeyboardShortcuts/tree/main/Example)
- [Apple 官方文档 - Handling Key Events](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingKeyEvents/HandlingKeyEvents.html)
