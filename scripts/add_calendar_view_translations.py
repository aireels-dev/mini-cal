#!/usr/bin/env python3
"""
补全日历视图中的翻译
"""

import json
from pathlib import Path

# 日历视图的翻译
CALENDAR_VIEW_TRANSLATIONS = {
    "calendar.back_to_today": {
        "zh-Hans": "回到今天",
        "zh-Hant": "回到今天",
        "en": "Back to Today",
        "ar": "العودة إلى اليوم",
        "he": "חזור להיום",
        "ja": "今日に戻る",
        "ko": "오늘로 돌아가기",
        "vi": "Quay về hôm nay",
        "fa": "بازگشت به امروز",
        "th": "กลับไปวันนี้",
        "tr": "Bugüne Dön",
        "ur": "آج پر واپس جائیں"
    }
}

def update_localizable():
    """更新 Localizable.xcstrings"""
    project_root = Path(__file__).parent.parent
    xcstrings_path = project_root / 'MiniCal/Resources/Localizations/Localizable.xcstrings'

    print("📖 读取 Localizable.xcstrings...")
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'strings' not in data:
        data['strings'] = {}

    updated = 0
    added = 0

    print("\n🔄 更新日历视图翻译...")
    for key, translations in CALENDAR_VIEW_TRANSLATIONS.items():
        if key not in data['strings']:
            data['strings'][key] = {}
            added += 1

        if 'localizations' not in data['strings'][key]:
            data['strings'][key]['localizations'] = {}

        # 添加所有12种语言的翻译
        for locale, value in translations.items():
            data['strings'][key]['localizations'][locale] = {
                'stringUnit': {
                    'state': 'translated',
                    'value': value
                }
            }
            updated += 1

    # 备份
    backup_path = xcstrings_path.with_suffix('.xcstrings.backup_calendar_view')
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"💾 创建备份: {backup_path}")

    # 保存
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("✅ 日历视图翻译更新完成!")
    print("="*60)
    print(f"新增键: {added} 个")
    print(f"更新翻译: {updated} 个")

if __name__ == '__main__':
    update_localizable()
