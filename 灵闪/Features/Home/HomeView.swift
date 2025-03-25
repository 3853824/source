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
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    
    @State private var searchText = ""
    @State private var selectedProject: Project?
    @State private var isShowingProjectView = false
    @State private var isShowingRenameAlert = false
    @State private var newProjectName = ""
    @State private var contextMenuProject: Project?
    
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // 主视图
            if !isShowingProjectView {
                VStack(spacing: 0) {
                    // 项目网格
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260))], spacing: 20) {
                            ForEach(filteredProjects) { project in
                                ProjectCard(project: project)
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
                                    .onTapGesture {
                                        openProject(project)
                                    }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("所有看板")
                .searchable(text: $searchText, prompt: "搜索项目")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: createAndOpenNewProject) {
                            Image(systemName: "plus")
                        }
                    }
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
            } else if let project = selectedProject {
                // 项目视图
                ContentView(selectedProject: project, onDismiss: {
                    isShowingProjectView = false
                    selectedProject = nil
                })
            }
        }
    }
    
    // 打开指定项目
    private func openProject(_ project: Project) {
        self.selectedProject = project
        self.isShowingProjectView = true
    }
    
    // 创建并打开新项目
    private func createAndOpenNewProject() {
        let newProject = Project(name: "新项目 \(Date().formatted(.dateTime.hour().minute()))")
        modelContext.insert(newProject)
        openProject(newProject)
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

#Preview {
    HomeView()
        .modelContainer(for: Project.self, inMemory: true)
} 