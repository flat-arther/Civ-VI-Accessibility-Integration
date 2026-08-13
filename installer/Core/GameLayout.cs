namespace CivVIAccessInstaller.Core;

internal sealed class GameLayout
{
    public const string ModFolderName = "CivVi-Accessibility-Integration";

    public string Root { get; }
    public string BinaryDirectory { get; }
    public string CivilizationExe => Path.Combine(BinaryDirectory, "CivilizationVI.exe");
    public string LightFxDll => Path.Combine(BinaryDirectory, "LightFX.dll");
    public string LightFxBackup => Path.Combine(BinaryDirectory, "LightFX.cai-original.dll");

    public string ModsDirectory => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
        "My Games", "Sid Meier's Civilization VI", "Mods");

    public string ModDirectory => Path.Combine(ModsDirectory, ModFolderName);

    public GameLayout(string root)
    {
        Root = Path.GetFullPath(root);
        BinaryDirectory = FindBinaryDirectory(Root);
    }

    private static string FindBinaryDirectory(string root)
    {
        var steam = Path.Combine(root, "Base", "Binaries", "Win64Steam");
        if (File.Exists(Path.Combine(steam, "CivilizationVI.exe"))) return steam;

        var epic = Path.Combine(root, "Base", "Binaries", "Win64EOS");
        if (File.Exists(Path.Combine(epic, "CivilizationVI.exe"))) return epic;

        throw new InvalidDataException(
            "The selected folder is not a supported Steam or Epic Games installation of Civilization VI.");
    }

    // The native integration ships as a single self-contained LightFX.dll
    // (screen-reader backends are linked in). This is the only runtime file
    // the release package carries and the installer copies into the game.
    public static readonly string[] RuntimeDllNames =
    {
        "LightFX.dll",
    };

    // Companion DLLs shipped by older (pre-2.0) integration builds. The
    // installer no longer installs them, but still removes any left behind by
    // a previous version so upgrades and uninstalls leave a clean directory.
    public static readonly string[] LegacyRuntimeDllNames =
    {
        "nvdaControllerClient64.dll",
        "SAAPI64.dll",
    };
}
