# 小四爪 (Starva Auto)

这是一个基于 Flutter 开发的 Strava 数据同步工具，旨在解决运动数据在不同平台间流转的难题。

## ✨ 主要功能

*   **FIT 文件上传**：支持手动选择或通过系统分享直接上传 .fit 文件到 Strava。
*   **顽鹿自动同步**：登录顽鹿账号后，自动后台检测并同步骑行记录到 Strava。
*   **多语言支持**：支持简体中文和英文。
*   **原生体验**：适配 iOS/Android 深色模式与系统交互。

## 🛠️ 本地开发与配置

本项目依赖于 Strava API 进行数据同步，为了在本地成功运行或构建该项目，您需要配置自己的 Strava API 凭证。

### 1. 获取 Strava API 凭证
前往 [Strava 开发者后台](https://www.strava.com/settings/api) 注册并创建一个应用，获取您的 **Client ID** 和 **Client Secret**。

### 2. 配置 `.env` 文件
在项目根目录下创建一个名为 `.env` 的文件（请不要将其提交到版本控制中，项目已在 `.gitignore` 中将其忽略），并填入以下内容：

```env
STRAVA_CLIENT_ID=您的ClientID
STRAVA_CLIENT_SECRET=您的ClientSecret
```

### 3. 生成代码
本项目使用 `envied` 库来安全地管理环境变量。配置好 `.env` 文件后，您需要运行以下命令来生成包含这些密钥的 Dart 代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

执行完毕后，项目将可以正常编译运行。

## 📄 开源协议

本项目采用 **GNU General Public License v3.0 (GPL-3.0)** 协议开源。
这意味着如果您基于本项目修改或开发衍生项目，也必须开源。

