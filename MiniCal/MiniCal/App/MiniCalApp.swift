//
//  MiniCalApp.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

@main
struct MiniCalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
