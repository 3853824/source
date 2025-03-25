//
//  ContentView.swift
//  灵闪
//
//  Created by mandel on 2025/3/15.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject private var layoutManager = LayoutManager()
    @StateObject private var aiService = AIService()
    
    @State private var canvasImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var projectName: String
    @State private var showingProjectMenu = false
    @State private var prompt: String = ""
    
    // 由HomeView传入的项目
    var selectedProject: Project
    
    // 新创建的项目需要保存
    private var isNewProject: Bool = false
    
    init(selectedProject: Project, onDismiss: (() -> Void)? = nil) {
        self.selectedProject = selectedProject
        self._projectName = State(initialValue: selectedProject.name)
        self._prompt = State(initialValue: selectedProject.prompt ?? "")
        
        // 检查是否为新创建的项目
        if selectedProject.canvasImage == nil && selectedProject.generatedImage == nil {
            self.isNewProject = true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                HStack(spacing: 4) {
                    Button(action: {
                        // 返回到主页
                        saveCurrentProject()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Button(action: {
                        showingProjectMenu = true
                    }) {
                        Text(projectName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 简化的提示词输入框，直接放在顶部中间
                TextField("添加提示词引导AI创作...", text: $prompt)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(maxWidth: 280)
                
                Spacer()
                
                // 布局切换按钮
                HStack(spacing: 8) {
                    ForEach(LayoutMode.allCases) { mode in
                        Button(action: {
                            layoutManager.setLayout(mode)
                        }) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 20))
                                .foregroundColor(layoutManager.currentLayout == mode ? .blue : .gray)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(layoutManager.currentLayout == mode ? Color.blue.opacity(0.2) : Color.clear)
                                )
                        }
                    }
                }
                
                // 清空画板按钮
                Button(action: clearCanvas) {
                    Image(systemName: "trash")
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 主内容区域
            GeometryReader { geometry in
                switch layoutManager.currentLayout {
                case .splitScreen:
                    HStack(spacing: 0) {
                        // 左侧画布
                        CanvasView(canvasImage: $canvasImage, onDrawingChanged: { image in
                            canvasImage = image
                            updateCurrentProject()
                        })
                        .frame(width: geometry.size.width * layoutManager.canvasRatio)
                        .contentShape(Rectangle()) // 确保整个区域可响应点击
                        
                        // 只保留中间分割线
                        Divider()
                        
                        // 右侧AI生成
                        AIGenerationView(
                            inputImage: $canvasImage,
                            externalPrompt: prompt
                        )
                        .frame(width: geometry.size.width * (1 - layoutManager.canvasRatio))
                        .contentShape(Rectangle())
                    }
                    // 移除整体的填充
                    .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
                    
                case .fullCanvasWithPreview:
                    ZStack {
                        // 全屏画布
                        CanvasView(canvasImage: $canvasImage, onDrawingChanged: { image in
                            canvasImage = image
                            updateCurrentProject()
                        })
                        .contentShape(Rectangle()) // 确保整个区域可响应点击
                        .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
                        
                        // 右下角预览窗口
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                AIGenerationView(
                                    inputImage: $canvasImage,
                                    externalPrompt: prompt
                                )
                                .frame(width: 200, height: 250)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding(16) // 仅保留适当的边距
                            }
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea([.bottom, .horizontal]) // 整个视图忽略安全区域
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            print("ContentView appeared - Project: \(projectName)")
            loadProject()
        }
        .onDisappear {
            print("ContentView disappeared - Saving project: \(projectName)")
            saveCurrentProject()
        }
        .sheet(isPresented: $showingProjectMenu) {
            ProjectMenuView(projectName: $projectName, 
                           onRename: updateProjectName,
                           onExport: exportAsPDF,
                           onPrint: printProject)
                .presentationDetents([.medium])
        }
    }
    
    private func loadProject() {
        canvasImage = selectedProject.canvasImage
        generatedImage = selectedProject.generatedImage
    }
    
    private func updateProjectName() {
        selectedProject.name = projectName
    }
    
    private func saveCurrentProject() {
        if let canvasImage = canvasImage {
            selectedProject.setCanvasImage(canvasImage)
        }
        
        if let generatedImage = generatedImage {
            selectedProject.setGeneratedImage(generatedImage)
        }
        
        // 保存提示词 - 简化逻辑
        selectedProject.prompt = prompt
        
        // 更新时间戳
        selectedProject.updatedAt = Date()
    }
    
    private func updateCurrentProject() {
        // 自动保存当前项目
        saveCurrentProject()
    }
    
    private func exportAsPDF() {
        // PDF导出功能实现
        print("导出为PDF")
    }
    
    private func printProject() {
        // 打印功能实现
        print("打印项目")
    }
    
    // 添加清空画布功能
    private func clearCanvas() {
        // 替代方案：使用空白的UIImage作为中间媒介重置绘图
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let blankImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.canvasImage = blankImage
        updateCurrentProject()
    }
}

// 项目菜单视图
struct ProjectMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var projectName: String
    @State private var tempName: String = ""
    @State private var showingRenameField = false
    
    var onRename: () -> Void
    var onExport: () -> Void
    var onPrint: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                // 标题栏展示项目缩略图和名称
                HStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "pencil.and.outline")
                                .foregroundColor(.blue)
                        )
                    
                    Text(projectName)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        // 分享功能
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
                }
                .padding(.vertical)
                .listRowSeparator(.hidden)
                
                if showingRenameField {
                    HStack {
                        TextField("项目名称", text: $tempName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("确定") {
                            if !tempName.isEmpty {
                                projectName = tempName
                                onRename()
                                showingRenameField = false
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                } else {
                    Button {
                        tempName = projectName
                        showingRenameField = true
                    } label: {
                        HStack {
                            Text("重命名")
                            Spacer()
                            Image(systemName: "pencil")
                        }
                    }
                }
                
                Button {
                    // 收藏功能
                } label: {
                    HStack {
                        Text("收藏")
                        Spacer()
                        Image(systemName: "heart")
                    }
                }
                
                Button {
                    // 搜索功能
                } label: {
                    HStack {
                        Text("查找")
                        Spacer()
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                Button {
                    // 对齐设置
                } label: {
                    HStack {
                        Text("对齐设置")
                        Spacer()
                        Image(systemName: "square.grid.3x3")
                    }
                }
                
                Section {
                    Button {
                        onExport()
                        dismiss()
                    } label: {
                        HStack {
                            Text("导出PDF")
                            Spacer()
                            Image(systemName: "doc.text")
                        }
                    }
                    
                    Button {
                        onPrint()
                        dismiss()
                    } label: {
                        HStack {
                            Text("打印")
                            Spacer()
                            Image(systemName: "printer")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("项目选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(selectedProject: Project(name: "Example Project"))
        .modelContainer(for: Project.self, inMemory: true)
}
