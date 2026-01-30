# MiniCal 自动化构建流程（参考 Codex + MCP 端侧模板）

> 目标：在本地形成“可脚本化”的自动化构建闭环，产出构建日志与 xcresult 结果包，为后续接入 Codex/MCP 或 CI 做准备。

---

## 1. 前置依赖

- macOS 15+
- Xcode 16+（含 Command Line Tools）
- MiniCal 工程（macOS）
- 可用的 Codex CLI（可选）
- MCP Server（可选，若需要工具化调用）

---

## 2. MCP 工具最小集合（macOS 版本）

> 本项目是 macOS App，不涉及 iOS 模拟器流程。

建议的工具：

- `xcode.build`
- `xcode.test`（可选，当前项目暂无测试时可不实现）
- `report.collect`

### 2.1 工具定义示例（schema）

```json
{
  "tools": [
    {
      "name": "xcode.build",
      "description": "Build macOS scheme",
      "input": {
        "type": "object",
        "properties": {
          "project": { "type": "string" },
          "scheme": { "type": "string" },
          "configuration": { "type": "string" },
          "resultBundlePath": { "type": "string" }
        },
        "required": ["scheme"]
      }
    },
    {
      "name": "xcode.test",
      "description": "Run macOS unit tests",
      "input": {
        "type": "object",
        "properties": {
          "project": { "type": "string" },
          "scheme": { "type": "string" },
          "destination": { "type": "string" },
          "resultBundlePath": { "type": "string" }
        },
        "required": ["scheme"]
      }
    },
    {
      "name": "report.collect",
      "description": "Collect logs and xcresult bundle",
      "input": {
        "type": "object",
        "properties": {
          "resultBundlePath": { "type": "string" },
          "outputDir": { "type": "string" }
        },
        "required": ["outputDir"]
      }
    }
  ]
}
```

---

## 3. 命令映射（最小实现）

### 3.1 xcode.build

```bash
xcodebuild \
  -project "MiniCal.xcodeproj" \
  -scheme "MiniCal" \
  -configuration "Debug" \
  -resultBundlePath "/tmp/xcresults/minical/MiniCal-build.xcresult" \
  build
```

### 3.2 xcode.test（可选）

> 当前项目暂无测试 Target，此步骤可先留空。

```bash
xcodebuild \
  -project "MiniCal.xcodeproj" \
  -scheme "MiniCal" \
  -destination "platform=macOS" \
  -resultBundlePath "/tmp/xcresults/minical/MiniCal-test.xcresult" \
  test
```

### 3.3 report.collect（示意）

```bash
mkdir -p "/tmp/xcresults/minical/artifacts"
cp -R "/tmp/xcresults/minical/MiniCal-build.xcresult" "/tmp/xcresults/minical/artifacts/"
```

---

## 4. 项目内脚本化流程（已落地）

已新增脚本：`scripts/ci/run-build.sh`

- 产出目录：`/tmp/xcresults/minical`
- 产出物：
  - `MiniCal-build.xcresult`
  - `MiniCal-build.log`

### 4.1 执行方式

```bash
"scripts/ci/run-build.sh"
```

### 4.2 可配置参数（环境变量）

- `CONFIGURATION`（默认：`Debug`）
- `RESULT_ROOT`（默认：`/tmp/xcresults/minical`）
- `RESULT_BUNDLE`（默认：`$RESULT_ROOT/MiniCal-build.xcresult`）
- `LOG_PATH`（默认：`$RESULT_ROOT/MiniCal-build.log`）

示例：

```bash
CONFIGURATION="Release" RESULT_ROOT="/tmp/xcresults/minical-release" "scripts/ci/run-build.sh"
```

---

## 5. Codex 端最小流程（示意）

```
1. xcode.build { project: "MiniCal.xcodeproj", scheme: "MiniCal", configuration: "Debug", resultBundlePath: "/tmp/xcresults/minical/MiniCal-build.xcresult" }
2. report.collect { resultBundlePath: "/tmp/xcresults/minical/MiniCal-build.xcresult", outputDir: "/tmp/xcresults/minical/artifacts" }
```

---

## 6. 后续可选扩展

- 添加 Unit/UI Tests 后补齐 `xcode.test` 流程
- 接入 `xcresulttool` 转换报告（JUnit/HTML）
- 增加签名/归档/导出 DMG 的自动化步骤
- 将流程封装进 MCP Server，作为 Codex 工具调用
