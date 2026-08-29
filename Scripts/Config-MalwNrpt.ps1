#requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# =========================
# Настройки
# =========================

# TODO: добавить выбор шлюза:
# "dns.malw.link", альтернатива "5u35p8m9i7.cloudflare-gateway.com"
# dns.comss.one
# xbox-dns.ru

$GatewayHost = "dns.comss.one"
$DohTemplate = "https://$GatewayHost/dns-query"

$ExactListUrl =
    "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains.txt"

$SubdomainsListUrl =
    "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains_with_subdomains.txt"

$RuleMarker = "dns.malw.link automatic NRPT"

# Категории применяются только к доменам, которые реально присутствуют
# в актуальных lists/domains.txt и lists/domains_with_subdomains.txt.
# Если в репозитории появится новый неизвестный домен, он попадёт в
# категорию "Прочее / новые домены", а не потеряется.
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
    [pscustomobject]@{ Key="other";        Name="Прочее / новые домены";           Patterns=@() }
)

if ($Host.Name -eq "ConsoleHost") {
    try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
}

Write-Host "=== dns.malw.link NRPT configurator ===" -ForegroundColor Cyan

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

function ConvertTo-SelectedIndexes {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][int]$MaxIndex
    )

    $Result = New-Object System.Collections.Generic.HashSet[int]

    foreach ($RawPart in ($Text -split ',')) {
        $Part = $RawPart.Trim()
        if (-not $Part) { continue }

        if ($Part -match '^(\d+)\s*-\s*(\d+)$') {
            $Start = [int]$Matches[1]
            $End   = [int]$Matches[2]

            if ($Start -gt $End) {
                $Tmp = $Start; $Start = $End; $End = $Tmp
            }

            if ($Start -lt 1 -or $End -gt $MaxIndex) {
                throw "Диапазон '$Part' выходит за пределы 1-$MaxIndex."
            }

            for ($i = $Start; $i -le $End; $i++) {
                [void]$Result.Add($i)
            }
        }
        elseif ($Part -match '^\d+$') {
            $Index = [int]$Part
            if ($Index -lt 1 -or $Index -gt $MaxIndex) {
                throw "Номер '$Part' выходит за пределы 1-$MaxIndex."
            }
            [void]$Result.Add($Index)
        }
        else {
            throw "Не удалось разобрать '$Part'. Используй, например: 1,2,5-8"
        }
    }

    return @($Result | Sort-Object)
}

# =========================
# 1. Загружаем актуальные списки
# =========================

Write-Host "`n[1/7] Downloading current malw domain lists..."

$ExactDomains = Get-NormalizedDomains -Url $ExactListUrl
$SubdomainDomains = Get-NormalizedDomains -Url $SubdomainsListUrl

Write-Host "Exact hosts:              $($ExactDomains.Count)"
Write-Host "Domains with subdomains:  $($SubdomainDomains.Count)"

# =========================
# 2. Строим категории и спрашиваем выбор
# =========================

Write-Host "`n[2/7] Choose categories to KEEP in NRPT..." -ForegroundColor Cyan

$AvailableCategories = @()

foreach ($Category in $CategoryDefinitions) {
    $ExactForCategory = @($ExactDomains | Where-Object { (Get-DomainCategoryKey $_) -eq $Category.Key })
    $SubForCategory   = @($SubdomainDomains | Where-Object { (Get-DomainCategoryKey $_) -eq $Category.Key })
    $Total = $ExactForCategory.Count + $SubForCategory.Count

    if ($Total -gt 0) {
        $AvailableCategories += [pscustomobject]@{
            Index = $AvailableCategories.Count + 1
            Key = $Category.Key
            Name = $Category.Name
            ExactCount = $ExactForCategory.Count
            SubtreeCount = $SubForCategory.Count
            TotalCount = $Total
        }
    }
}

foreach ($Item in $AvailableCategories) {
    Write-Host ("{0,2}. {1,-34} exact: {2,2}   subtree: {3,2}" -f `
        $Item.Index, $Item.Name, $Item.ExactCount, $Item.SubtreeCount)
}

Write-Host ""
Write-Host "Enter      = оставить ВСЕ категории"
Write-Host "1,3,5-8    = оставить только перечисленные категории"
Write-Host "0           = выйти без изменений"

while ($true) {
    $SelectionText = (Read-Host "`nКакие категории оставить").Trim()

    if ($SelectionText -eq "0") {
        Write-Host "Отменено. NRPT не изменён." -ForegroundColor Yellow
        return
    }

    if (-not $SelectionText -or $SelectionText -match '^(all|a|все)$') {
        $SelectedIndexes = @(1..$AvailableCategories.Count)
        break
    }

    try {
        $SelectedIndexes = ConvertTo-SelectedIndexes -Text $SelectionText -MaxIndex $AvailableCategories.Count
        if ($SelectedIndexes.Count -eq 0) {
            throw "Не выбрана ни одна категория."
        }
        break
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}

$SelectedCategoryKeys = @(
    $AvailableCategories |
        Where-Object { $SelectedIndexes -contains $_.Index } |
        Select-Object -ExpandProperty Key
)

$SelectedCategoryNames = @(
    $AvailableCategories |
        Where-Object { $SelectedIndexes -contains $_.Index } |
        Select-Object -ExpandProperty Name
)

$SelectedExactDomains = @(
    $ExactDomains |
        Where-Object { $SelectedCategoryKeys -contains (Get-DomainCategoryKey $_) } |
        Sort-Object -Unique
)

$SelectedSubdomainDomains = @(
    $SubdomainDomains |
        Where-Object { $SelectedCategoryKeys -contains (Get-DomainCategoryKey $_) } |
        Sort-Object -Unique
)

Write-Host "`nSelected categories: $($SelectedCategoryNames.Count)" -ForegroundColor Green
$SelectedCategoryNames | ForEach-Object { Write-Host "  + $_" }
Write-Host "Selected exact hosts:             $($SelectedExactDomains.Count)"
Write-Host "Selected domains with subdomains: $($SelectedSubdomainDomains.Count)"

# =========================
# 3. Получаем актуальные IP Gateway
# =========================

Write-Host "`n[3/7] Resolving Cloudflare Gateway..."

$GatewayIPs = @()

try {
    $GatewayIPs = Resolve-DnsName `
        -Name $GatewayHost `
        -Type A `
        -Server 9.9.9.9 `
        -DnsOnly `
        -ErrorAction Stop |
        Where-Object { $_.Type -eq "A" } |
        Select-Object -ExpandProperty IPAddress
}
catch {
    Write-Warning "Quad9 resolution failed. Trying Windows system resolver..."

    $GatewayIPs = Resolve-DnsName `
        -Name $GatewayHost `
        -Type A `
        -DnsOnly `
        -ErrorAction Stop |
        Where-Object { $_.Type -eq "A" } |
        Select-Object -ExpandProperty IPAddress
}

$GatewayIPs = @($GatewayIPs | Sort-Object -Unique)

if ($GatewayIPs.Count -eq 0) {
    throw "Не удалось получить IPv4 адреса $GatewayHost"
}

Write-Host "Gateway IP:"
$GatewayIPs | ForEach-Object { Write-Host "  $_" }

# =========================
# 4. Регистрируем IP как DoH
# =========================

Write-Host "`n[4/7] Registering DoH servers..."

foreach ($IP in $GatewayIPs) {
    $Existing = Get-DnsClientDohServerAddress |
        Where-Object { $_.ServerAddress -eq $IP }

    if ($Existing) {
        Set-DnsClientDohServerAddress `
            -ServerAddress $IP `
            -DohTemplate $DohTemplate `
            -AllowFallbackToUdp $False `
            -AutoUpgrade $True

        Write-Host "Updated DoH: $IP"
    }
    else {
        Add-DnsClientDohServerAddress `
            -ServerAddress $IP `
            -DohTemplate $DohTemplate `
            -AllowFallbackToUdp $False `
            -AutoUpgrade $True

        Write-Host "Added DoH:   $IP"
    }
}

# =========================
# 5. Удаляем старые управляемые NRPT правила
# =========================

Write-Host "`n[5/7] Removing previous managed NRPT rules..."

$OldRules = @(
    Get-DnsClientNrptRule |
        Where-Object { $_.Comment -eq $RuleMarker }
)

foreach ($Rule in $OldRules) {
    Remove-DnsClientNrptRule `
        -Name $Rule.Name `
        -Force `
        -ErrorAction SilentlyContinue
}

Write-Host "Removed: $($OldRules.Count)"

# =========================
# 6. Создаём NRPT только для выбранных категорий
# =========================

Write-Host "`n[6/7] Creating selected NRPT rules..."

$Created = 0

foreach ($Domain in $SelectedExactDomains) {
    $CategoryKey = Get-DomainCategoryKey $Domain
    $CategoryName = ($CategoryDefinitions | Where-Object Key -eq $CategoryKey | Select-Object -First 1).Name

    Add-DnsClientNrptRule `
        -Namespace $Domain `
        -NameServers $GatewayIPs `
        -DisplayName "malw [$CategoryName] exact: $Domain" `
        -Comment $RuleMarker

    $Created++
}

foreach ($Domain in $SelectedSubdomainDomains) {
    $Namespace = ".$Domain"
    $CategoryKey = Get-DomainCategoryKey $Domain
    $CategoryName = ($CategoryDefinitions | Where-Object Key -eq $CategoryKey | Select-Object -First 1).Name

    Add-DnsClientNrptRule `
        -Namespace $Namespace `
        -NameServers $GatewayIPs `
        -DisplayName "malw [$CategoryName] subtree: $Domain" `
        -Comment $RuleMarker

    $Created++
}

Write-Host "Created: $Created rules"

# =========================
# 7. Очистка кэша и итог
# =========================

Write-Host "`n[7/7] Flushing DNS cache..."
Clear-DnsClientCache

Write-Host "`n=== DONE ===" -ForegroundColor Green

Write-Host "`nGateway:"
$GatewayIPs | ForEach-Object { Write-Host "  $_ -> $DohTemplate" }

Write-Host "`nEnabled categories:"
$SelectedCategoryNames | ForEach-Object { Write-Host "  + $_" }

Write-Host "`nEffective malw NRPT rules:"
Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq $RuleMarker } |
    Select-Object DisplayName, Namespace, NameServers
