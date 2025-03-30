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
    @State private var drawingData: Data?
    
    // 由HomeView传入的项目
    var selectedProject: Project
    
    // 返回回调
    var onDismiss: (() -> Void)?
    
    // 新创建的项目需要保存
    private var isNewProject: Bool = false
    
    // 添加加载状态标记
    @State private var isInitialLoading: Bool = true
    
    init(selectedProject: Project, onDismiss: (() -> Void)? = nil) {
        print("ContentView.init - 项目: \(selectedProject.name), ID: \(selectedProject.id)")
        self.selectedProject = selectedProject
        self.onDismiss = onDismiss
        self._projectName = State(initialValue: selectedProject.name)
        self._prompt = State(initialValue: selectedProject.prompt ?? "")
        self._drawingData = State(initialValue: selectedProject.drawingData)
        
        // 检查是否为新创建的项目
        if selectedProject.canvasImage == nil && selectedProject.generatedImage == nil {
            self.isNewProject = true
            print("ContentView.init - 这是一个新项目")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                HStack(spacing: 4) {
                    Button(action: {
                        // 返回到主页
                        print("ContentView - 返回按钮被点击")
                        saveCurrentProject()
                        if let dismiss = onDismiss {
                            print("ContentView - 使用onDismiss回调返回")
                            dismiss()
                        } else {
                            print("ContentView - 使用presentationMode返回")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
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
                
                // 布局切换按钮和删除按钮
                HStack(spacing: 12) {
                    // 分屏模式按钮
                    Button(action: {
                        layoutManager.currentLayout = .splitScreen
                    }) {
                        ZStack {
                            Circle()
                                .fill(layoutManager.currentLayout == .splitScreen ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "rectangle.split.2x1")
                                .font(.system(size: 20))
                                .foregroundColor(layoutManager.currentLayout == .splitScreen ? Color.blue : Color.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 画布全屏按钮
                    Button(action: {
                        layoutManager.currentLayout = .fullCanvasWithPreview
                    }) {
                        ZStack {
                            Circle()
                                .fill(layoutManager.currentLayout == .fullCanvasWithPreview ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "rectangle.leftthird.inset.filled")
                                .font(.system(size: 20))
                                .foregroundColor(layoutManager.currentLayout == .fullCanvasWithPreview ? Color.blue : Color.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 清空画板按钮
                    Button(action: clearCanvas) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 主内容区域
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if layoutManager.currentLayout == .splitScreen {
                        // 分屏模式视图
                        SplitScreenView(
                            geometry: geometry,
                            canvasImage: $canvasImage,
                            drawingData: $drawingData,
                            canvasRatio: layoutManager.canvasRatio,
                            prompt: prompt,
                            onCanvasChange: { image in
                                canvasImage = image
                                saveCurrentProject()
                            },
                            onDrawingDataChange: { data in
                                drawingData = data
                                saveCurrentProject()
                            }
                        )
                    } else {
                        // 全屏画布视图
                        FullCanvasView(
                            canvasImage: $canvasImage,
                            drawingData: $drawingData,
                            onCanvasChange: { image in
                                canvasImage = image
                                saveCurrentProject()
                            },
                            onDrawingDataChange: { data in
                                drawingData = data
                                saveCurrentProject()
                            },
                            onSwitchToSplitScreen: {
                                layoutManager.currentLayout = .splitScreen
                            }
                        )
                    }
                }
                .onChange(of: layoutManager.currentLayout) { _, _ in
                    print("布局已变更: \(layoutManager.currentLayout.displayName)")
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
        print("ContentView.loadProject - 开始加载项目: \(selectedProject.name)")
        canvasImage = selectedProject.canvasImage
        generatedImage = selectedProject.generatedImage
        drawingData = selectedProject.drawingData
        
        print("ContentView.loadProject - canvasImage: \(canvasImage != nil ? "有值" : "nil"), generatedImage: \(generatedImage != nil ? "有值" : "nil"), drawingData: \(drawingData != nil ? "\(drawingData!.count)字节" : "nil")")
        
        // 延迟设置加载完成，确保视图有足够时间初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isInitialLoading = false
            print("ContentView.loadProject - 加载完成, isInitialLoading = false")
        }
    }
    
    private func updateProjectName() {
        print("ContentView.updateProjectName - 更新项目名称为: \(projectName)")
        selectedProject.name = projectName
    }
    
    private func saveCurrentProject() {
        print("ContentView.saveCurrentProject - 保存项目: \(selectedProject.name)")
        
        if let canvasImage = canvasImage {
            selectedProject.setCanvasImage(canvasImage)
            print("ContentView.saveCurrentProject - 保存了画布图像")
        }
        
        if let generatedImage = generatedImage {
            selectedProject.setGeneratedImage(generatedImage)
            print("ContentView.saveCurrentProject - 保存了生成图像")
        }
        
        // 保存绘画数据
        if let drawingData = drawingData {
            selectedProject.setDrawingData(drawingData)
            print("ContentView.saveCurrentProject - 保存了绘画笔迹数据 (\(drawingData.count) 字节)")
        }
        
        // 保存提示词 - 简化逻辑
        selectedProject.prompt = prompt
        
        // 更新时间戳
        selectedProject.updatedAt = Date()
        print("ContentView.saveCurrentProject - 完成保存")
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
        saveCurrentProject()
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

// 辅助视图组件定义
private struct SplitScreenView: View {
    let geometry: GeometryProxy
    @Binding var canvasImage: UIImage?
    @Binding var drawingData: Data?
    let canvasRatio: CGFloat
    let prompt: String
    let onCanvasChange: (UIImage) -> Void
    let onDrawingDataChange: (Data) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧画布
            CanvasView(
                canvasImage: $canvasImage,
                drawingData: $drawingData,
                onDrawingChanged: onCanvasChange,
                onDrawingDataChanged: onDrawingDataChange
            )
            .frame(width: geometry.size.width * canvasRatio)
            .contentShape(Rectangle())
            
            // 中间分隔线
            Divider()
            
            // 右侧AI生成
            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                AIGenerationView(
                    inputImage: $canvasImage,
                    externalPrompt: prompt
                )
            }
            .frame(width: geometry.size.width * (1 - canvasRatio))
            .contentShape(Rectangle())
            .background(Color.clear)
        }
        .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
    }
}

private struct FullCanvasView: View {
    @Binding var canvasImage: UIImage?
    @Binding var drawingData: Data?
    let onCanvasChange: (UIImage) -> Void
    let onDrawingDataChange: (Data) -> Void
    let onSwitchToSplitScreen: () -> Void
    
    var body: some View {
        ZStack {
            // 画布
            CanvasView(
                canvasImage: $canvasImage,
                drawingData: $drawingData,
                onDrawingChanged: onCanvasChange,
                onDrawingDataChanged: onDrawingDataChange
            )
            .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
            
            // 预览浮窗
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onSwitchToSplitScreen) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(radius: 3)
                                .frame(width: 160, height: 160)
                            
                            // 使用AIGenerationView但启用小型预览模式
                            AIGenerationView(
                                inputImage: $canvasImage,
                                isSmallPreview: true
                            )
                            .frame(width: 150, height: 150)
                            
                            // 预览文本提示
                            VStack {
                                Spacer()
                                Text("点击查看")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 5)
                            }
                        }
                        .frame(width: 160, height: 160)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(16)
                }
            }
        }
        .onAppear {
            print("全屏画布视图已加载")
        }
    }
}

#Preview {
    ContentView(selectedProject: Project(name: "Example Project"))
        .modelContainer(for: Project.self, inMemory: true)
}
