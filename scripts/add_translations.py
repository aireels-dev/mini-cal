#!/usr/bin/env python3
"""
批量添加12语言翻译到 Localizable.xcstrings
"""

import json
from pathlib import Path

# 翻译映射：键 -> {语言: 翻译}
TRANSLATIONS = {
    # Settings - Language
    "settings.language.section": {
        "zh-Hans": "语言",
        "zh-Hant": "語言",
        "en": "Language",
        "ar": "اللغة",
        "he": "שפה",
        "ja": "言語",
        "ko": "언어",
        "vi": "Ngôn ngữ",
        "fa": "زبان",
        "th": "ภาษา",
        "tr": "Dil",
        "ur": "زبان"
    },
    "settings.language.interface": {
        "zh-Hans": "界面语言",
        "zh-Hant": "介面語言",
        "en": "Interface Language",
        "ar": "لغة الواجهة",
        "he": "שפת הממשק",
        "ja": "インターフェース言語",
        "ko": "인터페이스 언어",
        "vi": "Ngôn ngữ giao diện",
        "fa": "زبان رابط کاربری",
        "th": "ภาษาอินเทอร์เฟซ",
        "tr": "Arayüz Dili",
        "ur": "انٹرفیس کی زبان"
    },
    "settings.language.description": {
        "zh-Hans": "设置菜单栏、设置界面和UI元素的显示语言",
        "zh-Hant": "設定選單欄、設定介面和UI元素的顯示語言",
        "en": "Set the display language for menu bar, settings, and UI elements",
        "ar": "تعيين لغة العرض لشريط القوائم والإعدادات وعناصر واجهة المستخدم",
        "he": "הגדר את שפת התצוגה עבור שורת התפריט, ההגדרות ורכיבי ממשק המשתמש",
        "ja": "メニューバー、設定、UI要素の表示言語を設定します",
        "ko": "메뉴바, 설정 및 UI 요素의 표시 언어 설정",
        "vi": "Đặt ngôn ngữ hiển thị cho thanh menu, cài đặt và các phần tử giao diện",
        "fa": "تنظیم زبان نمایش برای نوار منو، تنظیمات و عناصر رابط کاربری",
        "th": "ตั้งค่าภาษาที่แสดงสำหรับแถบเมนู การตั้งค่า และองค์ประกอบ UI",
        "tr": "Menü çubuğu, ayarlar ve kullanıcı arayüzü öğeleri için görüntüleme dilini ayarlayın",
        "ur": "مینو بار، ترتیبات اور UI عناصر کے لیے ڈسپلے زبان مقرر کریں"
    },

    # Settings - Calendar
    "settings.calendar.secondary": {
        "zh-Hans": "本地历法",
        "zh-Hant": "本地曆法",
        "en": "Secondary Calendar",
        "ar": "التقويم الثانوي",
        "he": "לוח שנה משני",
        "ja": "セカンダリカレンダー",
        "ko": "보조 달력",
        "vi": "Lịch phụ",
        "fa": "تقویم ثانویه",
        "th": "ปฏิทินรอง",
        "tr": "İkincil Takvim",
        "ur": "ثانوی کیلنڈر"
    },
    "settings.calendar.type": {
        "zh-Hans": "历法类型",
        "zh-Hant": "曆法類型",
        "en": "Calendar Type",
        "ar": "نوع التقويم",
        "he": "סוג לוח שנה",
        "ja": "カレンダーの種類",
        "ko": "달력 유형",
        "vi": "Loại lịch",
        "fa": "نوع تقویم",
        "th": "ประเภทปฏิทิน",
        "tr": "Takvim Türü",
        "ur": "کیلنڈر کی قسم"
    },
    "settings.calendar.none": {
        "zh-Hans": "不显示",
        "zh-Hant": "不顯示",
        "en": "None",
        "ar": "لا شيء",
        "he": "ללא",
        "ja": "なし",
        "ko": "없음",
        "vi": "Không",
        "fa": "هیچ",
        "th": "ไม่มี",
        "tr": "Yok",
        "ur": "کوئی نہیں"
    },
    "settings.calendar.description": {
        "zh-Hans": "在公历日期下方显示本地历法",
        "zh-Hant": "在公曆日期下方顯示本地曆法",
        "en": "Display secondary calendar below Gregorian date",
        "ar": "عرض التقويم الثانوي أسفل التاريخ الميلادي",
        "he": "הצג לוח שנה משני מתחת לתאריך הגרגוריאני",
        "ja": "グレゴリオ暦の下にセカンダリカレンダーを表示",
        "ko": "그레고리력 날짜 아래에 보조 달력 표시",
        "vi": "Hiển thị lịch phụ bên dưới ngày Dương lịch",
        "fa": "نمایش تقویم ثانویه در زیر تاریخ میلادی",
        "th": "แสดงปฏิทินรองด้านล่างวันที่ปฏิทินเกรกอเรียน",
        "tr": "Miladi tarihin altında ikincil takvimi göster",
        "ur": "عیسوی تاریخ کے نیچے ثانوی کیلنڈر دکھائیں"
    },
    "settings.calendar.system_sync": {
        "zh-Hans": "系统同步",
        "zh-Hant": "系統同步",
        "en": "System Sync",
        "ar": "مزامنة النظام",
        "he": "סנכרון מערכת",
        "ja": "システム同期",
        "ko": "시스템 동기화",
        "vi": "Đồng bộ hệ thống",
        "fa": "همگام‌سازی سیستم",
        "th": "ซิงค์ระบบ",
        "tr": "Sistem Senkronizasyonu",
        "ur": "نظام کی مطابقت"
    },
    "settings.calendar.external_subscriptions": {
        "zh-Hans": "外部订阅",
        "zh-Hant": "外部訂閱",
        "en": "External Subscriptions",
        "ar": "الاشتراكات الخارجية",
        "he": "מינויים חיצוניים",
        "ja": "外部サブスクリプション",
        "ko": "외부 구독",
        "vi": "Đăng ký ngoài",
        "fa": "اشتراک‌های خارجی",
        "th": "การสมัครสมาชิกภายนอก",
        "tr": "Harici Abonelikler",
        "ur": "بیرونی رکنیتیں"
    },
    "settings.calendar.local_management": {
        "zh-Hans": "本地管理",
        "zh-Hant": "本地管理",
        "en": "Local Management",
        "ar": "الإدارة المحلية",
        "he": "ניהול מקומי",
        "ja": "ローカル管理",
        "ko": "로컬 관리",
        "vi": "Quản lý cục bộ",
        "fa": "مدیریت محلی",
        "th": "การจัดการท้องถิ่น",
        "tr": "Yerel Yönetim",
        "ur": "مقامی انتظام"
    },

    # Settings - Appearance
    "settings.appearance.panel_size": {
        "zh-Hans": "面板大小",
        "zh-Hant": "面板大小",
        "en": "Panel Size",
        "ar": "حجم اللوحة",
        "he": "גודל פאנל",
        "ja": "パネルサイズ",
        "ko": "패널 크기",
        "vi": "Kích thước bảng điều khiển",
        "fa": "اندازه پنل",
        "th": "ขนาดแผง",
        "tr": "Panel Boyutu",
        "ur": "پینل کا سائز"
    },
    "settings.appearance.size_level": {
        "zh-Hans": "尺寸档位",
        "zh-Hant": "尺寸檔位",
        "en": "Size Level",
        "ar": "مستوى الحجم",
        "he": "רמת גודל",
        "ja": "サイズレベル",
        "ko": "크기 수준",
        "vi": "Mức kích thước",
        "fa": "سطح اندازه",
        "th": "ระดับขนาด",
        "tr": "Boyut Seviyesi",
        "ur": "سائز کی سطح"
    },
    "settings.appearance.current_size": {
        "zh-Hans": "当前尺寸：",
        "zh-Hant": "當前尺寸：",
        "en": "Current Size:",
        "ar": "الحجم الحالي:",
        "he": "גודל נוכחי:",
        "ja": "現在のサイズ：",
        "ko": "현재 크기:",
        "vi": "Kích thước hiện tại:",
        "fa": "اندازه فعلی:",
        "th": "ขนาดปัจจุบัน:",
        "tr": "Mevcut Boyut:",
        "ur": "موجودہ سائز:"
    },
    "settings.appearance.cell_size": {
        "zh-Hans": "单元格大小：",
        "zh-Hant": "單元格大小：",
        "en": "Cell Size:",
        "ar": "حجم الخلية:",
        "he": "גודל תא:",
        "ja": "セルサイズ：",
        "ko": "셀 크기:",
        "vi": "Kích thước ô:",
        "fa": "اندازه سلول:",
        "th": "ขนาดเซลล์:",
        "tr": "Hücre Boyutu:",
        "ur": "خلیے کا سائز:"
    },
    "settings.appearance.opacity": {
        "zh-Hans": "浮窗透明度",
        "zh-Hant": "浮窗透明度",
        "en": "Window Opacity",
        "ar": "شفافية النافذة",
        "he": "שקיפות חלון",
        "ja": "ウィンドウの透明度",
        "ko": "창 불투명도",
        "vi": "Độ mờ cửa sổ",
        "fa": "شفافیت پنجره",
        "th": "ความทึบของหน้าต่าง",
        "tr": "Pencere Saydamlığı",
        "ur": "ونڈو کی شفافیت"
    },
    "settings.appearance.opacity_label": {
        "zh-Hans": "不透明度",
        "zh-Hant": "不透明度",
        "en": "Opacity",
        "ar": "عدم الشفافية",
        "he": "אטימות",
        "ja": "不透明度",
        "ko": "불투명도",
        "vi": "Độ mờ",
        "fa": "کدری",
        "th": "ความทึบ",
        "tr": "Opaklık",
        "ur": "دھندلاپن"
    },
    "settings.appearance.more_transparent": {
        "zh-Hans": "更透明",
        "zh-Hant": "更透明",
        "en": "More Transparent",
        "ar": "أكثر شفافية",
        "he": "שקוף יותר",
        "ja": "より透明",
        "ko": "더 투명하게",
        "vi": "Trong suốt hơn",
        "fa": "شفاف‌تر",
        "th": "โปร่งใสมากขึ้น",
        "tr": "Daha Saydam",
        "ur": "مزید شفاف"
    },
    "settings.appearance.more_opaque": {
        "zh-Hans": "更不透明",
        "zh-Hant": "更不透明",
        "en": "More Opaque",
        "ar": "أكثر عتامة",
        "he": "אטום יותר",
        "ja": "より不透明",
        "ko": "더 불투명하게",
        "vi": "Mờ hơn",
        "fa": "کدرتر",
        "th": "ทึบมากขึ้น",
        "tr": "Daha Opak",
        "ur": "مزید دھندلا"
    },
    "settings.appearance.theme": {
        "zh-Hans": "主题",
        "zh-Hant": "主題",
        "en": "Theme",
        "ar": "الموضوع",
        "he": "ערכת נושא",
        "ja": "テーマ",
        "ko": "테마",
        "vi": "Chủ đề",
        "fa": "تم",
        "th": "ธีม",
        "tr": "Tema",
        "ur": "تھیم"
    },
    "settings.appearance.reset": {
        "zh-Hans": "重置",
        "zh-Hant": "重置",
        "en": "Reset",
        "ar": "إعادة تعيين",
        "he": "איפוס",
        "ja": "リセット",
        "ko": "재설정",
        "vi": "Đặt lại",
        "fa": "بازنشانی",
        "th": "รีเซ็ต",
        "tr": "Sıfırla",
        "ur": "دوبارہ ترتیب دیں"
    },

    # Permissions
    "permission.calendar.required": {
        "zh-Hans": "需要访问日历权限",
        "zh-Hant": "需要訪問日曆權限",
        "en": "Calendar Access Required",
        "ar": "مطلوب الوصول إلى التقويم",
        "he": "נדרשת גישה ללוח שנה",
        "ja": "カレンダーアクセスが必要",
        "ko": "달력 접근 권한 필요",
        "vi": "Cần quyền truy cập lịch",
        "fa": "دسترسی به تقویم مورد نیاز است",
        "th": "ต้องการสิทธิ์เข้าถึงปฏิทิน",
        "tr": "Takvim Erişimi Gerekli",
        "ur": "کیلنڈر تک رسائی درکار ہے"
    },
    "permission.calendar.description": {
        "zh-Hans": "授权后可同步 iCloud 和本地日历的事件",
        "zh-Hant": "授權後可同步 iCloud 和本地日曆的事件",
        "en": "Sync iCloud and local calendar events after authorization",
        "ar": "مزامنة أحداث iCloud والتقويم المحلي بعد التفويض",
        "he": "סנכרן אירועי iCloud ולוח שנה מקומי לאחר אישור",
        "ja": "承認後、iCloudとローカルカレンダーのイベントを同期",
        "ko": "승인 후 iCloud 및 로컬 달력 이벤트 동기화",
        "vi": "Đồng bộ sự kiện iCloud và lịch cục bộ sau khi ủy quyền",
        "fa": "همگام‌سازی رویدادهای iCloud و تقویم محلی پس از مجوز",
        "th": "ซิงค์เหตุการณ์ iCloud และปฏิทินท้องถิ่นหลังจากได้รับอนุญาต",
        "tr": "Yetkilendirme sonrası iCloud ve yerel takvim etkinliklerini senkronize et",
        "ur": "اجازت کے بعد iCloud اور مقامی کیلنڈر کے واقعات کو مطابقت دیں"
    },
    "permission.calendar.hint": {
        "zh-Hans": "提示:点击按钮将打开系统设置,在「隐私与安全性」>「日历」中授权",
        "zh-Hant": "提示:點擊按鈕將打開系統設定,在「隱私與安全性」>「日曆」中授權",
        "en": "Tip: Click button to open System Settings and authorize in Privacy & Security > Calendar",
        "ar": "تلميح: انقر فوق الزر لفتح إعدادات النظام والتفويض في الخصوصية والأمان > التقويم",
        "he": "טיפ: לחץ על הכפתור לפתיחת הגדרות מערכת ואשר בפרטיות ואבטחה > לוח שנה",
        "ja": "ヒント：ボタンをクリックしてシステム設定を開き、プライバシーとセキュリティ > カレンダーで承認",
        "ko": "팁: 버튼을 클릭하여 시스템 설정을 열고 개인 정보 보호 및 보안 > 달력에서 승인",
        "vi": "Mẹo: Nhấp vào nút để mở Cài đặt Hệ thống và ủy quyền trong Quyền riêng tư & Bảo mật > Lịch",
        "fa": "نکته: برای باز کردن تنظیمات سیستم و مجوز در حریم خصوصی و امنیت > تقویم روی دکمه کلیک کنید",
        "th": "เคล็ดลับ: คลิกปุ่มเพื่อเปิดการตั้งค่าระบบและอนุญาตในความเป็นส่วนตัวและความปลอดภัย > ปฏิทิน",
        "tr": "İpucu: Sistem Ayarlarını açmak ve Gizlilik ve Güvenlik > Takvim'de yetkilendirmek için düğmeye tıklayın",
        "ur": "تجویز: نظام کی ترتیبات کھولنے اور رازداری اور سیکورٹی > کیلنڈر میں اجازت دینے کے لیے بٹن پر کلک کریں"
    },

    # Subscriptions
    "subscription.add": {
        "zh-Hans": "添加订阅",
        "zh-Hant": "添加訂閱",
        "en": "Add Subscription",
        "ar": "إضافة اشتراك",
        "he": "הוסף מינוי",
        "ja": "サブスクリプションを追加",
        "ko": "구독 추가",
        "vi": "Thêm đăng ký",
        "fa": "افزودن اشتراک",
        "th": "เพิ่มการสมัครสมาชิก",
        "tr": "Abonelik Ekle",
        "ur": "رکنیت شامل کریں"
    },
    "subscription.url": {
        "zh-Hans": "订阅 URL",
        "zh-Hant": "訂閱 URL",
        "en": "Subscription URL",
        "ar": "عنوان URL للاشتراك",
        "he": "כתובת URL למינוי",
        "ja": "サブスクリプション URL",
        "ko": "구독 URL",
        "vi": "URL đăng ký",
        "fa": "آدرس URL اشتراک",
        "th": "URL การสมัครสมาชิก",
        "tr": "Abonelik URL'si",
        "ur": "رکنیت URL"
    },
    "subscription.protocol_hint": {
        "zh-Hans": "支持 http://、https:// 和 webcal:// 协议",
        "zh-Hant": "支持 http://、https:// 和 webcal:// 協議",
        "en": "Supports http://, https://, and webcal:// protocols",
        "ar": "يدعم بروتوكولات http:// و https:// و webcal://",
        "he": "תומך בפרוטוקולים http://, https:// ו-webcal://",
        "ja": "http://、https://、webcal:// プロトコルをサポート",
        "ko": "http://, https://, webcal:// 프로토콜 지원",
        "vi": "Hỗ trợ các giao thức http://, https://, và webcal://",
        "fa": "از پروتکل‌های http://، https:// و webcal:// پشتیبانی می‌کند",
        "th": "รองรับโปรโตคอล http://, https://, และ webcal://",
        "tr": "http://, https:// ve webcal:// protokollerini destekler",
        "ur": "http://، https://، اور webcal:// پروٹوکول کو سپورٹ کرتا ہے"
    },
    "subscription.adding": {
        "zh-Hans": "正在添加订阅...",
        "zh-Hant": "正在添加訂閱...",
        "en": "Adding subscription...",
        "ar": "جارٍ إضافة الاشتراك...",
        "he": "מוסיף מינוי...",
        "ja": "サブスクリプションを追加中...",
        "ko": "구독 추가 중...",
        "vi": "Đang thêm đăng ký...",
        "fa": "در حال افزودن اشتراک...",
        "th": "กำลังเพิ่มการสมัครสมาชิก...",
        "tr": "Abonelik ekleniyor...",
        "ur": "رکنیت شامل کی جا رہی ہے..."
    },
    "subscription.downloading": {
        "zh-Hans": "正在验证并下载日历数据",
        "zh-Hant": "正在驗證並下載日曆數據",
        "en": "Verifying and downloading calendar data",
        "ar": "التحقق وتنزيل بيانات التقويم",
        "he": "מאמת ומוריד נתוני לוח שנה",
        "ja": "カレンダーデータを検証してダウンロード中",
        "ko": "달력 데이터 확인 및 다운로드 중",
        "vi": "Đang xác minh và tải xuống dữ liệu lịch",
        "fa": "در حال تأیید و دانلود داده‌های تقویم",
        "th": "กำลังตรวจสอบและดาวน์โหลดข้อมูลปฏิทิน",
        "tr": "Takvim verileri doğrulanıyor ve indiriliyor",
        "ur": "کیلنڈر ڈیٹا کی توثیق اور ڈاؤن لوڈ کر رہا ہے"
    },
    "subscription.refresh_all": {
        "zh-Hans": "刷新全部",
        "zh-Hant": "刷新全部",
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

    # Local groups
    "local_group.add": {
        "zh-Hans": "添加类别",
        "zh-Hant": "添加類別",
        "en": "Add Category",
        "ar": "إضافة فئة",
        "he": "הוסף קטגוריה",
        "ja": "カテゴリを追加",
        "ko": "카테고리 추가",
        "vi": "Thêm danh mục",
        "fa": "افزودن دسته",
        "th": "เพิ่มหมวดหมู่",
        "tr": "Kategori Ekle",
        "ur": "زمرہ شامل کریں"
    },
    "local_group.name": {
        "zh-Hans": "类别名称",
        "zh-Hant": "類別名稱",
        "en": "Category Name",
        "ar": "اسم الفئة",
        "he": "שם קטגוריה",
        "ja": "カテゴリ名",
        "ko": "카테고리 이름",
        "vi": "Tên danh mục",
        "fa": "نام دسته",
        "th": "ชื่อหมวดหมู่",
        "tr": "Kategori Adı",
        "ur": "زمرہ کا نام"
    },
    "local_group.add_title": {
        "zh-Hans": "添加本地类别",
        "zh-Hant": "添加本地類別",
        "en": "Add Local Category",
        "ar": "إضافة فئة محلية",
        "he": "הוסף קטגוריה מקומית",
        "ja": "ローカルカテゴリを追加",
        "ko": "로컬 카테고리 추가",
        "vi": "Thêm danh mục cục bộ",
        "fa": "افزودن دسته محلی",
        "th": "เพิ่มหมวดหมู่ท้องถิ่น",
        "tr": "Yerel Kategori Ekle",
        "ur": "مقامی زمرہ شامل کریں"
    },

    # Common
    "common.color": {
        "zh-Hans": "颜色",
        "zh-Hant": "顏色",
        "en": "Color",
        "ar": "اللون",
        "he": "צבע",
        "ja": "色",
        "ko": "색상",
        "vi": "Màu sắc",
        "fa": "رنگ",
        "th": "สี",
        "tr": "Renk",
        "ur": "رنگ"
    },
    "common.name": {
        "zh-Hans": "名称",
        "zh-Hant": "名稱",
        "en": "Name",
        "ar": "الاسم",
        "he": "שם",
        "ja": "名前",
        "ko": "이름",
        "vi": "Tên",
        "fa": "نام",
        "th": "ชื่อ",
        "tr": "Ad",
        "ur": "نام"
    },
    "common.note": {
        "zh-Hans": "备注",
        "zh-Hant": "備註",
        "en": "Note",
        "ar": "ملاحظة",
        "he": "הערה",
        "ja": "ノート",
        "ko": "메모",
        "vi": "Ghi chú",
        "fa": "یادداشت",
        "th": "หมายเหตุ",
        "tr": "Not",
        "ur": "نوٹ"
    },
    "common.all_day": {
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
    "common.no_events": {
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
    "common.no_system_calendars": {
        "zh-Hans": "暂无可用的系统日历",
        "zh-Hant": "暫無可用的系統日曆",
        "en": "No System Calendars Available",
        "ar": "لا توجد تقاويم نظام متاحة",
        "he": "אין לוחות שנה של מערכת זמינים",
        "ja": "利用可能なシステムカレンダーがありません",
        "ko": "사용 가능한 시스템 달력 없음",
        "vi": "Không có lịch hệ thống khả dụng",
        "fa": "تقویم سیستم در دسترس نیست",
        "th": "ไม่มีปฏิทินระบบที่พร้อมใช้งาน",
        "tr": "Kullanılabilir Sistem Takvimi Yok",
        "ur": "کوئی نظام کیلنڈر دستیاب نہیں"
    },
    "common.no_subscriptions": {
        "zh-Hans": "暂无外部订阅",
        "zh-Hant": "暫無外部訂閱",
        "en": "No External Subscriptions",
        "ar": "لا توجد اشتراكات خارجية",
        "he": "אין מינויים חיצוניים",
        "ja": "外部サブスクリプションがありません",
        "ko": "외부 구독 없음",
        "vi": "Không có đăng ký ngoài",
        "fa": "اشتراک خارجی وجود ندارد",
        "th": "ไม่มีการสมัครสมาชิกภายนอก",
        "tr": "Harici Abonelik Yok",
        "ur": "کوئی بیرونی رکنیت نہیں"
    },
    "common.arrow": {
        "zh-Hans": "→",
        "zh-Hant": "→",
        "en": "→",
        "ar": "←",  # RTL
        "he": "←",  # RTL
        "ja": "→",
        "ko": "→",
        "vi": "→",
        "fa": "←",  # RTL
        "th": "→",
        "tr": "→",
        "ur": "←"  # RTL
    },
    "common.dot": {
        "zh-Hans": "·",
        "zh-Hant": "·",
        "en": "·",
        "ar": "·",
        "he": "·",
        "ja": "·",
        "ko": "·",
        "vi": "·",
        "fa": "·",
        "th": "·",
        "tr": "·",
        "ur": "·"
    },
    "common.cancel": {
        "zh-Hans": "取消",
        "zh-Hant": "取消",
        "en": "Cancel",
        "ar": "إلغاء",
        "he": "ביטול",
        "ja": "キャンセル",
        "ko": "취소",
        "vi": "Hủy",
        "fa": "لغو",
        "th": "ยกเลิก",
        "tr": "İptal",
        "ur": "منسوخ کریں"
    },
    "common.add": {
        "zh-Hans": "添加",
        "zh-Hant": "添加",
        "en": "Add",
        "ar": "إضافة",
        "he": "הוסף",
        "ja": "追加",
        "ko": "추가",
        "vi": "Thêm",
        "fa": "افزودن",
        "th": "เพิ่ม",
        "tr": "Ekle",
        "ur": "شامل کریں"
    },

    # Events
    "event.live_preview": {
        "zh-Hans": "实时预览",
        "zh-Hant": "實時預覽",
        "en": "Live Preview",
        "ar": "معاينة مباشرة",
        "he": "תצוגה מקדימה חיה",
        "ja": "ライブプレビュー",
        "ko": "실시간 미리보기",
        "vi": "Xem trước trực tiếp",
        "fa": "پیش‌نمایش زنده",
        "th": "แสดงตัวอย่างสด",
        "tr": "Canlı Önizleme",
        "ur": "براہ راست پیش منظر"
    },
    "event.hover_delay": {
        "zh-Hans": "延迟时间",
        "zh-Hant": "延遲時間",
        "en": "Hover Delay",
        "ar": "تأخير التمرير",
        "he": "עיכוב ריחוף",
        "ja": "ホバー遅延",
        "ko": "호버 지연",
        "vi": "Độ trễ di chuột",
        "fa": "تأخیر هاور",
        "th": "ความล่าช้าเมื่อนำเมาส์ชี้",
        "tr": "Üzerine Gelme Gecikmesi",
        "ur": "ہوور تاخیر"
    },
    "event.delay": {
        "zh-Hans": "延迟",
        "zh-Hant": "延遲",
        "en": "Delay",
        "ar": "التأخير",
        "he": "עיכוב",
        "ja": "遅延",
        "ko": "지연",
        "vi": "Độ trễ",
        "fa": "تأخیر",
        "th": "ความล่าช้า",
        "tr": "Gecikme",
        "ur": "تاخیر"
    },
    "event.format_symbols": {
        "zh-Hans": "支持的格式符号：",
        "zh-Hant": "支持的格式符號：",
        "en": "Supported Format Symbols:",
        "ar": "رموز التنسيق المدعومة:",
        "he": "סמלי פורמט נתמכים:",
        "ja": "サポートされているフォーマット記号：",
        "ko": "지원되는 형식 기호:",
        "vi": "Ký hiệu định dạng được hỗ trợ:",
        "fa": "نمادهای قالب پشتیبانی شده:",
        "th": "สัญลักษณ์รูปแบบที่รองรับ:",
        "tr": "Desteklenen Format Sembolleri:",
        "ur": "معاون فارمیٹ علامات:"
    },
    "event.format_example": {
        "zh-Hans": "示例：M月d日 HH:mm → 1月15日 14:30",
        "zh-Hant": "示例：M月d日 HH:mm → 1月15日 14:30",
        "en": "Example: M/d HH:mm → 1/15 14:30",
        "ar": "مثال: M/d HH:mm ← 1/15 14:30",
        "he": "דוגמה: M/d HH:mm ← 1/15 14:30",
        "ja": "例：M/d HH:mm → 1/15 14:30",
        "ko": "예: M/d HH:mm → 1/15 14:30",
        "vi": "Ví dụ: M/d HH:mm → 1/15 14:30",
        "fa": "مثال: M/d HH:mm ← 1/15 14:30",
        "th": "ตัวอย่าง: M/d HH:mm → 1/15 14:30",
        "tr": "Örnek: M/d HH:mm → 1/15 14:30",
        "ur": "مثال: M/d HH:mm ← 1/15 14:30"
    },

    # Menu bar
    "menu_bar.title": {
        "zh-Hans": "菜单栏",
        "zh-Hant": "選單欄",
        "en": "Menu Bar",
        "ar": "شريط القوائم",
        "he": "שורת תפריט",
        "ja": "メニューバー",
        "ko": "메뉴 바",
        "vi": "Thanh menu",
        "fa": "نوار منو",
        "th": "แถบเมนู",
        "tr": "Menü Çubuğu",
        "ur": "مینو بار"
    },
    "menu_bar.calendar": {
        "zh-Hans": "日历",
        "zh-Hant": "日曆",
        "en": "Calendar",
        "ar": "التقويم",
        "he": "לוח שנה",
        "ja": "カレンダー",
        "ko": "달력",
        "vi": "Lịch",
        "fa": "تقویم",
        "th": "ปฏิทิน",
        "tr": "Takvim",
        "ur": "کیلنڈر"
    },
    "menu_bar.appearance": {
        "zh-Hans": "外观",
        "zh-Hant": "外觀",
        "en": "Appearance",
        "ar": "المظهر",
        "he": "מראה",
        "ja": "外観",
        "ko": "외관",
        "vi": "Giao diện",
        "fa": "ظاهر",
        "th": "ลักษณะ",
        "tr": "Görünüm",
        "ur": "ظاہری شکل"
    }
}

def add_translations_to_xcstrings():
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
    for key, translations in TRANSLATIONS.items():
        if key not in data['strings']:
            # 新键
            data['strings'][key] = {
                'localizations': {}
            }
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
    backup_path = xcstrings_path.with_suffix('.xcstrings.backup3')
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
    print(f"总翻译数: {len(TRANSLATIONS)} 键 × 12 语言 = {len(TRANSLATIONS) * 12} 翻译")

if __name__ == '__main__':
    add_translations_to_xcstrings()
