using System.Drawing;
using System.Drawing.Imaging;
using Svg;

// Converte todos os *.svg em assets/logos para PNG 256px (branco, p/ tema escuro).
var logosDir = @"C:\Users\Administrator\.gemini\antigravity\scratch\TL-Otimizador\assets\logos";

if (!Directory.Exists(logosDir))
{
    Console.WriteLine("Pasta nao encontrada: " + logosDir);
    return;
}

var svgs = Directory.GetFiles(logosDir, "*.svg");
Console.WriteLine($"Convertendo {svgs.Length} SVGs em {logosDir}");

foreach (var svgPath in svgs)
{
    var pkg = Path.GetFileNameWithoutExtension(svgPath);
    var pngPath = Path.Combine(logosDir, pkg + ".png");

    var content = await File.ReadAllTextAsync(svgPath);
    // Deixa branco (tema escuro): troca cores escuras por branco
    content = content.Replace("#000", "#FFFFFF", StringComparison.OrdinalIgnoreCase)
                     .Replace("#000000", "#FFFFFF", StringComparison.OrdinalIgnoreCase)
                     .Replace("#111", "#FFFFFF", StringComparison.OrdinalIgnoreCase)
                     .Replace("#1A1A1A", "#FFFFFF", StringComparison.OrdinalIgnoreCase)
                     .Replace("#2D2D2D", "#FFFFFF", StringComparison.OrdinalIgnoreCase)
                     .Replace("currentColor", "#FFFFFF", StringComparison.OrdinalIgnoreCase);

    var svg = SvgDocument.Open<SvgDocument>(new MemoryStream(System.Text.Encoding.UTF8.GetBytes(content)));
    // Mantém proporção; usa 256 de base
    int size = 256;
    using var bmp = svg.Draw(size, size);
    bmp.Save(pngPath, ImageFormat.Png);
    Console.WriteLine($"  {pkg}.png OK ({bmp.Width}x{bmp.Height})");
}

Console.WriteLine("Concluido.");
