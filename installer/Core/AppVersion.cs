using System.Reflection;

namespace CivVIAccessInstaller.Core;

/// <summary>
/// The installer's own version metadata. Independent of the mod's release version.
/// </summary>
internal static class AppVersion
{
    /// <summary>
    /// Highest mod-release major version this installer build can install.
    /// If the latest fetched release has a higher major version, the installer
    /// refuses to install it and tells the user to download a newer installer.
    ///
    /// Bump this constant whenever a new installer build gains support for a
    /// breaking mod-release major bump. The mod's major version must be raised
    /// whenever a change ships that older installers cannot handle correctly.
    /// </summary>
    public const int SupportedMaxModMajor = 1;

    public static Version Self { get; } =
        Assembly.GetExecutingAssembly().GetName().Version ?? new Version(0, 0, 0, 0);

    public static string Display => $"{Self.Major}.{Self.Minor}.{Self.Build}";
}
