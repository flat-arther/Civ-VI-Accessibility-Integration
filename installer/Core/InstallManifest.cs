using System.Text.Json;

namespace CivVIAccessInstaller.Core;

internal sealed class InstallManifest
{
    public string Version { get; set; } = "";
    public InstallMode Mode { get; set; }
    public string GameDirectory { get; set; } = "";
    public bool BackedUpOriginalLightFx { get; set; }
    public DateTime InstalledAtUtc { get; set; }

    private static string DirectoryPath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "CivVIAccessInstaller");

    public static string FilePath => Path.Combine(DirectoryPath, "install.json");

    public static InstallManifest? Load()
    {
        try
        {
            if (!File.Exists(FilePath)) return null;
            return JsonSerializer.Deserialize<InstallManifest>(File.ReadAllText(FilePath));
        }
        catch
        {
            return null;
        }
    }

    public void Save()
    {
        Directory.CreateDirectory(DirectoryPath);
        File.WriteAllText(FilePath, JsonSerializer.Serialize(this, new JsonSerializerOptions
        {
            WriteIndented = true,
        }));
    }

    public static void Delete()
    {
        if (File.Exists(FilePath)) File.Delete(FilePath);
    }
}
