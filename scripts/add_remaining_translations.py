#!/usr/bin/env python3
"""
为剩余组件添加完整的12语言翻译
"""

import json
from pathlib import Path

# 剩余组件的完整翻译映射
ADDITIONAL_TRANSLATIONS = {
    # Calendar Events
    "calendar.today_events": {
        "zh-Hans": "今日事件",
        "zh-Hant": "今日事件",
        "en": "Today's Events",
        "ar": "أحداث اليوم",
        "he": "אירועי היום",
        "ja": "今日のイベント",
        "ko": "오늘의 이벤트",
        "vi": "Sự kiện hôm nay",
        "fa": "رویدادهای امروز",
        "th": "เหตุการณ์วันนี้",
        "tr": "Bugünün Etkinlikleri",
        "ur": "آج کے واقعات"
    },
    "calendar.no_events": {
        "zh-Hans": "暂无事件",
        "zh-Hant": "暫無事件",
        "en": "No Events",
        "ar": "لا توجد أحداث",
        "he": "אין אירועים",
        "ja": "イベントなし",
        "ko": "이벤트 없음",
        "vi": "Không có sự kiện",
        "fa": "رویدادی وجود ندارد",
        "th": "ไม่มีเหตุการณ์",
        "tr": "Etkinlik Yok",
        "ur": "کوئی واقعات نہیں"
    },
    "calendar.no_events_today": {
        "zh-Hans": "这天没有事件",
        "zh-Hant": "這天沒有事件",
        "en": "No Events Today",
        "ar": "لا توجد أحداث اليوم",
        "he": "אין אירועים היום",
        "ja": "今日はイベントがありません",
        "ko": "오늘 이벤트 없음",
        "vi": "Không có sự kiện hôm nay",
        "fa": "امروز رویدادی ندارد",
        "th": "วันนี้ไม่มีเหตุการณ์",
        "tr": "Bugün Etkinlik Yok",
        "ur": "آج کوئی واقعات نہیں"
    },
    "calendar.enjoy_day": {
        "zh-Hans": "享受轻松的一天",
        "zh-Hant": "享受輕鬆的一天",
        "en": "Enjoy a relaxing day",
        "ar": "استمتع بيوم مريح",
        "he": "תיהנה מיום רגוע",
        "ja": "リラックスした一日をお楽しみください",
        "ko": "편안한 하루 보내세요",
        "vi": "Tận hưởng một ngày thư giãn",
        "fa": "از یک روز آرام لذت ببرید",
        "th": "เพลิดเพลินกับวันที่ผ่อนคลาย",
        "tr": "Rahat bir günün tadını çıkarın",
        "ur": "آرام دن سے لطف اندوز ہوں"
    },
    "event.all_day": {
        "zh-Hans": "全天",
        "zh-Hant": "全天",
        "en": "All Day",
        "ar": "طوال اليوم",
        "he": "כל היום",
        "ja": "終日",
        "ko": "종일",
        "vi": "Cả ngày",
        "fa": "تمام روز",
        "th": "ตลอดวัน",
        "tr": "Tüm Gün",
        "ur": "پورا دن"
    },
    "event.multi_day": {
        "zh-Hans": "多日",
        "zh-Hant": "多日",
        "en": "Multi-day",
        "ar": "متعدد الأيام",
        "he": "מספר ימים",
        "ja": "複数日",
        "ko": "여러 날",
        "vi": "Nhiều ngày",
        "fa": "چند روزه",
        "th": "หลายวัน",
        "tr": "Çok Günlü",
        "ur": "کئی دن"
    },
    "event.time": {
        "zh-Hans": "时间",
        "zh-Hant": "時間",
        "en": "Time",
        "ar": "الوقت",
        "he": "זמן",
        "ja": "時間",
        "ko": "시간",
        "vi": "Thời gian",
        "fa": "زمان",
        "th": "เวลา",
        "tr": "Zaman",
        "ur": "وقت"
    },
    "event.location": {
        "zh-Hans": "地点",
        "zh-Hant": "地點",
        "en": "Location",
        "ar": "الموقع",
        "he": "מיקום",
        "ja": "場所",
        "ko": "위치",
        "vi": "Địa điểm",
        "fa": "مکان",
        "th": "สถานที่",
        "tr": "Konum",
        "ur": "مقام"
    },
    "event.notes": {
        "zh-Hans": "备注",
        "zh-Hant": "備註",
        "en": "Notes",
        "ar": "ملاحظات",
        "he": "הערות",
        "ja": "メモ",
        "ko": "메모",
        "vi": "Ghi chú",
        "fa": "یادداشت‌ها",
        "th": "หมายเหตุ",
        "tr": "Notlar",
        "ur": "نوٹس"
    },
    "event.attendees": {
        "zh-Hans": "参与者",
        "zh-Hant": "參與者",
        "en": "Attendees",
        "ar": "الحاضرون",
        "he": "משתתפים",
        "ja": "参加者",
        "ko": "참석자",
        "vi": "Người tham dự",
        "fa": "شرکت‌کنندگان",
        "th": "ผู้เข้าร่วม",
        "tr": "Katılımcılar",
        "ur": "شرکاء"
    },
    "event.title": {
        "zh-Hans": "事件标题",
        "zh-Hant": "事件標題",
        "en": "Event Title",
        "ar": "عنوان الحدث",
        "he": "כותרת אירוע",
        "ja": "イベントタイトル",
        "ko": "이벤트 제목",
        "vi": "Tiêu đề sự kiện",
        "fa": "عنوان رویداد",
        "th": "ชื่อเหตุการณ์",
        "tr": "Etkinlik Başlığı",
        "ur": "واقعہ کا عنوان"
    },
    "event.loading": {
        "zh-Hans": "加载事件中...",
        "zh-Hant": "載入事件中...",
        "en": "Loading Events...",
        "ar": "تحميل الأحداث...",
        "he": "טוען אירועים...",
        "ja": "イベントを読み込んでいます...",
        "ko": "이벤트 로딩 중...",
        "vi": "Đang tải sự kiện...",
        "fa": "در حال بارگذاری رویدادها...",
        "th": "กำลังโหลดเหตุการณ์...",
        "tr": "Etkinlikler Yükleniyor...",
        "ur": "واقعات لوڈ ہو رہے ہیں..."
    },
    "event.load_failed": {
        "zh-Hans": "加载失败",
        "zh-Hant": "載入失敗",
        "en": "Load Failed",
        "ar": "فشل التحميل",
        "he": "הטעינה נכשלה",
        "ja": "読み込み失敗",
        "ko": "로드 실패",
        "vi": "Tải thất bại",
        "fa": "بارگذاری ناموفق",
        "th": "โหลดล้มเหลว",
        "tr": "Yükleme Başarısız",
        "ur": "لوڈ ناکام"
    },
    "event.start_time": {
        "zh-Hans": "开始时间",
        "zh-Hant": "開始時間",
        "en": "Start Time",
        "ar": "وقت البدء",
        "he": "זמן התחלה",
        "ja": "開始時刻",
        "ko": "시작 시간",
        "vi": "Thời gian bắt đầu",
        "fa": "زمان شروع",
        "th": "เวลาเริ่มต้น",
        "tr": "Başlangıç Zamanı",
        "ur": "شروع کا وقت"
    },
    "event.end_time": {
        "zh-Hans": "结束时间",
        "zh-Hant": "結束時間",
        "en": "End Time",
        "ar": "وقت الانتهاء",
        "he": "זמן סיום",
        "ja": "終了時刻",
        "ko": "종료 시간",
        "vi": "Thời gian kết thúc",
        "fa": "زمان پایان",
        "th": "เวลาสิ้นสุด",
        "tr": "Bitiş Zamanı",
        "ur": "ختم کا وقت"
    },

    # Event Creation/Edit
    "event.add": {
        "zh-Hans": "添加事件",
        "zh-Hant": "添加事件",
        "en": "Add Event",
        "ar": "إضافة حدث",
        "he": "הוסף אירוע",
        "ja": "イベントを追加",
        "ko": "이벤트 추가",
        "vi": "Thêm sự kiện",
        "fa": "افزودن رویداد",
        "th": "เพิ่มเหตุการณ์",
        "tr": "Etkinlik Ekle",
        "ur": "واقعہ شامل کریں"
    },
    "event.manage_subscription": {
        "zh-Hans": "管理订阅",
        "zh-Hant": "管理訂閱",
        "en": "Manage Subscriptions",
        "ar": "إدارة الاشتراكات",
        "he": "נהל מינויים",
        "ja": "サブスクリプションを管理",
        "ko": "구독 관리",
        "vi": "Quản lý đăng ký",
        "fa": "مدیریت اشتراک‌ها",
        "th": "จัดการการสมัครสมาชิก",
        "tr": "Abonelikleri Yönet",
        "ur": "رکنیتوں کا انتظام کریں"
    },
    "event.title_label": {
        "zh-Hans": "标题",
        "zh-Hant": "標題",
        "en": "Title",
        "ar": "العنوان",
        "he": "כותרת",
        "ja": "タイトル",
        "ko": "제목",
        "vi": "Tiêu đề",
        "fa": "عنوان",
        "th": "ชื่อเรื่อง",
        "tr": "Başlık",
        "ur": "عنوان"
    },
    "event.start": {
        "zh-Hans": "开始",
        "zh-Hant": "開始",
        "en": "Start",
        "ar": "البداية",
        "he": "התחלה",
        "ja": "開始",
        "ko": "시작",
        "vi": "Bắt đầu",
        "fa": "شروع",
        "th": "เริ่มต้น",
        "tr": "Başlangıç",
        "ur": "شروع"
    },
    "event.end": {
        "zh-Hans": "结束",
        "zh-Hant": "結束",
        "en": "End",
        "ar": "النهاية",
        "he": "סיום",
        "ja": "終了",
        "ko": "종료",
        "vi": "Kết thúc",
        "fa": "پایان",
        "th": "สิ้นสุด",
        "tr": "Bitiş",
        "ur": "ختم"
    },
    "event.end_after_start": {
        "zh-Hans": "结束时间必须晚于开始时间",
        "zh-Hant": "結束時間必須晚於開始時間",
        "en": "End time must be after start time",
        "ar": "يجب أن يكون وقت الانتهاء بعد وقت البدء",
        "he": "זמן הסיום חייב להיות אחרי זמן ההתחלה",
        "ja": "終了時刻は開始時刻より後である必要があります",
        "ko": "종료 시간은 시작 시간 이후여야 합니다",
        "vi": "Thời gian kết thúc phải sau thời gian bắt đầu",
        "fa": "زمان پایان باید بعد از زمان شروع باشد",
        "th": "เวลาสิ้นสุดต้องหลังเวลาเริ่มต้น",
        "tr": "Bitiş zamanı başlangıç zamanından sonra olmalıdır",
        "ur": "ختم کا وقت شروع کے وقت کے بعد ہونا چاہیے"
    },
    "event.location_optional": {
        "zh-Hans": "位置（可选）",
        "zh-Hant": "位置（可選）",
        "en": "Location (Optional)",
        "ar": "الموقع (اختياري)",
        "he": "מיקום (אופציונלי)",
        "ja": "場所（任意）",
        "ko": "위치 (선택 사항)",
        "vi": "Địa điểm (Tùy chọn)",
        "fa": "مکان (اختیاری)",
        "th": "สถานที่ (ไม่บังคับ)",
        "tr": "Konum (İsteğe Bağlı)",
        "ur": "مقام (اختیاری)"
    },
    "event.notes_optional": {
        "zh-Hans": "备注（可选）",
        "zh-Hant": "備註（可選）",
        "en": "Notes (Optional)",
        "ar": "ملاحظات (اختياري)",
        "he": "הערות (אופציונלי)",
        "ja": "メモ（任意）",
        "ko": "메모 (선택 사항)",
        "vi": "Ghi chú (Tùy chọn)",
        "fa": "یادداشت (اختیاری)",
        "th": "หมายเหตุ (ไม่บังคับ)",
        "tr": "Notlar (İsteğe Bağlı)",
        "ur": "نوٹس (اختیاری)"
    },
    "event.save": {
        "zh-Hans": "保存",
        "zh-Hant": "保存",
        "en": "Save",
        "ar": "حفظ",
        "he": "שמור",
        "ja": "保存",
        "ko": "저장",
        "vi": "Lưu",
        "fa": "ذخیره",
        "th": "บันทึก",
        "tr": "Kaydet",
        "ur": "محفوظ کریں"
    },

    # Subscription Manager
    "subscription.manager_title": {
        "zh-Hans": "日历订阅管理",
        "zh-Hant": "日曆訂閱管理",
        "en": "Calendar Subscription Manager",
        "ar": "مدير اشتراك التقويم",
        "he": "מנהל מינויי לוח שנה",
        "ja": "カレンダーサブスクリプションマネージャー",
        "ko": "달력 구독 관리자",
        "vi": "Quản lý đăng ký lịch",
        "fa": "مدیر اشتراک تقویم",
        "th": "ตัวจัดการการสมัครสมาชิกปฏิทิน",
        "tr": "Takvim Abonelik Yöneticisi",
        "ur": "کیلنڈر رکنیت منتظم"
    },
    "subscription.no_subscriptions": {
        "zh-Hans": "还没有订阅任何日历",
        "zh-Hant": "還沒有訂閱任何日曆",
        "en": "No Calendar Subscriptions Yet",
        "ar": "لا توجد اشتراكات تقويم بعد",
        "he": "עדיין אין מינויי לוח שנה",
        "ja": "まだカレンダーサブスクリプションがありません",
        "ko": "아직 달력 구독이 없습니다",
        "vi": "Chưa có đăng ký lịch nào",
        "fa": "هنوز اشتراک تقویمی وجود ندارد",
        "th": "ยังไม่มีการสมัครสมาชิกปฏิทิน",
        "tr": "Henüz Takvim Aboneliği Yok",
        "ur": "ابھی تک کوئی کیلنڈر رکنیت نہیں"
    },
    "subscription.add_to_view": {
        "zh-Hans": "添加外部日历订阅来查看更多事件",
        "zh-Hant": "添加外部日曆訂閱來查看更多事件",
        "en": "Add external calendar subscriptions to view more events",
        "ar": "أضف اشتراكات تقويم خارجية لعرض المزيد من الأحداث",
        "he": "הוסף מינויי לוח שנה חיצוניים כדי לראות עוד אירועים",
        "ja": "外部カレンダーサブスクリプションを追加して、さらに多くのイベントを表示",
        "ko": "더 많은 이벤트를 보려면 외부 달력 구독 추가",
        "vi": "Thêm đăng ký lịch bên ngoài để xem thêm sự kiện",
        "fa": "اشتراک‌های تقویم خارجی را اضافه کنید تا رویدادهای بیشتری ببینید",
        "th": "เพิ่มการสมัครสมาชิกปฏิทินภายนอกเพื่อดูเหตุการณ์เพิ่มเติม",
        "tr": "Daha fazla etkinlik görmek için harici takvim abonelikleri ekleyin",
        "ur": "مزید واقعات دیکھنے کے لیے بیرونی کیلنڈر رکنیتیں شامل کریں"
    },
    "subscription.add_button": {
        "zh-Hans": "添加日历订阅",
        "zh-Hant": "添加日曆訂閱",
        "en": "Add Calendar Subscription",
        "ar": "إضافة اشتراك تقويم",
        "he": "הוסף מינוי לוח שנה",
        "ja": "カレンダーサブスクリプションを追加",
        "ko": "달력 구독 추가",
        "vi": "Thêm đăng ký lịch",
        "fa": "افزودن اشتراک تقویم",
        "th": "เพิ่มการสมัครสมาชิกปฏิทิน",
        "tr": "Takvim Aboneliği Ekle",
        "ur": "کیلنڈر رکنیت شامل کریں"
    },
    "subscription.url_input_placeholder": {
        "zh-Hans": "输入外部日历的URL地址",
        "zh-Hant": "輸入外部日曆的URL地址",
        "en": "Enter external calendar URL",
        "ar": "أدخل عنوان URL للتقويم الخارجي",
        "he": "הזן כתובת URL של לוח שנה חיצוני",
        "ja": "外部カレンダーのURLを入力",
        "ko": "외부 달력 URL 입력",
        "vi": "Nhập URL lịch bên ngoài",
        "fa": "آدرس URL تقویم خارجی را وارد کنید",
        "th": "ป้อน URL ปฏิทินภายนอก",
        "tr": "Harici takvim URL'sini girin",
        "ur": "بیرونی کیلنڈر کا URL درج کریں"
    },
    "subscription.calendar_url": {
        "zh-Hans": "日历URL",
        "zh-Hant": "日曆URL",
        "en": "Calendar URL",
        "ar": "عنوان URL للتقويم",
        "he": "כתובת URL של לוח שנה",
        "ja": "カレンダーURL",
        "ko": "달력 URL",
        "vi": "URL lịch",
        "fa": "آدرس URL تقویم",
        "th": "URL ปฏิทิน",
        "tr": "Takvim URL'si",
        "ur": "کیلنڈر URL"
    },
    "subscription.common_services": {
        "zh-Hans": "常见日历服务",
        "zh-Hant": "常見日曆服務",
        "en": "Common Calendar Services",
        "ar": "خدمات التقويم الشائعة",
        "he": "שירותי לוח שנה נפוצים",
        "ja": "一般的なカレンダーサービス",
        "ko": "일반 달력 서비스",
        "vi": "Dịch vụ lịch phổ biến",
        "fa": "سرویس‌های رایج تقویم",
        "th": "บริการปฏิทินทั่วไป",
        "tr": "Yaygın Takvim Hizmetleri",
        "ur": "عام کیلنڈر خدمات"
    },
    "subscription.refresh_all_button": {
        "zh-Hans": "全部刷新",
        "zh-Hant": "全部刷新",
        "en": "Refresh All",
        "ar": "تحديث الكل",
        "he": "רענן הכל",
        "ja": "すべて更新",
        "ko": "모두 새로 고침",
        "vi": "Làm mới tất cả",
        "fa": "به‌روزرسانی همه",
        "th": "รีเฟรชทั้งหมด",
        "tr": "Tümünü Yenile",
        "ur": "سب کو تازہ کریں"
    },

    # Location & Weather
    "location.enable_for_sunset": {
        "zh-Hans": "启用位置，显示日出日落信息",
        "zh-Hant": "啟用位置，顯示日出日落信息",
        "en": "Enable location to show sunrise and sunset times",
        "ar": "تمكين الموقع لإظهار أوقات شروق الشمس وغروبها",
        "he": "אפשר מיקום כדי להציג זמני זריחה ושקיעה",
        "ja": "位置情報を有効にして日の出と日の入りの時刻を表示",
        "ko": "위치를 활성화하여 일출 및 일몰 시간 표시",
        "vi": "Bật vị trí để hiển thị thời gian mặt trời mọc và lặn",
        "fa": "مکان را فعال کنید تا زمان طلوع و غروب خورشید نمایش داده شود",
        "th": "เปิดใช้งานตำแหน่งเพื่อแสดงเวลาพระอาทิตย์ขึ้นและตก",
        "tr": "Gün doğumu ve gün batımı zamanlarını göstermek için konumu etkinleştirin",
        "ur": "سورج طلوع اور غروب کے اوقات دکھانے کے لیے مقام فعال کریں"
    },
    "location.fetching": {
        "zh-Hans": "获取位置中...",
        "zh-Hant": "獲取位置中...",
        "en": "Fetching Location...",
        "ar": "جارٍ جلب الموقع...",
        "he": "מאחזר מיקום...",
        "ja": "位置情報を取得中...",
        "ko": "위치 가져오는 중...",
        "vi": "Đang lấy vị trí...",
        "fa": "در حال دریافت مکان...",
        "th": "กำลังดึงข้อมูลตำแหน่ง...",
        "tr": "Konum Getiriliyor...",
        "ur": "مقام حاصل کر رہا ہے..."
    },

    # Misc
    "misc.url": {
        "zh-Hans": "URL",
        "zh-Hant": "URL",
        "en": "URL",
        "ar": "URL",
        "he": "URL",
        "ja": "URL",
        "ko": "URL",
        "vi": "URL",
        "fa": "URL",
        "th": "URL",
        "tr": "URL",
        "ur": "URL"
    },
    "misc.default": {
        "zh-Hans": "默认",
        "zh-Hant": "默認",
        "en": "Default",
        "ar": "افتراضي",
        "he": "ברירת מחדל",
        "ja": "デフォルト",
        "ko": "기본값",
        "vi": "Mặc định",
        "fa": "پیش‌فرض",
        "th": "ค่าเริ่มต้น",
        "tr": "Varsayılan",
        "ur": "طے شدہ"
    },
    "misc.shortcut": {
        "zh-Hans": "快捷键",
        "zh-Hant": "快捷鍵",
        "en": "Shortcut",
        "ar": "اختصار",
        "he": "קיצור דרך",
        "ja": "ショートカット",
        "ko": "단축키",
        "vi": "Phím tắt",
        "fa": "میانبر",
        "th": "ทางลัด",
        "tr": "Kısayol",
        "ur": "شارٹ کٹ"
    }
}

def add_translations():
    """添加翻译到 Localizable.xcstrings"""
    project_root = Path(__file__).parent.parent
    xcstrings_path = project_root / 'MiniCal/Resources/Localizations/Localizable.xcstrings'

    print("📖 读取 Localizable.xcstrings...")
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'strings' not in data:
        data['strings'] = {}

    added = 0
    updated = 0

    print("\n🔄 添加翻译...")
    for key, translations in ADDITIONAL_TRANSLATIONS.items():
        if key not in data['strings']:
            data['strings'][key] = {'localizations': {}}
            added += 1

        # 添加或更新翻译
        for locale, value in translations.items():
            if locale not in data['strings'][key].get('localizations', {}):
                if 'localizations' not in data['strings'][key]:
                    data['strings'][key]['localizations'] = {}

                data['strings'][key]['localizations'][locale] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': value
                    }
                }
                updated += 1

    # 备份
    backup_path = xcstrings_path.with_suffix('.xcstrings.backup4')
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"💾 创建备份: {backup_path}")

    # 保存
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("✅ 翻译添加完成!")
    print("="*60)
    print(f"新增键: {added}")
    print(f"更新翻译: {updated}")
    print(f"总翻译数: {len(ADDITIONAL_TRANSLATIONS)} 键 × 12 语言 = {len(ADDITIONAL_TRANSLATIONS) * 12} 翻译")

if __name__ == '__main__':
    add_translations()
