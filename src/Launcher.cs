// PC TuneUp のランチャー。
// 役割はひとつ: 管理者権限で PCTuneUp.ps1 を起動すること。
// exe にしておくと (1) UAC のダイアログにアプリ名とアイコンが出る
// (2) スタートメニューやタスクバーに普通のアプリとして並ぶ
// (3) コンソールウィンドウが一瞬も出ない、という利点がある。
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Windows.Forms;

internal static class Launcher
{
    private const string ScriptName = "PCTuneUp.ps1";

    [STAThread]
    private static int Main(string[] args)
    {
        string dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        string script = Path.Combine(dir, ScriptName);
        if (!File.Exists(script))
        {
            Fail("PC TuneUp の本体が見つかりません:\n" + script +
                 "\n\nインストールし直してください。");
            return 1;
        }

        // 引数があるときは CLI として使われているので、コンソールを出して終了を待つ
        bool cli = args.Length > 0;

        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = FindPowerShell();
        psi.Arguments = BuildArguments(script, args, cli);
        psi.UseShellExecute = false;
        psi.WorkingDirectory = dir;
        psi.CreateNoWindow = !cli;

        try
        {
            using (Process p = Process.Start(psi))
            {
                if (p == null) { Fail("PowerShell を起動できませんでした。"); return 1; }
                if (!cli) { return 0; }   // GUI はそのまま手を離す
                p.WaitForExit();
                return p.ExitCode;
            }
        }
        catch (Exception ex)
        {
            Fail("起動に失敗しました:\n" + ex.Message);
            return 1;
        }
    }

    private static string FindPowerShell()
    {
        string system = Environment.GetFolderPath(Environment.SpecialFolder.System);
        string full = Path.Combine(system, @"WindowsPowerShell\v1.0\powershell.exe");
        return File.Exists(full) ? full : "powershell.exe";
    }

    private static string BuildArguments(string script, string[] args, bool cli)
    {
        StringBuilder sb = new StringBuilder();
        sb.Append("-NoProfile -ExecutionPolicy Bypass -STA ");
        if (!cli) { sb.Append("-WindowStyle Hidden "); }
        sb.Append("-File ").Append(Quote(script));

        // この exe のマニフェストで既に昇格済みなので、スクリプト側で再昇格させない。
        // 利用者が自分で -NoElevate を付けていた場合は重複させない。
        if (!HasArg(args, "-NoElevate")) { sb.Append(" -NoElevate"); }

        foreach (string a in args) { sb.Append(' ').Append(Quote(a)); }
        return sb.ToString();
    }

    private static bool HasArg(string[] args, string name)
    {
        foreach (string a in args)
        {
            if (string.Equals(a, name, StringComparison.OrdinalIgnoreCase)) { return true; }
        }
        return false;
    }

    private static string Quote(string s)
    {
        if (s.Length > 0 && s.IndexOfAny(new char[] { ' ', '\t', '"' }) < 0) { return s; }
        return "\"" + s.Replace("\"", "\\\"") + "\"";
    }

    private static void Fail(string message)
    {
        MessageBox.Show(message, "PC TuneUp", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
}
