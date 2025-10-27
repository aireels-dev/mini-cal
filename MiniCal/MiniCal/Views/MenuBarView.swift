//
//  MenuBarView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        Text(viewModel.displayText)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.primary)
            .padding(.horizontal, 4)
            .onAppear {
                viewModel.refreshDisplay()
            }
    }
}

#Preview {
    MenuBarView(viewModel: MenuBarViewModel())
}
