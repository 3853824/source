//
//  AIGenerationView.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI

struct AIGenerationView: View {
    @Binding var inputImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var isGenerating: Bool = false
    @State private var selectedStyle: AIStyle = .realistic
    @State private var prompt: String = ""
    
    // 构造函数，用于接收外部传入的prompt
    init(inputImage: Binding<UIImage?>, externalPrompt: String? = nil) {
        self._inputImage = inputImage
        if let externalPrompt = externalPrompt {
            self._prompt = State(initialValue: externalPrompt)
        }
    }
    
    var body: some View {
        ZStack {
            // 透明背景，确保不会有任何边框
            Color.clear
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                    Text("AI正在创作中...")
                        .font(.headline)
                } else if let generatedImage = generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                        // 不使用圆角和阴影
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .opacity(0.5)
                    Text("等待绘画输入...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            // 初始加载时生成图像
            if inputImage != nil {
                generateImageAsync()
            }
        }
        .onChange(of: inputImage) { _, newValue in
            // 使用Task处理状态更新
            if newValue != nil {
                generateImageAsync()
            }
        }
        .onChange(of: selectedStyle) { _, _ in
            generateImageAsync()
        }
        .onChange(of: prompt) { _, _ in
            generateImageAsync()
        }
    }
    
    private func generateImageAsync() {
        Task { @MainActor in
            guard let inputImage = inputImage else { return }
            
            // 避免重复触发生成
            if isGenerating { return }
            
            // 模拟AI生成过程
            isGenerating = true
            
            // 模拟异步操作
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
            
            // 模拟生成结果，实际应用中应替换为真实AI生成
            self.generatedImage = inputImage
            self.isGenerating = false
        }
    }
    
    private func generateImage() {
        guard let inputImage = inputImage else { return }
        
        // 避免重复触发生成
        if isGenerating { return }
        
        // 模拟AI生成过程
        isGenerating = true
        
        // 在实际应用中，这里应该调用AI服务
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 模拟生成结果，实际应用中应替换为真实AI生成
            self.generatedImage = inputImage
            self.isGenerating = false
        }
    }
}

struct StyleButton: View {
    let style: AIStyle
    @Binding var selectedStyle: AIStyle
    
    var body: some View {
        Button(action: {
            selectedStyle = style
        }) {
            Text(style.displayName)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedStyle == style ? Color.blue : Color(.systemGray5))
                .foregroundColor(selectedStyle == style ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

enum AIStyle: String, CaseIterable {
    case realistic = "realistic"
    case cartoon = "cartoon"
    case oilPainting = "oilPainting"
    case watercolor = "watercolor"
    case sketch = "sketch"
    case anime = "anime"
    
    var displayName: String {
        switch self {
        case .realistic: return "写实"
        case .cartoon: return "卡通"
        case .oilPainting: return "油画"
        case .watercolor: return "水彩"
        case .sketch: return "素描"
        case .anime: return "动漫"
        }
    }
} 