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
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var drawingIsActive: Bool = true
    
    var onDrawingChanged: ((UIImage) -> Void)?
    
    var body: some View {
        CanvasRepresentable(canvasView: $canvasView, 
                           toolPicker: $toolPicker, 
                           drawingIsActive: $drawingIsActive,
                           onDrawingChanged: onDrawingChanged)
            .background(Color.white)
            .onTapGesture { _ in 
                canvasView.becomeFirstResponder()
            }
    }
    
    // 公开清空画布方法
    public func clearCanvas() {
        canvasView.drawing = PKDrawing()
        if let onDrawingChanged = onDrawingChanged {
            let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            onDrawingChanged(image)
        }
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var drawingIsActive: Bool
    
    var onDrawingChanged: ((UIImage) -> Void)?
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawing = PKDrawing()
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
            if let onDrawingChanged = parent.onDrawingChanged {
                // 确保画布有合理的尺寸
                if canvasView.bounds.width > 0 && canvasView.bounds.height > 0 {
                    let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                    onDrawingChanged(image)
                } else {
                    print("警告：画布尺寸异常 - \(canvasView.bounds)")
                }
            }
        }
        
        // 当画布将要开始接收绘图输入时调用
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            print("开始使用绘图工具")
        }
        
        // 当工具更改时调用
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            print("结束使用绘图工具")
            // 确保更新最终图像
            if let onDrawingChanged = parent.onDrawingChanged, canvasView.bounds.width > 0 && canvasView.bounds.height > 0 {
                let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                onDrawingChanged(image)
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