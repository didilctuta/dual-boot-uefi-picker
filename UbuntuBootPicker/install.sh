#!/usr/bin/env bash
set -euo pipefail

script_source="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/ubuntu-boot-picker"
install -Dm755 "$script_source" "$HOME/.local/bin/ubuntu-boot-picker"

applications_dir="$HOME/.local/share/applications"
mkdir -p "$applications_dir"
desktop_file="$applications_dir/ubuntu-boot-picker.desktop"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=启动切换器
Comment=选择 Windows 或 Ubuntu 的 UEFI 启动项
Exec="$HOME/.local/bin/ubuntu-boot-picker"
Icon=preferences-system-boot
Terminal=false
Categories=System;Settings;
EOF
chmod 644 "$desktop_file"

if command -v xdg-user-dir >/dev/null 2>&1; then
    desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
else
    desktop_dir="$HOME/Desktop"
fi
if [[ -n "$desktop_dir" && -d "$desktop_dir" ]]; then
    cp "$desktop_file" "$desktop_dir/ubuntu-boot-picker.desktop"
    chmod +x "$desktop_dir/ubuntu-boot-picker.desktop"
    printf '桌面快捷方式已创建：%s\n' "$desktop_dir/ubuntu-boot-picker.desktop"
fi

printf '已安装启动切换器。可从应用菜单搜索“启动切换器”。\n'
printf '若桌面图标显示不受信任，右键图标并选择“允许启动”。\n'
