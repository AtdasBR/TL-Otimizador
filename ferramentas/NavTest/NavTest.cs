using System;
using System.Reflection;
using System.Windows.Forms;

class NavTest
{
    static void Main()
    {
        Application.EnableVisualStyles();
        var t = typeof(TLOptimizer.Launcher.MainForm);
        var form = (Form)Activator.CreateInstance(t);
        form.Load += (s, e) =>
        {
            var mi = t.GetMethod("SelectCategory", BindingFlags.NonPublic | BindingFlags.Instance);
            var gridF = t.GetField("_grid", BindingFlags.NonPublic | BindingFlags.Instance);
            var instF = t.GetField("_installerGrid", BindingFlags.NonPublic | BindingFlags.Instance);
            var contentF = t.GetField("_content", BindingFlags.NonPublic | BindingFlags.Instance);
            string[] cats = { "Limpeza", "Instalador" };
            foreach (var c in cats)
            {
                mi.Invoke(form, new object[] { c });
                var grid = (FlowLayoutPanel)gridF.GetValue(form);
                var inst = (FlowLayoutPanel)instF.GetValue(form);
                var content = (Panel)contentF.GetValue(form);
                System.IO.File.AppendAllText(@"C:\temp\tlnav.txt",
                    c + " (imediato): grid_count=" + grid.Controls.Count +
                    " inst_visible=" + inst.Visible +
                    " inst_count=" + inst.Controls.Count + "\n");
                if (c == "Instalador")
                {
                    // Deixa a detecção de estado rodar (o que antes causava o loop/piscar)
                    System.Threading.Thread.Sleep(4000);
                    mi.Invoke(form, new object[] { "Sistema" });
                    grid = (FlowLayoutPanel)gridF.GetValue(form);
                    inst = (FlowLayoutPanel)instF.GetValue(form);
                    content = (Panel)contentF.GetValue(form);
                    System.IO.File.AppendAllText(@"C:\temp\tlnav.txt",
                        "Sistema (apos instalador+4s): content_visible=" + content.Visible +
                        " grid_count=" + grid.Controls.Count +
                        " inst_count=" + inst.Controls.Count + "\n");
                }
            }
            Environment.Exit(0);
        };
        Application.Run(form);
    }
}
