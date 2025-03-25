//
//  ProjectManager.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import Foundation
import SwiftUI
import SwiftData

class ProjectManager: ObservableObject {
    @Published var currentProject: Project?
    
    func exportCurrentProject(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let project = currentProject,
              let canvasImage = project.canvasImage,
              let generatedImage = project.generatedImage else {
            // 处理错误情况
            let error = NSError(domain: "ProjectManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有可导出的项目或图像"])
            completion(.failure(error))
            return
        }
        
        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // 保存画布图像
            let canvasURL = tempDir.appendingPathComponent("\(project.name)_canvas.png")
            if let canvasData = canvasImage.pngData() {
                try canvasData.write(to: canvasURL)
            }
            
            // 保存生成图像
            let generatedURL = tempDir.appendingPathComponent("\(project.name)_generated.png")
            if let generatedData = generatedImage.pngData() {
                try generatedData.write(to: generatedURL)
            }
            
            // 创建元数据文件
            let metadataURL = tempDir.appendingPathComponent("metadata.json")
            let metadata: [String: Any] = [
                "name": project.name,
                "createdAt": project.createdAt.timeIntervalSince1970,
                "updatedAt": project.updatedAt.timeIntervalSince1970,
                "prompt": project.prompt ?? "",
                "aiStyle": project.aiStyle
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            try jsonData.write(to: metadataURL)
            
            // 在实际应用中，这里应该使用ZIP压缩库
            // 这里简化处理，直接返回临时目录
            completion(.success(tempDir))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func shareProject(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        exportCurrentProject { result in
            switch result {
            case .success(let url):
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                viewController.present(activityVC, animated: true)
                completion(true)
                
            case .failure(let error):
                print("导出项目失败: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
} 