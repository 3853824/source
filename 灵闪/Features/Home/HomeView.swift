//
//  HomeView.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Project.updatedAt, order: .reverse), SortDescriptor(\Project.id)]) private var projects: [Project]
    
    @State private var searchText = ""
    @State private var showingNewProject = false
    @State private var isShowingRenameAlert = false
    @State private var newProjectName = ""
    @State private var contextMenuProject: Project?
    @State private var showConfirmDeleteAll = false
    
    // 添加项目选择回调属性
    var onSelectProject: ((Project) -> Void)?
    
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 项目网格
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 320))], spacing: 20) {
                    ForEach(filteredProjects) { project in
                        // 点击项目卡片打开项目
                        Button(action: {
                            print("点击按钮打开项目: \(project.name), ID: \(project.id)")
                            if let callback = onSelectProject {
                                callback(project)
                            }
                        }) {
                            ProjectCard(project: project)
                                .id(project.id) // 使用固定ID确保稳定性
                        }
                        .buttonStyle(CardButtonStyle())
                        .contextMenu {
                            Button {
                                contextMenuProject = project
                                newProjectName = project.name
                                isShowingRenameAlert = true
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }
                            
                            Button {
                                // 添加到收藏
                                // 此功能待实现
                            } label: {
                                Label("收藏", systemImage: "heart")
                            }
                            
                            Button {
                                duplicateProject(project)
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                // 分享功能
                                // 此功能待实现
                            } label: {
                                Label("分享", systemImage: "square.and.arrow.up")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteProject(project)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("所有看板")
        .searchable(text: $searchText, prompt: "搜索项目")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        if let callback = onSelectProject {
                            // 使用传入的回调，创建一个新项目然后调用回调
                            let project = createNewProject()
                            callback(project)
                        }
                    } label: {
                        Label("新建项目", systemImage: "plus")
                    }
                    
                    // 删除所有项目选项
                    Button(role: .destructive) {
                        // 显示确认对话框
                        showConfirmDeleteAll = true
                    } label: {
                        Label("删除所有项目", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showingNewProject) {
            ContentViewWrapper(onDismiss: {
                showingNewProject = false
            })
        }
        .alert("重命名项目", isPresented: $isShowingRenameAlert) {
            TextField("项目名称", text: $newProjectName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                if let project = contextMenuProject {
                    renameProject(project, newName: newProjectName)
                }
            }
        } message: {
            Text("请输入新的项目名称")
        }
        .alert("确认删除所有项目？", isPresented: $showConfirmDeleteAll) {
            Button("取消", role: .cancel) {}
            Button("删除全部", role: .destructive) {
                deleteAllProjects()
            }
        } message: {
            Text("此操作将删除所有项目，无法恢复。")
        }
        .onAppear {
            // 检查是否有重复项目，如果有则删除
            checkForDuplicates()
            
            // 打印当前项目数量，便于调试
            print("当前共有 \(projects.count) 个项目")
        }
    }
    
    // 检查重复项目并删除
    private func checkForDuplicates() {
        var uniqueIDs = Set<UUID>()
        var duplicates = [Project]()
        
        for project in projects {
            if uniqueIDs.contains(project.id) {
                duplicates.append(project)
            } else {
                uniqueIDs.insert(project.id)
            }
        }
        
        // 删除重复项
        for duplicate in duplicates {
            modelContext.delete(duplicate)
        }
        
        if !duplicates.isEmpty {
            print("已删除\(duplicates.count)个重复项目")
        }
    }
    
    // 重命名项目
    private func renameProject(_ project: Project, newName: String) {
        if !newName.isEmpty {
            project.name = newName
        }
    }
    
    // 复制项目
    private func duplicateProject(_ project: Project) {
        let copy = Project(name: "\(project.name) 的副本")
        if let canvasImage = project.canvasImage {
            copy.setCanvasImage(canvasImage)
        }
        if let generatedImage = project.generatedImage {
            copy.setGeneratedImage(generatedImage)
        }
        modelContext.insert(copy)
    }
    
    // 删除项目
    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
    }
    
    // 删除所有项目
    private func deleteAllProjects() {
        for project in projects {
            modelContext.delete(project)
        }
    }
    
    // 创建并直接返回新项目，但不导航
    private func createNewProject() -> Project {
        // 获取当前已有的未命名项目数量，用于命名新项目
        let unnamedProjects = modelContext.fetchUnnamedProjects()
        let suffix = unnamedProjects > 0 ? "\(unnamedProjects)" : ""
        let newName = "未命名\(suffix)"
        
        let project = Project(name: newName)
        modelContext.insert(project)
        
        // 记录创建项目的操作
        print("创建新项目: \(project.name), ID: \(project.id)")
        
        return project
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 项目图片区域
            ZStack(alignment: .topTrailing) {
                if let image = project.canvasImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else if let image = project.generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // 项目信息区域
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(project.updatedAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .frame(height: 230) // 固定卡片高度
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// 用于设置特定角落圆角的扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 用于在项目创建和显示过程中避免直接在视图更新期间修改状态
struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newProject: Project?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        Group {
            if let project = newProject {
                ContentView(selectedProject: project, onDismiss: {
                    // 返回主页
                    if let dismiss = onDismiss {
                        dismiss()
                    } else {
                        self.dismiss()
                    }
                })
            } else {
                // 显示加载指示器，直到项目创建完成
                ProgressView()
                    .onAppear {
                        createNewProject()
                    }
            }
        }
    }
    
    // 创建新项目的方法
    private func createNewProject() {
        // 获取当前已有的未命名项目数量，用于命名新项目
        let unnamedProjects = modelContext.fetchUnnamedProjects()
        let suffix = unnamedProjects > 0 ? "\(unnamedProjects)" : ""
        let newName = "未命名\(suffix)"
        
        let project = Project(name: newName)
        modelContext.insert(project)
        
        // 记录创建项目的操作
        print("通过ContentViewWrapper创建新项目: \(project.name), ID: \(project.id)")
        
        // 使用DispatchQueue.main.async延迟设置状态，避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            self.newProject = project
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Project.self, inMemory: true)
}

// ModelContext扩展，用于计算未命名项目的数量
extension ModelContext {
    func fetchUnnamedProjects() -> Int {
        do {
            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate<Project> { project in
                    project.name.starts(with: "未命名")
                }
            )
            let unnamedProjects = try fetch(descriptor)
            return unnamedProjects.count
        } catch {
            print("获取未命名项目时出错: \(error)")
            return 0
        }
    }
}

// 添加卡片按钮样式
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 