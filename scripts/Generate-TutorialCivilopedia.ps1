param(
    [string]$CatalogPath = (Join-Path $PSScriptRoot '..\src\UI\uiManager\CAIUITutorialCatalog.lua'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\src\data\tutorial_civilopedia_CAI.xml')
)

$ErrorActionPreference = 'Stop'

function Get-DefinitionBlock {
    param(
        [string]$Source,
        [string]$StartMarker,
        [string]$EndMarker
    )

    $start = $Source.IndexOf($StartMarker, [StringComparison]::Ordinal)
    if ($start -lt 0) {
        throw "Could not find catalog marker: $StartMarker"
    }
    $start += $StartMarker.Length

    $end = $Source.IndexOf($EndMarker, $start, [StringComparison]::Ordinal)
    if ($end -lt 0) {
        throw "Could not find catalog marker: $EndMarker"
    }
    return $Source.Substring($start, $end - $start)
}

function Read-Definitions {
    param(
        [string]$Block,
        [bool]$UseGeneratedTitle
    )

    $definitions = @()
    $entryPattern = '(?ms)^    \{\r?\n(?<Body>.*?)^    \},\r?$'
    foreach ($entryMatch in [regex]::Matches($Block, $entryPattern)) {
        $body = $entryMatch.Groups['Body'].Value
        $idMatch = [regex]::Match($body, '(?m)^\s{8}Id = "([^"]+)"')
        if (-not $idMatch.Success) {
            throw 'A tutorial catalog entry has no Id.'
        }
        $id = $idMatch.Groups[1].Value

        if ($UseGeneratedTitle) {
            $title = "LOC_CAI_TUTORIAL_${id}_TITLE"
        }
        else {
            $titleMatch = [regex]::Match($body, '(?m)^\s{8}Title = "([^"]+)"')
            if (-not $titleMatch.Success) {
                throw "Context tutorial $id has no static Title tag."
            }
            $title = $titleMatch.Groups[1].Value
        }

        $contentMatch = [regex]::Match(
            $body,
            '(?ms)^\s{8}Content = \{\r?\n(?<Content>.*?)^\s{8}\},'
        )
        if (-not $contentMatch.Success) {
            throw "Tutorial $id has no Content array."
        }
        $content = @(
            [regex]::Matches($contentMatch.Groups['Content'].Value, '"(LOC_CAI_[A-Z0-9_]+)"') |
                ForEach-Object { $_.Groups[1].Value }
        )
        if ($content.Count -eq 0) {
            throw "Tutorial $id has an empty Content array."
        }

        $definitions += [pscustomobject]@{
            Id = $id
            Title = $title
            Content = $content
        }
    }
    return $definitions
}

$catalog = Get-Content -Raw -LiteralPath $CatalogPath
$screenBlock = Get-DefinitionBlock `
    -Source $catalog `
    -StartMarker 'local SCREEN_DEFINITIONS = {' `
    -EndMarker 'local CONTEXT_DEFINITIONS = {'
$contextBlock = Get-DefinitionBlock `
    -Source $catalog `
    -StartMarker 'local CONTEXT_DEFINITIONS = {' `
    -EndMarker 'local function Matches'

$definitions = @()
$definitions += Read-Definitions -Block $screenBlock -UseGeneratedTitle $true
$definitions += Read-Definitions -Block $contextBlock -UseGeneratedTitle $false

$generalPages = @(
    [pscustomobject]@{
        Id = 'INTRO'
        Title = 'LOC_CAI_TUTORIAL_MAIN_MENU_TITLE'
        SortIndex = 0
        Content = @(
            'LOC_CAI_TUTORIAL_MAIN_MENU_INTERFACE',
            'LOC_CAI_TUTORIAL_MAIN_MENU_NESTING',
            'LOC_CAI_TUTORIAL_MAIN_MENU_FOCUS_SPEECH',
            'LOC_CAI_TUTORIAL_MAIN_MENU_NAVIGATION',
            'LOC_CAI_TUTORIAL_MAIN_MENU_ACTIVATION',
            'LOC_CAI_TUTORIAL_MAIN_MENU_SEARCH',
            'LOC_CAI_TUTORIAL_MAIN_MENU_TOOLTIPS',
            'LOC_CAI_TUTORIAL_MAIN_MENU_HELP',
            'LOC_CAI_TUTORIAL_MAIN_MENU_SETTINGS'
        )
    },
    [pscustomobject]@{
        Id = 'SEARCH_TYPEAHEAD'
        Title = 'LOC_CAI_PEDIA_SEARCH_TITLE'
        SortIndex = 20
        Content = @(
            'LOC_CAI_PEDIA_SEARCH_TYPEAHEAD',
            'LOC_CAI_PEDIA_SEARCH_CYCLING',
            'LOC_CAI_PEDIA_SEARCH_RESULTS',
            'LOC_CAI_PEDIA_SEARCH_CLEARING',
            'LOC_CAI_PEDIA_SEARCH_PANEL',
            'LOC_CAI_PEDIA_SEARCH_QUERY',
            'LOC_CAI_PEDIA_SEARCH_PANEL_KEYS',
            'LOC_CAI_PEDIA_SEARCH_SETTINGS'
        )
    }
)

$keyBindingsPage = [pscustomobject]@{
    Id = 'KEY_BINDINGS'
    Title = 'LOC_CAI_PEDIA_KEY_BINDINGS_TITLE'
    Layout = 'CAIKeyBindings'
    Chapters = @(
        [pscustomobject]@{ Id = 'USING'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_USING_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_COMMON', 'LOC_CAI_PEDIA_KEY_BINDINGS_HELP', 'LOC_CAI_PEDIA_KEY_BINDINGS_TOOLTIPS', 'LOC_CAI_PEDIA_KEY_BINDINGS_NAVIGATION', 'LOC_CAI_PEDIA_KEY_BINDINGS_ACTIVATION', 'LOC_CAI_PEDIA_KEY_BINDINGS_CONTEXT') },
        [pscustomobject]@{ Id = 'REMAPPING'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_REMAPPING_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_REMAPPING_OPEN', 'LOC_CAI_PEDIA_KEY_BINDINGS_REMAPPING_CHANGE', 'LOC_CAI_PEDIA_KEY_BINDINGS_REMAPPING_CONFLICTS') },
        [pscustomobject]@{ Id = 'MESSAGE_BUFFER'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_MESSAGE_BUFFER_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_MESSAGE_BUFFER') },
        [pscustomobject]@{ Id = 'NAVIGATION_CURSOR'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_NAVIGATION_CURSOR_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_NAVIGATION_CURSOR_MOVEMENT', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_NAVIGATION_CURSOR_ACTIONS', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_NAVIGATION_CURSOR_BOOKMARKS') },
        [pscustomobject]@{ Id = 'WORLD_SCANNER'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_WORLD_SCANNER_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_WORLD_SCANNER') },
        [pscustomobject]@{ Id = 'SURVEYOR'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_SURVEYOR_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_SURVEYOR_BASIC', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_SURVEYOR_ADDITIONAL') },
        [pscustomobject]@{ Id = 'INFORMATION'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_INFORMATION_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_INFORMATION_SELECTION', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_INFORMATION_EMPIRE', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_INFORMATION_PLOT', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_INFORMATION_BANNERS') },
        [pscustomobject]@{ Id = 'CITY'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_CITY_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_CITY') },
        [pscustomobject]@{ Id = 'UI'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UI_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UI_CORE', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UI_RESEARCH', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UI_WORLD', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UI_MAP') },
        [pscustomobject]@{ Id = 'UNIT'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UNIT_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UNIT_MOVEMENT', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UNIT_ACTIONS', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_UNIT_OTHER') },
        [pscustomobject]@{ Id = 'GLOBAL'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_GLOBAL_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_GLOBAL_SELECTION', 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_GLOBAL_WORLD') },
        [pscustomobject]@{ Id = 'ONLINE'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_ONLINE_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_ONLINE') },
        [pscustomobject]@{ Id = 'LENSES'; Header = 'LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_LENSES_TITLE'; Content = @('LOC_CAI_PEDIA_KEY_BINDINGS_CATEGORY_LENSES') }
    )
}

$gameplayPages = @(
    [pscustomobject]@{
        Id = 'NAVIGATION_CURSOR'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_TITLE'
        Layout = 'CAIGameplayNavigationCursor'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_VISIBILITY') },
            [pscustomobject]@{ Id = 'MOVING'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_MOVING_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_MOVING', 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_JUMPS') },
            [pscustomobject]@{ Id = 'READING'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_READING_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_READING_PRIMARY', 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_READING_GEOGRAPHY', 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_INTERFACE') },
            [pscustomobject]@{ Id = 'BANNERS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_BANNERS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_BANNERS', 'LOC_CAI_PEDIA_GAMEPLAY_NAVIGATION_CURSOR_BANNER_KEYS') }
        )
    },
    [pscustomobject]@{
        Id = 'SURVEYOR'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_TITLE'
        Layout = 'CAIGameplaySurveyor'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_PRIVACY') },
            [pscustomobject]@{ Id = 'BASIC'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_BASIC_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_BASIC') },
            [pscustomobject]@{ Id = 'COUNTS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_COUNTS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_COUNTS') },
            [pscustomobject]@{ Id = 'DETAILS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_DETAILS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_DETAILS', 'LOC_CAI_PEDIA_GAMEPLAY_SURVEYOR_TERRAIN') }
        )
    },
    [pscustomobject]@{
        Id = 'WORLD_SCANNER'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_TITLE'
        Layout = 'CAIGameplayWorldScanner'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_LIVE_DATA') },
            [pscustomobject]@{ Id = 'NAVIGATION'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_NAVIGATION_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_NAVIGATION', 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_LOCATION') },
            [pscustomobject]@{ Id = 'SEARCH'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_SEARCH_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_SEARCH') },
            [pscustomobject]@{ Id = 'MANAGEMENT'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_MANAGEMENT_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_MANAGEMENT', 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_TYPES') },
            [pscustomobject]@{ Id = 'CUSTOM'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_CUSTOM_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_CUSTOM', 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_SCANNER_MATCHING') }
        )
    },
    [pscustomobject]@{
        Id = 'LENSES'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_TITLE'
        Layout = 'CAIGameplayLenses'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_ACTIVATION') },
            [pscustomobject]@{ Id = 'RELIGION'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_RELIGION_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_RELIGION') },
            [pscustomobject]@{ Id = 'CONTINENT'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_CONTINENT_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_CONTINENT') },
            [pscustomobject]@{ Id = 'APPEAL'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_APPEAL_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_APPEAL') },
            [pscustomobject]@{ Id = 'SETTLER'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_SETTLER_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_SETTLER', 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_SETTLER_SCANNER') },
            [pscustomobject]@{ Id = 'GOVERNMENT'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_GOVERNMENT_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_GOVERNMENT') },
            [pscustomobject]@{ Id = 'POLITICAL'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_POLITICAL_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_POLITICAL') },
            [pscustomobject]@{ Id = 'TOURISM'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_TOURISM_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_TOURISM', 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_TOURISM_DETAILS') },
            [pscustomobject]@{ Id = 'EMPIRE'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_EMPIRE_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_EMPIRE') },
            [pscustomobject]@{ Id = 'LOYALTY'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_LOYALTY_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_LOYALTY') },
            [pscustomobject]@{ Id = 'POWER'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_POWER_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_POWER') },
            [pscustomobject]@{ Id = 'PLAGUE'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_PLAGUE_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_PLAGUE') },
            [pscustomobject]@{ Id = 'SCANNER'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_LENSES_SCANNER_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_LENSES_SCANNER') }
        )
    },
    [pscustomobject]@{
        Id = 'MAP_TACS'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_TITLE'
        Layout = 'CAIGameplayMapTacs'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_LIST') },
            [pscustomobject]@{ Id = 'BOOKMARKS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_BOOKMARKS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_BOOKMARKS', 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_BOOKMARK_RULES') },
            [pscustomobject]@{ Id = 'KEYS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_KEYS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_KEYS') },
            [pscustomobject]@{ Id = 'SHARING'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_SHARING_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_MAP_TACS_SHARING') }
        )
    },
    [pscustomobject]@{
        Id = 'EMPIRE_INFORMATION'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_TITLE'
        Layout = 'CAIGameplayEmpireInformation'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_OVERVIEW') },
            [pscustomobject]@{ Id = 'PROGRESS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_PROGRESS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_PROGRESS') },
            [pscustomobject]@{ Id = 'YIELDS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_YIELDS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_YIELDS') },
            [pscustomobject]@{ Id = 'DIPLOMACY'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_DIPLOMACY_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_DIPLOMACY') },
            [pscustomobject]@{ Id = 'RULESETS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_RULESETS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_EMPIRE_INFORMATION_RULESETS') }
        )
    },
    [pscustomobject]@{
        Id = 'ENDING_TURN'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_TITLE'
        Layout = 'CAIGameplayEndingTurn'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_AUTOMATIC') },
            [pscustomobject]@{ Id = 'ACTIONS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_ACTIONS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_ACTIONS') },
            [pscustomobject]@{ Id = 'LIST'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_LIST_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_LIST', 'LOC_CAI_PEDIA_GAMEPLAY_ENDING_TURN_TUTORIAL') }
        )
    },
    [pscustomobject]@{
        Id = 'NOTIFICATIONS_HISTORY'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_TITLE'
        Layout = 'CAIGameplayNotificationsHistory'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_OVERVIEW') },
            [pscustomobject]@{ Id = 'CENTER'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_CENTER_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_CENTER', 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_CENTER_ACTIONS') },
            [pscustomobject]@{ Id = 'REVEALS'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_REVEALS_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_REVEALS', 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_REVEALS_LINES', 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_REVEALS_SETTINGS') },
            [pscustomobject]@{ Id = 'BUFFER'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_BUFFER_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_BUFFER', 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_BUFFER_KEYS') },
            [pscustomobject]@{ Id = 'MOVEMENT'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_MOVEMENT_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_MOVEMENT', 'LOC_CAI_PEDIA_GAMEPLAY_NOTIFICATIONS_HISTORY_SETTINGS') }
        )
    },
    [pscustomobject]@{
        Id = 'WORLD_ACTIONS'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_TITLE'
        Layout = 'CAIGameplayWorldActions'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_OVERVIEW') },
            [pscustomobject]@{ Id = 'SAVES'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_SAVES_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_SAVES') },
            [pscustomobject]@{ Id = 'MAP'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_MAP_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_MAP') },
            [pscustomobject]@{ Id = 'TURN'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_TURN_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_WORLD_ACTIONS_TURN') }
        )
    },
    [pscustomobject]@{
        Id = 'SELECTION'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_TITLE'
        Layout = 'CAIGameplaySelection'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SELECTION_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_ACTION_LIST') },
            [pscustomobject]@{ Id = 'MOVING'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_MOVING_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SELECTION_MOVING') },
            [pscustomobject]@{ Id = 'SUMMARY'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_SUMMARY_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SELECTION_SUMMARY') },
            [pscustomobject]@{ Id = 'CITY'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_CITY_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SELECTION_CITY') },
            [pscustomobject]@{ Id = 'UNIT'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_SELECTION_UNIT_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_SELECTION_UNIT') }
        )
    },
    [pscustomobject]@{
        Id = 'USER_INTERFACES'
        Title = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_TITLE'
        Layout = 'CAIGameplayUserInterfaces'
        Chapters = @(
            [pscustomobject]@{ Id = 'OVERVIEW'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_OVERVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_OVERVIEW', 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_TABS') },
            [pscustomobject]@{ Id = 'RESEARCH'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_RESEARCH_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_RESEARCH') },
            [pscustomobject]@{ Id = 'EMPIRE'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_EMPIRE_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_EMPIRE') },
            [pscustomobject]@{ Id = 'WORLD'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_WORLD_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_WORLD') },
            [pscustomobject]@{ Id = 'MAP'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_MAP_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_MAP') },
            [pscustomobject]@{ Id = 'AVAILABILITY'; Header = 'LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_AVAILABILITY_TITLE'; Content = @('LOC_CAI_PEDIA_GAMEPLAY_USER_INTERFACES_AVAILABILITY') }
        )
    }
)

# This is the audited set of concrete widget types exposed by in-game CAI
# screens. Abstract base classes and implementation-only HorizontalList
# containers are intentionally omitted.
$widgetPages = @(
    [pscustomobject]@{ Id = 'BUTTON'; Title = 'LOC_CAI_PEDIA_WIDGET_BUTTON_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_BUTTON_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_BUTTON_KEYS') },
    [pscustomobject]@{ Id = 'CHECKBOX'; Title = 'LOC_CAI_PEDIA_WIDGET_CHECKBOX_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_CHECKBOX_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_CHECKBOX_KEYS') },
    [pscustomobject]@{ Id = 'DIALOG'; Title = 'LOC_CAI_PEDIA_WIDGET_DIALOG_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_DIALOG_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_DIALOG_NAVIGATION', 'LOC_CAI_PEDIA_WIDGET_DIALOG_ACTIONS') },
    [pscustomobject]@{ Id = 'DROPDOWN'; Title = 'LOC_CAI_PEDIA_WIDGET_DROPDOWN_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_DROPDOWN_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_DROPDOWN_KEYS', 'LOC_CAI_PEDIA_WIDGET_DROPDOWN_COMMIT') },
    [pscustomobject]@{ Id = 'EDITBOX'; Title = 'LOC_CAI_PEDIA_WIDGET_EDITBOX_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_EDITBOX_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_EDITBOX_ENTRY', 'LOC_CAI_PEDIA_WIDGET_EDITBOX_HINT', 'LOC_CAI_PEDIA_WIDGET_EDITBOX_MOVEMENT', 'LOC_CAI_PEDIA_WIDGET_EDITBOX_SELECTION', 'LOC_CAI_PEDIA_WIDGET_EDITBOX_EDITING') },
    [pscustomobject]@{ Id = 'GAMEVIEW'; Title = 'LOC_CAI_PEDIA_WIDGET_GAMEVIEW_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_GAMEVIEW_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_GAMEVIEW_KEYS') },
    [pscustomobject]@{ Id = 'INTERFACEMODE'; Title = 'LOC_CAI_PEDIA_WIDGET_INTERFACEMODE_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_INTERFACEMODE_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_INTERFACEMODE_KEYS') },
    [pscustomobject]@{ Id = 'LIST'; Title = 'LOC_CAI_PEDIA_WIDGET_LIST_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_LIST_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_LIST_KEYS', 'LOC_CAI_PEDIA_WIDGET_LIST_SEARCH') },
    [pscustomobject]@{ Id = 'PANEL'; Title = 'LOC_CAI_PEDIA_WIDGET_PANEL_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_PANEL_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_PANEL_KEYS') },
    [pscustomobject]@{ Id = 'SEARCHPANEL'; Title = 'LOC_CAI_PEDIA_WIDGET_SEARCHPANEL_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_SEARCHPANEL_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_SEARCHPANEL_QUERY', 'LOC_CAI_PEDIA_WIDGET_SEARCHPANEL_KEYS') },
    [pscustomobject]@{ Id = 'SLIDER'; Title = 'LOC_CAI_PEDIA_WIDGET_SLIDER_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_SLIDER_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_SLIDER_KEYS') },
    [pscustomobject]@{ Id = 'STATICTEXT'; Title = 'LOC_CAI_PEDIA_WIDGET_STATICTEXT_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_STATICTEXT_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_STATICTEXT_KEYS') },
    [pscustomobject]@{ Id = 'SUBMENU'; Title = 'LOC_CAI_PEDIA_WIDGET_SUBMENU_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_SUBMENU_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_SUBMENU_KEYS') },
    [pscustomobject]@{ Id = 'TAB'; Title = 'LOC_CAI_PEDIA_WIDGET_TAB_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_TAB_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_TAB_KEYS') },
    [pscustomobject]@{ Id = 'TABCONTROL'; Title = 'LOC_CAI_PEDIA_WIDGET_TABCONTROL_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_TABCONTROL_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_TABCONTROL_KEYS', 'LOC_CAI_PEDIA_WIDGET_TABCONTROL_TRAVERSAL') },
    [pscustomobject]@{ Id = 'TABPAGE'; Title = 'LOC_CAI_PEDIA_WIDGET_TABPAGE_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_TABPAGE_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_TABPAGE_KEYS') },
    [pscustomobject]@{ Id = 'TABLE'; Title = 'LOC_CAI_PEDIA_WIDGET_TABLE_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_TABLE_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_TABLE_TABLES', 'LOC_CAI_PEDIA_WIDGET_TABLE_GRIDS', 'LOC_CAI_PEDIA_WIDGET_TABLE_TYPEAHEAD') },
    [pscustomobject]@{ Id = 'TREE'; Title = 'LOC_CAI_PEDIA_WIDGET_TREE_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_TREE_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_TREE_KEYS', 'LOC_CAI_PEDIA_WIDGET_TREE_EDGES', 'LOC_CAI_PEDIA_WIDGET_TREE_SEARCH') },
    [pscustomobject]@{ Id = 'TREEITEM'; Title = 'LOC_CAI_PEDIA_WIDGET_TREEITEM_TITLE'; Content = @('LOC_CAI_PEDIA_WIDGET_TREEITEM_FUNCTION', 'LOC_CAI_PEDIA_WIDGET_TREEITEM_KEYS', 'LOC_CAI_PEDIA_WIDGET_TREEITEM_ACTION') }
)

$widgetFamilies = @(
    [pscustomobject]@{
        Id = 'LEAF_WIDGETS'
        Title = 'LOC_CAI_PEDIA_WIDGET_FAMILY_LEAF_TITLE'
        Layout = 'CAIWidgetLeaf'
        Widgets = @($widgetPages | Where-Object Id -in @('BUTTON', 'STATICTEXT', 'TAB'))
    },
    [pscustomobject]@{
        Id = 'VALUE_WIDGETS'
        Title = 'LOC_CAI_PEDIA_WIDGET_FAMILY_VALUE_TITLE'
        Layout = 'CAIWidgetValue'
        Widgets = @($widgetPages | Where-Object Id -in @('CHECKBOX', 'SLIDER', 'EDITBOX'))
    },
    [pscustomobject]@{
        Id = 'CONTAINER_WIDGETS'
        Title = 'LOC_CAI_PEDIA_WIDGET_FAMILY_CONTAINER_TITLE'
        Layout = 'CAIWidgetContainer'
        Widgets = @($widgetPages | Where-Object Id -in @(
            'PANEL', 'SEARCHPANEL', 'DIALOG', 'LIST', 'SUBMENU', 'TREE',
            'TREEITEM', 'TABPAGE', 'TABCONTROL', 'DROPDOWN', 'GAMEVIEW',
            'INTERFACEMODE', 'TABLE'
        ))
    }
)

$familyWidgetIds = @($widgetFamilies | ForEach-Object { $_.Widgets | ForEach-Object Id })
$missingFamilyWidgets = @($widgetPages | Where-Object Id -notin $familyWidgetIds)
$duplicateFamilyWidgets = @($familyWidgetIds | Group-Object | Where-Object Count -gt 1)
if ($missingFamilyWidgets.Count -gt 0) {
    throw "Widget chapters missing a family: $($missingFamilyWidgets.Id -join ', ')"
}
if ($duplicateFamilyWidgets.Count -gt 0) {
    throw "Widget chapters assigned to multiple families: $($duplicateFamilyWidgets.Name -join ', ')"
}

$duplicateIds = @($definitions | Group-Object Id | Where-Object Count -gt 1)
if ($duplicateIds.Count -gt 0) {
    throw "Duplicate tutorial ids: $($duplicateIds.Name -join ', ')"
}
if ($definitions.Count -eq 0) {
    throw 'The tutorial catalog contains no definitions.'
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    throw "Output directory does not exist: $outputDirectory"
}

$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.IndentChars = '  '
$settings.NewLineChars = "`r`n"
$settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)

$writer = [System.Xml.XmlWriter]::Create($OutputPath, $settings)
try {
    $writer.WriteStartDocument()
    $writer.WriteStartElement('GameInfo')

    $writer.WriteStartElement('CivilopediaSections')
    $writer.WriteStartElement('Row')
    $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
    $writer.WriteAttributeString('Name', 'LOC_CAI_PEDIA_ACCESSIBILITY_SECTION_NAME')
    $writer.WriteAttributeString('Icon', 'ICON_CIVILOPEDIA_CONCEPTS')
    $writer.WriteAttributeString('SortIndex', '-10')
    $writer.WriteEndElement()
    $writer.WriteEndElement()

    $writer.WriteStartElement('CivilopediaPageGroups')
    $writer.WriteStartElement('Row')
    $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
    $writer.WriteAttributeString('PageGroupId', 'CAI_SCREEN_TUTORIALS')
    $writer.WriteAttributeString('Name', 'LOC_CAI_PEDIA_SCREEN_TUTORIALS_GROUP_NAME')
    $writer.WriteAttributeString('Tooltip', '')
    $writer.WriteAttributeString('VisibleIfEmpty', 'false')
    $writer.WriteAttributeString('SortIndex', '20')
    $writer.WriteEndElement()
    $writer.WriteStartElement('Row')
    $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
    $writer.WriteAttributeString('PageGroupId', 'CAI_GAMEPLAY')
    $writer.WriteAttributeString('Name', 'LOC_CAI_PEDIA_GAMEPLAY_GROUP_NAME')
    $writer.WriteAttributeString('Tooltip', '')
    $writer.WriteAttributeString('VisibleIfEmpty', 'false')
    $writer.WriteAttributeString('SortIndex', '10')
    $writer.WriteEndElement()
    $writer.WriteStartElement('Row')
    $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
    $writer.WriteAttributeString('PageGroupId', 'CAI_UI_WIDGETS')
    $writer.WriteAttributeString('Name', 'LOC_CAI_PEDIA_UI_WIDGETS_GROUP_NAME')
    $writer.WriteAttributeString('Tooltip', '')
    $writer.WriteAttributeString('VisibleIfEmpty', 'false')
    $writer.WriteAttributeString('SortIndex', '30')
    $writer.WriteEndElement()
    $writer.WriteEndElement()

    $writer.WriteStartElement('CivilopediaPageLayouts')
    $writer.WriteStartElement('Row')
    $writer.WriteAttributeString('PageLayoutId', $keyBindingsPage.Layout)
    $writer.WriteAttributeString('ScriptTemplate', 'Simple')
    $writer.WriteEndElement()
    foreach ($page in $gameplayPages) {
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('PageLayoutId', $page.Layout)
        $writer.WriteAttributeString('ScriptTemplate', 'Simple')
        $writer.WriteEndElement()
    }
    foreach ($family in $widgetFamilies) {
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('PageLayoutId', $family.Layout)
        $writer.WriteAttributeString('ScriptTemplate', 'Simple')
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement()

    $writer.WriteStartElement('CivilopediaPageLayoutChapters')
    for ($i = 0; $i -lt $keyBindingsPage.Chapters.Count; $i++) {
        $chapter = $keyBindingsPage.Chapters[$i]
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('PageLayoutId', $keyBindingsPage.Layout)
        $writer.WriteAttributeString('ChapterId', $chapter.Id)
        $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
        $writer.WriteEndElement()
    }
    foreach ($page in $gameplayPages) {
        for ($i = 0; $i -lt $page.Chapters.Count; $i++) {
            $chapter = $page.Chapters[$i]
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('PageLayoutId', $page.Layout)
            $writer.WriteAttributeString('ChapterId', $chapter.Id)
            $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
            $writer.WriteEndElement()
        }
    }
    foreach ($family in $widgetFamilies) {
        for ($i = 0; $i -lt $family.Widgets.Count; $i++) {
            $widget = $family.Widgets[$i]
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('PageLayoutId', $family.Layout)
            $writer.WriteAttributeString('ChapterId', $widget.Id)
            $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
            $writer.WriteEndElement()
        }
    }
    $writer.WriteEndElement()

    $writer.WriteStartElement('CivilopediaPages')
    for ($i = 0; $i -lt $generalPages.Count; $i++) {
        $page = $generalPages[$i]
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
        $writer.WriteAttributeString('PageId', $page.Id)
        $writer.WriteAttributeString('PageLayoutId', 'Simple')
        $writer.WriteAttributeString('Name', $page.Title)
        $writer.WriteAttributeString('Tooltip', '')
        $writer.WriteAttributeString('SortIndex', $page.SortIndex.ToString())
        $writer.WriteEndElement()
    }
    $writer.WriteStartElement('Row')
    $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
    $writer.WriteAttributeString('PageId', $keyBindingsPage.Id)
    $writer.WriteAttributeString('PageLayoutId', $keyBindingsPage.Layout)
    $writer.WriteAttributeString('Name', $keyBindingsPage.Title)
    $writer.WriteAttributeString('Tooltip', '')
    $writer.WriteAttributeString('SortIndex', '10')
    $writer.WriteEndElement()
    for ($i = 0; $i -lt $definitions.Count; $i++) {
        $definition = $definitions[$i]
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
        $writer.WriteAttributeString('PageId', "CAI_TUTORIAL_$($definition.Id)")
        $writer.WriteAttributeString('PageGroupId', 'CAI_SCREEN_TUTORIALS')
        $writer.WriteAttributeString('PageLayoutId', 'Simple')
        $writer.WriteAttributeString('Name', $definition.Title)
        $writer.WriteAttributeString('Tooltip', '')
        $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
        $writer.WriteEndElement()
    }
    for ($i = 0; $i -lt $gameplayPages.Count; $i++) {
        $page = $gameplayPages[$i]
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
        $writer.WriteAttributeString('PageId', "CAI_GAMEPLAY_$($page.Id)")
        $writer.WriteAttributeString('PageGroupId', 'CAI_GAMEPLAY')
        $writer.WriteAttributeString('PageLayoutId', $page.Layout)
        $writer.WriteAttributeString('Name', $page.Title)
        $writer.WriteAttributeString('Tooltip', '')
        $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
        $writer.WriteEndElement()
    }
    for ($i = 0; $i -lt $widgetFamilies.Count; $i++) {
        $family = $widgetFamilies[$i]
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
        $writer.WriteAttributeString('PageId', "CAI_WIDGET_FAMILY_$($family.Id)")
        $writer.WriteAttributeString('PageGroupId', 'CAI_UI_WIDGETS')
        $writer.WriteAttributeString('PageLayoutId', $family.Layout)
        $writer.WriteAttributeString('Name', $family.Title)
        $writer.WriteAttributeString('Tooltip', '')
        $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement()

    $writer.WriteStartElement('CivilopediaPageChapterHeaders')
    foreach ($chapter in $keyBindingsPage.Chapters) {
        $writer.WriteStartElement('Row')
        $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
        $writer.WriteAttributeString('PageId', $keyBindingsPage.Id)
        $writer.WriteAttributeString('ChapterId', $chapter.Id)
        $writer.WriteAttributeString('Header', $chapter.Header)
        $writer.WriteEndElement()
    }
    foreach ($page in $gameplayPages) {
        foreach ($chapter in $page.Chapters) {
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
            $writer.WriteAttributeString('PageId', "CAI_GAMEPLAY_$($page.Id)")
            $writer.WriteAttributeString('ChapterId', $chapter.Id)
            $writer.WriteAttributeString('Header', $chapter.Header)
            $writer.WriteEndElement()
        }
    }
    foreach ($family in $widgetFamilies) {
        foreach ($widget in $family.Widgets) {
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
            $writer.WriteAttributeString('PageId', "CAI_WIDGET_FAMILY_$($family.Id)")
            $writer.WriteAttributeString('ChapterId', $widget.Id)
            $writer.WriteAttributeString('Header', $widget.Title)
            $writer.WriteEndElement()
        }
    }
    $writer.WriteEndElement()

    $writer.WriteStartElement('CivilopediaPageChapterParagraphs')
    foreach ($page in $generalPages) {
        for ($i = 0; $i -lt $page.Content.Count; $i++) {
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
            $writer.WriteAttributeString('PageId', $page.Id)
            $writer.WriteAttributeString('ChapterId', 'CONTENT')
            $writer.WriteAttributeString('Paragraph', $page.Content[$i])
            $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
            $writer.WriteEndElement()
        }
    }
    foreach ($chapter in $keyBindingsPage.Chapters) {
        for ($i = 0; $i -lt $chapter.Content.Count; $i++) {
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
            $writer.WriteAttributeString('PageId', $keyBindingsPage.Id)
            $writer.WriteAttributeString('ChapterId', $chapter.Id)
            $writer.WriteAttributeString('Paragraph', $chapter.Content[$i])
            $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
            $writer.WriteEndElement()
        }
    }
    foreach ($definition in $definitions) {
        for ($i = 0; $i -lt $definition.Content.Count; $i++) {
            $writer.WriteStartElement('Row')
            $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
            $writer.WriteAttributeString('PageId', "CAI_TUTORIAL_$($definition.Id)")
            $writer.WriteAttributeString('ChapterId', 'CONTENT')
            $writer.WriteAttributeString('Paragraph', $definition.Content[$i])
            $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
            $writer.WriteEndElement()
        }
    }
    foreach ($page in $gameplayPages) {
        foreach ($chapter in $page.Chapters) {
            for ($i = 0; $i -lt $chapter.Content.Count; $i++) {
                $writer.WriteStartElement('Row')
                $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
                $writer.WriteAttributeString('PageId', "CAI_GAMEPLAY_$($page.Id)")
                $writer.WriteAttributeString('ChapterId', $chapter.Id)
                $writer.WriteAttributeString('Paragraph', $chapter.Content[$i])
                $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
                $writer.WriteEndElement()
            }
        }
    }
    foreach ($family in $widgetFamilies) {
        foreach ($widget in $family.Widgets) {
            for ($i = 0; $i -lt $widget.Content.Count; $i++) {
                $writer.WriteStartElement('Row')
                $writer.WriteAttributeString('SectionId', 'CAI_ACCESSIBILITY_MOD')
                $writer.WriteAttributeString('PageId', "CAI_WIDGET_FAMILY_$($family.Id)")
                $writer.WriteAttributeString('ChapterId', $widget.Id)
                $writer.WriteAttributeString('Paragraph', $widget.Content[$i])
                $writer.WriteAttributeString('SortIndex', (($i + 1) * 10).ToString())
                $writer.WriteEndElement()
            }
        }
    }
    $writer.WriteEndElement()

    $writer.WriteEndElement()
    $writer.WriteEndDocument()
}
finally {
    $writer.Dispose()
}

Write-Output "Generated $($generalPages.Count + 1) guides, $($gameplayPages.Count) gameplay articles, $($definitions.Count) screen tutorials, and $($widgetFamilies.Count) widget-family pages with $($widgetPages.Count) chapters at $OutputPath"
