//
//  CanvasView.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI
import PencilKit

struct CanvasView: View {
    @Binding var canvasImage: UIImage?
    @Binding var drawingData: Data?
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var drawingIsActive: Bool = true
    
    var onDrawingChanged: ((UIImage) -> Void)?
    var onDrawingDataChanged: ((Data) -> Void)?
    
    var body: some View {
        CanvasRepresentable(
            canvasView: $canvasView, 
            toolPicker: $toolPicker, 
            drawingIsActive: $drawingIsActive,
            drawingData: $drawingData,
            initialImage: canvasImage,
            onDrawingChanged: onDrawingChanged,
            onDrawingDataChanged: onDrawingDataChanged
        )
        .background(Color.white)
        .onTapGesture { _ in 
            canvasView.becomeFirstResponder()
        }
        .onAppear {
            print("CanvasView - onAppear, 初始图像: \(canvasImage != nil ? "有" : "无"), 绘画数据: \(drawingData != nil ? "有" : "无")")
        }
    }
    
    // 公开清空画布方法
    public func clearCanvas() {
        canvasView.drawing = PKDrawing()
        if let onDrawingChanged = onDrawingChanged {
            let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            onDrawingChanged(image)
        }
        if let onDrawingDataChanged = onDrawingDataChanged {
            let emptyData = PKDrawing().dataRepresentation()
            onDrawingDataChanged(emptyData)
        }
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var drawingIsActive: Bool
    @Binding var drawingData: Data?
    
    var initialImage: UIImage?
    var onDrawingChanged: ((UIImage) -> Void)?
    var onDrawingDataChanged: ((Data) -> Void)?
    
    func makeUIView(context: Context) -> PKCanvasView {
        print("CanvasRepresentable - makeUIView")
        
        canvasView.delegate = context.coordinator
        
        // 尝试从之前保存的drawing数据恢复
        if let data = drawingData, let drawing = try? PKDrawing(data: data) {
            print("CanvasRepresentable - 从保存的绘画数据恢复，数据大小: \(data.count)字节")
            canvasView.drawing = drawing
        } else {
            print("CanvasRepresentable - 创建新的空白画布")
            canvasView.drawing = PKDrawing()
            
            // 如果有初始图像但没有绘画数据，将图像作为背景
            if let initialImage = initialImage {
                print("CanvasRepresentable - 有初始图像，但无绘画数据")
                // 在这里不做特殊处理，后续合成时会考虑初始图像
            }
        }
        
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        canvasView.drawingPolicy = .anyInput
        canvasView.isUserInteractionEnabled = true
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if let superview = uiView.superview {
            uiView.frame = superview.bounds
        }
        
        if drawingIsActive {
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        } else {
            toolPicker.setVisible(false, forFirstResponder: uiView)
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasRepresentable
        
        init(_ parent: CanvasRepresentable) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            print("画布绘画状态已更新")
            
            // 保存绘画数据
            let rawDrawingData = canvasView.drawing.dataRepresentation()
            if let onDrawingDataChanged = parent.onDrawingDataChanged {
                onDrawingDataChanged(rawDrawingData)
            }
            self.parent.drawingData = rawDrawingData
            
            if let onDrawingChanged = parent.onDrawingChanged {
                // 确保画布有合理的尺寸
                if canvasView.bounds.width > 0 && canvasView.bounds.height > 0 {
                    // 合成图像 - 包括背景和绘画内容
                    let renderer = UIGraphicsImageRenderer(size: canvasView.bounds.size)
                    let compositeImage = renderer.image { context in
                        // 先绘制背景图像（如果有）
                        if let initialImage = parent.initialImage {
                            initialImage.draw(in: canvasView.bounds)
                        }
                        
                        // 绘制当前画布内容
                        let drawing = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                        drawing.draw(in: canvasView.bounds)
                    }
                    
                    onDrawingChanged(compositeImage)
                } else {
                    print("警告：画布尺寸异常 - \(canvasView.bounds)")
                }
            }
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            print("开始使用绘图工具")
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            print("结束使用绘图工具")
            // 确保保存最终的绘画数据
            let rawDrawingData = canvasView.drawing.dataRepresentation()
            if let onDrawingDataChanged = parent.onDrawingDataChanged {
                onDrawingDataChanged(rawDrawingData)
            }
            self.parent.drawingData = rawDrawingData
            
            // 确保更新最终图像
            if let onDrawingChanged = parent.onDrawingChanged, canvasView.bounds.width > 0 && canvasView.bounds.height > 0 {
                // 使用与canvasViewDrawingDidChange相同的合成逻辑
                let renderer = UIGraphicsImageRenderer(size: canvasView.bounds.size)
                let compositeImage = renderer.image { context in
                    // 先绘制背景图像（如果有）
                    if let initialImage = parent.initialImage {
                        initialImage.draw(in: canvasView.bounds)
                    }
                    
                    // 绘制当前画布内容
                    let drawing = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                    drawing.draw(in: canvasView.bounds)
                }
                
                onDrawingChanged(compositeImage)
            }
        }
    }
}

// 扩展UIColor以支持透明背景
extension UIColor {
    static var transparentWhite: UIColor {
        return UIColor.white.withAlphaComponent(0.001)
    }
} 