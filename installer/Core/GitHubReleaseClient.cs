using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace CivVIAccessInstaller.Core;

internal sealed class GitHubReleaseClient : IDisposable
{
    private const string Owner = "flat-arther";
    private const string Repository = "Civ-VI-Accessibility-Integration";
    private const string AssetPrefix = "Civ-VI-Accessibility-Integration-";

    private static readonly Regex VersionHeading = new(
        @"^##\s+\[(?<version>[^\]]+)\](?:\s+-\s+.*)?\s*$",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    private readonly HttpClient _http = new();

    public GitHubReleaseClient()
    {
        _http.DefaultRequestHeaders.UserAgent.ParseAdd("CivVIAccessInstaller/1.0");
        _http.DefaultRequestHeaders.Accept.Add(
            new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
        _http.DefaultRequestHeaders.Add("X-GitHub-Api-Version", "2022-11-28");
        _http.Timeout = TimeSpan.FromMinutes(10);
    }

    public sealed record ReleaseAsset(string Name, long Size, string DownloadUrl);

    public sealed record ReleaseInfo(
        string TagName,
        string Version,
        string Name,
        string Changelog,
        DateTimeOffset? PublishedAt,
        ReleaseAsset Asset);

    public async Task<ReleaseInfo> GetLatestAsync(CancellationToken cancellationToken)
    {
        var url = $"https://api.github.com/repos/{Owner}/{Repository}/releases/latest";
        using var response = await _http.GetAsync(url, cancellationToken).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken)
            .ConfigureAwait(false);
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken)
            .ConfigureAwait(false);

        var root = document.RootElement;
        var tag = root.GetProperty("tag_name").GetString();
        if (string.IsNullOrWhiteSpace(tag))
        {
            throw new InvalidDataException("The latest GitHub release has no tag name.");
        }

        var version = NormalizeTagVersion(tag);
        _ = ModInfoVersion.Parse(version); // Validate the release tag now.

        var asset = FindPackageAsset(root)
            ?? throw new InvalidDataException("The latest release has no installable ZIP asset.");

        var name = root.GetProperty("name").GetString();
        if (string.IsNullOrWhiteSpace(name)) name = tag;

        DateTimeOffset? publishedAt = null;
        if (root.TryGetProperty("published_at", out var publishedElement) &&
            publishedElement.ValueKind == JsonValueKind.String &&
            DateTimeOffset.TryParse(publishedElement.GetString(), out var parsedDate))
        {
            publishedAt = parsedDate;
        }

        var changelog = await GetChangelogAtTagAsync(tag, cancellationToken)
            .ConfigureAwait(false);

        return new ReleaseInfo(tag, version, name, changelog, publishedAt, asset);
    }

    public static string BuildChangesSince(
        string changelog,
        string? installedVersion,
        string latestVersion)
    {
        var sections = ParseVersionSections(changelog);
        var selected = sections.Where(section =>
            ModInfoVersion.Compare(section.Version, latestVersion) <= 0 &&
            (string.IsNullOrWhiteSpace(installedVersion)
                ? ModInfoVersion.Compare(section.Version, latestVersion) == 0
                : ModInfoVersion.Compare(section.Version, installedVersion) > 0));

        var builder = new StringBuilder();
        foreach (var section in selected)
        {
            if (builder.Length > 0) builder.AppendLine().AppendLine();
            builder.Append(section.Text.Trim());
        }

        return builder.Length == 0
            ? "There are no newer changelog entries since your installed version."
            : builder.ToString();
    }

    private sealed record ChangelogSection(string Version, string Text);

    private static IReadOnlyList<ChangelogSection> ParseVersionSections(string changelog)
    {
        var normalized = changelog.Replace("\r\n", "\n").Replace('\r', '\n');
        var lines = normalized.Split('\n');
        var sections = new List<ChangelogSection>();

        string? currentVersion = null;
        var current = new StringBuilder();

        void FinishCurrent()
        {
            if (currentVersion == null) return;
            sections.Add(new ChangelogSection(currentVersion, current.ToString()));
            currentVersion = null;
            current.Clear();
        }

        foreach (var line in lines)
        {
            var match = VersionHeading.Match(line);
            if (match.Success)
            {
                FinishCurrent();

                var value = match.Groups["version"].Value.Trim();
                if (value.Equals("Unreleased", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                try
                {
                    _ = ModInfoVersion.Parse(value);
                }
                catch
                {
                    continue;
                }

                currentVersion = value;
                current.AppendLine(line);
                continue;
            }

            if (currentVersion != null)
            {
                current.AppendLine(line);
            }
        }

        FinishCurrent();
        return sections;
    }

    private async Task<string> GetChangelogAtTagAsync(
        string tag,
        CancellationToken cancellationToken)
    {
        var escapedTag = Uri.EscapeDataString(tag);
        var url = $"https://raw.githubusercontent.com/{Owner}/{Repository}/{escapedTag}/changelog.md";
        using var response = await _http.GetAsync(url, cancellationToken).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
    }

    private static string NormalizeTagVersion(string tag)
    {
        var version = tag.Trim();
        if (version.StartsWith('v') || version.StartsWith('V'))
        {
            version = version[1..];
        }

        if (string.IsNullOrWhiteSpace(version))
        {
            throw new InvalidDataException($"Invalid release tag: {tag}");
        }

        return version;
    }

    private static ReleaseAsset? FindPackageAsset(JsonElement root)
    {
        foreach (var asset in root.GetProperty("assets").EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            if (!name.StartsWith(AssetPrefix, StringComparison.OrdinalIgnoreCase) ||
                !name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            return new ReleaseAsset(
                name,
                asset.GetProperty("size").GetInt64(),
                asset.GetProperty("browser_download_url").GetString()
                    ?? throw new InvalidDataException($"Release asset {name} has no download URL."));
        }

        return null;
    }

    public async Task DownloadAsync(
        ReleaseAsset asset,
        string destination,
        IProgress<(long Current, long Total)> progress,
        CancellationToken cancellationToken)
    {
        using var response = await _http.GetAsync(
            asset.DownloadUrl,
            HttpCompletionOption.ResponseHeadersRead,
            cancellationToken).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        var total = response.Content.Headers.ContentLength ?? asset.Size;
        await using var input = await response.Content.ReadAsStreamAsync(cancellationToken)
            .ConfigureAwait(false);
        await using var output = new FileStream(
            destination, FileMode.Create, FileAccess.Write, FileShare.None,
            81920, FileOptions.Asynchronous);

        var buffer = new byte[81920];
        long current = 0;
        int read;
        while ((read = await input.ReadAsync(buffer, cancellationToken).ConfigureAwait(false)) > 0)
        {
            await output.WriteAsync(buffer.AsMemory(0, read), cancellationToken)
                .ConfigureAwait(false);
            current += read;
            progress.Report((current, total));
        }
    }

    public void Dispose() => _http.Dispose();
}
