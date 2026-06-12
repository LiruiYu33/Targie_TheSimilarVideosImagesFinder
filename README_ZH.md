# Targie

[English](README.md)

> **仅支持 macOS。** Targie 是一款原生 macOS 14+ 应用，没有 Windows 或 Linux 版本，也不计划提供。

Targie 通过结合文件信息、内容哈希和视频抽帧分析，在指定文件夹中寻找相似视频。

> 仓库名 `Targie_TheSimilarVideoFinder` 只是当前阶段的项目描述；未来可能扩展到视频以外的范围（例如相似图片对比）。产品名始终是 **Targie**。

## 功能

- 递归扫描文件夹中的常见视频格式。
- 综合文件名、大小、时长、分辨率、SHA-256 和 Vision 画面特征。
- 将相似视频分组，方便并排检查。
- 在应用内直接预览选中的视频。
- 使用默认播放器打开视频，或在 Finder 中显示文件。
- 删除时必须明确选择移到废纸篓或永久删除。
- 支持英文和简体中文即时切换，并记住上次选择的语言。

## 构建（仅 macOS）

```bash
swift test
./script/build_app.sh
```

生成的应用位于：

```text
dist/Targie.app
```

开发时可以构建并启动：

```bash
./script/build_and_run.sh
```

应用使用临时签名，适合本机使用。如需通过网络或 App Store 分发，还需要 Developer ID、应用公证和对应的打包流程。

## 开源许可

Targie 采用 **[GNU General Public License v3.0](LICENSE)** 协议开源。

Copyright (C) 2026 Lirui Yu。

如果你复用本仓库的代码（无论是否修改）：

- **必须**保留版权声明，并署名原作者（Lirui Yu）。
- 任何对外分发的衍生作品**必须**同样以 GPL-3.0（或更新的 GPL 版本）开源，并向使用者提供完整源码。
- **不允许**闭源或私有化再分发。

完整法律条款见 [LICENSE](LICENSE) 文件。
