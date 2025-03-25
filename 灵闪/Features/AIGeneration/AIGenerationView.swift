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
    
    var body: some View {
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
                    .cornerRadius(10)
                    .shadow(radius: 3)
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
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("AI风格")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AIStyle.allCases, id: \.self) { style in
                            StyleButton(style: style, selectedStyle: $selectedStyle)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                TextField("添加提示词引导AI创作...", text: $prompt)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.top, 5)
            }
            .padding(.horizontal)
        }
        .onChange(of: inputImage) { _, _ in
            generateImage()
        }
        .onChange(of: selectedStyle) { _, _ in
            generateImage()
        }
        .onChange(of: prompt) { _, _ in
            // 可以添加防抖动逻辑，避免每次输入都触发生成
            // 这里简化处理，实际应用中应该添加延迟
            generateImage()
        }
    }
    
    private func generateImage() {
        guard let inputImage = inputImage else { return }
        
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