namespace CivVIAccessInstaller.Core;

internal sealed class GameLayout
{
    public const string ModFolderName = "CivVi-Accessibility-Integration";

    public string Root { get; }
    public string SteamBinaryDirectory => Path.Combine(Root, "Base", "Binaries", "Win64Steam");
    public string CivilizationExe => Path.Combine(SteamBinaryDirectory, "CivilizationVI.exe");
    public string LightFxDll => Path.Combine(SteamBinaryDirectory, "LightFX.dll");
    public string LightFxBackup => Path.Combine(SteamBinaryDirectory, "LightFX.cai-original.dll");

    public string ModsDirectory => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
        "My Games", "Sid Meier's Civilization VI", "Mods");

    public string ModDirectory => Path.Combine(ModsDirectory, ModFolderName);

    public GameLayout(string root) => Root = Path.GetFullPath(root);

    public static readonly string[] RuntimeDllNames =
    {
        "LightFX.dll",
        "nvdaControllerClient64.dll",
        "SAAPI64.dll",
    };
}
