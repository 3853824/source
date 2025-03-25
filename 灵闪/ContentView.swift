//
//  ContentView.swift
//  灵闪
//
//  Created by mandel on 2025/3/15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var layoutManager = LayoutManager()
    @StateObject private var aiService = AIService()
    
    @State private var canvasImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var projectName: String
    @State private var showingProjectMenu = false
    
    // 由HomeView传入的项目
    var selectedProject: Project
    
    // 返回到HomeView的回调函数
    var onDismiss: (() -> Void)?
    
    init(selectedProject: Project, onDismiss: (() -> Void)? = nil) {
        self.selectedProject = selectedProject
        self._projectName = State(initialValue: selectedProject.name)
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    HStack(spacing: 4) {
                        Button(action: {
                            // 返回到主页
                            saveCurrentProject()
                            if let onDismiss = onDismiss {
                                onDismiss()
                            }
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
                    
                    // 清空画板按钮
                    Button(action: clearCanvas) {
                        Image(systemName: "trash")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 布局切换器
                LayoutSwitcherView(layoutManager: layoutManager)
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                // 主内容区域
                mainContentView
                    .sheet(isPresented: $showingProjectMenu) {
                        ProjectMenuView(projectName: $projectName, 
                                       onRename: updateProjectName,
                                       onExport: exportAsPDF,
                                       onPrint: printProject)
                            .presentationDetents([.medium])
                    }
            }
            .ignoresSafeArea(.keyboard)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden)
        .onAppear {
            loadProject()
        }
    }
    
    // 拆分主内容视图
    private var mainContentView: some View {
        ZStack {
            switch layoutManager.currentLayout {
            case .splitScreen:
                splitScreenView
            case .fullCanvasWithPreview:
                fullCanvasWithPreviewView
            case .fullPreviewWithCanvas:
                fullPreviewWithCanvasView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 分屏模式视图
    private var splitScreenView: some View {
        HStack(spacing: 0) {
            // 左侧画布
            CanvasView(canvasImage: $canvasImage, onDrawingChanged: { image in
                canvasImage = image
                updateCurrentProject()
            })
            .frame(width: UIScreen.main.bounds.width * layoutManager.canvasRatio)
            
            Divider()
            
            // 右侧AI生成
            AIGenerationView(inputImage: $canvasImage)
                .frame(width: UIScreen.main.bounds.width * (1 - layoutManager.canvasRatio))
        }
    }
    
    // 全屏画布模式视图
    private var fullCanvasWithPreviewView: some View {
        ZStack {
            // 全屏画布
            CanvasView(canvasImage: $canvasImage, onDrawingChanged: { image in
                canvasImage = image
                updateCurrentProject()
            })
            
            // 右下角预览窗口
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AIGenerationView(inputImage: $canvasImage)
                        .frame(width: 200, height: 250)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                }
            }
        }
    }
    
    // 全屏预览模式视图
    private var fullPreviewWithCanvasView: some View {
        ZStack {
            // 全屏AI生成
            AIGenerationView(inputImage: $canvasImage)
            
            // 左下角画布窗口
            VStack {
                Spacer()
                HStack {
                    CanvasView(canvasImage: $canvasImage, onDrawingChanged: { image in
                        canvasImage = image
                        updateCurrentProject()
                    })
                    .frame(width: 200, height: 250)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                    
                    Spacer()
                }
            }
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
