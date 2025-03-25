//
//  Project.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var canvasData: Data?
    var generatedImageData: Data?
    var prompt: String?
    var aiStyle: String
    var isFavorite: Bool
    
    init(name: String, prompt: String = "", aiStyle: String = "realistic") {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.prompt = prompt
        self.aiStyle = aiStyle
        self.isFavorite = false
    }
    
    var canvasImage: UIImage? {
        guard let data = canvasData else { return nil }
        return UIImage(data: data)
    }
    
    var generatedImage: UIImage? {
        guard let data = generatedImageData else { return nil }
        return UIImage(data: data)
    }
    
    func setCanvasImage(_ image: UIImage) {
        self.canvasData = image.jpegData(compressionQuality: 0.8)
        self.updatedAt = Date()
    }
    
    func setGeneratedImage(_ image: UIImage) {
        self.generatedImageData = image.jpegData(compressionQuality: 0.8)
        self.updatedAt = Date()
    }
} 