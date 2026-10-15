using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class Launcher
{
    [STAThread]
    private static void Main()
    {
        string script = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "WindowsBootPicker.ps1");
        if (!File.Exists(script))
        {
            MessageBox.Show("找不到 WindowsBootPicker.ps1，请将它与启动切换器.exe 放在同一文件夹。",
                "Windows 启动切换器", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
            @"System32\WindowsPowerShell\v1.0\powershell.exe");
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = powershell,
                Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -STA -File \"" + script + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            });
        }
        catch (Exception error)
        {
            MessageBox.Show("启动失败：\n" + error.Message, "Windows 启动切换器",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
