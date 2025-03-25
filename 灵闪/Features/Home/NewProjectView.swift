//
//  NewProjectView.swift
//  灵闪
//
//  Created by AI Assistant on 2025/3/15.
//

import SwiftUI
import SwiftData

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var selectedTemplate: ProjectTemplate = .blank
    @FocusState private var isNameFieldFocused: Bool
    
    var onProjectCreated: ((Project) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("项目信息")) {
                        TextField("项目名称", text: $projectName)
                            .focused($isNameFieldFocused)
                    }
                    
                    Section(header: Text("模板")) {
                        ForEach(ProjectTemplate.allCases, id: \.self) { template in
                            Button(action: {
                                selectedTemplate = template
                            }) {
                                HStack {
                                    Image(systemName: template.iconName)
                                        .foregroundColor(template.iconColor)
                                        .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(template.displayName)
                                            .font(.headline)
                                        
                                        Text(template.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedTemplate == template {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 底部按钮区域
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                    
                    Button("创建项目") {
                        createProject()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .disabled(projectName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("新建项目")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 自动聚焦到项目名称输入框
                isNameFieldFocused = true
            }
        }
    }
    
    private func createProject() {
        let newProject = Project(name: projectName)
        modelContext.insert(newProject)
        
        // 如果提供了回调函数，则调用它
        if let onProjectCreated = onProjectCreated {
            onProjectCreated(newProject)
        }
        
        dismiss()
    }
}

enum ProjectTemplate: String, CaseIterable {
    case blank
    case landscape
    case portrait
    
    var displayName: String {
        switch self {
        case .blank: return "空白画板"
        case .landscape: return "横向画板"
        case .portrait: return "纵向画板"
        }
    }
    
    var description: String {
        switch self {
        case .blank: return "从空白画布开始创作"
        case .landscape: return "适合横向设计的预设画布"
        case .portrait: return "适合纵向设计的预设画布"
        }
    }
    
    var iconName: String {
        switch self {
        case .blank: return "square"
        case .landscape: return "rectangle"
        case .portrait: return "rectangle.portrait"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .blank: return .blue
        case .landscape: return .green
        case .portrait: return .orange
        }
    }
} 