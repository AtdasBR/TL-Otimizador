using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace TLOptimizer.Launcher;

public sealed class ActionState
{
    public Dictionary<string, ActionItemState> Items { get; set; } = new();

    public ActionItemState Get(string id)
    {
        if (!Items.TryGetValue(id, out var state))
        {
            state = new ActionItemState();
            Items[id] = state;
        }
        return state;
    }

    public void Set(string id, ActionItemState state) => Items[id] = state;
}

public sealed class ActionItemState
{
    public bool IsOn { get; set; }
    public DateTime? LastExecution { get; set; }
}

public static class ActionStateManager
{
    private static readonly string StateFile = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "TLOptimizer",
        "action-state.json");

    private static ActionState? _state;
    private static readonly object _lock = new();

    public static ActionState Load()
    {
        lock (_lock)
        {
            if (_state != null) return _state;

            try
            {
                var dir = Path.GetDirectoryName(StateFile);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir!);

                if (File.Exists(StateFile))
                {
                    var json = File.ReadAllText(StateFile);
                    _state = JsonSerializer.Deserialize<ActionState>(json) ?? new ActionState();
                }
                else
                {
                    _state = new ActionState();
                }
            }
            catch
            {
                _state = new ActionState();
            }
            return _state;
        }
    }

    public static void Save()
    {
        lock (_lock)
        {
            try
            {
                var dir = Path.GetDirectoryName(StateFile);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir!);

                var json = JsonSerializer.Serialize(_state, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(StateFile, json);
            }
            catch { }
        }
    }

    public static ActionItemState GetState(string id) => Load().Get(id);

    public static void SetToggle(string id, bool isOn)
    {
        var state = Load();
        var item = state.Get(id);
        item.IsOn = isOn;
        state.Set(id, item);
        Save();
    }

    public static void SetLastExecution(string id)
    {
        var state = Load();
        var item = state.Get(id);
        item.LastExecution = DateTime.Now;
        state.Set(id, item);
        Save();
    }
}