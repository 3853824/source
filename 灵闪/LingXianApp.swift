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
    @State private var selectedItem: SidebarItem? = SidebarItem.home
    
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
            NavigationStack {
                if let selection = selectedItem {
                    switch selection {
                    case .home:
                        HomeView()
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
                    HomeView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
} 