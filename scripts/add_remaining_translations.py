#!/usr/bin/env python3
"""
添加剩余的翻译键
"""

import json
import sys
from pathlib import Path

# 翻译数据
TRANSLATIONS = {
    "calendar_source.subscribed": {
        "zh-Hans": "订阅的日历",
        "zh-Hant": "訂閱的日曆",
        "en": "Subscribed Calendars",
        "ar": "التقويمات المشتركة",
        "he": "לוחות שנה מנויים",
        "ja": "購読カレンダー",
        "ko": "구독한 캘린더",
        "vi": "Lịch đã đăng ký",
        "fa": "تقویم‌های اشتراکی",
        "th": "ปฏิทินที่สมัครสมาชิก",
        "tr": "Abone Olunan Takvimler",
        "ur": "سبسکرائب شدہ کیلنڈرز"
    },
    "calendar_source.other": {
        "zh-Hans": "其他",
        "zh-Hant": "其他",
        "en": "Other",
        "ar": "أخرى",
        "he": "אחר",
        "ja": "その他",
        "ko": "기타",
        "vi": "Khác",
        "fa": "سایر",
        "th": "อื่นๆ",
        "tr": "Diğer",
        "ur": "دیگر"
    },
    "calendar_source.default": {
        "zh-Hans": "默认",
        "zh-Hant": "預設",
        "en": "Default",
        "ar": "افتراضي",
        "he": "ברירת מחדל",
        "ja": "デフォルト",
        "ko": "기본값",
        "vi": "Mặc định",
        "fa": "پیش‌فرض",
        "th": "ค่าเริ่มต้น",
        "tr": "Varsayılan",
        "ur": "ڈیفالٹ"
    },
    "calendar_source.birthdays": {
        "zh-Hans": "生日",
        "zh-Hant": "生日",
        "en": "Birthdays",
        "ar": "أعياد الميلاد",
        "he": "ימי הולדת",
        "ja": "誕生日",
        "ko": "생일",
        "vi": "Sinh nhật",
        "fa": "تولدها",
        "th": "วันเกิด",
        "tr": "Doğum Günleri",
        "ur": "سالگرہ"
    },
    "local_group.default_name": {
        "zh-Hans": "默认",
        "zh-Hant": "預設",
        "en": "Default",
        "ar": "افتراضي",
        "he": "ברירת מחדל",
        "ja": "デフォルト",
        "ko": "기본값",
        "vi": "Mặc định",
        "fa": "پیش‌فرض",
        "th": "ค่าเริ่มต้น",
        "tr": "Varsayılan",
        "ur": "ڈیفالٹ"
    }
}

def add_translations():
    # 定位 Localizable.xcstrings 文件
    xcstrings_path = Path(__file__).parent.parent / "MiniCal" / "Resources" / "Localizations" / "Localizable.xcstrings"

    if not xcstrings_path.exists():
        print(f"❌ 找不到文件: {xcstrings_path}")
        return False

    # 读取现有内容
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 添加翻译
    strings = data.get("strings", {})
    added_count = 0

    for key, translations in TRANSLATIONS.items():
        if key in strings:
            print(f"⚠️  跳过已存在的键: {key}")
            continue

        # 创建翻译条目
        localizations = {}
        for locale, text in translations.items():
            localizations[locale] = {
                "stringUnit": {
                    "state": "translated",
                    "value": text
                }
            }

        strings[key] = {
            "localizations": localizations
        }
        added_count += 1
        print(f"✅ 添加翻译键: {key}")

    # 保存回文件
    data["strings"] = strings
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 成功添加 {added_count} 个翻译键")
    return True

if __name__ == "__main__":
    success = add_translations()
    sys.exit(0 if success else 1)
