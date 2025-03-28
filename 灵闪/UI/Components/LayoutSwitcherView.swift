//
//  LayoutSwitcherView.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI

struct LayoutSwitcherView: View {
    @ObservedObject var layoutManager: LayoutManager
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 0) {
                let layoutModes = LayoutMode.allCases
                ForEach(layoutModes, id: \.id) { mode in
                    let isSelected = layoutManager.currentLayout == mode
                    let foregroundColor = isSelected ? Color.blue : Color.gray
                    let backgroundColor = isSelected ? Color.blue.opacity(0.1) : Color.clear
                    
                    Button(action: {
                        layoutManager.setLayout(mode)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18))
                            
                            Text(mode.displayName)
                                .font(.caption)
                        }
                        .frame(width: 70, height: 56)
                        .foregroundColor(foregroundColor)
                        .background(backgroundColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            
            Spacer()
        }
    }
}

#Preview {
    LayoutSwitcherView(layoutManager: LayoutManager())
} 