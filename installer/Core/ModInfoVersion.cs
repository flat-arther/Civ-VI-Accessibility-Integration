using System.Xml.Linq;

namespace CivVIAccessInstaller.Core;

internal static class ModInfoVersion
{
    public static string? ReadFromFile(string path)
    {
        if (!File.Exists(path)) return null;
        using var stream = File.OpenRead(path);
        return ReadFromStream(stream);
    }

    public static string ReadFromStream(Stream stream)
    {
        var document = XDocument.Load(stream, LoadOptions.None);
        var mod = document.Root;
        if (mod == null || !string.Equals(mod.Name.LocalName, "Mod", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidDataException("The modinfo file does not contain a Mod root element.");
        }

        var version = mod.Attribute("version")?.Value?.Trim();
        if (string.IsNullOrWhiteSpace(version))
        {
            throw new InvalidDataException("The Mod element has no version attribute.");
        }

        return version;
    }

    public static Version Parse(string value)
    {
        var normalized = value.Trim();
        if (normalized.StartsWith('v')) normalized = normalized[1..];
        normalized = normalized.Split('-', 2)[0];

        if (!Version.TryParse(normalized, out var version))
        {
            throw new InvalidDataException($"Invalid mod version: {value}");
        }

        return version;
    }

    public static int Compare(string left, string right) => Parse(left).CompareTo(Parse(right));
}
