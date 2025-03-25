//
//  LingXianApp.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI
import SwiftData

@main
struct LingXianApp: App {
    // 应用程序的共享数据模型容器
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法创建ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(sharedModelContainer)
        }
    }
}

// 侧边栏项目枚举，用于导航
enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "主页"
    case favorites = "收藏"
    case settings = "设置"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .home:
            return "house"
        case .favorites:
            return "star"
        case .settings:
            return "gear"
        }
    }
    
    var displayName: String { self.rawValue }
}

// 主视图结构，包含分栏导航
struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: SidebarItem? = SidebarItem.home
    @State private var showingContentView = false
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List(selection: $selectedItem) {
                ForEach(SidebarItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label(item.displayName, systemImage: item.icon)
                    }
                }
            }
            .navigationTitle("灵闪")
        } detail: {
            // 详情内容区域
            ZStack {
                if let selection = selectedItem {
                    switch selection {
                    case .home:
                        HomeView(onSelectProject: { project in
                            self.selectedProject = project
                            // 延迟一帧显示内容视图，避免同步更新问题
                            DispatchQueue.main.async {
                                self.showingContentView = true
                            }
                        })
                    case .favorites:
                        Text("收藏夹")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .settings:
                        Text("设置")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    // 默认显示主页
                    HomeView(onSelectProject: { project in
                        self.selectedProject = project
                        // 延迟一帧显示内容视图，避免同步更新问题
                        DispatchQueue.main.async {
                            self.showingContentView = true
                        }
                    })
                }
                
                // 使用全屏覆盖显示内容视图
                if showingContentView, let project = selectedProject {
                    ContentView(selectedProject: project, onDismiss: {
                        self.showingContentView = false
                    })
                    .transition(.opacity)
                    .zIndex(2) // 确保内容视图在最上层
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .fullScreenCover(isPresented: $showingContentView, onDismiss: {
            // 清除已选项目
            self.selectedProject = nil
        }) {
            if let project = selectedProject {
                ContentView(selectedProject: project, onDismiss: {
                    self.showingContentView = false
                })
            }
        }
    }
} 