#!/usr/bin/env python3
"""
添加所有剩余的翻译内容
"""

import json
from pathlib import Path

# 所有需要添加的翻译
COMPREHENSIVE_TRANSLATIONS = {
    # 主题名称（16个主题）
    "theme.classic_blue": {
        "zh-Hans": "经典蓝",
        "zh-Hant": "經典藍",
        "en": "Classic Blue",
        "ar": "الأزرق الكلاسيكي",
        "he": "כחול קלאסי",
        "ja": "クラシックブルー",
        "ko": "클래식 블루",
        "vi": "Xanh cổ điển",
        "fa": "آبی کلاسیک",
        "th": "สีน้ำเงินคลาสสิก",
        "tr": "Klasik Mavi",
        "ur": "کلاسک بلیو"
    },
    "theme.ocean_teal": {
        "zh-Hans": "海洋青",
        "zh-Hant": "海洋青",
        "en": "Ocean Teal",
        "ar": "الفيروزي المحيطي",
        "he": "טורקיז אוקיינוס",
        "ja": "オーシャンティール",
        "ko": "오션 틸",
        "vi": "Xanh ngọc đại dương",
        "fa": "فیروزه‌ای اقیانوس",
        "th": "สีฟ้าทะเล",
        "tr": "Okyanus Camgöbeği",
        "ur": "سمندری نیلا"
    },
    "theme.forest_green": {
        "zh-Hans": "翠绿森林",
        "zh-Hant": "翠綠森林",
        "en": "Forest Green",
        "ar": "الأخضر الغابي",
        "he": "ירוק יער",
        "ja": "フォレストグリーン",
        "ko": "포레스트 그린",
        "vi": "Xanh rừng",
        "fa": "سبز جنگلی",
        "th": "สีเขียวป่า",
        "tr": "Orman Yeşili",
        "ur": "جنگل کا سبز"
    },
    "theme.sunset_orange": {
        "zh-Hans": "阳光橙",
        "zh-Hant": "陽光橙",
        "en": "Sunset Orange",
        "ar": "البرتقالي الغروب",
        "he": "כתום שקיעה",
        "ja": "サンセットオレンジ",
        "ko": "선셋 오렌지",
        "vi": "Cam hoàng hôn",
        "fa": "نارنجی غروب",
        "th": "สีส้มพระอาทิตย์ตก",
        "tr": "Gün Batımı Turuncu",
        "ur": "غروب کا نارنجی"
    },
    "theme.rose_pink": {
        "zh-Hans": "玫瑰粉",
        "zh-Hant": "玫瑰粉",
        "en": "Rose Pink",
        "ar": "الوردي الوردي",
        "he": "ורוד ורד",
        "ja": "ローズピンク",
        "ko": "로즈 핑크",
        "vi": "Hồng hoa hồng",
        "fa": "صورتی گلی",
        "th": "สีชมพูกุหลาบ",
        "tr": "Gül Pembesi",
        "ur": "گلابی گلاب"
    },
    "theme.lavender_purple": {
        "zh-Hans": "薰衣草紫",
        "zh-Hant": "薰衣草紫",
        "en": "Lavender Purple",
        "ar": "البنفسجي الخزامى",
        "he": "סגול לבנדר",
        "ja": "ラベンダーパープル",
        "ko": "라벤더 퍼플",
        "vi": "Tím hoa oải hương",
        "fa": "بنفش اسطوخودوس",
        "th": "สีม่วงลาเวนเดอร์",
        "tr": "Lavanta Moru",
        "ur": "لیوینڈر جامنی"
    },
    "theme.sky_blue": {
        "zh-Hans": "天空蓝",
        "zh-Hant": "天空藍",
        "en": "Sky Blue",
        "ar": "الأزرق السماوي",
        "he": "כחול שמיים",
        "ja": "スカイブルー",
        "ko": "스카이 블루",
        "vi": "Xanh trời",
        "fa": "آبی آسمانی",
        "th": "สีฟ้าท้องฟ้า",
        "tr": "Gök Mavisi",
        "ur": "آسمانی نیلا"
    },
    "theme.neutral_gray": {
        "zh-Hans": "中性灰",
        "zh-Hant": "中性灰",
        "en": "Neutral Gray",
        "ar": "الرمادي المحايد",
        "he": "אפור נייטרלי",
        "ja": "ニュートラルグレー",
        "ko": "뉴트럴 그레이",
        "vi": "Xám trung tính",
        "fa": "خاکستری خنثی",
        "th": "สีเทากลาง",
        "tr": "Nötr Gri",
        "ur": "غیر جانبدار سرمئی"
    },
    "theme.midnight_blue": {
        "zh-Hans": "午夜蓝",
        "zh-Hant": "午夜藍",
        "en": "Midnight Blue",
        "ar": "الأزرق منتصف الليل",
        "he": "כחול חצות",
        "ja": "ミッドナイトブルー",
        "ko": "미드나이트 블루",
        "vi": "Xanh nửa đêm",
        "fa": "آبی نیمه‌شب",
        "th": "สีน้ำเงินเที่ยงคืน",
        "tr": "Gece Yarısı Mavisi",
        "ur": "آدھی رات کا نیلا"
    },
    "theme.deep_teal": {
        "zh-Hans": "深海青",
        "zh-Hant": "深海青",
        "en": "Deep Teal",
        "ar": "الفيروزي العميق",
        "he": "טורקיז עמוק",
        "ja": "ディープティール",
        "ko": "딥 틸",
        "vi": "Xanh ngọc đậm",
        "fa": "فیروزه‌ای تیره",
        "th": "สีฟ้าเข้ม",
        "tr": "Koyu Camgöbeği",
        "ur": "گہرا نیلا"
    },
    "theme.dark_green": {
        "zh-Hans": "暗夜绿",
        "zh-Hant": "暗夜綠",
        "en": "Dark Green",
        "ar": "الأخضر الداكن",
        "he": "ירוק כהה",
        "ja": "ダークグリーン",
        "ko": "다크 그린",
        "vi": "Xanh tối",
        "fa": "سبز تیره",
        "th": "สีเขียวเข้ม",
        "tr": "Koyu Yeşil",
        "ur": "گہرا سبز"
    },
    "theme.amber_orange": {
        "zh-Hans": "琥珀橙",
        "zh-Hant": "琥珀橙",
        "en": "Amber Orange",
        "ar": "البرتقالي الكهرماني",
        "he": "כתום ענבר",
        "ja": "アンバーオレンジ",
        "ko": "앰버 오렌지",
        "vi": "Cam hổ phách",
        "fa": "نارنجی کهربایی",
        "th": "สีส้มอำพัน",
        "tr": "Kehribar Turuncu",
        "ur": "کہربا نارنجی"
    },
    "theme.dark_magenta": {
        "zh-Hans": "暗紫红",
        "zh-Hant": "暗紫紅",
        "en": "Dark Magenta",
        "ar": "الأرجواني الداكن",
        "he": "מגנטה כהה",
        "ja": "ダークマゼンタ",
        "ko": "다크 마젠타",
        "vi": "Tím đỏ tối",
        "fa": "ارغوانی تیره",
        "th": "สีม่วงแดงเข้ม",
        "tr": "Koyu Macenta",
        "ur": "گہرا جامنی"
    },
    "theme.deep_purple": {
        "zh-Hans": "深邃紫",
        "zh-Hant": "深邃紫",
        "en": "Deep Purple",
        "ar": "البنفسجي العميق",
        "he": "סגול עמוק",
        "ja": "ディープパープル",
        "ko": "딥 퍼플",
        "vi": "Tím đậm",
        "fa": "بنفش عمیق",
        "th": "สีม่วงเข้ม",
        "tr": "Koyu Mor",
        "ur": "گہرا جامنی"
    },
    "theme.indigo_purple": {
        "zh-Hans": "靛蓝紫",
        "zh-Hant": "靛藍紫",
        "en": "Indigo Purple",
        "ar": "البنفسجي النيلي",
        "he": "סגול אינדיגו",
        "ja": "インディゴパープル",
        "ko": "인디고 퍼플",
        "vi": "Tím chàm",
        "fa": "بنفش نیلی",
        "th": "สีม่วงครามท่า",
        "tr": "Çivit Moru",
        "ur": "نیلا جامنی"
    },
    "theme.graphite_gray": {
        "zh-Hans": "石墨灰",
        "zh-Hant": "石墨灰",
        "en": "Graphite Gray",
        "ar": "الرمادي الجرافيت",
        "he": "אפור גרפיט",
        "ja": "グラファイトグレー",
        "ko": "그래파이트 그레이",
        "vi": "Xám than chì",
        "fa": "خاکستری گرافیتی",
        "th": "สีเทาแกรไฟต์",
        "tr": "Grafit Gri",
        "ur": "گریفائٹ سرمئی"
    },

    # MenuBarFormat 菜单栏格式
    "menubar_format.date_only": {
        "zh-Hans": "仅日期",
        "zh-Hant": "僅日期",
        "en": "Date Only",
        "ar": "التاريخ فقط",
        "he": "תאריך בלבד",
        "ja": "日付のみ",
        "ko": "날짜만",
        "vi": "Chỉ ngày",
        "fa": "فقط تاریخ",
        "th": "วันที่เท่านั้น",
        "tr": "Yalnızca Tarih",
        "ur": "صرف تاریخ"
    },
    "menubar_format.time_only": {
        "zh-Hans": "仅时间",
        "zh-Hant": "僅時間",
        "en": "Time Only",
        "ar": "الوقت فقط",
        "he": "שעה בלבד",
        "ja": "時刻のみ",
        "ko": "시간만",
        "vi": "Chỉ giờ",
        "fa": "فقط زمان",
        "th": "เวลาเท่านั้น",
        "tr": "Yalnızca Saat",
        "ur": "صرف وقت"
    },
    "menubar_format.date_time": {
        "zh-Hans": "日期+时间",
        "zh-Hant": "日期+時間",
        "en": "Date + Time",
        "ar": "التاريخ + الوقت",
        "he": "תאריך + שעה",
        "ja": "日付+時刻",
        "ko": "날짜 + 시간",
        "vi": "Ngày + Giờ",
        "fa": "تاریخ + زمان",
        "th": "วันที่ + เวลา",
        "tr": "Tarih + Saat",
        "ur": "تاریخ + وقت"
    },
    "menubar_format.custom": {
        "zh-Hans": "自定义",
        "zh-Hant": "自定義",
        "en": "Custom",
        "ar": "مخصص",
        "he": "מותאם אישית",
        "ja": "カスタム",
        "ko": "사용자 정의",
        "vi": "Tùy chỉnh",
        "fa": "سفارشی",
        "th": "กำหนดเอง",
        "tr": "Özel",
        "ur": "حسب ضرورت"
    },

    # 订阅状态
    "sync_status.syncing": {
        "zh-Hans": "同步中",
        "zh-Hant": "同步中",
        "en": "Syncing",
        "ar": "جاري المزامنة",
        "he": "מסנכרן",
        "ja": "同期中",
        "ko": "동기화 중",
        "vi": "Đang đồng bộ",
        "fa": "در حال همگام‌سازی",
        "th": "กำลังซิงค์",
        "tr": "Senkronize Ediliyor",
        "ur": "ہم وقت سازی میں"
    },
    "sync_status.success": {
        "zh-Hans": "成功",
        "zh-Hant": "成功",
        "en": "Success",
        "ar": "نجح",
        "he": "הצליח",
        "ja": "成功",
        "ko": "성공",
        "vi": "Thành công",
        "fa": "موفق",
        "th": "สำเร็จ",
        "tr": "Başarılı",
        "ur": "کامیاب"
    },
    "sync_status.failed": {
        "zh-Hans": "失败",
        "zh-Hant": "失敗",
        "en": "Failed",
        "ar": "فشل",
        "he": "נכשל",
        "ja": "失敗",
        "ko": "실패",
        "vi": "Thất bại",
        "fa": "ناموفق",
        "th": "ล้มเหลว",
        "tr": "Başarısız",
        "ur": "ناکام"
    },

    # 周几（用于主题预览）
    "weekday.sun": {
        "zh-Hans": "日",
        "zh-Hant": "日",
        "en": "Sun",
        "ar": "الأحد",
        "he": "א׳",
        "ja": "日",
        "ko": "일",
        "vi": "CN",
        "fa": "ی",
        "th": "อา",
        "tr": "Paz",
        "ur": "اتوار"
    },
    "weekday.mon": {
        "zh-Hans": "一",
        "zh-Hant": "一",
        "en": "Mon",
        "ar": "الإثنين",
        "he": "ב׳",
        "ja": "月",
        "ko": "월",
        "vi": "T2",
        "fa": "د",
        "th": "จ",
        "tr": "Pzt",
        "ur": "پیر"
    },
    "weekday.tue": {
        "zh-Hans": "二",
        "zh-Hant": "二",
        "en": "Tue",
        "ar": "الثلاثاء",
        "he": "ג׳",
        "ja": "火",
        "ko": "화",
        "vi": "T3",
        "fa": "س",
        "th": "อ",
        "tr": "Sal",
        "ur": "منگل"
    },
    "weekday.wed": {
        "zh-Hans": "三",
        "zh-Hant": "三",
        "en": "Wed",
        "ar": "الأربعاء",
        "he": "ד׳",
        "ja": "水",
        "ko": "수",
        "vi": "T4",
        "fa": "چ",
        "th": "พ",
        "tr": "Çar",
        "ur": "بدھ"
    },
    "weekday.thu": {
        "zh-Hans": "四",
        "zh-Hant": "四",
        "en": "Thu",
        "ar": "الخميس",
        "he": "ה׳",
        "ja": "木",
        "ko": "목",
        "vi": "T5",
        "fa": "پ",
        "th": "พฤ",
        "tr": "Per",
        "ur": "جمعرات"
    },
    "weekday.fri": {
        "zh-Hans": "五",
        "zh-Hant": "五",
        "en": "Fri",
        "ar": "الجمعة",
        "he": "ו׳",
        "ja": "金",
        "ko": "금",
        "vi": "T6",
        "fa": "ج",
        "th": "ศ",
        "tr": "Cum",
        "ur": "جمعہ"
    },
    "weekday.sat": {
        "zh-Hans": "六",
        "zh-Hant": "六",
        "en": "Sat",
        "ar": "السبت",
        "he": "ש׳",
        "ja": "土",
        "ko": "토",
        "vi": "T7",
        "fa": "ش",
        "th": "ส",
        "tr": "Cmt",
        "ur": "ہفتہ"
    },

    # 删除确认对话框
    "confirm.delete_local_group": {
        "zh-Hans": "确定要删除这个本地日历组吗？",
        "zh-Hant": "確定要刪除這個本地日曆組嗎？",
        "en": "Are you sure you want to delete this local calendar group?",
        "ar": "هل أنت متأكد من حذف مجموعة التقويم المحلية هذه؟",
        "he": "האם אתה בטוח שברצונך למחוק את קבוצת היומן המקומית הזו?",
        "ja": "このローカルカレンダーグループを削除してもよろしいですか？",
        "ko": "이 로컬 캘린더 그룹을 삭제하시겠습니까?",
        "vi": "Bạn có chắc chắn muốn xóa nhóm lịch cục bộ này không?",
        "fa": "آیا مطمئن هستید که می‌خواهید این گروه تقویم محلی را حذف کنید؟",
        "th": "คุณแน่ใจหรือไม่ว่าต้องการลบกลุ่มปฏิทินนี้?",
        "tr": "Bu yerel takvim grubunu silmek istediğinizden emin misiniz?",
        "ur": "کیا آپ واقعی اس مقامی کیلنڈر گروپ کو حذف کرنا چاہتے ہیں؟"
    },
    "confirm.delete": {
        "zh-Hans": "删除",
        "zh-Hant": "刪除",
        "en": "Delete",
        "ar": "حذف",
        "he": "מחק",
        "ja": "削除",
        "ko": "삭제",
        "vi": "Xóa",
        "fa": "حذف",
        "th": "ลบ",
        "tr": "Sil",
        "ur": "حذف کریں"
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

    print("\n🔄 添加全面翻译...")
    for key, translations in COMPREHENSIVE_TRANSLATIONS.items():
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
    print("✅ 全面翻译添加完成!")
    print("="*60)
    print(f"更新翻译: {updated} 个")
    print(f"翻译键数: {len(COMPREHENSIVE_TRANSLATIONS)} 个")

if __name__ == '__main__':
    update_localizable()
