$ErrorActionPreference = "Stop"

# =========================
# Settings
# =========================

$ExactListUrl =
    "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains.txt"

$SubdomainsListUrl =
    "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains_with_subdomains.txt"

$OutputPath = Join-Path $PSScriptRoot "domains.json"

$CategoryDefinitions = @(
    [pscustomobject]@{ Key="google";       Name="Google / Gemini";                 Patterns=@('(^|\.)google\.com$','(^|\.)googleapis\.com$','(^|\.)withgoogle\.com$','(^|\.)goog$','^labs\.google$') },
    [pscustomobject]@{ Key="openai";       Name="ChatGPT / OpenAI / Sora";         Patterns=@('(^|\.)chatgpt\.com$','(^|\.)openai\.com$','(^|\.)oaistatic\.com$','(^|\.)oaiusercontent\.com$') },
    [pscustomobject]@{ Key="grok";         Name="Grok / xAI";                     Patterns=@('(^|\.)grok\.com$','(^|\.)grokusercontent\.com$','(^|\.)x\.ai$') },
    [pscustomobject]@{ Key="claude";       Name="Claude / Anthropic";             Patterns=@('(^|\.)claude\.ai$','(^|\.)claude\.com$','(^|\.)anthropic\.com$') },
    [pscustomobject]@{ Key="groq";         Name="Groq";                           Patterns=@('(^|\.)groq\.com$') },
    [pscustomobject]@{ Key="microsoft";    Name="Microsoft Copilot / Bing / Xbox"; Patterns=@('(^|\.)microsoft\.com$','(^|\.)bing\.com$','(^|\.)xboxlive\.com$') },
    [pscustomobject]@{ Key="spotify";      Name="Spotify";                        Patterns=@('(^|\.)spotify\.com$','(^|\.)spotifycdn\.com$','(^|\.)scdn\.co$') },
    [pscustomobject]@{ Key="githubcopilot";Name="GitHub Copilot";                 Patterns=@('(^|\.)githubcopilot\.com$','^api\.github\.com$') },
    [pscustomobject]@{ Key="jetbrains";    Name="JetBrains / JetBrains AI";        Patterns=@('(^|\.)jetbrains\.com$','(^|\.)jetbrains\.ai$') },
    [pscustomobject]@{ Key="elevenlabs";   Name="ElevenLabs / ElevenReader";       Patterns=@('(^|\.)elevenlabs\.io$','(^|\.)elevenreader\.io$') },
    [pscustomobject]@{ Key="tidal";        Name="TIDAL";                          Patterns=@('(^|\.)tidal\.com$','(^|\.)squareup\.com$','^geolocation\.onetrust\.com$') },
    [pscustomobject]@{ Key="supercell";    Name="Supercell";                      Patterns=@('(^|\.)supercell\.com$','(^|\.)clashroyaleapp\.com$','(^|\.)clashofclans\.com$','(^|\.)brawlstarsgame\.com$','(^|\.)squadbustersgame\.com$') },
    [pscustomobject]@{ Key="deepl";        Name="DeepL";                          Patterns=@('(^|\.)deepl\.com$') },
    [pscustomobject]@{ Key="deezer";       Name="Deezer";                         Patterns=@('(^|\.)deezer\.com$','(^|\.)dzcdn\.net$') },
    [pscustomobject]@{ Key="weather";      Name="Weather.com";                    Patterns=@('(^|\.)weather\.com$') },
    [pscustomobject]@{ Key="trae";         Name="Trae";                           Patterns=@('(^|\.)trae\.ai$','(^|\.)mchost\.guru$') },
    [pscustomobject]@{ Key="linear";       Name="Linear";                         Patterns=@('(^|\.)linear\.app$') },
    [pscustomobject]@{ Key="windsurf";     Name="Windsurf / Codeium";             Patterns=@('(^|\.)windsurf\.com$','(^|\.)codeium\.com$') },
    [pscustomobject]@{ Key="twitch";       Name="Twitch";                         Patterns=@('(^|\.)twitch\.tv$','(^|\.)ttvnw\.net$') },
    [pscustomobject]@{ Key="manus";        Name="Manus";                          Patterns=@('(^|\.)manus\.im$') },
    [pscustomobject]@{ Key="notion";       Name="Notion";                         Patterns=@('(^|\.)notion\.so$','(^|\.)notion\.com$') },
    [pscustomobject]@{ Key="canva";        Name="Canva";                          Patterns=@('(^|\.)canva\.com$') },
    [pscustomobject]@{ Key="intel";        Name="Intel";                          Patterns=@('(^|\.)intel\.com$') },
    [pscustomobject]@{ Key="dell";         Name="Dell";                           Patterns=@('(^|\.)dell\.com$','(^|\.)dellcdn\.com$') },
    [pscustomobject]@{ Key="tiktok";       Name="TikTok";                         Patterns=@('(^|\.)tiktok\.com$') },
    [pscustomobject]@{ Key="archive";      Name="Archive.org";                    Patterns=@('(^|\.)archive\.org$') },
    [pscustomobject]@{ Key="nvidia";       Name="NVIDIA";                         Patterns=@('(^|\.)nvidia\.com$','(^|\.)nvidiagrid\.net$') },
    [pscustomobject]@{ Key="parsec";       Name="Parsec";                         Patterns=@('(^|\.)parsec\.app$') },
    [pscustomobject]@{ Key="triage";       Name="Tria.ge";                        Patterns=@('(^|\.)tria\.ge$') },
    [pscustomobject]@{ Key="qwant";        Name="Qwant";                          Patterns=@('(^|\.)qwant\.com$') },
    [pscustomobject]@{ Key="guidedhacking";Name="GuidedHacking";                  Patterns=@('(^|\.)guidedhacking\.com$') },
    [pscustomobject]@{ Key="framer";       Name="Framer";                         Patterns=@('(^|\.)framer\.com$') },
    [pscustomobject]@{ Key="autodesk";     Name="Autodesk";                       Patterns=@('(^|\.)autodesk\.com$') },
    [pscustomobject]@{ Key="pumpfun";      Name="Pump.fun";                       Patterns=@('(^|\.)pump\.fun$') },
    [pscustomobject]@{ Key="truthsocial";  Name="Truth Social";                   Patterns=@('(^|\.)truthsocial\.com$') },
    [pscustomobject]@{ Key="elgato";       Name="Elgato";                         Patterns=@('(^|\.)elgato\.com$') },
    [pscustomobject]@{ Key="imgur";        Name="Imgur";                          Patterns=@('(^|\.)imgur\.com$') },
    [pscustomobject]@{ Key="dyson";        Name="Dyson";                          Patterns=@('(^|\.)dyson\.com$','(^|\.)dyson\.fr$') },
    [pscustomobject]@{ Key="broadcom";     Name="Broadcom";                       Patterns=@('(^|\.)broadcom\.com$') },
    [pscustomobject]@{ Key="patreon";      Name="Patreon";                        Patterns=@('(^|\.)patreon\.com$','(^|\.)patreonusercontent\.com$') },
    [pscustomobject]@{ Key="strava";       Name="Strava";                         Patterns=@('(^|\.)strava\.com$') },
    [pscustomobject]@{ Key="soundcloud";   Name="SoundCloud";                     Patterns=@('(^|\.)soundcloud\.com$') },
    [pscustomobject]@{ Key="clickup";      Name="ClickUp";                        Patterns=@('(^|\.)clickup\.com$','(^|\.)clickup-attachments\.com$','(^|\.)clickup-eu\.com$','(^|\.)clickup-prod\.com$','(^|\.)clickup-sg\.com$') },
    [pscustomobject]@{ Key="datacamp";     Name="DataCamp";                       Patterns=@('(^|\.)datacamp\.com$') },
    [pscustomobject]@{ Key="discordme";    Name="Discord.me";                     Patterns=@('(^|\.)discord\.me$') },
    [pscustomobject]@{ Key="easydmarc";    Name="EasyDMARC";                      Patterns=@('(^|\.)easydmarc\.com$') },
    [pscustomobject]@{ Key="genspark";     Name="Genspark";                       Patterns=@('(^|\.)genspark\.ai$') },
    [pscustomobject]@{ Key="httptoolkit";  Name="HTTP Toolkit";                   Patterns=@('(^|\.)httptoolkit\.com$') },
    [pscustomobject]@{ Key="hume";         Name="Hume AI";                        Patterns=@('(^|\.)hume\.ai$') },
    [pscustomobject]@{ Key="hybridanalysis";Name="Hybrid Analysis";               Patterns=@('(^|\.)hybrid-analysis\.com$') },
    [pscustomobject]@{ Key="lastfm";       Name="Last.fm / AudioScrobbler";        Patterns=@('(^|\.)last\.fm$','(^|\.)audioscrobbler\.com$') },
    [pscustomobject]@{ Key="m3u";          Name="M3U.in";                         Patterns=@('(^|\.)m3u\.in$') },
    [pscustomobject]@{ Key="mongodb";      Name="MongoDB";                        Patterns=@('(^|\.)mongodb\.com$') },
    [pscustomobject]@{ Key="netacad";      Name="Cisco NetAcad";                  Patterns=@('(^|\.)netacad\.com$') },
    [pscustomobject]@{ Key="snapeda";      Name="SnapEDA";                        Patterns=@('(^|\.)snapeda\.com$') },
    [pscustomobject]@{ Key="tempnumber";   Name="Temp-Number.org";                 Patterns=@('(^|\.)temp-number\.org$') },
    [pscustomobject]@{ Key="ti";           Name="Texas Instruments";              Patterns=@('(^|\.)ti\.com$') },
    [pscustomobject]@{ Key="analog";       Name="Analog Devices";                  Patterns=@('(^|\.)analog\.com$') },
    [pscustomobject]@{ Key="uizard";       Name="Uizard";                         Patterns=@('(^|\.)uizard\.io$') },
    [pscustomobject]@{ Key="wikidot";      Name="Wikidot";                        Patterns=@('(^|\.)wikidot\.com$') },
    [pscustomobject]@{ Key="xdaforums";    Name="XDA Forums";                     Patterns=@('(^|\.)xdaforums\.com$') },
    [pscustomobject]@{ Key="metadefender"; Name="MetaDefender";                   Patterns=@('(^|\.)metadefender\.com$') },
    [pscustomobject]@{ Key="anixsekai";    Name="AniXsekai";                      Patterns=@('(^|\.)anixsekai\.com$') },
    [pscustomobject]@{ Key="augment";      Name="Augment Code";                   Patterns=@('(^|\.)augmentcode\.com$') },
    [pscustomobject]@{ Key="lovable";      Name="Lovable / Vercel AI Gateway";     Patterns=@('(^|\.)loveable\.dev$','(^|\.)vercel\.sh$') },
    [pscustomobject]@{ Key="posthog";      Name="PostHog";                        Patterns=@('(^|\.)posthog\.com$') },
    [pscustomobject]@{ Key="linuxgsm";     Name="LinuxGSM / TechnicalRamblings";   Patterns=@('(^|\.)linuxgsm\.com$','(^|\.)technicalramblings\.com$') },
    [pscustomobject]@{ Key="other";        Name="Other / new domains";           Patterns=@() }
)

if ($Host.Name -eq "ConsoleHost") {
    try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
}

function Get-NormalizedDomains {
    param([Parameter(Mandatory)][string]$Url)

    return @(
        (Invoke-WebRequest -UseBasicParsing $Url).Content `
            -split "`r?`n" |
            ForEach-Object { $_.Trim().ToLowerInvariant() } |
            Where-Object { $_ -and -not $_.StartsWith("#") } |
            Sort-Object -Unique
    )
}

function Get-DomainCategoryKey {
    param([Parameter(Mandatory)][string]$Domain)

    foreach ($Category in $CategoryDefinitions) {
        if ($Category.Key -eq "other") { continue }

        foreach ($Pattern in $Category.Patterns) {
            if ($Domain -match $Pattern) {
                return $Category.Key
            }
        }
    }

    return "other"
}

Write-Host "=== Pull dns.malw.link domains ===" -ForegroundColor Cyan
Write-Host "`nDownloading current lists..."

$ExactDomains = Get-NormalizedDomains -Url $ExactListUrl
$SubdomainDomains = Get-NormalizedDomains -Url $SubdomainsListUrl

Write-Host "Exact hosts:              $($ExactDomains.Count)"
Write-Host "Domains with subdomains:  $($SubdomainDomains.Count)"

Write-Host "`nCategorizing domains..."

$Categories = @()
foreach ($Category in $CategoryDefinitions) {
    $ExactForCategory = @(
        $ExactDomains |
            Where-Object { (Get-DomainCategoryKey $_) -eq $Category.Key } |
            Sort-Object -Unique
    )

    $SubtreeForCategory = @(
        $SubdomainDomains |
            Where-Object { (Get-DomainCategoryKey $_) -eq $Category.Key } |
            Sort-Object -Unique
    )

    if (($ExactForCategory.Count + $SubtreeForCategory.Count) -eq 0) {
        continue
    }

    $Categories += [ordered]@{
        key = $Category.Key
        name = $Category.Name
        exact = $ExactForCategory
        subtree = $SubtreeForCategory
    }

    Write-Host ("  {0,-34} exact: {1,2}   subtree: {2,2}" -f `
        $Category.Name, $ExactForCategory.Count, $SubtreeForCategory.Count)
}

$Data = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    sources = [ordered]@{
        exact = $ExactListUrl
        subtree = $SubdomainsListUrl
    }
    totals = [ordered]@{
        exact = $ExactDomains.Count
        subtree = $SubdomainDomains.Count
        categories = $Categories.Count
    }
    categories = $Categories
}

$Json = $Data | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($OutputPath, $Json, [System.Text.UTF8Encoding]::new($false))

Write-Host "`nSaved: $OutputPath" -ForegroundColor Green
Write-Host "Categories: $($Categories.Count)"