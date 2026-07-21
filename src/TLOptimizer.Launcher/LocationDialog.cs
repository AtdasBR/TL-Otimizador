using System.Drawing.Drawing2D;
using Microsoft.Win32;

namespace TLOptimizer.Launcher;

public sealed partial class LocationDialog : Form
{
    internal static readonly Dictionary<string, string?> Cache = new();
    private readonly string _actionId;
    private readonly string _actionName;

    public LocationDialog(string id, string nome)
    {
        _actionId = id;
        _actionName = nome;

        var bg = Color.FromArgb(24, 24, 28);
        var card = Color.FromArgb(30, 30, 34);
        var txt = Color.White;
        var txtDim = Color.FromArgb(148, 148, 154);
        var line = Color.FromArgb(60, 60, 66);
        var accent = Color.FromArgb(0, 103, 192);

        Text = nome;
        Size = new Size(520, 240);
        MinimumSize = new Size(480, 200);
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        ShowIcon = false;
        ShowInTaskbar = false;
        BackColor = bg;
        ForeColor = txt;
        Font = new Font("Segoe UI", 10F);

        // Title bar
        var titleBar = new Panel { Dock = DockStyle.Top, Height = 52, BackColor = card, Padding = new Padding(20, 0, 20, 0) };
        var lblTitle = new Label
        {
            Text = nome,
            Location = new Point(20, 10),
            AutoSize = true,
            Font = new Font("Segoe UI Semibold", 14F, FontStyle.Bold),
            ForeColor = txt
        };
        titleBar.Controls.Add(lblTitle);

        // Body
        var body = new Panel { Dock = DockStyle.Fill, BackColor = bg, Padding = new Padding(20, 16, 20, 12) };

        var statusLabel = new Label
        {
            Text = "Procurando...",
            Location = new Point(20, 16),
            AutoSize = true,
            ForeColor = txtDim,
            Font = new Font("Segoe UI", 10F)
        };
        body.Controls.Add(statusLabel);

        var pathBox = new TextBox
        {
            Location = new Point(20, 44),
            Width = body.Width - 40,
            Height = 28,
            BackColor = card,
            ForeColor = txt,
            BorderStyle = BorderStyle.FixedSingle,
            Font = new Font("Segoe UI", 9.5F),
            ReadOnly = true,
            Visible = false
        };

        var btnCopy = new Button
        {
            Text = "Copiar caminho",
            Location = new Point(20, 82),
            Size = new Size(130, 32),
            FlatStyle = FlatStyle.Flat,
            BackColor = accent,
            ForeColor = Color.White,
            FlatAppearance = { BorderSize = 0 },
            Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
            Cursor = Cursors.Hand,
            Visible = false
        };
        btnCopy.Click += (_, _) => { Clipboard.SetText(pathBox.Text); statusLabel.Text = "Copiado!"; };

        var btnOpen = new Button
        {
            Text = "Abrir pasta",
            Location = new Point(160, 82),
            Size = new Size(110, 32),
            FlatStyle = FlatStyle.Flat,
            BackColor = card,
            ForeColor = txt,
            FlatAppearance = { BorderSize = 1, BorderColor = line },
            Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
            Cursor = Cursors.Hand,
            Visible = false
        };
        btnOpen.Click += (_, _) => { if (Directory.Exists(pathBox.Text)) System.Diagnostics.Process.Start("explorer.exe", pathBox.Text); };

        var btnRetry = new Button
        {
            Text = "Tentar novamente",
            Location = new Point(20, 82),
            Size = new Size(140, 32),
            FlatStyle = FlatStyle.Flat,
            BackColor = accent,
            ForeColor = Color.White,
            FlatAppearance = { BorderSize = 0 },
            Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
            Cursor = Cursors.Hand,
            Visible = false
        };

        var btnClose = new Button
        {
            Text = "Fechar",
            Location = new Point(body.Width - 90, 82),
            Size = new Size(72, 32),
            FlatStyle = FlatStyle.Flat,
            BackColor = card,
            ForeColor = txtDim,
            FlatAppearance = { BorderSize = 0 },
            Cursor = Cursors.Hand,
        };
        btnClose.Click += (_, _) => Close();

        body.Controls.AddRange(new Control[] { pathBox, btnCopy, btnOpen, btnRetry, btnClose });
        body.Resize += (_, _) =>
        {
            pathBox.Width = body.ClientSize.Width - 40;
            btnClose.Location = new Point(body.ClientSize.Width - 92, 82);
        };

        Controls.AddRange(new Control[] { body, titleBar });
        Shown += (_, _) => Buscar();

        void Buscar()
        {
            if (Cache.TryGetValue(_actionId, out var cached))
            {
                MostrarResultado(cached);
                return;
            }
            Task.Run(() =>
            {
                var resultado = _actionId == "96" ? ProcurarGtaV() : ProcurarFiveM();
                lock (Cache) Cache[_actionId] = resultado;
                Invoke(() => MostrarResultado(resultado));
            });
        }

        void MostrarResultado(string? path)
        {
            if (path != null)
            {
                statusLabel.Text = "Caminho encontrado:";
                statusLabel.ForeColor = Color.FromArgb(60, 190, 90);
                pathBox.Text = path;
                pathBox.Visible = true;
                btnCopy.Visible = true;
                btnOpen.Visible = true;
                btnRetry.Visible = false;
            }
            else
            {
                statusLabel.Text = "Nao foi possivel localizar automaticamente.";
                statusLabel.ForeColor = Color.FromArgb(220, 70, 70);
                pathBox.Visible = false;
                btnCopy.Visible = false;
                btnOpen.Visible = false;
                btnRetry.Visible = true;
                btnRetry.Click += (_, _) =>
                {
                    statusLabel.Text = "Procurando...";
                    statusLabel.ForeColor = txtDim;
                    btnRetry.Visible = false;
                    Task.Run(() =>
                    {
                        var resultado = _actionId == "96" ? ProcurarGtaV() : ProcurarFiveM();
                        lock (Cache) Cache[_actionId] = resultado;
                        Invoke(() => MostrarResultado(resultado));
                    });
                };
            }
        }
    }

    private static string? ProcurarGtaV()
    {
        try
        {
            using var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V");
            var path = key?.GetValue("InstallFolder") as string;
            if (!string.IsNullOrEmpty(path) && Directory.Exists(path))
                return path;
        }
        catch { }

        var fallbacks = new[]
        {
            @"C:\Program Files\Rockstar Games\Grand Theft Auto V",
            @"C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V",
            @"C:\Program Files\Epic Games\GTAV",
        };
        foreach (var fb in fallbacks)
        {
            if (Directory.Exists(fb))
                return fb;
        }
        return null;
    }

    private static string? ProcurarFiveM()
    {
        var path = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "FiveM", "FiveM.app");
        return Directory.Exists(path) ? path : null;
    }
}
