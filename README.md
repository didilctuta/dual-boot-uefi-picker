# Windows / Ubuntu UEFI 启动切换器

在 Windows 11 或 Ubuntu 桌面中，选择现有的 Windows Boot Manager 或 Ubuntu UEFI 启动项。可将所选系统设为默认启动，或只指定下一次启动的系统。两端都有图形界面，修改启动项时会请求系统授权。

## 下载发布包

[前往 v1.0.0 中文发布页](https://github.com/didilctuta/dual-boot-uefi-picker/releases/tag/v1.0.0)

| 文件 | 内容 | 使用方法 |
| --- | --- | --- |
| `dual-boot-uefi-picker-v1.0.0-win11.zip` | Windows 11 启动器 EXE、PowerShell 主程序、VBS 备用入口与说明 | 解压后双击 `启动切换器.exe`，不要单独移动 EXE |
| `dual-boot-uefi-picker-v1.0.0-ubuntu.zip` | Ubuntu 图形脚本、安装脚本与说明 | 解压后按 Ubuntu 目录的 README 安装 |
| `dual-boot-uefi-picker-source-v1.0.0.zip` | 两端源码与说明，不含 Windows EXE | 适合检查或自行构建 |

Windows 版以 EXE 或 VBS 启动，不提供会弹出命令窗口的 BAT 启动器。

| 当前系统 | 目录 | 启动方式 |
| --- | --- | --- |
| Windows 11 | [`WindowsBootPicker-Win11`](WindowsBootPicker-Win11/README.md) | 双击 `启动切换器.exe`，并保留同目录的 `WindowsBootPicker.ps1` |
| Ubuntu 桌面 | [`UbuntuBootPicker`](UbuntuBootPicker/README.md) | 安装依赖后运行 `install.sh`，从应用菜单启动 |

## 两种设置

- **默认启动**：调整 UEFI 固件启动顺序，持续生效，直到再次更改。
- **仅下次启动**：设置一次性启动项，固件使用后恢复原来的默认顺序。

设置完成不会自动重启。Windows 版提供单独的“现在重启”按钮；Ubuntu 版会在设置完成后询问是否重启。

## 使用前

设备必须以 UEFI 模式启动，固件中也必须已有目标系统的有效启动项。本项目只选择和调整已有启动项，不安装操作系统，也不创建或删除 EFI 启动项。请在第一次切换后确认目标系统能正常启动；远程使用时还应确认目标系统可远程连接。

具体安装步骤、所需权限和限制见各目录的 README。

## 验证范围

Windows 版启动界面已在 Windows 11 上打开；本仓库不声称已经在所有固件上验证启动项写入和实际跨系统重启。Ubuntu 版需要在目标 Ubuntu 桌面及其 UEFI 固件上验证图形授权与启动结果。
