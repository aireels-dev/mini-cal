#!/usr/bin/env python3
"""
批量替换所有视图文件中的硬编码字符串
"""

import re
import shutil
from pathlib import Path

# 完整的字符串映射：原始文本 -> 本地化键
COMPLETE_STRING_MAP = {
    # Settings - Language (已完成)
    "语言": "settings.language.section",
    "界面语言": "settings.language.interface",
    "设置菜单栏、设置界面和UI元素的显示语言": "settings.language.description",

    # Settings - Calendar (已完成)
    "本地历法": "settings.calendar.secondary",
    "历法类型": "settings.calendar.type",
    "不显示": "settings.calendar.none",
    "在公历日期下方显示本地历法": "settings.calendar.description",
    "系统同步": "settings.calendar.system_sync",
    "外部订阅": "settings.calendar.external_subscriptions",
    "本地管理": "settings.calendar.local_management",

    # Settings - Appearance (已完成)
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

    # Permissions (已完成)
    "需要访问日历权限": "permission.calendar.required",
    "授权后可同步 iCloud 和本地日历的事件": "permission.calendar.description",
    "请求权限": "permission.calendar.request",
    "打开系统设置": "permission.calendar.open_settings",
    "提示:点击按钮将打开系统设置,在「隐私与安全性」>「日历」中授权": "permission.calendar.hint",

    # Subscriptions (部分已完成，现在补全)
    "添加订阅": "subscription.add",
    "订阅 URL": "subscription.url",
    "支持 http://、https:// 和 webcal:// 协议": "subscription.protocol_hint",
    "正在添加订阅...": "subscription.adding",
    "正在验证并下载日历数据": "subscription.downloading",
    "刷新全部": "subscription.refresh_all",
    "日历订阅管理": "subscription.manager_title",
    "还没有订阅任何日历": "subscription.no_subscriptions",
    "添加外部日历订阅来查看更多事件": "subscription.add_to_view",
    "添加日历订阅": "subscription.add_button",
    "输入外部日历的URL地址": "subscription.url_input_placeholder",
    "日历URL": "subscription.calendar_url",
    "常见日历服务": "subscription.common_services",
    "全部刷新": "subscription.refresh_all_button",

    # Local event groups (已完成)
    "添加类别": "local_group.add",
    "类别名称": "local_group.name",
    "颜色": "common.color",
    "添加本地类别": "local_group.add_title",

    # Common (已完成)
    "名称": "common.name",
    "备注": "common.note",
    "暂无可用的系统日历": "common.no_system_calendars",
    "暂无外部订阅": "common.no_subscriptions",
    "→": "common.arrow",
    "·": "common.dot",
    "取消": "common.cancel",
    "添加": "common.add",

    # Events (已完成)
    "实时预览": "event.live_preview",
    "延迟时间": "event.hover_delay",
    "延迟": "event.delay",
    "支持的格式符号：": "event.format_symbols",
    "示例：M月d日 HH:mm → 1月15日 14:30": "event.format_example",

    # Menu bar (已完成)
    "菜单栏": "menu_bar.title",
    "日历": "menu_bar.calendar",
    "外观": "menu_bar.appearance",

    # Calendar Events (新增)
    "今日事件": "calendar.today_events",
    "暂无事件": "calendar.no_events",
    "这天没有事件": "calendar.no_events_today",
    "享受轻松的一天": "calendar.enjoy_day",
    "全天": "event.all_day",
    "多日": "event.multi_day",
    "时间": "event.time",
    "地点": "event.location",
    "参与者": "event.attendees",
    "事件标题": "event.title",
    "加载事件中...": "event.loading",
    "加载失败": "event.load_failed",
    "开始时间": "event.start_time",
    "结束时间": "event.end_time",

    # Event Creation/Edit (新增)
    "添加事件": "event.add",
    "管理订阅": "event.manage_subscription",
    "标题": "event.title_label",
    "开始": "event.start",
    "结束": "event.end",
    "结束时间必须晚于开始时间": "event.end_after_start",
    "位置（可选）": "event.location_optional",
    "备注（可选）": "event.notes_optional",
    "保存": "event.save",

    # Location & Weather (新增)
    "启用位置，显示日出日落信息": "location.enable_for_sunset",
    "获取位置中...": "location.fetching",

    # Misc (新增)
    "URL": "misc.url",
    "默认": "misc.default",
    "快捷键": "misc.shortcut"
}

def replace_in_file(file_path, replacements, dry_run=False):
    """替换单个文件中的字符串"""
    print(f"\n📄 Processing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False

    for original, key in replacements.items():
        # 跳过已经是本地化键的字符串
        if original.startswith(('settings.', 'permission.', 'subscription.', 'local_group.',
                                'common.', 'event.', 'menu_bar.', 'calendar.', 'location.', 'misc.')):
            continue

        # 匹配 Text("原始文本")
        pattern1 = rf'Text\("{re.escape(original)}"\)'
        if re.search(pattern1, content):
            content = re.sub(pattern1, f'Text("{key}")', content)
            modified = True
            print(f"  ✓ Replaced Text: \"{original}\" -> \"{key}\"")

        # 匹配 Section("原始文本")
        pattern2 = rf'Section\("{re.escape(original)}"\)'
        if re.search(pattern2, content):
            content = re.sub(pattern2, f'Section("{key}")', content)
            modified = True
            print(f"  ✓ Replaced Section: \"{original}\" -> \"{key}\"")

        # 匹配 Label("原始文本", systemImage: ...)
        pattern3 = rf'Label\("{re.escape(original)}",\s*systemImage:'
        if re.search(pattern3, content):
            content = re.sub(pattern3, f'Label("{key}", systemImage:', content)
            modified = True
            print(f"  ✓ Replaced Label: \"{original}\" -> \"{key}\"")

    if modified and not dry_run:
        # 创建备份
        backup = f"{file_path}.backup"
        shutil.copy2(file_path, backup)
        print(f"  💾 Backup created: {backup}")

        # 保存修改
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ File updated")
    elif modified:
        print(f"  ℹ️  DRY RUN: Would update file")
    else:
        print(f"  ⊘ No changes needed")

    return modified

def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--file', help='Process specific file')
    args = parser.parse_args()

    project_root = Path(__file__).parent.parent
    views_dir = project_root / 'MiniCal/Views'

    # 要处理的文件列表
    files_to_process = [
        views_dir / 'CalendarEventView.swift',
        views_dir / 'EventDetailView.swift',
        views_dir / 'Components/DayEventListView.swift',
        views_dir / 'Components/DayEventHeader.swift',
        views_dir / 'Components/DayEventRow.swift',
        views_dir / 'SubscriptionManagerView.swift',
        views_dir / 'Components/ExternalSubscriptionCompactRow.swift',
        views_dir / 'Components/LocalEventGroupCompactRow.swift',
        views_dir / 'Components/LocalEventGroupRow.swift',
        views_dir / 'Components/SystemCalendarRow.swift',
        views_dir / 'HotkeyRecorder.swift',
    ]

    if args.file:
        files_to_process = [Path(args.file)]

    print("="*60)
    print("🔄 批量字符串本地化替换")
    print("="*60)
    print(f"模式: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(f"文件数: {len(files_to_process)}")
    print("="*60)

    modified_count = 0
    for file_path in files_to_process:
        if file_path.exists():
            if replace_in_file(file_path, COMPLETE_STRING_MAP, args.dry_run):
                modified_count += 1
        else:
            print(f"\n⚠️  File not found: {file_path}")

    print("\n" + "="*60)
    print(f"✅ 完成: {modified_count} 个文件已修改")
    print("="*60)

if __name__ == '__main__':
    main()
