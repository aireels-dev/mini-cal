//
//  VisualEffectView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Glass Effect Modifier

struct GlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active
                )
            )
    }
}

extension View {
    func glassEffect() -> some View {
        modifier(GlassEffect())
    }
}
