//
//  ThemeModelsTests.swift
//  MiniCalTests
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import XCTest
@testable import MiniCal

final class ThemeModelsTests: XCTestCase {

    // MARK: - ThemeMode Tests

    func testThemeModeEnumCases() {
        // Test that all enum cases exist
        XCTAssertEqual(ThemeMode.allCases.count, 3)
        XCTAssertTrue(ThemeMode.allCases.contains(.light))
        XCTAssertTrue(ThemeMode.allCases.contains(.dark))
        XCTAssertTrue(ThemeMode.allCases.contains(.auto))
    }

    func testThemeModeDisplayNames() {
        XCTAssertEqual(ThemeMode.light.displayName, "白天模式")
        XCTAssertEqual(ThemeMode.dark.displayName, "黑夜模式")
        XCTAssertEqual(ThemeMode.auto.displayName, "自动模式")
    }

    func testThemeModeSystemColorScheme() {
        XCTAssertEqual(ThemeMode.light.systemColorScheme, .light)
        XCTAssertEqual(ThemeMode.dark.systemColorScheme, .dark)
        XCTAssertNil(ThemeMode.auto.systemColorScheme)
    }

    func testThemeModeCodable() {
        // Test encoding
        let encoder = JSONEncoder()
        let lightMode = ThemeMode.light
        let encodedData = try? encoder.encode(lightMode)
        XCTAssertNotNil(encodedData)

        // Test decoding
        let decoder = JSONDecoder()
        let decodedMode = try? decoder.decode(ThemeMode.self, from: encodedData!)
        XCTAssertEqual(decodedMode, .light)

        // Test all modes roundtrip
        for mode in ThemeMode.allCases {
            let data = try! encoder.encode(mode)
            let decoded = try! decoder.decode(ThemeMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }

    func testThemeModeRawValues() {
        XCTAssertEqual(ThemeMode.light.rawValue, "light")
        XCTAssertEqual(ThemeMode.dark.rawValue, "dark")
        XCTAssertEqual(ThemeMode.auto.rawValue, "auto")
    }

    // MARK: - ThemeCategory Tests

    func testThemeCategoryEnumCases() {
        XCTAssertEqual(ThemeCategory.allCases.count, 2)
        XCTAssertTrue(ThemeCategory.allCases.contains(.light))
        XCTAssertTrue(ThemeCategory.allCases.contains(.dark))
    }

    func testThemeCategoryDisplayNames() {
        XCTAssertEqual(ThemeCategory.light.displayName, "白天主题")
        XCTAssertEqual(ThemeCategory.dark.displayName, "黑夜主题")
    }

    func testThemeCategoryDefaultThemes() {
        let lightDefaults = ThemeCategory.light.defaultThemes
        let darkDefaults = ThemeCategory.dark.defaultThemes

        XCTAssertEqual(lightDefaults.count, 5)
        XCTAssertEqual(darkDefaults.count, 5)
        XCTAssertTrue(lightDefaults.contains("classic_blue"))
        XCTAssertTrue(darkDefaults.contains("midnight_blue"))

        // Ensure no overlap between light and dark defaults
        let overlap = Set(lightDefaults).intersection(Set(darkDefaults))
        XCTAssertTrue(overlap.isEmpty, "Light and dark default themes should not overlap")
    }

    func testThemeCategoryCodable() {
        // Test encoding and decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in ThemeCategory.allCases {
            let data = try! encoder.encode(category)
            let decoded = try! decoder.decode(ThemeCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    // MARK: - UserThemePreferences Tests

    func testUserThemePreferencesDefaultValues() {
        let preferences = UserThemePreferences()

        XCTAssertEqual(preferences.mode, .auto)
        XCTAssertEqual(preferences.lightThemeId, "classic_blue")
        XCTAssertEqual(preferences.darkThemeId, "midnight_blue")
        XCTAssertTrue(preferences.enableRealTimePreview)
        XCTAssertTrue(preferences.enableSmoothTransitions)
        XCTAssertEqual(preferences.lastUsedVersion, "1.0")
        XCTAssertTrue(preferences.customSettings.isEmpty)
    }

    func testUserThemePreferencesCodable() {
        let preferences = UserThemePreferences()
        preferences.mode = .dark
        preferences.lightThemeId = "fresh_green"
        preferences.darkThemeId = "forest_green"
        preferences.enableRealTimePreview = false
        preferences.customSettings = ["test": "value"]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Test encoding
        let data = try! encoder.encode(preferences)
        XCTAssertNotNil(data)

        // Test decoding
        let decoded = try! decoder.decode(UserThemePreferences.self, from: data)
        XCTAssertEqual(decoded.mode, .dark)
        XCTAssertEqual(decoded.lightThemeId, "fresh_green")
        XCTAssertEqual(decoded.darkThemeId, "forest_green")
        XCTAssertFalse(decoded.enableRealTimePreview)
        XCTAssertEqual(decoded.customSettings["test"], "value")
    }

    // MARK: - ThemePreviewState Tests

    func testThemePreviewStateInitialState() {
        let previewState = ThemePreviewState()

        XCTAssertFalse(previewState.isPreviewing)
        XCTAssertNil(previewState.previewThemeId)
        XCTAssertNil(previewState.originalThemeId)
    }

    func testThemePreviewStateStartPreview() {
        let previewState = ThemePreviewState()

        previewState.startPreview(themeId: "test_theme", originalThemeId: "original_theme")

        XCTAssertTrue(previewState.isPreviewing)
        XCTAssertEqual(previewState.previewThemeId, "test_theme")
        XCTAssertEqual(previewState.originalThemeId, "original_theme")
    }

    func testThemePreviewStateStopPreview() {
        let previewState = ThemePreviewState()

        // Start preview first
        previewState.startPreview(themeId: "test_theme", originalThemeId: "original_theme")
        XCTAssertTrue(previewState.isPreviewing)

        // Then stop preview
        previewState.stopPreview()
        XCTAssertFalse(previewState.isPreviewing)
        XCTAssertNil(previewState.previewThemeId)
        XCTAssertNil(previewState.originalThemeId)
    }

    func testThemePreviewStateMultipleOperations() {
        let previewState = ThemePreviewState()

        // Start first preview
        previewState.startPreview(themeId: "theme1", originalThemeId: "original1")
        XCTAssertEqual(previewState.previewThemeId, "theme1")

        // Start second preview (should replace first)
        previewState.startPreview(themeId: "theme2", originalThemeId: "original2")
        XCTAssertEqual(previewState.previewThemeId, "theme2")
        XCTAssertEqual(previewState.originalThemeId, "original2")

        // Stop preview
        previewState.stopPreview()
        XCTAssertFalse(previewState.isPreviewing)
    }

    // MARK: - Edge Cases

    func testThemeModeDisplayNameConsistency() {
        // Ensure display names are unique
        let displayNames = ThemeMode.allCases.map { $0.displayName }
        let uniqueNames = Set(displayNames)
        XCTAssertEqual(displayNames.count, uniqueNames.count, "Display names should be unique")
    }

    func testThemeCategoryDefaultThemesExist() {
        // Ensure all default theme IDs are non-empty strings
        for category in ThemeCategory.allCases {
            for themeId in category.defaultThemes {
                XCTAssertFalse(themeId.isEmpty, "Theme ID should not be empty")
            }
        }
    }

    func testUserThemePreferencesInitializationWithEmptyDefaults() {
        // Test that preferences initialize correctly even if category defaults are empty
        // This is a defensive test for future changes
        let preferences = UserThemePreferences()
        XCTAssertNotNil(preferences.lightThemeId)
        XCTAssertNotNil(preferences.darkThemeId)
        XCTAssertFalse(preferences.lightThemeId.isEmpty)
        XCTAssertFalse(preferences.darkThemeId.isEmpty)
    }

    // MARK: - Performance Tests

    func testThemeModePerformance() {
        // Test that enum operations are fast
        measure {
            for _ in 0..<1000 {
                _ = ThemeMode.allCases
                _ = ThemeMode.light.displayName
                _ = ThemeMode.auto.systemColorScheme
            }
        }
    }

    func testThemePreviewStatePerformance() {
        let previewState = ThemePreviewState()

        measure {
            for i in 0..<100 {
                previewState.startPreview(themeId: "theme_\(i)", originalThemeId: "original")
                previewState.stopPreview()
            }
        }
    }
}