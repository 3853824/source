# 灵闪 - AI实时绘画应用

灵闪是一款创新的AI实时绘画应用，灵感来源于无边记，让用户在绘画的同时，实时看到AI根据绘画内容生成的图像。

## 主要功能

### 核心绘画功能
- 自由绘画工具（铅笔、画笔、喷枪等）
- 形状工具（直线、矩形、圆形等）
- 橡皮擦和清除功能
- 颜色选择器和调色板
- 画笔粗细调整
- 图层管理

### AI生成功能
- 实时AI图像生成（基于用户绘画内容）
- 多种AI风格选择（写实、卡通、油画、水彩等）
- 提示词编辑（允许用户调整AI生成方向）
- 生成历史记录和收藏

### 布局和界面
- 多种布局模式（左右分屏、画板全屏+小窗口预览等）
- 深色/浅色主题
- 自定义工具栏
- 手势控制（缩放、旋转、平移）

### 文件管理
- 保存/加载项目
- 导出为图片（PNG、JPG等）
- 云同步功能
- 自动保存和版本历史

### 社交和分享
- 分享到社交媒体
- 社区画廊
- 用户作品集

## 项目结构

```
灵闪/
├── Features/
│   ├── Canvas/             # 画布相关功能
│   ├── AIGeneration/       # AI生成相关功能
│   ├── Layout/             # 布局管理
│   ├── FileManagement/     # 文件管理
│   └── Social/             # 社交分享功能
├── Core/
│   ├── Models/             # 数据模型
│   ├── Services/           # 服务层
│   └── Utils/              # 工具类
├── UI/
│   ├── Components/         # UI组件
│   └── Styles/             # 样式定义
└── Resources/              # 资源文件
```

## 技术栈

- SwiftUI：用户界面框架
- SwiftData：数据持久化
- PencilKit：绘画功能
- Core ML：本地AI处理（可选）
- 第三方AI API：云端AI生成

## 开发环境

- Xcode 15+
- iOS 17+
- Swift 5.9+

## 未来计划

- 添加更多AI风格
- 支持Apple Pencil高级功能
- 添加协作功能
- 开发macOS版本
- 添加更多社交功能

## 贡献指南

欢迎贡献代码、报告问题或提出新功能建议。请遵循以下步骤：

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 许可证

[MIT License](LICENSE) 