//
//  ShareView.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI

struct ShareView: View {
    @ObservedObject var projectManager: ProjectManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isExporting = false
    @State private var exportError: ErrorMessage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let project = projectManager.currentProject,
                   let generatedImage = project.generatedImage {
                    
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                    
                    Text("作品名称: \(project.name)")
                        .font(.headline)
                    
                    if let prompt = project.prompt, !prompt.isEmpty {
                        Text("提示词: \(prompt)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 30) {
                        ShareButton(title: "保存到相册", icon: "photo", color: .blue) {
                            if let image = project.generatedImage {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }
                        }
                        
                        ShareButton(title: "分享", icon: "square.and.arrow.up", color: .green) {
                            isExporting = true
                            
                            // 在实际应用中，这里应该使用UIActivityViewController
                            // 这里简化处理
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isExporting = false
                            }
                        }
                        
                        ShareButton(title: "导出项目", icon: "folder", color: .orange) {
                            isExporting = true
                            
                            // 在实际应用中，这里应该调用ProjectManager的导出方法
                            // 这里简化处理
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isExporting = false
                            }
                        }
                    }
                    .padding()
                    
                } else {
                    Text("没有可分享的项目")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("分享作品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .overlay {
                if isExporting {
                    ProgressView("处理中...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert(item: $exportError) { errorMessage in
                Alert(
                    title: Text("导出失败"),
                    message: Text(errorMessage.message),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(10)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

// 使用自定义结构体代替String作为Identifiable
struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
} 