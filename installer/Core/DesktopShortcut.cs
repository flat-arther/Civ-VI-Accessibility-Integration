using System.Runtime.Versioning;

namespace CivVIAccessInstaller.Core;

/// <summary>
/// Creates a Windows desktop shortcut (.lnk) pointing at the running installer,
/// so the user can relaunch it later to check for and install updates.
/// </summary>
[SupportedOSPlatform("windows")]
internal static class DesktopShortcut
{
    private const string ShortcutName = "Civilization VI Accessibility Installer.lnk";

    public static string ShortcutPath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
        ShortcutName);

    /// <summary>
    /// Create (or overwrite) the desktop shortcut. Uses the WScript.Shell COM
    /// object so no external dependency is needed. Throws on failure so the
    /// caller can surface the reason.
    /// </summary>
    public static void Create()
    {
        // Environment.ProcessPath is correct for single-file published apps,
        // where Assembly.Location is empty.
        var target = Environment.ProcessPath
            ?? throw new InvalidOperationException("Could not determine the installer's own path.");

        var shellType = Type.GetTypeFromProgID("WScript.Shell")
            ?? throw new InvalidOperationException("Windows Script Host is not available on this system.");

        dynamic shell = Activator.CreateInstance(shellType)!;
        try
        {
            dynamic shortcut = shell.CreateShortcut(ShortcutPath);
            try
            {
                shortcut.TargetPath = target;
                shortcut.WorkingDirectory = Path.GetDirectoryName(target) ?? "";
                shortcut.Description = "Install or update the Civilization VI accessibility mod.";
                shortcut.IconLocation = $"{target}, 0";
                shortcut.Save();
            }
            finally
            {
                System.Runtime.InteropServices.Marshal.FinalReleaseComObject(shortcut);
            }
        }
        finally
        {
            System.Runtime.InteropServices.Marshal.FinalReleaseComObject(shell);
        }
    }
}
