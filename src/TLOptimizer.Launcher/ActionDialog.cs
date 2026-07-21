using System.Drawing.Drawing2D;

namespace TLOptimizer.Launcher;

public sealed partial class ActionDialog : Form
{
    private readonly bool _ligado;
    private bool _toggleValue;
    private bool _dragging;
    private int _thumbOffset;

    public bool ToggleResult => _toggleValue;

    public ActionDialog(string id, string nome, string desc, string risco)
    {
        var info = ActionData.Get(id, nome, desc, risco);
        var state = ActionStateManager.GetState(id);
        
        _ligado = state.IsOn; // Use saved state instead of default
        _toggleValue = _ligado;

        var bg = Color.FromArgb(24, 24, 28);
        var card = Color.FromArgb(30, 30, 34);
        var txt = Color.White;
        var txtDim = Color.FromArgb(148, 148, 154);
        var line = Color.FromArgb(60, 60, 66);
        var accent = Color.FromArgb(0, 103, 192);

        Text = nome;
        Size = new Size(480, 440);
        MinimumSize = new Size(440, 380);
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        ShowIcon = false;
        ShowInTaskbar = false;
        BackColor = bg;
        ForeColor = txt;
        Font = new Font("Segoe UI", 10F);

        // === Título + badge de risco ===
        var titleBar = new Panel { Dock = DockStyle.Top, Height = 60, BackColor = card, Padding = new Padding(20, 0, 20, 0) };
        var lblNome = new Label
        {
            Text = nome,
            Location = new Point(20, 10),
            AutoSize = true,
            Font = new Font("Segoe UI Semibold", 16F, FontStyle.Bold),
            ForeColor = txt
        };
        var badge = new Label
        {
            Text = risco.ToUpper(),
            Location = new Point(titleBar.Width - 90, 14),
            Size = new Size(70, 22),
            TextAlign = ContentAlignment.MiddleCenter,
            ForeColor = Color.White,
            BackColor = risco switch
            {
                "Arriscado" => Color.FromArgb(220, 70, 70),
                "Moderado" => Color.FromArgb(230, 190, 60),
                _ => Color.FromArgb(60, 190, 90)
            },
            Font = new Font("Segoe UI", 8F, FontStyle.Bold)
        };
        titleBar.Controls.AddRange(new Control[] { lblNome, badge });

        // === Botões ===
        var btnPanel = new Panel { Dock = DockStyle.Bottom, Height = 52, BackColor = bg, Padding = new Padding(20, 8, 20, 8) };
        var btnCancel = new Button
        {
            Text = "Cancelar",
            Location = new Point(btnPanel.Width - 170, 6),
            Size = new Size(72, 32),
            FlatStyle = FlatStyle.Flat,
            BackColor = card,
            ForeColor = txtDim,
            FlatAppearance = { BorderSize = 0 },
            Cursor = Cursors.Hand
        };
        btnCancel.Click += (_, _) => { DialogResult = DialogResult.Cancel; Close(); };
        var btnExecutar = new Button
        {
            Text = info.HasToggle ? "Aplicar" : "Executar",
            Location = new Point(btnPanel.Width - 86, 6),
            Size = new Size(72, 32),
            FlatStyle = FlatStyle.Flat,
            BackColor = accent,
            ForeColor = Color.White,
            FlatAppearance = { BorderSize = 0 },
            Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
            Cursor = Cursors.Hand
        };
        btnExecutar.Click += (_, _) => { DialogResult = DialogResult.OK; Close(); };
        btnPanel.Controls.AddRange(new Control[] { btnCancel, btnExecutar });
        btnPanel.Resize += (_, _) =>
        {
            btnCancel.Location = new Point(btnPanel.Width - 170, 6);
            btnExecutar.Location = new Point(btnPanel.Width - 86, 6);
        };

        // === Corpo com scroll ===
        var body = new Panel { Dock = DockStyle.Fill, BackColor = bg, Padding = new Padding(20, 16, 20, 8) };
        var scroll = new Panel { Dock = DockStyle.Fill, AutoScroll = true, BackColor = bg };

        var y = 0;

        // Descrição detalhada
        var lblDetalhes = new Label
        {
            Text = info.Detalhes,
            Location = new Point(0, y),
            AutoSize = true,
            MaximumSize = new Size(400, 0),
            ForeColor = txtDim,
            Font = new Font("Segoe UI", 9.5F)
        };
        scroll.Controls.Add(lblDetalhes);
        y = lblDetalhes.Bottom + 20;

        // Status atual (toggle ou última execução)
        if (info.HasToggle)
        {
            var statusLabel = new Label
            {
                Text = _ligado ? "Status: Ativado" : "Status: Desativado",
                Location = new Point(0, y),
                AutoSize = true,
                ForeColor = _ligado ? Color.FromArgb(60, 190, 90) : txtDim,
                Font = new Font("Segoe UI Semibold", 11F, FontStyle.Bold)
            };
            scroll.Controls.Add(statusLabel);
            y = statusLabel.Bottom + 10;
        }
        else
        {
            var lastExec = state.LastExecution;
            var statusLabel = new Label
            {
                Text = lastExec.HasValue 
                    ? $"Última execução: {lastExec.Value:dd/MM/yyyy HH:mm}" 
                    : "Status: Nunca executado",
                Location = new Point(0, y),
                AutoSize = true,
                ForeColor = lastExec.HasValue ? Color.FromArgb(60, 190, 90) : txtDim,
                Font = new Font("Segoe UI Semibold", 11F, FontStyle.Bold)
            };
            scroll.Controls.Add(statusLabel);
            y = statusLabel.Bottom + 10;
        }

        // Toggle switch (só para ações com liga/desliga)
        if (info.HasToggle)
        {
            var toggleLabel = new Label
            {
                Text = _ligado ? "Ligado" : "Desligado",
                Location = new Point(0, y + 14),
                AutoSize = true,
                ForeColor = _ligado ? Color.FromArgb(60, 190, 90) : txtDim,
                Font = new Font("Segoe UI Semibold", 11F, FontStyle.Bold)
            };
            var toggle = new Panel
            {
                Location = new Point(100, y + 6),
                Size = new Size(56, 28),
                BackColor = _ligado ? Color.FromArgb(60, 190, 90) : Color.FromArgb(80, 80, 86),
                Cursor = Cursors.Hand
            };
            _thumbOffset = _ligado ? 28 : 4;

            toggle.Paint += (s, e) =>
            {
                var g = e.Graphics; g.SmoothingMode = SmoothingMode.AntiAlias;
                using var path = RoundedRect(new Rectangle(0, 0, 55, 27), 14);
                g.FillPath(new SolidBrush(toggle.BackColor), path);
                using var thumb = RoundedRect(new Rectangle(_thumbOffset, 3, 22, 22), 11);
                g.FillPath(new SolidBrush(Color.White), thumb);
            };
            toggle.MouseDown += (_, _) => _dragging = true;
            toggle.MouseMove += (_, e) =>
            {
                if (!_dragging) return;
                _thumbOffset = Math.Clamp(e.X - 11, 4, 28);
                var novo = _thumbOffset > 16;
                if (novo != _toggleValue)
                {
                    _toggleValue = novo;
                    toggle.BackColor = _toggleValue ? Color.FromArgb(60, 190, 90) : Color.FromArgb(80, 80, 86);
                    toggleLabel.Text = _toggleValue ? "Ligado" : "Desligado";
                    toggleLabel.ForeColor = _toggleValue ? Color.FromArgb(60, 190, 90) : txtDim;
                }
                toggle.Invalidate();
            };
            toggle.MouseUp += (_, _) =>
            {
                _dragging = false;
                _thumbOffset = _toggleValue ? 28 : 4;
                toggle.Invalidate();
            };
            toggle.Click += (_, _) =>
            {
                _toggleValue = !_toggleValue;
                _thumbOffset = _toggleValue ? 28 : 4;
                toggle.BackColor = _toggleValue ? Color.FromArgb(60, 190, 90) : Color.FromArgb(80, 80, 86);
                toggleLabel.Text = _toggleValue ? "Ligado" : "Desligado";
                toggleLabel.ForeColor = _toggleValue ? Color.FromArgb(60, 190, 90) : txtDim;
                toggle.Invalidate();
            };

            scroll.Controls.Add(toggle);
            scroll.Controls.Add(toggleLabel);
            y = toggle.Bottom + 20;

            // Separator
            scroll.Controls.Add(new Panel
            {
                Location = new Point(0, y),
                Width = 400,
                Height = 1,
                BackColor = line
            });
            y += 16;
        }
        else
        {
            // Separator for execute-only
            scroll.Controls.Add(new Panel
            {
                Location = new Point(0, y),
                Width = 400,
                Height = 1,
                BackColor = line
            });
            y += 16;
        }

        // === Pros ===
        if (info.Pros is not null)
        {
            var lblProsTitle = new Label
            {
                Text = "✓ Prós de ativar",
                Location = new Point(0, y),
                AutoSize = true,
                Font = new Font("Segoe UI Semibold", 10.5F, FontStyle.Bold),
                ForeColor = Color.FromArgb(60, 190, 90)
            };
            scroll.Controls.Add(lblProsTitle);
            y = lblProsTitle.Bottom + 4;
            var lblPros = new Label
            {
                Text = info.Pros,
                Location = new Point(0, y),
                AutoSize = true,
                MaximumSize = new Size(400, 0),
                ForeColor = txtDim,
                Font = new Font("Segoe UI", 9F)
            };
            scroll.Controls.Add(lblPros);
            y = lblPros.Bottom + 16;
        }

        // === Contras ===
        if (info.Contras is not null)
        {
            var lblContrasTitle = new Label
            {
                Text = "✗ Contras de ativar",
                Location = new Point(0, y),
                AutoSize = true,
                Font = new Font("Segoe UI Semibold", 10.5F, FontStyle.Bold),
                ForeColor = Color.FromArgb(220, 120, 60)
            };
            scroll.Controls.Add(lblContrasTitle);
            y = lblContrasTitle.Bottom + 4;
            var lblContras = new Label
            {
                Text = info.Contras,
                Location = new Point(0, y),
                AutoSize = true,
                MaximumSize = new Size(400, 0),
                ForeColor = txtDim,
                Font = new Font("Segoe UI", 9F)
            };
            scroll.Controls.Add(lblContras);
        }

        body.Controls.Add(scroll);
        Controls.AddRange(new Control[] { body, btnPanel, titleBar });
    }

    private static GraphicsPath RoundedRect(Rectangle bounds, int r)
    {
        var path = new GraphicsPath();
        path.AddArc(bounds.X, bounds.Y, r, r, 180, 90);
        path.AddArc(bounds.Right - r, bounds.Y, r, r, 270, 90);
        path.AddArc(bounds.Right - r, bounds.Bottom - r, r, r, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - r, r, r, 90, 90);
        path.CloseFigure();
        return path;
    }
}
