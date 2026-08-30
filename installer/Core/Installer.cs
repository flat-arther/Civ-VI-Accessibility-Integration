using System.IO.Compression;
using System.Xml.Linq;

namespace CivVIAccessInstaller.Core;

internal sealed class Installer
{
    public sealed record ProgressInfo(string Status, int Percentage);

    // A sighted install ships the full mod but must not touch the player's key
    // bindings. These two database files carry the entire accessibility input
    // map (new input actions plus their default key gestures) and rebindings of
    // other mods' keys, so they are dropped from the applied FRONTEND_CAI_CONFIG
    // database action. The Lua still loads; only these database entries are
    // skipped, leaving vanilla and other mods' bindings untouched.
    private static readonly string[] SightedOnlyExcludedDatabaseFiles =
    {
        "data/hotkey_config_CAI.xml",
        "data/ModCompatibilityConfig_CAI.sql",
    };

    public async Task InstallLatestAsync(
        string gameDirectory,
        InstallMode mode,
        IProgress<ProgressInfo> progress,
        CancellationToken cancellationToken)
    {
        EnsureGameIsNotRunning();

        if (!GameDetector.LooksLikeSupportedInstall(gameDirectory))
        {
            throw new InvalidDataException(
                "The selected directory is not a supported Steam or Epic Games installation of Civilization VI.");
        }

        using var github = new GitHubReleaseClient();
        progress.Report(new ProgressInfo("Checking the latest release...", 0));
        var release = await github.GetLatestAsync(cancellationToken).ConfigureAwait(false);

        var tempRoot = Path.Combine(Path.GetTempPath(), "CivVIAccessInstaller", Guid.NewGuid().ToString("N"));
        var zipPath = Path.Combine(tempRoot, release.Asset.Name);
        var extractPath = Path.Combine(tempRoot, "extracted");
        Directory.CreateDirectory(tempRoot);

        try
        {
            var byteProgress = new Progress<(long Current, long Total)>(value =>
            {
                var percent = value.Total > 0
                    ? (int)Math.Clamp(value.Current * 700L / value.Total, 0, 700)
                    : 0;
                progress.Report(new ProgressInfo("Downloading the latest release...", percent));
            });

            await github.DownloadAsync(release.Asset, zipPath, byteProgress, cancellationToken)
                .ConfigureAwait(false);

            progress.Report(new ProgressInfo("Extracting the release...", 720));
            ExtractZipSafely(zipPath, extractPath);
            cancellationToken.ThrowIfCancellationRequested();

            var packageMod = Path.Combine(extractPath, GameLayout.ModFolderName);
            var packageBinaries = Path.Combine(extractPath, "Base", "Binaries", "Win64Steam");
            ValidatePackage(packageMod, packageBinaries);

            var packagedVersion = ModInfoVersion.ReadFromFile(
                Path.Combine(packageMod, "CivViAccess.modinfo"))
                ?? throw new InvalidDataException("The packaged modinfo has no version.");

            if (ModInfoVersion.Compare(packagedVersion, release.Version) != 0)
            {
                throw new InvalidDataException(
                    $"The downloaded package version {packagedVersion} does not match " +
                    $"the release source version {release.Version}.");
            }

            var layout = new GameLayout(gameDirectory);
            progress.Report(new ProgressInfo("Installing the mod...", 790));

            // Both modes deploy the complete mod and the screen-reader runtime.
            // A sighted install differs only in that it starts suspended and
            // leaves the player's key bindings untouched (applied below).
            ReplaceDirectory(packageMod, layout.ModDirectory);

            progress.Report(new ProgressInfo("Installing screen-reader integration...", 880));
            InstallRuntime(packageBinaries, layout);

            if (mode == InstallMode.SightedOnly)
            {
                progress.Report(new ProgressInfo("Configuring the sighted-only version...", 940));
                RemoveInputMapFromModInfo(
                    Path.Combine(layout.ModDirectory, "CivViAccess.modinfo"));
                PresetSuspendedFlag();
            }

            new InstallManifest
            {
                Version = packagedVersion,
                Mode = mode,
                GameDirectory = layout.Root,
                BackedUpOriginalLightFx = File.Exists(layout.LightFxBackup),
                InstalledAtUtc = DateTime.UtcNow,
            }.Save();

            progress.Report(new ProgressInfo("Installation complete.", 1000));
        }
        finally
        {
            try
            {
                if (Directory.Exists(tempRoot)) Directory.Delete(tempRoot, recursive: true);
            }
            catch
            {
                // Temporary cleanup failure does not invalidate the installation.
            }
        }
    }

    public void Uninstall(
        string gameDirectory,
        bool removeConfiguration,
        IProgress<ProgressInfo> progress)
    {
        EnsureGameIsNotRunning();

        if (!GameDetector.LooksLikeSupportedInstall(gameDirectory))
        {
            throw new InvalidDataException(
                "The selected directory is not a supported Steam or Epic Games installation of Civilization VI.");
        }

        var layout = new GameLayout(gameDirectory);

        progress.Report(new ProgressInfo("Removing the mod...", 250));
        if (Directory.Exists(layout.ModDirectory)) Directory.Delete(layout.ModDirectory, recursive: true);

        progress.Report(new ProgressInfo("Removing screen-reader integration...", 650));
        RemoveRuntime(layout);

        if (removeConfiguration)
        {
            progress.Report(new ProgressInfo("Removing mod configuration...", 850));
            RemoveConfiguration();
        }

        InstallManifest.Delete();
        progress.Report(new ProgressInfo("Uninstall complete.", 1000));
    }

    private static void RemoveConfiguration()
    {
        var configurationPath = ConfigurationFilePath();
        if (File.Exists(configurationPath))
        {
            File.Delete(configurationPath);
        }
    }

    // The screen-reader runtime stores its configuration (including the mod
    // suspend flag) in this INI. The path is shared by the Steam and Epic
    // editions, matching the runtime's own LocalAppData location.
    private static string ConfigurationFilePath() => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Firaxis Games",
        "Sid Meier's Civilization VI",
        "civ6-accessibility-integration.ini");

    private static void EnsureGameIsNotRunning()
    {
        if (GameDetector.IsGameRunning())
        {
            throw new InvalidOperationException(
                "Civilization VI is currently running. Close the game before installing or uninstalling.");
        }
    }

    private static void ValidatePackage(
        string packageMod,
        string packageBinaries)
    {
        if (!Directory.Exists(packageMod) ||
            !File.Exists(Path.Combine(packageMod, "CivViAccess.modinfo")))
        {
            throw new InvalidDataException(
                $"The release archive does not contain {GameLayout.ModFolderName}/CivViAccess.modinfo.");
        }

        // Both the full and sighted-only versions ship the runtime DLL.
        foreach (var dll in GameLayout.RuntimeDllNames)
        {
            if (!File.Exists(Path.Combine(packageBinaries, dll)))
            {
                throw new InvalidDataException($"The release archive is missing Base/Binaries/Win64Steam/{dll}.");
            }
        }
    }

    private static void InstallRuntime(string packageBinaries, GameLayout layout)
    {
        Directory.CreateDirectory(layout.BinaryDirectory);

        // Preserve a stock or third-party LightFX.dll once. If both Tolk runtime
        // companions are already present, treat LightFX.dll as an earlier manual
        // installation of this integration rather than as the game's original DLL.
        var appearsToBeExistingIntegration =
            File.Exists(Path.Combine(layout.BinaryDirectory, "nvdaControllerClient64.dll")) &&
            File.Exists(Path.Combine(layout.BinaryDirectory, "SAAPI64.dll"));

        if (File.Exists(layout.LightFxDll) &&
            !File.Exists(layout.LightFxBackup) &&
            !appearsToBeExistingIntegration)
        {
            File.Move(layout.LightFxDll, layout.LightFxBackup);
        }

        foreach (var dll in GameLayout.RuntimeDllNames)
        {
            File.Copy(
                Path.Combine(packageBinaries, dll),
                Path.Combine(layout.BinaryDirectory, dll),
                overwrite: true);
        }

        // Remove companion DLLs left by a pre-2.0 integration; the current
        // build no longer needs them alongside LightFX.dll.
        DeleteLegacyRuntime(layout);
    }

    private static void RemoveRuntime(GameLayout layout)
    {
        foreach (var dll in GameLayout.RuntimeDllNames)
        {
            var path = Path.Combine(layout.BinaryDirectory, dll);
            if (File.Exists(path)) File.Delete(path);
        }

        DeleteLegacyRuntime(layout);

        if (File.Exists(layout.LightFxBackup))
        {
            File.Move(layout.LightFxBackup, layout.LightFxDll, overwrite: true);
        }
    }

    private static void DeleteLegacyRuntime(GameLayout layout)
    {
        foreach (var dll in GameLayout.LegacyRuntimeDllNames)
        {
            var path = Path.Combine(layout.BinaryDirectory, dll);
            if (File.Exists(path)) File.Delete(path);
        }
    }

    // Removes the accessibility input-map database files from the deployed
    // modinfo so a sighted install leaves the player's key bindings untouched.
    // Only the applied FRONTEND_CAI_CONFIG database action is edited; the files
    // remain registered on the VFS, they are simply never applied.
    private static void RemoveInputMapFromModInfo(string modInfoPath)
    {
        var document = XDocument.Load(modInfoPath, LoadOptions.PreserveWhitespace);

        var configBlock = document
            .Descendants("UpdateDatabase")
            .FirstOrDefault(e => (string?)e.Attribute("id") == "FRONTEND_CAI_CONFIG");

        if (configBlock == null)
        {
            throw new InvalidDataException(
                "The modinfo is missing the FRONTEND_CAI_CONFIG database action, " +
                "so the sighted-only input map could not be removed.");
        }

        var excluded = configBlock
            .Elements("File")
            .Where(e => SightedOnlyExcludedDatabaseFiles.Contains(
                e.Value.Trim(), StringComparer.OrdinalIgnoreCase))
            .ToList();

        foreach (var file in excluded)
        {
            // Also drop the indentation whitespace that preceded the element so
            // removing it does not leave a blank line behind.
            if (file.PreviousNode is XText whitespace &&
                whitespace.Value.Trim().Length == 0)
            {
                whitespace.Remove();
            }

            file.Remove();
        }

        document.Save(modInfoPath);
    }

    // Marks the mod as suspended so a sighted install starts with the mod off,
    // exactly as if the player had pressed Ctrl+Shift+F12 in game. The runtime
    // reads this flag from the shared configuration INI on load.
    private static void PresetSuspendedFlag()
    {
        var path = ConfigurationFilePath();
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        SetIniValue(path, "CAI", "Suspended", "true");
    }

    // Minimal INI merge: sets Section/Key to Value, preserving every other line,
    // section, and key already in the file. Section and key matches are
    // case-insensitive to mirror how the runtime reads them.
    private static void SetIniValue(string path, string section, string key, string value)
    {
        var lines = File.Exists(path)
            ? new List<string>(File.ReadAllLines(path))
            : new List<string>();

        var entry = $"{key}={value}";

        var sectionStart = -1;
        var sectionEnd = lines.Count;
        for (var i = 0; i < lines.Count; i++)
        {
            var trimmed = lines[i].Trim();
            if (!trimmed.StartsWith('[') || !trimmed.EndsWith(']')) continue;

            if (sectionStart >= 0)
            {
                sectionEnd = i;
                break;
            }

            var name = trimmed[1..^1].Trim();
            if (string.Equals(name, section, StringComparison.OrdinalIgnoreCase))
            {
                sectionStart = i;
            }
        }

        if (sectionStart < 0)
        {
            if (lines.Count > 0 && lines[^1].Trim().Length != 0) lines.Add("");
            lines.Add($"[{section}]");
            lines.Add(entry);
            File.WriteAllLines(path, lines);
            return;
        }

        for (var i = sectionStart + 1; i < sectionEnd; i++)
        {
            var trimmed = lines[i].Trim();
            var equals = trimmed.IndexOf('=');
            if (equals <= 0) continue;

            var existingKey = trimmed[..equals].Trim();
            if (string.Equals(existingKey, key, StringComparison.OrdinalIgnoreCase))
            {
                lines[i] = entry;
                File.WriteAllLines(path, lines);
                return;
            }
        }

        lines.Insert(sectionEnd, entry);
        File.WriteAllLines(path, lines);
    }

    private static void ReplaceDirectory(string source, string destination)
    {
        if (Directory.Exists(destination)) Directory.Delete(destination, recursive: true);
        Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
        CopyDirectory(source, destination);
    }

    private static void CopyDirectory(string source, string destination)
    {
        Directory.CreateDirectory(destination);

        foreach (var file in Directory.GetFiles(source))
        {
            File.Copy(file, Path.Combine(destination, Path.GetFileName(file)), overwrite: true);
        }

        foreach (var directory in Directory.GetDirectories(source))
        {
            CopyDirectory(directory, Path.Combine(destination, Path.GetFileName(directory)));
        }
    }

    private static void ExtractZipSafely(string zipPath, string destination)
    {
        Directory.CreateDirectory(destination);
        var destinationRoot = Path.GetFullPath(destination) + Path.DirectorySeparatorChar;

        using var archive = ZipFile.OpenRead(zipPath);
        foreach (var entry in archive.Entries)
        {
            var target = Path.GetFullPath(Path.Combine(destination, entry.FullName));
            if (!target.StartsWith(destinationRoot, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("The release archive contains an unsafe path.");
            }

            if (string.IsNullOrEmpty(entry.Name))
            {
                Directory.CreateDirectory(target);
                continue;
            }

            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            entry.ExtractToFile(target, overwrite: true);
        }
    }
}
