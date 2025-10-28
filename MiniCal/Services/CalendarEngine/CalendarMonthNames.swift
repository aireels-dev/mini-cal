//
//  CalendarMonthNames.swift
//  MiniCal
//
//  Created on 2025/10/28.
//

import Foundation

/// 各种历法的月份名称映射
struct CalendarMonthNames {

    // MARK: - Islamic Calendar Month Names (伊斯兰历月份)

    /// 伊斯兰历月份名称（阿拉伯语）
    static let islamicMonthsArabic = [
        "", // 占位符，月份从1开始
        "محرم",      // 1. Muharram
        "صفر",       // 2. Safar
        "ربيع الأول", // 3. Rabi' al-awwal
        "ربيع الآخر", // 4. Rabi' al-akhir
        "جمادى الأولى", // 5. Jumada al-ula
        "جمادى الآخرة", // 6. Jumada al-akhira
        "رجب",       // 7. Rajab
        "شعبان",     // 8. Sha'ban
        "رمضان",     // 9. Ramadan
        "شوال",      // 10. Shawwal
        "ذو القعدة", // 11. Dhu al-Qi'dah
        "ذو الحجة"   // 12. Dhu al-Hijjah
    ]

    /// 伊斯兰历月份名称（英文缩写，适合小空间显示）
    static let islamicMonthsShort = [
        "", "Muh", "Saf", "Rab1", "Rab2", "Jum1", "Jum2",
        "Raj", "Sha", "Ram", "Shaw", "DhuQ", "DhuH"
    ]

    // MARK: - Hebrew Calendar Month Names (希伯来历月份)

    /// 希伯来历月份名称（英文）
    static let hebrewMonthsEnglish = [
        "",
        "Nisan",      // 1. 尼散月
        "Iyar",       // 2. 以珥月
        "Sivan",      // 3. 西弯月
        "Tammuz",     // 4. 搭模斯月
        "Av",         // 5. 埃波月
        "Elul",       // 6. 以禄月
        "Tishrei",    // 7. 提斯利月
        "Heshvan",    // 8. 马西班月
        "Kislev",     // 9. 基斯流月
        "Tevet",      // 10. 提别月
        "Shevat",     // 11. 细罢特月
        "Adar",       // 12. 亚达月
        "Adar II"     // 13. 亚达二月（闰月）
    ]

    /// 希伯来历月份名称（短缩写）
    static let hebrewMonthsShort = [
        "", "Nis", "Iya", "Siv", "Tam", "Av", "Elu",
        "Tis", "Hes", "Kis", "Tev", "She", "Ada", "Ad2"
    ]

    // MARK: - Persian Calendar Month Names (波斯历月份)

    /// 波斯历月份名称（波斯语）
    static let persianMonthsPersian = [
        "",
        "فروردین",   // 1. Farvardin
        "اردیبهشت",  // 2. Ordibehesht
        "خرداد",      // 3. Khordad
        "تیر",        // 4. Tir
        "مرداد",      // 5. Mordad
        "شهریور",     // 6. Shahrivar
        "مهر",        // 7. Mehr
        "آبان",       // 8. Aban
        "آذر",        // 9. Azar
        "دی",         // 10. Dey
        "بهمن",       // 11. Bahman
        "اسفند"       // 12. Esfand
    ]

    /// 波斯历月份名称（英文缩写）
    static let persianMonthsShort = [
        "", "Far", "Ord", "Kho", "Tir", "Mor", "Sha",
        "Meh", "Aba", "Aza", "Dey", "Bah", "Esf"
    ]

    // MARK: - Helper Methods

    /// 获取伊斯兰历月份名称（短格式）
    static func getIslamicMonthName(_ month: Int?, short: Bool = true) -> String {
        guard let month = month, month >= 1, month <= 12 else { return "" }
        return short ? islamicMonthsShort[month] : islamicMonthsArabic[month]
    }

    /// 获取希伯来历月份名称（短格式）
    static func getHebrewMonthName(_ month: Int?, short: Bool = true) -> String {
        guard let month = month, month >= 1, month <= 13 else { return "" }
        return short ? hebrewMonthsShort[month] : hebrewMonthsEnglish[month]
    }

    /// 获取波斯历月份名称（短格式）
    static func getPersianMonthName(_ month: Int?, short: Bool = true) -> String {
        guard let month = month, month >= 1, month <= 12 else { return "" }
        return short ? persianMonthsShort[month] : persianMonthsPersian[month]
    }
}
