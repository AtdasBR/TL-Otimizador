using System;
using System.IO;
using System.Windows;

namespace TLOptimizer.Setup;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        DispatcherUnhandledException += (s, args) =>
        {
            var msg = args.Exception.ToString();
            File.WriteAllText(Path.Combine(Path.GetTempPath(), "tlsetup_error.log"), msg);
            MessageBox.Show("Ocorreu um erro inesperado. Detalhes salvos em %TEMP%\\tlsetup_error.log",
                "TL Optimizer - Erro", MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
        };
        AppDomain.CurrentDomain.UnhandledException += (s, args) =>
        {
            var ex = (Exception)args.ExceptionObject;
            var msg = $"Erro fatal:\n{ex.Message}";
            File.WriteAllText(Path.Combine(Path.GetTempPath(), "tlsetup_fatal.log"), msg);
            Dispatcher.Invoke(() =>
                MessageBox.Show(msg, "TL Optimizer - Erro Fatal", MessageBoxButton.OK, MessageBoxImage.Error));
        };

        base.OnStartup(e);
    }
}
