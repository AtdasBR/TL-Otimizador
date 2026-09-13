using TLOptimizer.Launcher.Design.Services;

namespace TLOptimizer.Launcher;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        ThemeManager.Initialize();
        IconService.PreloadCommon();
        Application.Run(new MainForm());
    }
}
