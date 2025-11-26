//
//  SolarTerm.swift
//  MiniCal
//
//  二十四节气数据模型
//

import Foundation

/// 二十四节气
struct SolarTerm: Codable, Equatable {
    let name: String              // 节气名称
    let solarLongitude: Int       // 太阳黄经角度 (0-360)
    let approximateMonth: Int     // 大致月份
    let approximateDay: Int       // 大致日期
    let order: Int                // 节气顺序（1-24）

    // 寿星公式常数（20世纪和21世纪）
    let century20C: Double        // 20世纪常数C（1900-1999）
    let century21C: Double        // 21世纪常数C（2000-2099）

    /// 所有二十四节气定义（按太阳黄经顺序）
    /// 使用寿星公式常数（适用于1900-2100年）
    static let allSolarTerms: [SolarTerm] = [
        // 春季
        SolarTerm(name: "立春", solarLongitude: 315, approximateMonth: 2, approximateDay: 4, order: 1, century20C: 4.6295, century21C: 3.87),
        SolarTerm(name: "雨水", solarLongitude: 330, approximateMonth: 2, approximateDay: 19, order: 2, century20C: 19.4599, century21C: 18.73),
        SolarTerm(name: "惊蛰", solarLongitude: 345, approximateMonth: 3, approximateDay: 6, order: 3, century20C: 6.3926, century21C: 5.63),
        SolarTerm(name: "春分", solarLongitude: 0, approximateMonth: 3, approximateDay: 21, order: 4, century20C: 21.4155, century21C: 20.646),
        SolarTerm(name: "清明", solarLongitude: 15, approximateMonth: 4, approximateDay: 5, order: 5, century20C: 5.59, century21C: 4.81),
        SolarTerm(name: "谷雨", solarLongitude: 30, approximateMonth: 4, approximateDay: 20, order: 6, century20C: 20.888, century21C: 20.1),

        // 夏季
        SolarTerm(name: "立夏", solarLongitude: 45, approximateMonth: 5, approximateDay: 6, order: 7, century20C: 6.318, century21C: 5.52),
        SolarTerm(name: "小满", solarLongitude: 60, approximateMonth: 5, approximateDay: 21, order: 8, century20C: 21.86, century21C: 21.04),
        SolarTerm(name: "芒种", solarLongitude: 75, approximateMonth: 6, approximateDay: 6, order: 9, century20C: 6.5, century21C: 5.678),
        SolarTerm(name: "夏至", solarLongitude: 90, approximateMonth: 6, approximateDay: 22, order: 10, century20C: 22.20, century21C: 21.37),
        SolarTerm(name: "小暑", solarLongitude: 105, approximateMonth: 7, approximateDay: 7, order: 11, century20C: 7.928, century21C: 7.108),
        SolarTerm(name: "大暑", solarLongitude: 120, approximateMonth: 7, approximateDay: 23, order: 12, century20C: 23.65, century21C: 22.83),

        // 秋季
        SolarTerm(name: "立秋", solarLongitude: 135, approximateMonth: 8, approximateDay: 8, order: 13, century20C: 8.35, century21C: 7.5),
        SolarTerm(name: "处暑", solarLongitude: 150, approximateMonth: 8, approximateDay: 23, order: 14, century20C: 23.95, century21C: 23.13),
        SolarTerm(name: "白露", solarLongitude: 165, approximateMonth: 9, approximateDay: 8, order: 15, century20C: 8.44, century21C: 7.646),
        SolarTerm(name: "秋分", solarLongitude: 180, approximateMonth: 9, approximateDay: 23, order: 16, century20C: 23.822, century21C: 23.042),
        SolarTerm(name: "寒露", solarLongitude: 195, approximateMonth: 10, approximateDay: 8, order: 17, century20C: 8.77, century21C: 8.318),
        SolarTerm(name: "霜降", solarLongitude: 210, approximateMonth: 10, approximateDay: 24, order: 18, century20C: 24.218, century21C: 23.438),

        // 冬季
        SolarTerm(name: "立冬", solarLongitude: 225, approximateMonth: 11, approximateDay: 8, order: 19, century20C: 8.218, century21C: 7.438),
        SolarTerm(name: "小雪", solarLongitude: 240, approximateMonth: 11, approximateDay: 22, order: 20, century20C: 23.08, century21C: 22.36),
        SolarTerm(name: "大雪", solarLongitude: 255, approximateMonth: 12, approximateDay: 7, order: 21, century20C: 7.9, century21C: 7.18),
        SolarTerm(name: "冬至", solarLongitude: 270, approximateMonth: 12, approximateDay: 22, order: 22, century20C: 22.60, century21C: 21.94),
        SolarTerm(name: "小寒", solarLongitude: 285, approximateMonth: 1, approximateDay: 6, order: 23, century20C: 6.11, century21C: 5.4055),
        SolarTerm(name: "大寒", solarLongitude: 300, approximateMonth: 1, approximateDay: 20, order: 24, century20C: 20.84, century21C: 20.12)
    ]
}
