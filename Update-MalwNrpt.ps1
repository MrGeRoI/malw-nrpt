#requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# =========================
# Настройки
# =========================

$GatewayHost = "5u35p8m9i7.cloudflare-gateway.com"
$DohTemplate = "https://$GatewayHost/dns-query"

$ExactListUrl =
    "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains.txt"

$SubdomainsListUrl =
    "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains_with_subdomains.txt"

$RuleMarker = "dns.malw.link automatic NRPT"

Write-Host "=== dns.malw.link NRPT updater ===" -ForegroundColor Cyan


# =========================
# 1. Получаем актуальные IP Gateway
# =========================

Write-Host "`n[1/6] Resolving Cloudflare Gateway..."

$GatewayIPs = @()

# Сначала Quad9 — у тебя он уже точно отвечает по обычному DNS.
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
$GatewayIPs | ForEach-Object {
    Write-Host "  $_"
}


# =========================
# 2. Регистрируем IP как DoH
# =========================

Write-Host "`n[2/6] Registering DoH servers..."

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
# 3. Загружаем списки malw
# =========================

Write-Host "`n[3/6] Downloading current malw domain lists..."

$ExactDomains = @(
    (Invoke-WebRequest -UseBasicParsing $ExactListUrl).Content `
        -split "`r?`n" |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object {
            $_ -and
            -not $_.StartsWith("#")
        } |
        Sort-Object -Unique
)

$SubdomainDomains = @(
    (Invoke-WebRequest -UseBasicParsing $SubdomainsListUrl).Content `
        -split "`r?`n" |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object {
            $_ -and
            -not $_.StartsWith("#")
        } |
        Sort-Object -Unique
)

Write-Host "Exact hosts:              $($ExactDomains.Count)"
Write-Host "Domains with subdomains:  $($SubdomainDomains.Count)"


# =========================
# 4. Удаляем старые наши NRPT правила
# =========================

Write-Host "`n[4/6] Removing previous managed NRPT rules..."

$OldRules = Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq $RuleMarker }

foreach ($Rule in $OldRules) {
    Remove-DnsClientNrptRule `
        -Name $Rule.Name `
        -Force `
        -ErrorAction SilentlyContinue
}

Write-Host "Removed: $($OldRules.Count)"


# =========================
# 5. Создаём свежие NRPT правила
# =========================

Write-Host "`n[5/6] Creating current NRPT rules..."

$Created = 0


# Точные хосты:
# gemini.google.com
# api.anthropic.com
# и т.п.
foreach ($Domain in $ExactDomains) {

    Add-DnsClientNrptRule `
        -Namespace $Domain `
        -NameServers $GatewayIPs `
        -DisplayName "malw exact: $Domain" `
        -Comment $RuleMarker

    $Created++
}


# Домены вместе со всеми поддоменами:
# .chatgpt.com
# .openai.com
# .claude.ai
# и т.п.
foreach ($Domain in $SubdomainDomains) {

    $Namespace = ".$Domain"

    Add-DnsClientNrptRule `
        -Namespace $Namespace `
        -NameServers $GatewayIPs `
        -DisplayName "malw subtree: $Domain" `
        -Comment $RuleMarker

    $Created++
}

Write-Host "Created: $Created rules"


# =========================
# 6. Очистка кэша и проверка
# =========================

Write-Host "`n[6/6] Flushing DNS cache..."

Clear-DnsClientCache


Write-Host "`n=== DONE ===" -ForegroundColor Green

Write-Host "`nGateway:"
$GatewayIPs | ForEach-Object {
    Write-Host "  $_ -> $DohTemplate"
}

Write-Host "`nEffective malw NRPT rules:"
Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq $RuleMarker } |
    Select-Object DisplayName, Namespace, NameServers