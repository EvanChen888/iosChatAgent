# iOS Chat Agent 🦖

A native, high-performance iOS chat client that connects to multiple cutting-edge Large Language Models (LLMs) including GPT-4o, Claude 3.5, Gemini, and DeepSeek. Built completely in Swift and SwiftUI, it leverages an `xcodegen` architecture to maintain a clean and conflict-free codebase.

## ✨ Features

- **Multi-Model Support**: Seamlessly switch between OpenAI (GPT), Anthropic (Claude), Google (Gemini), and DeepSeek in the same app.
- **Vision & File Support**:
  - **Camera & Photos**: Take a photo or select images from your gallery. The app automatically scales and compresses images to the optimal resolution (Max 2048px, 85% JPEG quality) to save tokens and ensure high-detail LLM reading.
  - **PDF & Text Extraction**: Upload `.pdf` or `.txt` files directly. The app utilizes a lightning-fast native PDF extraction engine to pull text directly from documents.
  - **PDF Vision Mode**: Toggle to automatically rasterize PDF pages into high-res images and feed them to Vision models (like GPT-4o) for complex diagram or chart understanding.
- **Rich Markdown Rendering**: Full support for markdown rendering including tables, bold/italics, and syntax-highlighted code blocks (powered by `swift-markdown-ui`).
- **Token & Cost Tracking**: Live, accurate tracking of Prompt Tokens, Completion Tokens, and total API Costs calculated in real-time.
- **Local Persistence**: All your conversations and API keys are securely and asynchronously stored on your device's local sandbox and Keychain. No telemetry, no middle-man servers.
- **Buttery Smooth Performance**: Heavy tasks like JSON disk writing and large PDF parsing are fully offloaded to background threads (`Task.detached`), guaranteeing zero UI freezes.

## 🛠 Prerequisites

- iOS 16.0+
- Xcode 14.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating the project file)

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/EvanChen888/iosChatAgent.git
   cd iosChatAgent/LLMClient
   ```

2. **Generate the Xcode Project**:
   Since the project uses `project.yml` to define its architecture, you must run XcodeGen first:
   ```bash
   xcodegen
   ```

3. **Open & Build**:
   Open the newly generated `LLMClient.xcodeproj` in Xcode.
   Press `Cmd + R` to build and run the app on your simulator or physical iPhone.

4. **Add API Keys**:
   Inside the App, tap the Settings (Gear) icon in the top right.
   Paste your respective API keys for OpenAI, Anthropic, Gemini, or DeepSeek. All keys are stored securely in the iOS Keychain.

## 📦 Dependencies

- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) (Version 2.4.0+)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/EvanChen888/iosChatAgent/issues).

## 📄 License

This project is open-sourced under the MIT License.
