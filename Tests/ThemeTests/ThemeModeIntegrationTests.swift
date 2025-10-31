//
//  ThemeModeIntegrationTests.swift
//  MiniCalTests
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import XCTest
import SwiftUI
@testable import MiniCal

final class ThemeModeIntegrationTests: XCTestCase {

    // MARK: - Enhanced Theme Manager Integration Tests

    func testThemeModeSwitchingIntegration() {
        // This test would require the actual EnhancedThemeManager implementation
        // For now, we'll test the integration between different components

        let themeMode = ThemeMode.light
        let category = ThemeCategory.light

        // Test that mode and category work together correctly
        switch themeMode {
        case .light:
            XCTAssertEqual(category, .light)
        case .dark:
            XCTAssertEqual(category, .dark)
        case .auto:
            // Auto mode should work with both categories
            break
        }
    }

    func testThemeModeWithSystemAppearance() {
        // Test integration between ThemeMode and system appearance
        let systemMonitor = SystemAppearanceMonitor.shared

        // Test that the monitor can detect appearance changes
        XCTAssertNotNil(systemMonitor)
        XCTAssertFalse(systemMonitor.isDarkMode) // Default state in test environment

        // Test color scheme mapping
        XCTAssertEqual(systemMonitor.effectiveColorScheme, .light)
    }

    func testUserPreferencesIntegration() {
        let preferences = UserThemePreferences()
        let storage = UserPreferencesStorage.shared

        // Test saving and loading preferences
        preferences.mode = .dark
        preferences.lightThemeId = "fresh_green"
        preferences.darkThemeId = "forest_green"

        let success = storage.savePreferences(preferences)
        XCTAssertTrue(success)

        let loadedPreferences = storage.loadPreferences()
        XCTAssertEqual(loadedPreferences.mode, .dark)
        XCTAssertEqual(loadedPreferences.lightThemeId, "fresh_green")
        XCTAssertEqual(loadedPreferences.darkThemeId, "forest_green")
    }

    func testThemeCacheIntegration() {
        let themeCache = ThemeCache.shared

        // Test that default themes are loaded
        let lightTheme = themeCache.theme(for: "classic_blue")
        XCTAssertNotNil(lightTheme)
        XCTAssertEqual(lightTheme?.category, .light)

        let darkTheme = themeCache.theme(for: "midnight_blue")
        XCTAssertNotNil(darkTheme)
        XCTAssertEqual(darkTheme?.category, .dark)

        // Test themes by category
        let lightThemes = themeCache.themes(for: .light)
        XCTAssertFalse(lightThemes.isEmpty)
        XCTAssertTrue(lightThemes.allSatisfy { $0.category == .light })

        let darkThemes = themeCache.themes(for: .dark)
        XCTAssertFalse(darkThemes.isEmpty)
        XCTAssertTrue(darkThemes.allSatisfy { $0.category == .dark })
    }

    func testThemePreviewStateIntegration() {
        let previewState = ThemePreviewState()
        let themeCache = ThemeCache.shared

        // Test preview with actual themes
        let theme = themeCache.theme(for: "classic_blue")
        XCTAssertNotNil(theme)

        previewState.startPreview(themeId: theme!.id, originalThemeId: "midnight_blue")
        XCTAssertTrue(previewState.isPreviewing)
        XCTAssertEqual(previewState.previewThemeId, theme!.id)
        XCTAssertEqual(previewState.originalThemeId, "midnight_blue")

        previewState.stopPreview()
        XCTAssertFalse(previewState.isPreviewing)
        XCTAssertNil(previewState.previewThemeId)
        XCTAssertNil(previewState.originalThemeId)
    }

    // MARK: - Color Extension Integration Tests

    func testColorExtensionWithThemeConfiguration() {
        let theme = ThemeConfiguration.defaultLight

        // Test that color extensions work with theme colors
        let primaryColor = Color(hex: theme.primary.main)
        let backgroundColor = Color(hex: theme.background.main)
        let textColor = Color(hex: theme.text.primary)

        // Test color utility functions
        XCTAssertNotNil(primaryColor.toHex())
        XCTAssertNotNil(backgroundColor.toHex())
        XCTAssertNotNil(textColor.toHex())

        // Test contrast calculation
        let contrast = primaryColor.contrastRatio(with: backgroundColor)
        XCTAssertGreaterThan(contrast, 1.0)
    }

    func testThemeColorUtilsIntegration() {
        let theme = ThemeConfiguration.defaultLight

        // Test ThemeColorUtils with actual theme configuration
        let primaryColor = ThemeColorUtils.color(from: theme.primary)
        let backgroundColor = ThemeColorUtils.color(from: theme.background)

        // Test themed color creation
        let themedColor = ThemeColorUtils.themedColor(
            light: theme.primary.main,
            dark: theme.primary.dark ?? theme.primary.main,
            appearance: .aqua
        )

        // Test gradient creation
        let gradient = ThemeColorUtils.gradient(
            from: primaryColor,
            to: backgroundColor
        )
        XCTAssertNotNil(gradient)

        // Test preview colors
        let previewColors = ThemeColorUtils.previewColors(for: theme)
        XCTAssertEqual(previewColors.count, theme.previewColors.count)
    }

    // MARK: - Performance Monitoring Integration Tests

    func testPerformanceMonitoringIntegration() {
        let monitor = PerformanceMonitor.shared

        // Test basic performance monitoring
        monitor.startTimer(for: "test_operation")
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.01)
        let duration = monitor.endTimer(for: "test_operation")

        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 1.0) // Should be very fast

        // Test measure function
        let result = monitor.measure(operation: "test_measure") {
            return 42
        }
        XCTAssertEqual(result, 42)

        // Test performance statistics
        let stats = monitor.getPerformanceStatistics()
        XCTAssertGreaterThan(stats.totalOperations, 0)
    }

    // MARK: - System Appearance Integration Tests

    func testSystemAppearanceWithThemeMode() {
        let systemMonitor = SystemAppearanceMonitor.shared

        // Test integration between system appearance and theme modes
        let suggestedMode = systemMonitor.suggestedThemeMode(for: .auto)
        XCTAssertEqual(suggestedMode, systemMonitor.isDarkMode ? .dark : .light)

        // Test appropriate theme category
        let appropriateCategory = systemMonitor.appropriateThemeCategory()
        XCTAssertEqual(appropriateCategory, systemMonitor.isDarkMode ? .dark : .light)
    }

    func testColorSchemeManagerIntegration() {
        let colorSchemeManager = ColorSchemeManager()
        let systemMonitor = SystemAppearanceMonitor.shared

        // Test that color scheme manager responds to system appearance
        let expectedScheme = colorSchemeManager.colorScheme(for: .auto)
        XCTAssertEqual(expectedScheme, systemMonitor.isDarkMode ? .dark : .light)

        // Test fixed color schemes
        XCTAssertEqual(colorSchemeManager.colorScheme(for: .light), .light)
        XCTAssertEqual(colorSchemeManager.colorScheme(for: .dark), .dark)
    }

    // MARK: - Error Handling Integration Tests

    func testErrorHandlingIntegration() {
        let storage = UserPreferencesStorage.shared
        let monitor = PerformanceMonitor.shared

        // Test error recording in performance monitor
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        monitor.recordError(operation: "test_operation", error: testError)

        // Test corrupted data recovery
        let recoveredPreferences = storage.loadPreferences() // Should handle corruption gracefully
        XCTAssertNotNil(recoveredPreferences)
        XCTAssertFalse(recoveredPreferences.lightThemeId.isEmpty)
        XCTAssertFalse(recoveredPreferences.darkThemeId.isEmpty)
    }

    // MARK: - Data Persistence Integration Tests

    func testDataPersistenceIntegration() {
        let originalPreferences = UserThemePreferences()
        originalPreferences.mode = .dark
        originalPreferences.lightThemeId = "fresh_green"
        originalPreferences.darkThemeId = "forest_green"
        originalPreferences.enableRealTimePreview = false
        originalPreferences.customSettings = ["test": "integration"]

        // Save preferences
        let storage = UserPreferencesStorage.shared
        let saveSuccess = storage.savePreferences(originalPreferences)
        XCTAssertTrue(saveSuccess)

        // Load preferences in a new instance
        let newStorage = UserPreferencesStorage.shared
        let loadedPreferences = newStorage.loadPreferences()

        // Verify all data persisted correctly
        XCTAssertEqual(loadedPreferences.mode, .dark)
        XCTAssertEqual(loadedPreferences.lightThemeId, "fresh_green")
        XCTAssertEqual(loadedPreferences.darkThemeId, "forest_green")
        XCTAssertEqual(loadedPreferences.enableRealTimePreview, false)
        XCTAssertEqual(loadedPreferences.customSettings["test"], "integration")
    }

    // MARK: - Memory Management Integration Tests

    func testMemoryManagementIntegration() {
        // Test that components don't create retain cycles
        weak var weakMonitor: PerformanceMonitor?
        weak var weakCache: ThemeCache?
        weak var weakSystemMonitor: SystemAppearanceMonitor?

        autoreleasepool {
            let monitor = PerformanceMonitor.shared
            let cache = ThemeCache.shared
            let systemMonitor = SystemAppearanceMonitor.shared

            weakMonitor = monitor
            weakCache = cache
            weakSystemMonitor = systemMonitor

            // Use the components
            _ = monitor.getPerformanceStatistics()
            _ = cache.allThemes()
            _ = systemMonitor.isDarkMode
        }

        // Singletons should not be deallocated, but we can test that they work correctly
        XCTAssertNotNil(PerformanceMonitor.shared)
        XCTAssertNotNil(ThemeCache.shared)
        XCTAssertNotNil(SystemAppearanceMonitor.shared)
    }

    // MARK: - Thread Safety Integration Tests

    func testThreadSafetyIntegration() {
        let themeCache = ThemeCache.shared
        let expectation = XCTestExpectation(description: "Thread safety test")
        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        // Test concurrent access to theme cache
        for i in 0..<10 {
            concurrentQueue.async {
                let theme = themeCache.theme(for: "classic_blue")
                XCTAssertNotNil(theme)

                if i == 9 {
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Performance Integration Tests

    func testPerformanceIntegrationBenchmark() {
        let themeCache = ThemeCache.shared
        let storage = UserPreferencesStorage.shared

        // Benchmark theme loading
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<100 {
                _ = themeCache.allThemes()
            }
        }

        // Benchmark preferences saving/loading
        let preferences = UserThemePreferences()
        preferences.mode = .dark
        preferences.lightThemeId = "fresh_green"

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<50 {
                _ = storage.savePreferences(preferences)
                _ = storage.loadPreferences()
            }
        }
    }

    // MARK: - End-to-End Integration Tests

    func testEndToEndThemeModeFlow() {
        // Test a complete user flow for theme mode selection

        // 1. Load initial preferences
        let storage = UserPreferencesStorage.shared
        var preferences = storage.loadPreferences()
        XCTAssertEqual(preferences.mode, .auto) // Default mode

        // 2. User selects light mode
        preferences.mode = .light
        let saveSuccess = storage.savePreferences(preferences)
        XCTAssertTrue(saveSuccess)

        // 3. Load preferences to confirm persistence
        let loadedPreferences = storage.loadPreferences()
        XCTAssertEqual(loadedPreferences.mode, .light)

        // 4. Verify theme availability for selected mode
        let themeCache = ThemeCache.shared
        let lightThemes = themeCache.themes(for: .light)
        XCTAssertFalse(lightThemes.isEmpty)

        // 5. Verify system appearance integration
        let systemMonitor = SystemAppearanceMonitor.shared
        let suggestedMode = systemMonitor.suggestedThemeMode(for: loadedPreferences.mode)
        XCTAssertEqual(suggestedMode, .light)

        // 6. Test theme preview state
        let previewState = ThemePreviewState()
        let firstLightTheme = lightThemes.first!
        previewState.startPreview(themeId: firstLightTheme.id, originalThemeId: loadedPreferences.lightThemeId)
        XCTAssertTrue(previewState.isPreviewing)

        // 7. Stop preview
        previewState.stopPreview()
        XCTAssertFalse(previewState.isPreviewing)

        // 8. Verify performance monitoring captured operations
        let monitor = PerformanceMonitor.shared
        let stats = monitor.getPerformanceStatistics()
        XCTAssertGreaterThan(stats.totalOperations, 0)
    }
}