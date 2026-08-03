using Microsoft.Win32;
using System.Text.RegularExpressions;

namespace CivVIAccessInstaller.Core;

internal static class GameDetector
{
    private const string SteamAppId = "289070";

    public static string? AutoDetect()
    {
        var candidates = new List<string>();
        Add(candidates, Environment.GetEnvironmentVariable("CIV6_DIR"));
        AddUninstallLocations(candidates);
        AddSteamLibraries(candidates);

        Add(candidates, Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
            "Steam", "steamapps", "common", "Sid Meier's Civilization VI"));

        Add(candidates, Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            "Steam", "steamapps", "common", "Sid Meier's Civilization VI"));

        return candidates
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault(LooksLikeSteamInstall);
    }

    public static bool LooksLikeSteamInstall(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return false;
        try
        {
            return File.Exists(Path.Combine(
                path, "Base", "Binaries", "Win64Steam", "CivilizationVI.exe"));
        }
        catch
        {
            return false;
        }
    }

    private static void AddUninstallLocations(List<string> candidates)
    {
        string[] keys =
        {
            $@"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App {SteamAppId}",
            $@"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App {SteamAppId}",
        };

        foreach (var keyPath in keys)
        {
            AddRegistryValue(candidates, Registry.LocalMachine, keyPath, "InstallLocation");
            AddRegistryValue(candidates, Registry.CurrentUser, keyPath, "InstallLocation");
        }
    }

    private static void AddSteamLibraries(List<string> candidates)
    {
        var steamRoots = new List<string>();
        AddRegistryValue(steamRoots, Registry.CurrentUser, @"Software\Valve\Steam", "SteamPath");
        AddRegistryValue(steamRoots, Registry.CurrentUser, @"Software\Valve\Steam", "SteamExe", true);

        Add(steamRoots, Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam"));

        foreach (var steamRootValue in steamRoots.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var steamRoot = steamRootValue;
            if (File.Exists(steamRoot)) steamRoot = Path.GetDirectoryName(steamRoot) ?? steamRoot;

            Add(candidates, Path.Combine(
                steamRoot, "steamapps", "common", "Sid Meier's Civilization VI"));

            var vdf = Path.Combine(steamRoot, "steamapps", "libraryfolders.vdf");
            if (!File.Exists(vdf)) continue;

            try
            {
                var text = File.ReadAllText(vdf);
                foreach (Match match in Regex.Matches(text, "\\\"path\\\"\\s+\\\"([^\\\"]+)\\\""))
                {
                    var library = match.Groups[1].Value.Replace("\\\\", "\\");
                    Add(candidates, Path.Combine(
                        library, "steamapps", "common", "Sid Meier's Civilization VI"));
                }
            }
            catch
            {
                // Continue with the other detection methods.
            }
        }
    }

    private static void AddRegistryValue(
        List<string> candidates,
        RegistryKey root,
        string keyPath,
        string valueName,
        bool valueMayBeFile = false)
    {
        try
        {
            using var key = root.OpenSubKey(keyPath);
            var value = key?.GetValue(valueName) as string;
            if (valueMayBeFile && File.Exists(value)) value = Path.GetDirectoryName(value);
            Add(candidates, value);
        }
        catch
        {
            // Registry detection is best effort.
        }
    }

    private static void Add(List<string> values, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value)) values.Add(value.Trim().Trim('"'));
    }
}
