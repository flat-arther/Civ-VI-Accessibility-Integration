using System.IO.Compression;

namespace CivVIAccessInstaller.Core;

internal sealed class Installer
{
    public sealed record ProgressInfo(string Status, int Percentage);

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
            ValidatePackage(packageMod, packageBinaries, mode);

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

            if (mode == InstallMode.Full)
            {
                ReplaceDirectory(packageMod, layout.ModDirectory);

                progress.Report(new ProgressInfo("Installing screen-reader integration...", 880));
                InstallRuntime(packageBinaries, layout);
            }
            else
            {
                InstallSightedOnly(packageMod, layout);

                progress.Report(new ProgressInfo("Removing screen-reader integration...", 880));
                RemoveRuntime(layout);
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
        var configurationPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Firaxis Games",
            "Sid Meier's Civilization VI",
            "civ6-accessibility-integration.ini");

        if (File.Exists(configurationPath))
        {
            File.Delete(configurationPath);
        }
    }

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
        string packageBinaries,
        InstallMode mode)
    {
        if (!Directory.Exists(packageMod) ||
            !File.Exists(Path.Combine(packageMod, "CivViAccess.modinfo")))
        {
            throw new InvalidDataException(
                $"The release archive does not contain {GameLayout.ModFolderName}/CivViAccess.modinfo.");
        }

        if (mode != InstallMode.Full) return;

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
    }

    private static void RemoveRuntime(GameLayout layout)
    {
        foreach (var dll in GameLayout.RuntimeDllNames)
        {
            var path = Path.Combine(layout.BinaryDirectory, dll);
            if (File.Exists(path)) File.Delete(path);
        }

        if (File.Exists(layout.LightFxBackup))
        {
            File.Move(layout.LightFxBackup, layout.LightFxDll, overwrite: true);
        }
    }

    private static void InstallSightedOnly(string packageMod, GameLayout layout)
    {
        if (Directory.Exists(layout.ModDirectory))
        {
            Directory.Delete(layout.ModDirectory, recursive: true);
        }

        Directory.CreateDirectory(layout.ModDirectory);

        var sourceModInfo = Path.Combine(packageMod, "CivViAccess.modinfo");
        var destinationModInfo = Path.Combine(layout.ModDirectory, "CivViAccess.modinfo");

        if (!File.Exists(sourceModInfo))
        {
            throw new InvalidDataException(
                "The release archive is missing CivViAccess.modinfo.");
        }

        File.Copy(sourceModInfo, destinationModInfo, overwrite: true);
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
