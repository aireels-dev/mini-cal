//
//  ThemeConfigurationTests.swift
//  MiniCalTests
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import XCTest
@testable import MiniCal

final class ThemeConfigurationTests: XCTestCase {

    // MARK: - Default Themes Tests

    func testDefaultLightThemeConfiguration() {
        let theme = ThemeConfiguration.defaultLight

        XCTAssertEqual(theme.id, "classic_blue")
        XCTAssertEqual(theme.name, "Classic Blue")
        XCTAssertEqual(theme.displayName, "经典蓝")
        XCTAssertEqual(theme.category, .light)
        XCTAssertTrue(theme.isBuiltIn)
        XCTAssertEqual(theme.author, "MiniCal Team")
        XCTAssertEqual(theme.version, "1.0")
        XCTAssertEqual(theme.previewColors.count, 4)
        XCTAssertTrue(theme.previewColors.contains("#4285F4"))
    }

    func testDefaultDarkThemeConfiguration() {
        let theme = ThemeConfiguration.defaultDark

        XCTAssertEqual(theme.id, "midnight_blue")
        XCTAssertEqual(theme.name, "Midnight Blue")
        XCTAssertEqual(theme.displayName, "午夜蓝")
        XCTAssertEqual(theme.category, .dark)
        XCTAssertTrue(theme.isBuiltIn)
        XCTAssertEqual(theme.author, "MiniCal Team")
        XCTAssertEqual(theme.version, "1.0")
        XCTAssertEqual(theme.previewColors.count, 4)
        XCTAssertTrue(theme.previewColors.contains("#1A73E8"))
    }

    // MARK: - ColorSet Tests

    func testColorSetInitialization() {
        let colorSet = ColorSet(main: "#FF0000", light: "#FF6666", dark: "#CC0000", alpha: 0.8)

        XCTAssertEqual(colorSet.main, "#FF0000")
        XCTAssertEqual(colorSet.light, "#FF6666")
        XCTAssertEqual(colorSet.dark, "#CC0000")
        XCTAssertEqual(colorSet.alpha, 0.8)
    }

    func testColorSetWithOptionalParameters() {
        let colorSet = ColorSet(main: "#00FF00")

        XCTAssertEqual(colorSet.main, "#00FF00")
        XCTAssertNil(colorSet.light)
        XCTAssertNil(colorSet.dark)
        XCTAssertNil(colorSet.alpha)
    }

    func testColorSetEquality() {
        let colorSet1 = ColorSet(main: "#FF0000", light: "#FF6666", dark: "#CC0000", alpha: 0.8)
        let colorSet2 = ColorSet(main: "#FF0000", light: "#FF6666", dark: "#CC0000", alpha: 0.8)
        let colorSet3 = ColorSet(main: "#00FF00", light: "#FF6666", dark: "#CC0000", alpha: 0.8)

        XCTAssertEqual(colorSet1, colorSet2)
        XCTAssertNotEqual(colorSet1, colorSet3)
    }

    // MARK: - TextColorSet Tests

    func testTextColorSetInitialization() {
        let textColors = TextColorSet(
            primary: "#000000",
            secondary: "#666666",
            disabled: "#CCCCCC",
            inverse: "#FFFFFF"
        )

        XCTAssertEqual(textColors.primary, "#000000")
        XCTAssertEqual(textColors.secondary, "#666666")
        XCTAssertEqual(textColors.disabled, "#CCCCCC")
        XCTAssertEqual(textColors.inverse, "#FFFFFF")
    }

    func testTextColorSetEquality() {
        let textColors1 = TextColorSet(primary: "#000000", secondary: "#666666", disabled: "#CCCCCC", inverse: "#FFFFFF")
        let textColors2 = TextColorSet(primary: "#000000", secondary: "#666666", disabled: "#CCCCCC", inverse: "#FFFFFF")
        let textColors3 = TextColorSet(primary: "#111111", secondary: "#666666", disabled: "#CCCCCC", inverse: "#FFFFFF")

        XCTAssertEqual(textColors1, textColors2)
        XCTAssertNotEqual(textColors1, textColors3)
    }

    // MARK: - CalendarColorSet Tests

    func testCalendarColorSetInitialization() {
        let calendarColors = CalendarColorSet(
            todayBackground: "#E8F0FE",
            todayText: "#1967D2",
            selectedBackground: "#4285F4",
            selectedText: "#FFFFFF",
            weekendText: "#EA4335",
            eventIndicator: "#FBBC04"
        )

        XCTAssertEqual(calendarColors.todayBackground, "#E8F0FE")
        XCTAssertEqual(calendarColors.todayText, "#1967D2")
        XCTAssertEqual(calendarColors.selectedBackground, "#4285F4")
        XCTAssertEqual(calendarColors.selectedText, "#FFFFFF")
        XCTAssertEqual(calendarColors.weekendText, "#EA4335")
        XCTAssertEqual(calendarColors.eventIndicator, "#FBBC04")
    }

    // MARK: - StatusColorSet Tests

    func testStatusColorSetInitialization() {
        let statusColors = StatusColorSet(
            success: "#34A853",
            warning: "#FBBC04",
            error: "#EA4335",
            info: "#4285F4"
        )

        XCTAssertEqual(statusColors.success, "#34A853")
        XCTAssertEqual(statusColors.warning, "#FBBC04")
        XCTAssertEqual(statusColors.error, "#EA4335")
        XCTAssertEqual(statusColors.info, "#4285F4")
    }

    // MARK: - ThemeConfiguration Equality Tests

    func testThemeConfigurationEquality() {
        let theme1 = ThemeConfiguration.defaultLight
        let theme2 = ThemeConfiguration.defaultLight
        let theme3 = ThemeConfiguration.defaultDark

        XCTAssertEqual(theme1, theme2)
        XCTAssertNotEqual(theme1, theme3)
    }

    func testThemeConfigurationIdentifiable() {
        let theme = ThemeConfiguration.defaultLight
        XCTAssertEqual(theme.id, "classic_blue")
    }

    // MARK: - Theme Configuration Validation Tests

    func testValidThemeConfigurationValidation() {
        let theme = ThemeConfiguration.defaultLight
        let errors = theme.validate()
        XCTAssertTrue(errors.isEmpty, "Default theme should be valid")
    }

    func testInvalidThemeIdValidation() {
        var theme = ThemeConfiguration.defaultLight
        theme = ThemeConfiguration(
            id: "", // Empty ID
            name: theme.name,
            displayName: theme.displayName,
            category: theme.category,
            isBuiltIn: theme.isBuiltIn,
            primary: theme.primary,
            secondary: theme.secondary,
            accent: theme.accent,
            background: theme.background,
            surface: theme.surface,
            text: theme.text,
            calendar: theme.calendar,
            status: theme.status,
            author: theme.author,
            version: theme.version,
            description: theme.description,
            previewColors: theme.previewColors
        )

        let errors = theme.validate()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.field == "id" })
    }

    func testInvalidThemeNameValidation() {
        var theme = ThemeConfiguration.defaultLight
        theme = ThemeConfiguration(
            id: theme.id,
            name: "", // Empty name
            displayName: theme.displayName,
            category: theme.category,
            isBuiltIn: theme.isBuiltIn,
            primary: theme.primary,
            secondary: theme.secondary,
            accent: theme.accent,
            background: theme.background,
            surface: theme.surface,
            text: theme.text,
            calendar: theme.calendar,
            status: theme.status,
            author: theme.author,
            version: theme.version,
            description: theme.description,
            previewColors: theme.previewColors
        )

        let errors = theme.validate()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.field == "name" })
    }

    func testInvalidHexColorValidation() {
        var invalidPrimary = ColorSet(main: "invalid_color")
        var theme = ThemeConfiguration.defaultLight
        theme = ThemeConfiguration(
            id: theme.id,
            name: theme.name,
            displayName: theme.displayName,
            category: theme.category,
            isBuiltIn: theme.isBuiltIn,
            primary: invalidPrimary,
            secondary: theme.secondary,
            accent: theme.accent,
            background: theme.background,
            surface: theme.surface,
            text: theme.text,
            calendar: theme.calendar,
            status: theme.status,
            author: theme.author,
            version: theme.version,
            description: theme.description,
            previewColors: theme.previewColors
        )

        let errors = theme.validate()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.field.contains("primary.main") })
    }

    // MARK: - Color Validator Tests

    func testColorValidatorValidHexColors() {
        let validator = ColorValidator()

        let validColors = ["#FF0000", "#00FF00", "#0000FF", "#FFFFFF", "#000000"]
        for color in validColors {
            let errors = validator.validate(color, field: "test")
            XCTAssertTrue(errors.isEmpty, "Color \(color) should be valid")
        }
    }

    func testColorValidatorInvalidHexColors() {
        let validator = ColorValidator()

        let invalidColors = ["invalid", "#GGGGGG", "#FF000", "FF0000", "#FF00000"]
        for color in invalidColors {
            let errors = validator.validate(color, field: "test")
            XCTAssertFalse(errors.isEmpty, "Color \(color) should be invalid")
        }
    }

    func testColorValidatorShortHexColors() {
        let validator = ColorValidator()

        let validColors = ["#F00", "#0F0", "#00F", "#FFF", "#000"]
        for color in validColors {
            let errors = validator.validate(color, field: "test")
            XCTAssertTrue(errors.isEmpty, "Short hex color \(color) should be valid")
        }
    }

    // MARK: - Contrast Validator Tests

    func testContrastValidatorValidContrast() {
        let validator = ContrastValidator()

        // High contrast combinations
        let validPairs = [
            ("#000000", "#FFFFFF"), // Black on white
            ("#FFFFFF", "#000000"), // White on black
            ("#FF0000", "#FFFFFF"), // Red on white
            ("#0000FF", "#FFFF00"), // Blue on yellow
        ]

        for (foreground, background) in validPairs {
            XCTAssertTrue(
                validator.isValidContrast(foreground, background),
                "Contrast between \(foreground) and \(background) should be valid"
            )
        }
    }

    func testContrastValidatorInvalidContrast() {
        let validator = ContrastValidator()

        // Low contrast combinations
        let invalidPairs = [
            ("#CCCCCC", "#DDDDDD"), // Light gray on slightly lighter gray
            ("#333333", "#444444"), // Dark gray on slightly lighter dark gray
        ]

        for (foreground, background) in invalidPairs {
            XCTAssertFalse(
                validator.isValidContrast(foreground, background),
                "Contrast between \(foreground) and \(background) should be invalid"
            )
        }
    }

    // MARK: - Codable Tests

    func testThemeConfigurationCodable() {
        let originalTheme = ThemeConfiguration.defaultLight
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(originalTheme)
            XCTAssertNotNil(data)

            let decodedTheme = try decoder.decode(ThemeConfiguration.self, from: data)
            XCTAssertEqual(originalTheme, decodedTheme)
        } catch {
            XCTFail("Encoding/decoding failed: \(error)")
        }
    }

    func testColorSetCodable() {
        let originalColorSet = ColorSet(main: "#FF0000", light: "#FF6666", dark: "#CC0000", alpha: 0.8)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(originalColorSet)
            let decodedColorSet = try decoder.decode(ColorSet.self, from: data)
            XCTAssertEqual(originalColorSet, decodedColorSet)
        } catch {
            XCTFail("ColorSet encoding/decoding failed: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testThemeConfigurationValidationPerformance() {
        let theme = ThemeConfiguration.defaultLight

        measure {
            for _ in 0..<100 {
                _ = theme.validate()
            }
        }
    }

    func testThemeConfigurationEqualityPerformance() {
        let theme1 = ThemeConfiguration.defaultLight
        let theme2 = ThemeConfiguration.defaultLight

        measure {
            for _ in 0..<1000 {
                _ = theme1 == theme2
            }
        }
    }

    // MARK: - Edge Cases

    func testThemeConfigurationWithEmptyPreviewColors() {
        var theme = ThemeConfiguration.defaultLight
        theme = ThemeConfiguration(
            id: theme.id,
            name: theme.name,
            displayName: theme.displayName,
            category: theme.category,
            isBuiltIn: theme.isBuiltIn,
            primary: theme.primary,
            secondary: theme.secondary,
            accent: theme.accent,
            background: theme.background,
            surface: theme.surface,
            text: theme.text,
            calendar: theme.calendar,
            status: theme.status,
            author: theme.author,
            version: theme.version,
            description: theme.description,
            previewColors: [] // Empty preview colors
        )

        // Should still be valid
        let errors = theme.validate()
        XCTAssertTrue(errors.isEmpty)
    }

    func testColorSetWithBoundaryAlphaValues() {
        let alphaZero = ColorSet(main: "#FF0000", alpha: 0.0)
        let alphaOne = ColorSet(main: "#FF0000", alpha: 1.0)
        let alphaNegative = ColorSet(main: "#FF0000", alpha: -0.1)
        let alphaOverOne = ColorSet(main: "#FF0000", alpha: 1.1)

        XCTAssertEqual(alphaZero.alpha, 0.0)
        XCTAssertEqual(alphaOne.alpha, 1.0)
        XCTAssertEqual(alphaNegative.alpha, -0.1)
        XCTAssertEqual(alphaOverOne.alpha, 1.1)
    }
}