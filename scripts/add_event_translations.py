#!/usr/bin/env python3
"""
补全事件视图中的翻译
"""

import json
from pathlib import Path

# 事件视图的翻译
EVENT_TRANSLATIONS = {
    # 相对日期
    "date.today": {
        "zh-Hans": "今天",
        "zh-Hant": "今天",
        "en": "Today",
        "ar": "اليوم",
        "he": "היום",
        "ja": "今日",
        "ko": "오늘",
        "vi": "Hôm nay",
        "fa": "امروز",
        "th": "วันนี้",
        "tr": "Bugün",
        "ur": "آج"
    },
    "date.tomorrow": {
        "zh-Hans": "明天",
        "zh-Hant": "明天",
        "en": "Tomorrow",
        "ar": "غداً",
        "he": "מחר",
        "ja": "明日",
        "ko": "내일",
        "vi": "Ngày mai",
        "fa": "فردا",
        "th": "พรุ่งนี้",
        "tr": "Yarın",
        "ur": "کل"
    },
    "date.yesterday": {
        "zh-Hans": "昨天",
        "zh-Hant": "昨天",
        "en": "Yesterday",
        "ar": "أمس",
        "he": "אתמול",
        "ja": "昨日",
        "ko": "어제",
        "vi": "Hôm qua",
        "fa": "دیروز",
        "th": "เมื่อวานนี้",
        "tr": "Dün",
        "ur": "کل"
    },

    # 星期格式
    "date.week_number": {
        "zh-Hans": "第 %d 周",
        "zh-Hant": "第 %d 週",
        "en": "Week %d",
        "ar": "الأسبوع %d",
        "he": "שבוע %d",
        "ja": "第%d週",
        "ko": "%d주차",
        "vi": "Tuần %d",
        "fa": "هفته %d",
        "th": "สัปดาห์ที่ %d",
        "tr": "%d. Hafta",
        "ur": "ہفتہ %d"
    },

    # 事件数量
    "event.count": {
        "zh-Hans": "%d 个事件",
        "zh-Hant": "%d 個事件",
        "en": "%d events",
        "ar": "%d أحداث",
        "he": "%d אירועים",
        "ja": "%d件のイベント",
        "ko": "%d개 이벤트",
        "vi": "%d sự kiện",
        "fa": "%d رویداد",
        "th": "%d กิจกรรม",
        "tr": "%d etkinlik",
        "ur": "%d ایونٹس"
    },

    # 事件输入
    "event.title_placeholder": {
        "zh-Hans": "事件标题",
        "zh-Hant": "事件標題",
        "en": "Event Title",
        "ar": "عنوان الحدث",
        "he": "כותרת אירוע",
        "ja": "イベントタイトル",
        "ko": "이벤트 제목",
        "vi": "Tiêu đề sự kiện",
        "fa": "عنوان رویداد",
        "th": "ชื่อกิจกรรม",
        "tr": "Etkinlik Başlığı",
        "ur": "ایونٹ کا عنوان"
    },
    "event.add_location": {
        "zh-Hans": "添加位置",
        "zh-Hant": "新增位置",
        "en": "Add Location",
        "ar": "إضافة موقع",
        "he": "הוסף מיקום",
        "ja": "場所を追加",
        "ko": "위치 추가",
        "vi": "Thêm vị trí",
        "fa": "افزودن مکان",
        "th": "เพิ่มสถานที่",
        "tr": "Konum Ekle",
        "ur": "مقام شامل کریں"
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

    print("\n🔄 更新事件视图翻译...")
    for key, translations in EVENT_TRANSLATIONS.items():
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
    backup_path = xcstrings_path.with_suffix('.xcstrings.backup_events')
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"💾 创建备份: {backup_path}")

    # 保存
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("✅ 事件视图翻译更新完成!")
    print("="*60)
    print(f"新增键: {added} 个")
    print(f"更新翻译: {updated} 个")

if __name__ == '__main__':
    update_localizable()
