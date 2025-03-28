//
//  LayoutManager.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI

enum LayoutMode: String, CaseIterable, Identifiable {
    case splitScreen = "splitScreen"
    case fullCanvasWithPreview = "fullCanvasWithPreview"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .splitScreen: return "分屏模式"
        case .fullCanvasWithPreview: return "画板全屏"
        }
    }
    
    var icon: String {
        switch self {
        case .splitScreen: return "rectangle.split.2x1"
        case .fullCanvasWithPreview: return "rectangle.leftthird.inset.filled"
        }
    }
}

class LayoutManager: ObservableObject {
    @Published var currentLayout: LayoutMode = .splitScreen
    @Published var canvasRatio: CGFloat = 0.5 // 0.0-1.0，表示画布占据的比例
    
    func toggleLayout() {
        switch currentLayout {
        case .splitScreen:
            currentLayout = .fullCanvasWithPreview
        case .fullCanvasWithPreview:
            currentLayout = .splitScreen
        }
    }
    
    func setLayout(_ layout: LayoutMode) {
        self.currentLayout = layout
    }
    
    func adjustCanvasRatio(_ delta: CGFloat) {
        let newRatio = canvasRatio + delta
        canvasRatio = min(max(0.1, newRatio), 0.9) // 限制在0.1-0.9之间
    }
} 