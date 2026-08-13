using CivVIAccessInstaller.Core;

namespace CivVIAccessInstaller.UI;

internal sealed class MainForm : Form
{
    private readonly TextBox _gameDirectory;
    private readonly RadioButton _full;
    private readonly RadioButton _sighted;
    private readonly Button _install;
    private readonly Button _uninstall;
    private readonly Label _installedStatus;
    private readonly Label _availableStatus;
    private readonly TextBox _changes;
    private readonly CheckBox _desktopShortcut;

    private string? _installedVersion;
    private string? _latestVersion;

    public MainForm()
    {
        Text = "Civilization VI Accessibility Installer";
        AccessibleName = Text;
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        ClientSize = new Size(720, 610);
        Font = SystemFonts.MessageBoxFont;

        var heading = new Label
        {
            Text = "Civilization VI Accessibility Integration",
            Font = new Font(Font.FontFamily, 12f, FontStyle.Bold),
            Location = new Point(16, 15),
            Size = new Size(688, 28),
        };

        var intro = new Label
        {
            Text = "Install or update the accessibility mod. Full installation includes screen-reader integration. Sighted-only installs the mod without the integration DLLs.",
            Location = new Point(16, 50),
            Size = new Size(688, 42),
        };

        var gameLabel = new Label
        {
            Text = "Civilization VI installation folder:",
            Location = new Point(16, 100),
            Size = new Size(300, 22),
        };

        _gameDirectory = new TextBox
        {
            Location = new Point(16, 125),
            Size = new Size(590, 25),
        };

        var browse = new Button
        {
            Text = "Browse...",
            Location = new Point(614, 123),
            Size = new Size(90, 29),
        };
        browse.Click += BrowseClicked;

        var modeGroup = new GroupBox
        {
            Text = "Installation type",
            Location = new Point(16, 163),
            Size = new Size(688, 88),
        };

        _full = new RadioButton
        {
            Text = "Full version — install the mod and screen-reader integration",
            Location = new Point(14, 24),
            Size = new Size(650, 24),
            Checked = true,
        };

        _sighted = new RadioButton
        {
            Text = "Sighted-only version — install the mod without screen-reader integration",
            Location = new Point(14, 52),
            Size = new Size(650, 24),
        };

        modeGroup.Controls.AddRange(new Control[] { _full, _sighted });

        _installedStatus = new Label
        {
            Location = new Point(16, 263),
            Size = new Size(688, 24),
            Text = "Checking installed version...",
        };

        _availableStatus = new Label
        {
            Location = new Point(16, 289),
            Size = new Size(688, 24),
            Text = "Checking for releases...",
        };

        var changesLabel = new Label
        {
            Text = "Changes since your installed version:",
            Location = new Point(16, 320),
            Size = new Size(400, 22),
        };

        _changes = new TextBox
        {
            Location = new Point(16, 345),
            Size = new Size(688, 170),
            Multiline = true,
            ReadOnly = true,
            ScrollBars = ScrollBars.Vertical,
            AccessibleName = "Changes since your installed version",
            Text = "Checking for changes...",
        };

        _desktopShortcut = new CheckBox
        {
            Text = "Create a desktop shortcut to this installer",
            Location = new Point(16, 525),
            Size = new Size(400, 24),
            Checked = true,
        };

        var donate = new Button
        {
            Text = "Donate",
            Location = new Point(16, 565),
            Size = new Size(100, 30),
            AccessibleName = "Donate on Ko-fi",
        };
        donate.Click += DonateClicked;

        _install = new Button
        {
            Text = "Install",
            Location = new Point(420, 565),
            Size = new Size(126, 30),
            Enabled = false,
        };
        _install.Click += InstallClicked;

        _uninstall = new Button
        {
            Text = "Uninstall",
            Location = new Point(552, 565),
            Size = new Size(90, 30),
        };
        _uninstall.Click += UninstallClicked;

        var close = new Button
        {
            Text = "Close",
            Location = new Point(648, 565),
            Size = new Size(56, 30),
        };
        close.Click += (_, _) => Close();

        Controls.AddRange(new Control[]
        {
            heading, intro, gameLabel, _gameDirectory, browse, modeGroup,
            _installedStatus, _availableStatus, changesLabel, _changes,
            _desktopShortcut, _install, _uninstall, donate, close,
        });

        AcceptButton = _install;
        CancelButton = close;

        LoadExistingState();
        Shown += async (_, _) => await RefreshReleaseInformationAsync();
    }

    private void LoadExistingState()
    {
        var manifest = InstallManifest.Load();
        var detected = manifest?.GameDirectory;
        if (string.IsNullOrWhiteSpace(detected) || !GameDetector.LooksLikeSupportedInstall(detected))
        {
            detected = GameDetector.AutoDetect();
        }

        _gameDirectory.Text = detected ?? "";

        if (manifest != null)
        {
            _full.Checked = manifest.Mode == InstallMode.Full;
            _sighted.Checked = manifest.Mode == InstallMode.SightedOnly;
        }

        var layout = !string.IsNullOrWhiteSpace(detected)
            ? new GameLayout(detected)
            : null;

        var modInfoPath = layout == null
            ? null
            : Path.Combine(layout.ModDirectory, "CivViAccess.modinfo");

        try
        {
            _installedVersion = modInfoPath == null
                ? null
                : ModInfoVersion.ReadFromFile(modInfoPath);
        }
        catch (Exception ex)
        {
            _installedVersion = null;
            _installedStatus.Text = $"Installed modinfo could not be read: {ex.Message}";
            _uninstall.Enabled = layout != null && Directory.Exists(layout.ModDirectory);
            return;
        }

        if (_installedVersion == null)
        {
            _installedStatus.Text = "The accessibility mod is not installed.";
            _uninstall.Enabled = false;
        }
        else
        {
            var modeText = manifest == null ? "installation type unknown" : ModeName(manifest.Mode);
            _installedStatus.Text = $"Installed: version {_installedVersion}, {modeText}.";
            _uninstall.Enabled = true;
        }
    }

    private async Task RefreshReleaseInformationAsync()
    {
        _install.Enabled = false;
        _availableStatus.Text = "Checking for releases...";
        _changes.Text = "Checking for changes...";

        try
        {
            using var github = new GitHubReleaseClient();
            var latest = await github.GetLatestAsync(CancellationToken.None);

            var latestMajor = ModInfoVersion.Parse(latest.Version).Major;
            if (latestMajor > AppVersion.SupportedMaxModMajor)
            {
                _latestVersion = null;
                _availableStatus.Text =
                    $"This installer is out of date. The latest release ({latest.Version}) requires a newer installer.";
                _changes.Text =
                    "A newer version of the accessibility mod is available that this installer cannot install. " +
                    "Download the latest installer from the project's releases page, then try again.";
                _install.Enabled = false;
                return;
            }

            _latestVersion = latest.Version;
            var comparison = _installedVersion == null
                ? -1
                : ModInfoVersion.Compare(_installedVersion, _latestVersion);

            if (_installedVersion == null)
            {
                _availableStatus.Text = $"Latest available version: {_latestVersion}.";
                _install.Text = "Install";
                _changes.Text = GitHubReleaseClient.BuildChangesSince(latest.Changelog, null, _latestVersion);
            }
            else if (comparison < 0)
            {
                _availableStatus.Text = $"Update available: {_installedVersion} to {_latestVersion}.";
                _install.Text = "Update";
                _changes.Text = GitHubReleaseClient.BuildChangesSince(latest.Changelog, _installedVersion, _latestVersion);
            }
            else if (comparison == 0)
            {
                _availableStatus.Text = $"Version {_installedVersion} is up to date.";
                _install.Text = "Reinstall";
                _changes.Text = "There are no newer changes since your installed version.";
            }
            else
            {
                _availableStatus.Text = $"Installed version {_installedVersion} is newer than the latest published version {_latestVersion}.";
                _install.Text = "Reinstall latest";
                _changes.Text = "No published release is newer than your installed version. Installing would downgrade the mod.";
            }

            _install.Enabled = true;
        }
        catch (Exception ex)
        {
            _availableStatus.Text = "Could not check the latest release.";
            _changes.Text = ex.Message;
            _install.Enabled = false;
        }
    }

    private void BrowseClicked(object? sender, EventArgs e)
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Select the Sid Meier's Civilization VI installation folder.",
            UseDescriptionForTitle = true,
            SelectedPath = Directory.Exists(_gameDirectory.Text) ? _gameDirectory.Text : "",
            ShowNewFolderButton = false,
        };

        if (dialog.ShowDialog(this) == DialogResult.OK)
        {
            _gameDirectory.Text = dialog.SelectedPath;
            LoadExistingState();
            _ = RefreshReleaseInformationAsync();
        }
    }

    private void InstallClicked(object? sender, EventArgs e)
    {
        if (WarnIfGameIsRunning()) return;

        var gameDirectory = _gameDirectory.Text.Trim();
        if (!GameDetector.LooksLikeSupportedInstall(gameDirectory))
        {
            MessageBox.Show(
                this,
                "The selected folder is not a supported Steam or Epic Games installation of Civilization VI. Select the folder containing the Base directory.",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            _gameDirectory.Focus();
            return;
        }

        if (_installedVersion != null && _latestVersion != null &&
            ModInfoVersion.Compare(_installedVersion, _latestVersion) > 0)
        {
            var answer = MessageBox.Show(
                this,
                $"Installed version {_installedVersion} is newer than published version {_latestVersion}. Continue and downgrade?",
                Text,
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);
            if (answer != DialogResult.Yes) return;
        }

        var mode = _sighted.Checked ? InstallMode.SightedOnly : InstallMode.Full;
        var installer = new Installer();

        SetControlsEnabled(false);
        var result = ProgressForm.Run(
            this,
            "Installing Civilization VI Accessibility Integration",
            (progress, cancellation) => installer.InstallLatestAsync(
                gameDirectory, mode, progress, cancellation));
        SetControlsEnabled(true);

        if (result.Error != null)
        {
            MessageBox.Show(this, result.Error.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        else if (result.Cancelled)
        {
            MessageBox.Show(this, "Installation was cancelled.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        else
        {
            MessageBox.Show(this, "Installation completed successfully.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            if (_desktopShortcut.Checked) CreateDesktopShortcut();
        }

        LoadExistingState();
        _ = RefreshReleaseInformationAsync();
    }

    private void CreateDesktopShortcut()
    {
        try
        {
            DesktopShortcut.Create();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                this,
                $"The mod was installed, but the desktop shortcut could not be created: {ex.Message}",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
        }
    }

    private void DonateClicked(object? sender, EventArgs e)
    {
        const string url = "https://ko-fi.com/hamadatr";
        try
        {
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url)
            {
                UseShellExecute = true,
            });
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                this,
                $"Could not open the donation page. Visit {url} in your browser.\n\n{ex.Message}",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
        }
    }

    private void UninstallClicked(object? sender, EventArgs e)
    {
        if (WarnIfGameIsRunning()) return;

        var gameDirectory = _gameDirectory.Text.Trim();
        if (!GameDetector.LooksLikeSupportedInstall(gameDirectory))
        {
            MessageBox.Show(
                this,
                "The selected folder is not a supported Steam or Epic Games installation of Civilization VI. Select the folder containing the Base directory.",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            _gameDirectory.Focus();
            return;
        }
        if (MessageBox.Show(
                this,
                "Remove the accessibility mod and restore the original LightFX DLL if it was backed up?",
                Text,
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question) != DialogResult.Yes)
        {
            return;
        }

        var configurationAnswer = MessageBox.Show(
            this,
            "Do you also want to remove the mod configuration?\n\n" +
            "Selecting Yes deletes your saved accessibility settings. " +
            "Selecting No preserves them for a future installation.",
            "Remove mod configuration?",
            MessageBoxButtons.YesNoCancel,
            MessageBoxIcon.Question);

        if (configurationAnswer == DialogResult.Cancel)
        {
            return;
        }

        var removeConfiguration = configurationAnswer == DialogResult.Yes;
        var installer = new Installer();
        SetControlsEnabled(false);
        var result = ProgressForm.Run(this, "Uninstalling", (progress, _) =>
        {
            installer.Uninstall(gameDirectory, removeConfiguration, progress);
            return Task.CompletedTask;
        });
        SetControlsEnabled(true);

        if (result.Error != null)
        {
            MessageBox.Show(this, result.Error.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        else
        {
            MessageBox.Show(this, "Uninstall completed successfully.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        LoadExistingState();
        _ = RefreshReleaseInformationAsync();
    }

    private bool WarnIfGameIsRunning()
    {
        if (!GameDetector.IsGameRunning()) return false;

        MessageBox.Show(
            this,
            "Civilization VI is currently running. Close the game before installing, updating, or uninstalling the mod.",
            Text,
            MessageBoxButtons.OK,
            MessageBoxIcon.Warning);

        return true;
    }

    private void SetControlsEnabled(bool enabled)
    {
        foreach (Control control in Controls) control.Enabled = enabled;
    }

    private static string ModeName(InstallMode mode) =>
        mode == InstallMode.Full ? "full version" : "sighted-only version";
}
