#!/usr/bin/env python3
"""
添加自动语言选项的翻译
"""

import json
from pathlib import Path

# 自动语言选项的翻译
AUTO_LANGUAGE_TRANSLATIONS = {
    "settings.language.auto": {
        "zh-Hans": "自动（跟随系统）",
        "zh-Hant": "自動（跟隨系統）",
        "en": "Auto (Follow System)",
        "ar": "تلقائي (اتبع النظام)",
        "he": "אוטומטי (עקוב אחר המערכת)",
        "ja": "自動（システムに従う）",
        "ko": "자동 (시스템 따라가기)",
        "vi": "Tự động (Theo hệ thống)",
        "fa": "خودکار (پیروی از سیستم)",
        "th": "อัตโนมัติ (ตามระบบ)",
        "tr": "Otomatik (Sistemi Takip Et)",
        "ur": "خودکار (سسٹم کی پیروی کریں)"
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

    print("\n🔄 更新自动语言翻译...")
    for key, translations in AUTO_LANGUAGE_TRANSLATIONS.items():
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
    print("✅ 自动语言翻译更新完成!")
    print("="*60)
    print(f"更新翻译: {updated} 个")

if __name__ == '__main__':
    update_localizable()
