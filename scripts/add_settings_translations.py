#!/usr/bin/env python3
"""
添加设置界面所有未翻译选项的翻译
"""

import json
from pathlib import Path

# 所有需要添加的翻译
SETTINGS_TRANSLATIONS = {
    # CalendarSize 面板尺寸
    "size.compact": {
        "zh-Hans": "紧凑",
        "zh-Hant": "緊湊",
        "en": "Compact",
        "ar": "مضغوط",
        "he": "קומפקטי",
        "ja": "コンパクト",
        "ko": "작게",
        "vi": "Nhỏ gọn",
        "fa": "فشرده",
        "th": "กะทัดรัด",
        "tr": "Kompakt",
        "ur": "کمپیکٹ"
    },
    "size.standard": {
        "zh-Hans": "标准",
        "zh-Hant": "標準",
        "en": "Standard",
        "ar": "قياسي",
        "he": "סטנדרטי",
        "ja": "標準",
        "ko": "표준",
        "vi": "Tiêu chuẩn",
        "fa": "استاندارد",
        "th": "มาตรฐาน",
        "tr": "Standart",
        "ur": "معیاری"
    },
    "size.large": {
        "zh-Hans": "大号",
        "zh-Hant": "大號",
        "en": "Large",
        "ar": "كبير",
        "he": "גדול",
        "ja": "大",
        "ko": "크게",
        "vi": "Lớn",
        "fa": "بزرگ",
        "th": "ใหญ่",
        "tr": "Büyük",
        "ur": "بڑا"
    },
    "size.xlarge": {
        "zh-Hans": "超大",
        "zh-Hant": "超大",
        "en": "Extra Large",
        "ar": "كبير جداً",
        "he": "גדול במיוחד",
        "ja": "特大",
        "ko": "매우 크게",
        "vi": "Rất lớn",
        "fa": "بسیار بزرگ",
        "th": "ใหญ่พิเศษ",
        "tr": "Çok Büyük",
        "ur": "بہت بڑا"
    },

    # ThemeMode 主题模式
    "theme_mode.light": {
        "zh-Hans": "浅色",
        "zh-Hant": "淺色",
        "en": "Light",
        "ar": "فاتح",
        "he": "בהיר",
        "ja": "ライト",
        "ko": "라이트",
        "vi": "Sáng",
        "fa": "روشن",
        "th": "สว่าง",
        "tr": "Açık",
        "ur": "ہلکا"
    },
    "theme_mode.auto": {
        "zh-Hans": "自动",
        "zh-Hant": "自動",
        "en": "Auto",
        "ar": "تلقائي",
        "he": "אוטומטי",
        "ja": "自動",
        "ko": "자동",
        "vi": "Tự động",
        "fa": "خودکار",
        "th": "อัตโนมัติ",
        "tr": "Otomatik",
        "ur": "خودکار"
    },
    "theme_mode.dark": {
        "zh-Hans": "深色",
        "zh-Hant": "深色",
        "en": "Dark",
        "ar": "داكن",
        "he": "כהה",
        "ja": "ダーク",
        "ko": "다크",
        "vi": "Tối",
        "fa": "تیره",
        "th": "มืด",
        "tr": "Koyu",
        "ur": "گہرا"
    },

    # ThemeMode descriptions
    "theme_mode.light.description": {
        "zh-Hans": "始终使用浅色主题，适合在明亮环境下使用",
        "zh-Hant": "始終使用淺色主題，適合在明亮環境下使用",
        "en": "Always use light theme, suitable for bright environments",
        "ar": "استخدم دائماً المظهر الفاتح، مناسب للبيئات المضيئة",
        "he": "השתמש תמיד בערכת נושא בהירה, מתאים לסביבות בהירות",
        "ja": "常にライトテーマを使用、明るい環境に適しています",
        "ko": "항상 라이트 테마 사용, 밝은 환경에 적합",
        "vi": "Luôn sử dụng chủ đề sáng, phù hợp cho môi trường sáng",
        "fa": "همیشه از تم روشن استفاده کنید، مناسب برای محیط های روشن",
        "th": "ใช้ธีมสว่างเสมอ เหมาะสำหรับสภาพแวดล้อมที่สว่าง",
        "tr": "Her zaman açık tema kullan, parlak ortamlar için uygundur",
        "ur": "ہمیشہ ہلکا تھیم استعمال کریں، روشن ماحول کے لیے موزوں"
    },
    "theme_mode.auto.description": {
        "zh-Hans": "跟随 macOS 系统外观自动切换",
        "zh-Hant": "跟隨 macOS 系統外觀自動切換",
        "en": "Automatically switch following macOS system appearance",
        "ar": "التبديل التلقائي باتباع مظهر نظام macOS",
        "he": "החלף אוטומטית בהתאם למראה מערכת macOS",
        "ja": "macOS システムの外観に従って自動的に切り替え",
        "ko": "macOS 시스템 외관에 따라 자동 전환",
        "vi": "Tự động chuyển đổi theo giao diện hệ thống macOS",
        "fa": "تغییر خودکار با پیروی از ظاهر سیستم macOS",
        "th": "สลับอัตโนมัติตามรูปลักษณ์ระบบ macOS",
        "tr": "macOS sistem görünümünü takip ederek otomatik geçiş yap",
        "ur": "macOS سسٹم ظہور کی پیروی کرتے ہوئے خودکار سوئچ"
    },
    "theme_mode.dark.description": {
        "zh-Hans": "始终使用深色主题，适合在昏暗环境或夜间使用",
        "zh-Hant": "始終使用深色主題，適合在昏暗環境或夜間使用",
        "en": "Always use dark theme, suitable for dim environments or nighttime",
        "ar": "استخدم دائماً المظهر الداكن، مناسب للبيئات المعتمة أو الليل",
        "he": "השתמש תמיד בערכת נושא כהה, מתאים לסביבות עמומות או שימוש לילי",
        "ja": "常にダークテーマを使用、暗い環境や夜間に適しています",
        "ko": "항상 다크 테마 사용, 어두운 환경이나 야간에 적합",
        "vi": "Luôn sử dụng chủ đề tối, phù hợp cho môi trường tối hoặc ban đêm",
        "fa": "همیشه از تم تیره استفاده کنید، مناسب برای محیط های کم نور یا شب",
        "th": "ใช้ธีมมืดเสมอ เหมาะสำหรับสภาพแวดล้อมที่มืดหรือเวลากลางคืน",
        "tr": "Her zaman koyu tema kullan, karanlık ortamlar veya gece için uygundur",
        "ur": "ہمیشہ گہرا تھیم استعمال کریں، مدھم ماحول یا رات کے لیے موزوں"
    },

    # 其他设置文本
    "settings.reset_theme": {
        "zh-Hans": "重置为默认主题（自动模式 + 经典蓝/午夜蓝）",
        "zh-Hant": "重置為默認主題（自動模式 + 經典藍/午夜藍）",
        "en": "Reset to default theme (Auto mode + Classic Blue/Midnight Blue)",
        "ar": "إعادة تعيين إلى المظهر الافتراضي (الوضع التلقائي + الأزرق الكلاسيكي/أزرق منتصف الليل)",
        "he": "אפס לערכת נושא ברירת מחדל (מצב אוטומטי + כחול קלאסי/כחול חצות)",
        "ja": "デフォルトテーマにリセット（自動モード + クラシックブルー/ミッドナイトブルー）",
        "ko": "기본 테마로 재설정 (자동 모드 + 클래식 블루/미드나이트 블루)",
        "vi": "Đặt lại về chủ đề mặc định (Chế độ tự động + Xanh cổ điển/Xanh nửa đêm)",
        "fa": "بازنشانی به تم پیش‌فرض (حالت خودکار + آبی کلاسیک/آبی نیمه‌شب)",
        "th": "รีเซ็ตเป็นธีมเริ่มต้น (โหมดอัตโนมัติ + สีน้ำเงินคลาสสิก/สีน้ำเงินเที่ยงคืน)",
        "tr": "Varsayılan temaya sıfırla (Otomatik mod + Klasik Mavi/Gece Yarısı Mavisi)",
        "ur": "ڈیفالٹ تھیم پر ری سیٹ کریں (خودکار موڈ + کلاسک بلیو/مڈ نائٹ بلیو)"
    },
    "settings.theme_auto_switch": {
        "zh-Hans": "💡 系统外观变化时，将自动切换到对应模式下您选择的主题",
        "zh-Hant": "💡 系統外觀變化時，將自動切換到對應模式下您選擇的主題",
        "en": "💡 When system appearance changes, it will automatically switch to your selected theme for that mode",
        "ar": "💡 عندما يتغير مظهر النظام، سيتم التبديل تلقائياً إلى المظهر المحدد لهذا الوضع",
        "he": "💡 כאשר מראה המערכת משתנה, זה יעבור אוטומטית לערכת הנושא שבחרת עבור מצב זה",
        "ja": "💡 システム外観が変更されると、そのモードで選択したテーマに自動的に切り替わります",
        "ko": "💡 시스템 외관이 변경되면 해당 모드에서 선택한 테마로 자동 전환됩니다",
        "vi": "💡 Khi giao diện hệ thống thay đổi, sẽ tự động chuyển sang chủ đề đã chọn cho chế độ đó",
        "fa": "💡 هنگامی که ظاهر سیستم تغییر می‌کند، به‌طور خودکار به تم انتخابی شما برای آن حالت تغییر می‌کند",
        "th": "💡 เมื่อรูปลักษณ์ระบบเปลี่ยนแปลง จะสลับไปยังธีมที่คุณเลือกสำหรับโหมดนั้นโดยอัตโนมัติ",
        "tr": "💡 Sistem görünümü değiştiğinde, o mod için seçtiğiniz temaya otomatik olarak geçecektir",
        "ur": "💡 جب سسٹم کی ظاہری شکل تبدیل ہوتی ہے، تو یہ خودکار طور پر اس موڈ کے لیے آپ کے منتخب کردہ تھیم میں سوئچ ہو جائے گا"
    },
    "settings.size_description": {
        "zh-Hans": "比例",
        "zh-Hant": "比例",
        "en": "Ratio",
        "ar": "النسبة",
        "he": "יחס",
        "ja": "比率",
        "ko": "비율",
        "vi": "Tỷ lệ",
        "fa": "نسبت",
        "th": "อัตราส่วน",
        "tr": "Oran",
        "ur": "تناسب"
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

    print("\n🔄 添加设置翻译...")
    for key, translations in SETTINGS_TRANSLATIONS.items():
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

    # 保存
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("✅ 设置翻译添加完成!")
    print("="*60)
    print(f"更新翻译: {updated} 个")
    print(f"翻译键数: {len(SETTINGS_TRANSLATIONS)} 个")

if __name__ == '__main__':
    update_localizable()
