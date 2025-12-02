#!/usr/bin/env python3
"""
修复permission相关翻译键的缺失语言
"""

import json
import sys
from pathlib import Path

# 需要补充的翻译数据
TRANSLATIONS = {
    "permission.calendar.open_settings": {
        "zh-Hans": "打开系统设置",
        "zh-Hant": "打開系統設定",
        "en": "Open System Settings",
        "ar": "فتح إعدادات النظام",
        "he": "פתח הגדרות מערכת",
        "ja": "システム設定を開く",
        "ko": "시스템 설정 열기",
        "vi": "Mở Cài đặt Hệ thống",
        "fa": "باز کردن تنظیمات سیستم",
        "th": "เปิดการตั้งค่าระบบ",
        "tr": "Sistem Ayarlarını Aç",
        "ur": "سسٹم کی ترتیبات کھولیں"
    },
    "permission.calendar.request": {
        "zh-Hans": "请求权限",
        "zh-Hant": "請求權限",
        "en": "Request Permission",
        "ar": "طلب الإذن",
        "he": "בקש הרשאה",
        "ja": "権限をリクエスト",
        "ko": "권한 요청",
        "vi": "Yêu cầu Quyền",
        "fa": "درخواست مجوز",
        "th": "ขอสิทธิ์",
        "tr": "İzin İste",
        "ur": "اجازت کی درخواست کریں"
    }
}

def fix_translations():
    # 定位 Localizable.xcstrings 文件
    xcstrings_path = Path(__file__).parent.parent / "MiniCal" / "Resources" / "Localizations" / "Localizable.xcstrings"

    if not xcstrings_path.exists():
        print(f"❌ 找不到文件: {xcstrings_path}")
        return False

    # 读取现有内容
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    strings = data.get("strings", {})
    fixed_count = 0

    for key, translations in TRANSLATIONS.items():
        if key not in strings:
            print(f"⚠️  翻译键不存在，跳过: {key}")
            continue

        # 获取现有的localizations
        existing_localizations = strings[key].get("localizations", {})

        # 补充缺失的语言
        for locale, text in translations.items():
            if locale not in existing_localizations:
                existing_localizations[locale] = {
                    "stringUnit": {
                        "state": "translated",
                        "value": text
                    }
                }
                print(f"✅ 为 {key} 添加 {locale} 翻译: {text}")
                fixed_count += 1
            else:
                # 更新已有翻译（确保格式正确）
                existing_value = existing_localizations[locale].get("stringUnit", {}).get("value", "")
                if existing_value != text:
                    existing_localizations[locale]["stringUnit"]["value"] = text
                    existing_localizations[locale]["stringUnit"]["state"] = "translated"
                    print(f"🔄 更新 {key} 的 {locale} 翻译: {text}")
                    fixed_count += 1

        # 更新localizations
        strings[key]["localizations"] = existing_localizations

    # 保存回文件
    data["strings"] = strings
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 成功修复/更新 {fixed_count} 个翻译条目")
    return True

if __name__ == "__main__":
    success = fix_translations()
    sys.exit(0 if success else 1)
