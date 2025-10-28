//
//  MenuBarViewModel.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import Combine
import SwiftUI

class MenuBarViewModel: ObservableObject {
    @Published var displayText: String = ""

    private var timer: Timer?
    var cancellables = Set<AnyCancellable>()
    private let settingsManager: SettingsManager

    init(settingsManager: SettingsManager = SettingsManager.shared) {
        self.settingsManager = settingsManager

        setupTimer()
        updateDisplayText()
        observeSettingsChanges()
        observeTimeZoneChanges()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Timer Management

    private func setupTimer() {
        // 每60秒更新一次显示文本
        timer = Timer.scheduledTimer(withTimeInterval: Constants.Timing.menuBarUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateDisplayText()
        }
    }

    // MARK: - Display Text Update

    func updateDisplayText() {
        let currentDate = Date()
        let settings = settingsManager.currentSettings
        displayText = settings.menuBarFormat.format(
            date: currentDate,
            show24Hour: settings.show24Hour,
            showWeekday: settings.showWeekday,
            showSeconds: settings.showSeconds,
            customFormat: settings.customFormat
        )
    }

    // MARK: - Settings Observer

    private func observeSettingsChanges() {
        settingsManager.$currentSettings
            .sink { [weak self] _ in
                self?.updateDisplayText()
            }
            .store(in: &cancellables)
    }

    private func observeTimeZoneChanges() {
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in
                Logger.info("Time zone changed, updating display", category: Logger.ui)
                self?.updateDisplayText()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func refreshDisplay() {
        updateDisplayText()
    }
}
