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
    @Published var settings: UserSettings

    private var timer: Timer?
    var cancellables = Set<AnyCancellable>()
    private let settingsManager: SettingsManager

    init(settingsManager: SettingsManager = SettingsManager()) {
        self.settingsManager = settingsManager
        self.settings = settingsManager.loadSettings()

        setupTimer()
        updateDisplayText()
        observeSettingsChanges()
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
        displayText = settings.menuBarFormat.format(
            date: currentDate,
            show24Hour: settings.show24Hour,
            showWeekday: settings.showWeekday
        )
    }

    // MARK: - Settings Observer

    private func observeSettingsChanges() {
        $settings
            .sink { [weak self] newSettings in
                self?.settingsManager.saveSettings(newSettings)
                self?.updateDisplayText()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func updateSettings(_ newSettings: UserSettings) {
        settings = newSettings
    }

    func refreshDisplay() {
        updateDisplayText()
    }
}
