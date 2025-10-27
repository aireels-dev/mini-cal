//
//  MenuBarController.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Cocoa
import SwiftUI
import Combine

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBarViewModel: MenuBarViewModel!
    private var menuBarHostingView: NSHostingController<MenuBarView>?

    override init() {
        super.init()
        setupViewModel()
        setupMenuBar()
        setupPopover()
    }

    private func setupViewModel() {
        menuBarViewModel = MenuBarViewModel()
    }

    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Set initial title from ViewModel
            updateMenuBarTitle()

            button.action = #selector(togglePopover)
            button.target = self

            // Observe ViewModel changes to update menu bar title
            observeViewModelChanges()
        }
    }

    private func setupPopover() {
        // Create popover with calendar view
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 380)
        popover.behavior = .transient

        // Set calendar view as popover content
        let calendarView = CalendarView()
        let hostingController = NSHostingController(rootView: calendarView)
        popover.contentViewController = hostingController
    }

    private func updateMenuBarTitle() {
        if let button = statusItem.button {
            button.title = menuBarViewModel.displayText
        }
    }

    private func observeViewModelChanges() {
        // Observe displayText changes
        menuBarViewModel.$displayText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
            }
            .store(in: &menuBarViewModel.cancellables)
    }

    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() {
        popover.close()
    }
}
