# Ubuntu 启动切换器

一个用 Zenity 下拉框选择现有 Windows/Ubuntu UEFI 启动项的 Bash 图形工具。

## 文件

- `ubuntu-boot-picker`：主程序。
- `install.sh`：安装到当前用户的 `~/.local/bin`，并创建应用菜单入口；桌面目录存在时也复制桌面快捷方式。

## 安装

Ubuntu 桌面版通常已有 Zenity。还需要 `efibootmgr` 和 `pkexec`；缺少时先安装：

```bash
sudo apt update
sudo apt install efibootmgr zenity policykit-1
```

下载本目录后，在终端进入目录并运行：

```bash
chmod +x install.sh
./install.sh
```

随后从应用菜单搜索“启动切换器”，或双击桌面快捷方式。桌面图标若提示不受信任，右键选择“允许启动”。安装只写入当前用户目录，不修改系统启动配置；只有在界面中确认设置时才会写入 UEFI 变量。

## 使用

下拉框列出从 `efibootmgr -v` 识别到的活动 Windows Boot Manager 和 Ubuntu 固件项。选择系统和操作：

- **设为默认启动**：将所选项移到 BootOrder 首位，并保留其他已有启动项的先后顺序。
- **下次启动进入所选系统**：设置 BootNext，仅覆盖下一次启动；固件消费后会回到原默认顺序。

写入 UEFI 变量时，系统会弹出 PolicyKit 身份验证。设置完成后，再由你确认是否立即重启。

## 适用条件

- Ubuntu 必须以 UEFI 模式启动，且固件中已有要选择的有效、启用的启动项。此工具不适用于 Legacy BIOS 启动。
- 需要有可用的图形会话（本机桌面或远程桌面）；纯 SSH 会话不能显示下拉窗口。
- 工具只调整已有启动项，不创建或删除 EFI 启动项。若未检测到某个系统，请先检查 `sudo efibootmgr -v`。
