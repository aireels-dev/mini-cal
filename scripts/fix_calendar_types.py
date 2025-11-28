#!/usr/bin/env python3
"""
补全历法类型的12语言翻译
"""

import json
from pathlib import Path

# 历法类型的完整翻译
CALENDAR_TYPE_TRANSLATIONS = {
    "calendar_type_gregorian": {
        "zh-Hans": "公历",
        "zh-Hant": "公曆",
        "en": "Gregorian",
        "ar": "الميلادي",
        "he": "לוח שנה גרגוריאני",
        "ja": "西暦",
        "ko": "그레고리력",
        "vi": "Dương lịch",
        "fa": "تقویم میلادی",
        "th": "ปฏิทินเกรกอเรียน",
        "tr": "Gregoryen",
        "ur": "عیسوی"
    },
    "calendar_type_chinese": {
        "zh-Hans": "农历",
        "zh-Hant": "農曆",
        "en": "Chinese Lunar",
        "ar": "التقويم الصيني",
        "he": "לוח שנה סיני",
        "ja": "旧暦",
        "ko": "음력",
        "vi": "Âm lịch",
        "fa": "تقویم قمری چینی",
        "th": "ปฏิทินจีน",
        "tr": "Çin Takvimi",
        "ur": "چینی قمری"
    },
    "calendar_type_islamic": {
        "zh-Hans": "伊斯兰历",
        "zh-Hant": "伊斯蘭曆",
        "en": "Islamic",
        "ar": "التقويم الهجري",
        "he": "לוח שנה אסלאמי",
        "ja": "イスラム暦",
        "ko": "이슬람력",
        "vi": "Lịch Hồi giáo",
        "fa": "تقویم هجری قمری",
        "th": "ปฏิทินอิสลาม",
        "tr": "İslami Takvim",
        "ur": "اسلامی"
    },
    "calendar_type_hebrew": {
        "zh-Hans": "希伯来历",
        "zh-Hant": "希伯來曆",
        "en": "Hebrew",
        "ar": "التقويم العبري",
        "he": "לוח עברי",
        "ja": "ヘブライ暦",
        "ko": "히브리력",
        "vi": "Lịch Do Thái",
        "fa": "تقویم عبری",
        "th": "ปฏิทินฮีบรู",
        "tr": "İbranice Takvim",
        "ur": "عبرانی"
    },
    "calendar_type_persian": {
        "zh-Hans": "波斯历",
        "zh-Hant": "波斯曆",
        "en": "Persian",
        "ar": "التقويم الفارسي",
        "he": "לוח שנה פרסי",
        "ja": "ペルシャ暦",
        "ko": "페르시아력",
        "vi": "Lịch Ba Tư",
        "fa": "تقویم هجری شمسی",
        "th": "ปฏิทินเปอร์เซีย",
        "tr": "Fars Takvimi",
        "ur": "فارسی"
    },
    "calendar_type_japanese": {
        "zh-Hans": "和历",
        "zh-Hant": "和曆",
        "en": "Japanese",
        "ar": "التقويم الياباني",
        "he": "לוח שנה יפני",
        "ja": "和暦",
        "ko": "일본력",
        "vi": "Lịch Nhật Bản",
        "fa": "تقویم ژاپنی",
        "th": "ปฏิทินญี่ปุ่น",
        "tr": "Japon Takvimi",
        "ur": "جاپانی"
    },
    "calendar_type_buddhist": {
        "zh-Hans": "佛历",
        "zh-Hant": "佛曆",
        "en": "Buddhist",
        "ar": "التقويم البوذي",
        "he": "לוח שנה בודהיסטי",
        "ja": "仏暦",
        "ko": "불교력",
        "vi": "Lịch Phật giáo",
        "fa": "تقویم بودایی",
        "th": "ปฏิทินพุทธ",
        "tr": "Budist Takvim",
        "ur": "بدھ مت"
    }
}

def update_calendar_names():
    """更新 CalendarNames.xcstrings"""
    project_root = Path(__file__).parent.parent
    xcstrings_path = project_root / 'MiniCal/Resources/Localizations/CalendarNames.xcstrings'

    print("📖 读取 CalendarNames.xcstrings...")
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'strings' not in data:
        data['strings'] = {}

    updated = 0

    print("\n🔄 更新历法类型翻译...")
    for key, translations in CALENDAR_TYPE_TRANSLATIONS.items():
        if key not in data['strings']:
            data['strings'][key] = {}

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
    backup_path = xcstrings_path.with_suffix('.xcstrings.backup_calendar')
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"💾 创建备份: {backup_path}")

    # 保存
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("✅ 历法类型翻译更新完成!")
    print("="*60)
    print(f"更新翻译: {updated} 个")
    print(f"历法类型: {len(CALENDAR_TYPE_TRANSLATIONS)}")
    print(f"每个类型: 12 语言")

if __name__ == '__main__':
    update_calendar_names()
