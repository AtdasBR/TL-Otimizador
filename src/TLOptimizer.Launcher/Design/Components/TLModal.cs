using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;
using Timer = System.Windows.Forms.Timer;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Modal dialog com backdrop overlay — trap focus, ESC para fechar, animação fade+scale.
/// </summary>
public class TLModal : Form
{
    private readonly Panel _backdrop;
    private readonly Panel _container;
    private readonly Panel _header;
    private readonly Label _titleLabel;
    private readonly Label _subtitleLabel;
    private readonly Panel _content;
    private readonly Panel _footer;
    private readonly FlowLayoutPanel _actions;

    private TLButton? _primaryButton;
    private TLButton? _secondaryButton;
    private float _animationProgress;

    public TLModal()
    {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        ShowIcon = false;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.FromArgb(0, 0, 0, 0); // Transparente
        Size = new Size(600, 440);
        MinimumSize = new Size(400, 320);
        Padding = new Padding(0);

        // Backdrop overlay
        _backdrop = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = Color.FromArgb(0, 0, 0, 180), // 70% black
            Visible = false
        };
        _backdrop.Click += (_, _) => Close(DialogResult.Cancel);

        // Container central
        _container = new Panel
        {
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(0),
            Anchor = AnchorStyles.None
        };
        _container.Paint += Container_Paint;

        // Header
        _header = new Panel
        {
            Dock = DockStyle.Top,
            Height = 64,
            BackColor = Tokens.Color.BgCard,
            Padding = new Padding(Tokens.Space.XXL, Tokens.Space.LG, Tokens.Space.XXL, Tokens.Space.MD)
        };
        _header.Paint += Header_Paint;

        _titleLabel = new Label
        {
            Dock = DockStyle.Top,
            AutoSize = true,
            Font = Tokens.Font.Create(Tokens.Font.XXL),
            ForeColor = Tokens.Color.TextPrimary,
            Text = "Título"
        };

        _subtitleLabel = new Label
        {
            Dock = DockStyle.Top,
            AutoSize = true,
            Font = Tokens.Font.Create(Tokens.Font.MD),
            ForeColor = Tokens.Color.TextSecondary,
            Text = "",
            Margin = new Padding(0, Tokens.Space.XS, 0, 0)
        };

        _header.Controls.AddRange(new Control[] { _subtitleLabel, _titleLabel });

        // Content
        _content = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXL),
            AutoScroll = true
        };

        // Footer
        _footer = new Panel
        {
            Dock = DockStyle.Bottom,
            Height = 60,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXL, Tokens.Space.MD, Tokens.Space.XXL, Tokens.Space.LG)
        };

        _actions = new FlowLayoutPanel
        {
            Dock = DockStyle.Right,
            FlowDirection = FlowDirection.RightToLeft,
            AutoSize = true,
            WrapContents = false,
            BackColor = Color.Transparent
        };

        _footer.Controls.Add(_actions);

        _container.Controls.AddRange(new Control[] { _content, _footer, _header });
        _backdrop.Controls.Add(_container);
        Controls.Add(_backdrop);

        // Animação de entrada
        _backdrop.Visible = true;
        AnimateIn();
    }

    [DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
    public Panel Content => _content;

    [Category("TL Modal")]
    public string Title
    {
        get => _titleLabel.Text;
        set => _titleLabel.Text = value;
    }

    [Category("TL Modal")]
    public string Subtitle
    {
        get => _subtitleLabel.Text;
        set
        {
            _subtitleLabel.Text = value;
            _subtitleLabel.Visible = !string.IsNullOrEmpty(value);
        }
    }

    [Category("TL Modal")]
    public TLButton? PrimaryButton
    {
        get => _primaryButton;
        set
        {
            if (_primaryButton != null)
                _actions.Controls.Remove(_primaryButton);

            _primaryButton = value;
            if (_primaryButton != null)
            {
                _primaryButton.Variant = TLButtonVariant.Primary;
                _primaryButton.ButtonSize = TLButtonSize.Medium;
                _primaryButton.Text = _primaryButton.Text ?? "Confirmar";
                _actions.Controls.Add(_primaryButton);
            }
        }
    }

    [Category("TL Modal")]
    public TLButton? SecondaryButton
    {
        get => _secondaryButton;
        set
        {
            if (_secondaryButton != null)
                _actions.Controls.Remove(_secondaryButton);

            _secondaryButton = value;
            if (_secondaryButton != null)
            {
                _secondaryButton.Variant = TLButtonVariant.Ghost;
                _secondaryButton.ButtonSize = TLButtonSize.Medium;
                _secondaryButton.Text = _secondaryButton.Text ?? "Cancelar";
                _actions.Controls.Add(_secondaryButton);
            }
        }
    }

    public static DialogResult ShowDialog(IWin32Window? owner, string title, string? subtitle,
        Control content, TLButton? primary = null, TLButton? secondary = null)
    {
        var modal = new TLModal
        {
            Title = title,
            Subtitle = subtitle ?? ""
        };

        // Backdrop em tela cheia: cobre a área de trabalho do dono (ou a tela principal)
        var wa = owner is Control oc && oc.FindForm() is { } form
            ? Screen.FromHandle(form.Handle).WorkingArea
            : Screen.PrimaryScreen?.WorkingArea ?? new Rectangle(0, 0, 1024, 768);
        modal.StartPosition = FormStartPosition.Manual;
        modal.Location = wa.Location;
        modal.Size = wa.Size;

        if (content != null)
        {
            content.Dock = DockStyle.Fill;
            modal.Content.Controls.Add(content);
        }

        modal.PrimaryButton = primary;
        modal.SecondaryButton = secondary;

        if (secondary != null)
            secondary.Click += (_, _) => modal.Close(DialogResult.Cancel);

        if (primary != null)
            primary.Click += (_, _) => modal.Close(DialogResult.OK);

        // ESC para fechar
        modal.KeyDown += (_, e) =>
        {
            if (e.KeyCode == Keys.Escape)
                modal.Close(DialogResult.Cancel);
        };

        modal.ShowDialog(owner!);
        return modal.DialogResult;
    }

    /// <summary>Fecha o modal definindo o DialogResult (retorna ao chamador).</summary>
    public void Close(DialogResult result)
    {
        DialogResult = result;
        Close();
    }

    private void AnimateIn()
    {
        _animationProgress = 0f;
        _backdrop.BackColor = Color.FromArgb(0, 0, 0, 0);
        _container.Location = new Point(
            (ClientSize.Width - _container.Width) / 2,
            (ClientSize.Height - _container.Height) / 2 + 20);

        var timer = new Timer { Interval = 16 };
        var startTime = Environment.TickCount64;
        const int duration = 200;

        timer.Tick += (_, _) =>
        {
            float t = (float)(Environment.TickCount64 - startTime) / duration;
            if (t >= 1f)
            {
                _animationProgress = 1f;
                _backdrop.BackColor = Color.FromArgb(180, 0, 0, 0);
                _container.Location = new Point(
                    (ClientSize.Width - _container.Width) / 2,
                    (ClientSize.Height - _container.Height) / 2);
                timer.Stop();
                timer.Dispose();
            }
            else
            {
                float eased = 1 - (float)Math.Pow(1 - t, 3);
                _animationProgress = eased;
                _backdrop.BackColor = Color.FromArgb((int)(180 * eased), 0, 0, 0);
                _container.Location = new Point(
                    (ClientSize.Width - _container.Width) / 2,
                    (ClientSize.Height - _container.Height) / 2 + (int)(20 * (1 - eased)));
            }
            Invalidate();
        };
        timer.Start();
    }

    private void Container_Paint(object? sender, PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = new Rectangle(0, 0, _container.Width - 1, _container.Height - 1);
        using var path = GraphicsExtensions.RoundedRect(bounds, Tokens.Radius.XL);
        using var brush = new SolidBrush(_container.BackColor);
        g.FillPath(brush, path);
        g.DrawElevation(bounds, Tokens.Radius.XL, 3);
    }

    private void Header_Paint(object? sender, PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = new Rectangle(0, 0, _header.Width - 1, _header.Height - 1);
        using var path = GraphicsExtensions.RoundedRect(new Rectangle(0, 0, _header.Width, _header.Height),
            Tokens.Radius.XL, Tokens.Radius.XL, 0, 0);
        using var brush = new SolidBrush(_header.BackColor);
        g.FillPath(brush, path);
    }

    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        if (_container != null)
        {
            _container.Size = new Size(
                Math.Min(Width - 80, 600),
                Math.Min(Height - 80, 500));
            _container.Location = new Point(
                (ClientSize.Width - _container.Width) / 2,
                (ClientSize.Height - _container.Height) / 2);
        }
    }

    protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
    {
        if (keyData == Keys.Escape)
        {
            DialogResult = DialogResult.Cancel;
            Close();
            return true;
        }
        return base.ProcessCmdKey(ref msg, keyData);
    }
}