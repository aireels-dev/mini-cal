#!/usr/bin/env python3
"""
替换 SettingsView.swift 中的中文字符串为本地化键
"""

import re
import shutil
from pathlib import Path

# 完整的字符串映射
STRING_MAP = {
    # 应用设置
    "应用设置": "settings.app.section",
    "启用全局快捷键": "settings.app.global_hotkey",
    "开机自动启动": "settings.app.launch_at_login",

    # 菜单栏显示
    "菜单栏显示": "settings.menu_bar.display",
    "格式": "settings.menu_bar.format",
    "24小时制": "settings.menu_bar.24hour",
    "显示星期": "settings.menu_bar.show_weekday",
    "显示秒": "settings.menu_bar.show_seconds",

    # 日历交互
    "日历交互": "settings.calendar.interaction",
    "启用悬浮展示": "settings.calendar.hover_enable",

    # 自定义格式
    "自定义格式": "settings.format.custom",
    "编辑格式": "settings.format.edit_help",

    # 格式说明
    "四位年份": "settings.format.year_4digit",
    "两位年份": "settings.format.year_2digit",
    "月份": "settings.format.month",
    "月份（补零）": "settings.format.month_padded",
    "日期": "settings.format.day",
    "日期（补零）": "settings.format.day_padded",
    "星期": "settings.format.weekday",
    "第几周": "settings.format.week_of_year",
    "月中第几周": "settings.format.week_of_month",
    "24小时": "settings.format.hour_24",
    "12小时": "settings.format.hour_12",
    "分钟": "settings.format.minute",
    "秒": "settings.format.second",
    "上午/下午": "settings.format.am_pm",

    # 历法类型
    "历法类型": "settings.calendar.type_label",

    # 订阅相关
    "添加订阅失败": "subscription.add_failed",
    "确定": "common.ok",
    "点击下方「添加订阅」按钮开始": "subscription.click_to_add",

    # 权限状态
    "已授权": "permission.status.authorized",
    "已拒绝": "permission.status.denied",
    "受限": "permission.status.restricted",
    "未询问": "permission.status.not_determined",
    "未知": "permission.status.unknown",

    # 本地组
    "例如：工作、个人、提醒": "local_group.placeholder",

    # 面板大小
    "尺寸档位": "settings.appearance.size_level",

    # 快捷键与手势
    "快捷键与手势": "settings.shortcuts.section",
    "箭头键切换": "settings.shortcuts.arrow_keys",
    "WASD键切换": "settings.shortcuts.wasd_keys",
    "缩放调整": "settings.shortcuts.zoom",
    "触摸板手势": "settings.shortcuts.trackpad",
    "上个月": "settings.shortcuts.prev_month",
    "下个月": "settings.shortcuts.next_month",
    "上一年": "settings.shortcuts.prev_year",
    "下一年": "settings.shortcuts.next_year",
    "放大": "settings.shortcuts.zoom_in",
    "缩小": "settings.shortcuts.zoom_out",
    "左滑": "settings.gestures.swipe_left",
    "右滑": "settings.gestures.swipe_right",
    "上滑": "settings.gestures.swipe_up",
    "下滑": "settings.gestures.swipe_down",

    # 说明
    "说明": "settings.notes.section",
    "调整面板大小可以获得更好的视觉体验": "settings.notes.panel_size",
    "日历弹窗使用 macOS Glass 效果": "settings.notes.glass_effect",

    # 其他
    "今日": "calendar.today",
}

def replace_strings(file_path, dry_run=False):
    """替换文件中的字符串"""
    print(f"\n📄 Processing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False
    replacements = []

    for original, key in STRING_MAP.items():
        # 跳过已经是本地化键的字符串
        if original.startswith(('settings.', 'permission.', 'subscription.', 'common.', 'calendar.')):
            continue

        # 匹配 Text("原始文本")
        pattern1 = rf'Text\("{re.escape(original)}"\)'
        matches1 = re.findall(pattern1, content)
        if matches1:
            content = re.sub(pattern1, f'Text("{key}")', content)
            modified = True
            replacements.append(f'Text: "{original}" -> "{key}"')

        # 匹配 Section("原始文本")
        pattern2 = rf'Section\("{re.escape(original)}"\)'
        matches2 = re.findall(pattern2, content)
        if matches2:
            content = re.sub(pattern2, f'Section("{key}")', content)
            modified = True
            replacements.append(f'Section: "{original}" -> "{key}"')

        # 匹配 Label("原始文本", systemImage: ...)
        pattern3 = rf'Label\("{re.escape(original)}", systemImage:'
        matches3 = re.findall(pattern3, content)
        if matches3:
            content = re.sub(pattern3, f'Label("{key}", systemImage:', content)
            modified = True
            replacements.append(f'Label: "{original}" -> "{key}"')

        # 匹配 Picker("原始文本", selection: ...)
        pattern4 = rf'Picker\("{re.escape(original)}", selection:'
        matches4 = re.findall(pattern4, content)
        if matches4:
            content = re.sub(pattern4, f'Picker("{key}", selection:', content)
            modified = True
            replacements.append(f'Picker: "{original}" -> "{key}"')

        # 匹配 Toggle("原始文本", isOn: ...)
        pattern5 = rf'Toggle\("{re.escape(original)}", isOn:'
        matches5 = re.findall(pattern5, content)
        if matches5:
            content = re.sub(pattern5, f'Toggle("{key}", isOn:', content)
            modified = True
            replacements.append(f'Toggle: "{original}" -> "{key}"')

        # 匹配 TextField("原始文本", text: ...)
        pattern6 = rf'TextField\("{re.escape(original)}", text:'
        matches6 = re.findall(pattern6, content)
        if matches6:
            content = re.sub(pattern6, f'TextField("{key}", text:', content)
            modified = True
            replacements.append(f'TextField: "{original}" -> "{key}"')

        # 匹配 Button("原始文本")
        pattern7 = rf'Button\("{re.escape(original)}"\)'
        matches7 = re.findall(pattern7, content)
        if matches7:
            content = re.sub(pattern7, f'Button("{key}")', content)
            modified = True
            replacements.append(f'Button: "{original}" -> "{key}"')

        # 匹配 .alert("原始文本", isPresented: ...)
        pattern8 = rf'\.alert\("{re.escape(original)}", isPresented:'
        matches8 = re.findall(pattern8, content)
        if matches8:
            content = re.sub(pattern8, f'.alert("{key}", isPresented:', content)
            modified = True
            replacements.append(f'alert: "{original}" -> "{key}"')

        # 匹配 .help("原始文本")
        pattern9 = rf'\.help\("{re.escape(original)}"\)'
        matches9 = re.findall(pattern9, content)
        if matches9:
            content = re.sub(pattern9, f'.help("{key}")', content)
            modified = True
            replacements.append(f'help: "{original}" -> "{key}"')

        # 匹配 return "原始文本" (在 statusText 方法中)
        pattern10 = rf'return "{re.escape(original)}"'
        matches10 = re.findall(pattern10, content)
        if matches10:
            content = re.sub(pattern10, f'return "{key}"', content)
            modified = True
            replacements.append(f'return: "{original}" -> "{key}"')

        # 匹配 FormatExampleView(symbol: ..., description: "原始文本", ...)
        pattern11 = rf'FormatExampleView\(([^)]*?)description: "{re.escape(original)}"'
        matches11 = re.findall(pattern11, content)
        if matches11:
            content = re.sub(pattern11, rf'FormatExampleView(\1description: "{key}"', content)
            modified = True
            replacements.append(f'FormatExampleView: "{original}" -> "{key}"')

    # 特殊处理：延迟时间文本（不处理，需要手动修改）
    # 特殊处理：单元格大小文本（不处理，需要手动修改）
    # 这两个需要格式化，暂时跳过，手动处理

    if modified and not dry_run:
        # 创建备份
        backup = f"{file_path}.backup_settings"
        shutil.copy2(file_path, backup)
        print(f"  💾 Backup created: {backup}")

        # 保存修改
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ File updated")
        print(f"  📝 Replacements made: {len(replacements)}")
        for r in replacements:
            print(f"     • {r}")
    elif modified:
        print(f"  ℹ️  DRY RUN: Would update file")
        print(f"  📝 Would make {len(replacements)} replacements")
    else:
        print(f"  ⊘ No changes needed")

    return modified

def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    project_root = Path(__file__).parent.parent
    file_path = project_root / 'MiniCal/Views/SettingsView.swift'

    print("="*60)
    print("🔄 替换 SettingsView 中的中文字符串")
    print("="*60)
    print(f"模式: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print("="*60)

    if file_path.exists():
        replace_strings(file_path, args.dry_run)
    else:
        print(f"⚠️  File not found: {file_path}")

    print("\n" + "="*60)
    print("✅ 完成!")
    print("="*60)

if __name__ == '__main__':
    main()
