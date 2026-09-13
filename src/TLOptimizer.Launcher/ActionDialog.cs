using System.Drawing;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design;
using TLOptimizer.Launcher.Design.Components;

namespace TLOptimizer.Launcher;

/// <summary>
/// Diálogo de ação sobre o Design System (TLModal + TLToggleSwitch).
/// Mostra detalhes, status, toggle (quando a ação liga/desliga) e prós/contras,
/// mantendo o contrato público exigido pelo MainForm.
/// </summary>
public sealed class ActionDialog : IDisposable
{
    private readonly string _titulo;
    private readonly string _subtitulo;
    private readonly Panel _content;
    private readonly bool _hasToggle;
    private TLToggleSwitch? _toggle;
    private bool _toggleValue;

    public bool ToggleResult => _toggleValue;

    public ActionDialog(string id, string nome, string desc, string risco)
    {
        var info = ActionData.Get(id, nome, desc, risco);
        var state = ActionStateManager.GetState(id);

        _titulo = nome;
        _subtitulo = risco switch
        {
            "Arriscado" => "Operação avançada — pode afetar o sistema. Leia os contras antes de confirmar.",
            "Moderado" => "Operação moderada — requer atenção.",
            _ => "Operação segura e recomendada."
        };

        _hasToggle = info.HasToggle;
        _toggleValue = state.IsOn;

        const int cw = 520;
        var panel = new Panel
        {
            Dock = DockStyle.Fill,
            AutoScroll = true,
            BackColor = Tokens.Color.BgPrimary
        };
        var y = 0;

        // Descrição detalhada
        y = AddText(panel, y, info.Detalhes, Tokens.Font.MD, Tokens.Color.TextSecondary, cw, 0);

        y = AddSeparator(panel, y, cw);

        if (_hasToggle)
        {
            var statusLabel = new Label
            {
                Location = new Point(66, y + 6),
                AutoSize = true,
                Font = Tokens.Font.Create(Tokens.Font.MD)
            };
            _toggle = new TLToggleSwitch
            {
                Checked = _toggleValue,
                Location = new Point(0, y)
            };
            _toggle.SetLabel(statusLabel, "Ativado", "Desativado");

            panel.Controls.Add(_toggle);
            panel.Controls.Add(statusLabel);
            y += 42;

            y = AddSeparator(panel, y, cw);
        }
        else
        {
            var lastExec = state.LastExecution;
            var statusText = lastExec.HasValue
                ? $"Última execução: {lastExec.Value:dd/MM/yyyy HH:mm}"
                : "Nunca executado";
            y = AddText(panel, y, "Status: " + statusText, Tokens.Font.MD,
                lastExec.HasValue ? Tokens.Color.AccentSuccess : Tokens.Color.TextMuted, cw, 0);

            y = AddSeparator(panel, y, cw);
        }

        if (!string.IsNullOrEmpty(info.Pros))
        {
            y = AddText(panel, y, "✓ Prós de ativar", Tokens.Font.MD, Tokens.Color.AccentSuccess, cw, 14);
            y = AddText(panel, y, info.Pros, Tokens.Font.SM, Tokens.Color.TextSecondary, cw, 4);
        }

        if (!string.IsNullOrEmpty(info.Contras))
        {
            y = AddText(panel, y, "✗ Contras de ativar", Tokens.Font.MD, Tokens.Color.AccentWarning, cw, 14);
            y = AddText(panel, y, info.Contras, Tokens.Font.SM, Tokens.Color.TextSecondary, cw, 4);
        }

        panel.Height = y + 8;
        _content = panel;
    }

    private static int AddText(Panel panel, int y, string text, (float Size, FontStyle Style, int LineHeight) font, Color color, int cw, int marginTop)
    {
        y += marginTop;
        var lbl = new Label
        {
            Text = text,
            Location = new Point(0, y),
            AutoSize = true,
            MaximumSize = new Size(cw, 0),
            Font = Tokens.Font.Create(font),
            ForeColor = color
        };
        panel.Controls.Add(lbl);
        return lbl.Bottom;
    }

    private static int AddSeparator(Panel panel, int y, int cw)
    {
        y += 12;
        panel.Controls.Add(new Panel
        {
            Location = new Point(0, y),
            Size = new Size(cw, 1),
            BackColor = Tokens.Color.BorderSubtle
        });
        return y + 13;
    }

    public DialogResult ShowDialog(IWin32Window? owner)
    {
        var primary = new TLButton { Text = _hasToggle ? "Aplicar" : "Executar" };
        primary.Click += (_, _) =>
        {
            if (_toggle != null) _toggleValue = _toggle.Checked;
        };

        var secondary = new TLButton { Text = "Cancelar" };

        return TLModal.ShowDialog(owner, _titulo, _subtitulo, _content, primary, secondary);
    }

    public void Dispose() { }
}