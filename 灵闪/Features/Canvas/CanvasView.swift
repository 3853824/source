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
            .cornerRadius(10)
            .shadow(radius: 3)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: clearCanvas) {
                        Label("清除", systemImage: "trash")
                    }
                }
            }
    }
    
    func clearCanvas() {
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
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
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
            if let onDrawingChanged = parent.onDrawingChanged {
                let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                onDrawingChanged(image)
            }
        }
    }
} 