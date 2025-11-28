#!/usr/bin/env python3
"""
自动替换 Swift 代码中的硬编码字符串为本地化键
"""

import re
import json
from pathlib import Path
import shutil

# 字符串映射：原始文本 -> 本地化键
STRING_MAP = {
    # Settings - Language
    "语言": "settings.language.section",
    "界面语言": "settings.language.interface",
    "设置菜单栏、设置界面和UI元素的显示语言": "settings.language.description",

    # Settings - Calendar tab
    "本地历法": "settings.calendar.secondary",
    "历法类型": "settings.calendar.type",
    "不显示": "settings.calendar.none",
    "在公历日期下方显示本地历法": "settings.calendar.description",
    "系统同步": "settings.calendar.system_sync",
    "外部订阅": "settings.calendar.external_subscriptions",
    "本地管理": "settings.calendar.local_management",

    # Settings - Appearance tab
    "面板大小": "settings.appearance.panel_size",
    "尺寸档位": "settings.appearance.size_level",
    "当前尺寸：": "settings.appearance.current_size",
    "单元格大小：": "settings.appearance.cell_size",
    "浮窗透明度": "settings.appearance.opacity",
    "不透明度": "settings.appearance.opacity_label",
    "更透明": "settings.appearance.more_transparent",
    "更不透明": "settings.appearance.more_opaque",
    "主题": "settings.appearance.theme",
    "重置": "settings.appearance.reset",

    # Calendar permissions
    "需要访问日历权限": "permission.calendar.required",
    "授权后可同步 iCloud 和本地日历的事件": "permission.calendar.description",
    "请求权限": "permission.calendar.request",
    "打开系统设置": "permission.calendar.open_settings",
    "提示:点击按钮将打开系统设置,在「隐私与安全性」>「日历」中授权": "permission.calendar.hint",

    # Subscriptions
    "添加订阅": "subscription.add",
    "订阅 URL": "subscription.url",
    "支持 http://、https:// 和 webcal:// 协议": "subscription.protocol_hint",
    "取消": "common.cancel",
    "添加": "common.add",
    "正在添加订阅...": "subscription.adding",
    "正在验证并下载日历数据": "subscription.downloading",
    "刷新全部": "subscription.refresh_all",

    # Local event groups
    "添加类别": "local_group.add",
    "类别名称": "local_group.name",
    "颜色": "common.color",
    "添加本地类别": "local_group.add_title",

    # Common
    "名称": "common.name",
    "备注": "common.note",
    "全天": "common.all_day",
    "暂无事件": "common.no_events",
    "暂无可用的系统日历": "common.no_system_calendars",
    "暂无外部订阅": "common.no_subscriptions",
    "→": "common.arrow",
    "·": "common.dot",

    # Event details
    "实时预览": "event.live_preview",
    "延迟时间": "event.hover_delay",
    "延迟": "event.delay",
    "支持的格式符号：": "event.format_symbols",
    "示例：M月d日 HH:mm → 1月15日 14:30": "event.format_example",

    # Menu bar
    "菜单栏": "menu_bar.title",
    "日历": "menu_bar.calendar",
    "外观": "menu_bar.appearance",
}

def create_backup(file_path):
    """创建文件备份"""
    backup_path = f"{file_path}.backup"
    shutil.copy2(file_path, backup_path)
    return backup_path

def replace_text_strings(content, replacements):
    """替换 Text("...") 中的字符串"""
    modified = False

    for original, key in replacements.items():
        # 匹配 Text("原始文本")
        pattern = rf'Text\("{re.escape(original)}"\)'
        replacement = f'Text("{key}", bundle: .main, comment: "")'

        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            modified = True
            print(f"  ✓ Replaced: Text(\"{original}\") -> Text(\"{key}\")")

    return content, modified

def replace_section_strings(content, replacements):
    """替换 Section("...") 中的字符串"""
    modified = False

    for original, key in replacements.items():
        # 匹配 Section("原始文本")
        pattern = rf'Section\("{re.escape(original)}"\)'
        replacement = f'Section("{key}", bundle: .main, comment: "")'

        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            modified = True
            print(f"  ✓ Replaced: Section(\"{original}\") -> Section(\"{key}\")")

    return content, modified

def replace_label_strings(content, replacements):
    """替换 Label("...", ...) 中的字符串"""
    modified = False

    for original, key in replacements.items():
        # 匹配 Label("原始文本", ...)
        pattern = rf'Label\("{re.escape(original)}"\s*,'
        replacement = f'Label("{key}", bundle: .main, comment: "",'

        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            modified = True
            print(f"  ✓ Replaced: Label(\"{original}\", ...) -> Label(\"{key}\", ...)")

    return content, modified

def process_file(file_path, replacements, dry_run=False):
    """处理单个文件"""
    print(f"\n📄 Processing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False

    # 替换不同类型的字符串
    content, mod1 = replace_text_strings(content, replacements)
    content, mod2 = replace_section_strings(content, replacements)
    content, mod3 = replace_label_strings(content, replacements)

    modified = mod1 or mod2 or mod3

    if modified and not dry_run:
        # 创建备份
        backup = create_backup(file_path)
        print(f"  💾 Backup created: {backup}")

        # 保存修改后的文件
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ File updated")
    elif modified:
        print(f"  ℹ️  DRY RUN: Would update file")
    else:
        print(f"  ⊘ No changes needed")

    return modified

def add_translations_to_xcstrings(translations_map):
    """将翻译添加到 Localizable.xcstrings"""
    xcstrings_path = Path(__file__).parent.parent / 'MiniCal/Resources/Localizations/Localizable.xcstrings'

    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'strings' not in data:
        data['strings'] = {}

    # 这里需要手动添加翻译，或者从翻译文件中加载
    # 为了简化，我们只添加键和中文值
    added = 0
    for original, key in translations_map.items():
        if key not in data['strings']:
            data['strings'][key] = {
                'comment': f'Localized string for: {original}',
                'localizations': {
                    'zh-Hans': {
                        'stringUnit': {
                            'state': 'translated',
                            'value': original
                        }
                    }
                }
            }
            added += 1

    if added > 0:
        # 创建备份
        backup_path = xcstrings_path.with_suffix('.xcstrings.backup2')
        shutil.copy2(xcstrings_path, backup_path)

        with open(xcstrings_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\n✅ Added {added} new keys to Localizable.xcstrings")
        print(f"💾 Backup created: {backup_path}")

def main():
    import argparse

    parser = argparse.ArgumentParser(description='Auto-replace hardcoded strings with localization keys')
    parser.add_argument('files', nargs='*', help='Files to process (default: SettingsView.swift)')
    parser.add_argument('--dry-run', action='store_true', help='Perform a dry run without modifying files')
    parser.add_argument('--all-views', action='store_true', help='Process all view files')

    args = parser.parse_args()

    project_root = Path(__file__).parent.parent

    # 确定要处理的文件
    if args.all_views:
        files_to_process = list((project_root / 'MiniCal/Views').rglob('*.swift'))
    elif args.files:
        files_to_process = [Path(f) for f in args.files]
    else:
        files_to_process = [project_root / 'MiniCal/Views/SettingsView.swift']

    print("="*60)
    print("🔄 Automatic String Localization Replacement")
    print("="*60)
    print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(f"Files to process: {len(files_to_process)}")
    print("="*60)

    modified_count = 0
    for file_path in files_to_process:
        if file_path.exists():
            if process_file(file_path, STRING_MAP, args.dry_run):
                modified_count += 1

    print("\n" + "="*60)
    print(f"✅ Completed: {modified_count} file(s) modified")
    print("="*60)

    # 添加翻译到 xcstrings
    if not args.dry_run and modified_count > 0:
        print("\n🔄 Updating Localizable.xcstrings...")
        add_translations_to_xcstrings(STRING_MAP)

if __name__ == '__main__':
    main()
