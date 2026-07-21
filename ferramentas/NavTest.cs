using System;
using System.Reflection;
using System.Windows.Forms;

class NavTest {
    static void Main() {
        Application.SetHighDPIMode(HighDpiMode.SystemAware);
        Application.EnableVisualStyles();
        var t = typeof(Program).Assembly.GetType("TLOptimizer.Launcher.MainForm");
        var form = (Form)Activator.CreateInstance(t);
        form.Load += (s, e) => {
            var mi = t.GetMethod("SelectCategory", BindingFlags.NonPublic | BindingFlags.Instance);
            var gridF = t.GetField("_grid", BindingFlags.NonPublic | BindingFlags.Instance);
            var instF = t.GetField("_installerGrid", BindingFlags.NonPublic | BindingFlags.Instance);
            string[] cats = { "Limpeza", "Tweaks", "Rede", "Visual", "Privacidade", "Sistema", "Instalador", "Sistema" };
            foreach (var c in cats) {
                mi.Invoke(form, new object[]{ c });
                var grid = (FlowLayoutPanel)gridF.GetValue(form);
                var inst = (FlowLayoutPanel)instF.GetValue(form);
                System.IO.File.AppendAllText(@"C:\temp\tlnav.txt",
                    $"{c}: content_visible={form.Controls.Contains((Control)grid.Parent)} grid_count={grid.Controls.Count} inst_visible={inst.Visible} inst_count={inst.Controls.Count}\n");
            }
            Environment.Exit(0);
        };
        Application.Run(form);
    }
}
