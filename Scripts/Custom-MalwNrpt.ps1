#requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# =========================
# Settings
# =========================

$DnsServerOptions = @(
	[pscustomobject]@{ Name = "dns.malw.link";                Host = "dns.malw.link";                         DohTemplate = "https://dns.malw.link/dns-query" },
	[pscustomobject]@{ Name = "cloudflare-malw";   Host = "5u35p8m9i7.cloudflare-gateway.com";    DohTemplate = "https://5u35p8m9i7.cloudflare-gateway.com/dns-query" },
	[pscustomobject]@{ Name = "dns.comss.one";               Host = "dns.comss.one";                        DohTemplate = "https://dns.comss.one/dns-query" },
	[pscustomobject]@{ Name = "xbox-dns.ru";                    Host = "xbox-dns.ru";                          DohTemplate = "https://xbox-dns.ru/dns-query" }
)

$GatewayHost = $null
$DohTemplate = $null

$DomainsDataPath = Join-Path $PSScriptRoot "domains.json"

$RuleMarker = "dns.malw.link automatic NRPT"

if ($Host.Name -eq "ConsoleHost") {
	try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
}

Write-Host "=== NRPT-DoH configurator ===" -ForegroundColor Cyan

# =========================
# Current managed NRPT domains
# =========================

$CurrentManagedDomains = @(
	Get-DnsClientNrptRule |
		Where-Object { $_.Comment -eq $RuleMarker } |
		ForEach-Object {
			foreach ($Namespace in @($_.Namespace)) {
				if ($Namespace) { $Namespace.ToString().Trim().TrimStart('.').ToLowerInvariant() }
			}
		} |
		Where-Object { $_ } |
		Sort-Object -Unique
)

Write-Host "`nCurrent domains in managed NRPT rules ($($CurrentManagedDomains.Count)):" -ForegroundColor Cyan
if ($CurrentManagedDomains.Count -gt 0) {
	Write-Host ($CurrentManagedDomains -join ", ")
}
else {
	Write-Host "  (none)" -ForegroundColor DarkGray
}

function ConvertTo-SelectedIndexes {
	param(
		[Parameter(Mandatory)][string]$Text,
		[Parameter(Mandatory)][int]$MaxIndex
	)

	$Result = New-Object System.Collections.Generic.HashSet[int]

	foreach ($RawPart in ($Text -split '\s+')) {
		$Part = $RawPart.Trim()
		if (-not $Part) { continue }

		if ($Part -match '^(\d+)\s*-\s*(\d+)$') {
			$Start = [int]$Matches[1]
			$End   = [int]$Matches[2]

			if ($Start -gt $End) {
				$Tmp = $Start; $Start = $End; $End = $Tmp
			}

			if ($Start -lt 1 -or $End -gt $MaxIndex) {
				throw "Range '$Part' is outside 1-$MaxIndex."
			}

			for ($i = $Start; $i -le $End; $i++) {
				[void]$Result.Add($i)
			}
		}
		elseif ($Part -match '^\d+$') {
			$Index = [int]$Part
			if ($Index -lt 1 -or $Index -gt $MaxIndex) {
				throw "Number '$Part' is outside 1-$MaxIndex."
			}
			[void]$Result.Add($Index)
		}
		else {
			throw "Could not parse '$Part'. Use spaces, for example: 1 2 5-8"
		}
	}

	return @($Result | Sort-Object)
}

# =========================
# 1. Load prepared domain database
# =========================

Write-Host "`n[1/7] Loading prepared categorized domain database..."

if (-not (Test-Path -LiteralPath $DomainsDataPath)) {
	throw "Domain database was not found: $DomainsDataPath`nRun Pull-Domains.ps1 first."
}

try {
	$DomainsData = Get-Content -LiteralPath $DomainsDataPath -Raw -Encoding UTF8 | ConvertFrom-Json
}
catch {
	throw "Could not read domain database '$DomainsDataPath': $($_.Exception.Message)"
}

if (-not $DomainsData.categories) {
	throw "Domain database has no categories. Run Pull-Domains.ps1 again."
}

$AvailableCategories = @()
foreach ($Category in @($DomainsData.categories)) {
	$ExactCount = @($Category.exact).Count
	$SubtreeCount = @($Category.subtree).Count
	$Total = $ExactCount + $SubtreeCount

	if ($Total -gt 0) {
		$AvailableCategories += [pscustomobject]@{
			Index = $AvailableCategories.Count + 1
			Key = [string]$Category.key
			Name = [string]$Category.name
			ExactCount = $ExactCount
			SubtreeCount = $SubtreeCount
			TotalCount = $Total
			ExactDomains = @($Category.exact)
			SubtreeDomains = @($Category.subtree)
		}
	}
}

if ($AvailableCategories.Count -eq 0) {
	throw "Domain database contains no usable domains. Run Pull-Domains.ps1 again."
}

Write-Host "Database generated: $($DomainsData.generatedAt)"
Write-Host "Exact hosts:              $($DomainsData.totals.exact)"
Write-Host "Domains with subdomains:  $($DomainsData.totals.subtree)"

# =========================
# 2. Ask what to keep
# =========================

Write-Host "`n[2/7] Choose categories to KEEP in NRPT..." -ForegroundColor Cyan

foreach ($Item in $AvailableCategories) {
	Write-Host ("{0,2}. {1,-34} exact: {2,2}   subtree: {3,2}" -f `
		$Item.Index, $Item.Name, $Item.ExactCount, $Item.SubtreeCount)
}

Write-Host ""
Write-Host "Enter      = keep ALL categories"
Write-Host "1 3 5-8    = keep only the listed categories"
Write-Host "0           = remove ALL managed NRPT rules and exit"

while ($true) {
	$SelectionText = (Read-Host "`nWhich categories should be kept").Trim()

	if ($SelectionText -eq "0") {
		Write-Host "`nRemoving all managed NRPT rules..." -ForegroundColor Yellow

		$RulesToRemove = @(
			Get-DnsClientNrptRule |
				Where-Object { $_.Comment -eq $RuleMarker }
		)

		foreach ($Rule in $RulesToRemove) {
			Remove-DnsClientNrptRule `
				-Name $Rule.Name `
				-Force `
				-ErrorAction SilentlyContinue
		}

		Clear-DnsClientCache
		Write-Host "Removed: $($RulesToRemove.Count)" -ForegroundColor Green
		Write-Host "All managed NRPT rules were removed. Exiting." -ForegroundColor Green
		return
	}

	if (-not $SelectionText -or $SelectionText -match '^(all|a)$') {
		$SelectedIndexes = @(1..$AvailableCategories.Count)
		break
	}

	try {
		$SelectedIndexes = ConvertTo-SelectedIndexes -Text $SelectionText -MaxIndex $AvailableCategories.Count
		if ($SelectedIndexes.Count -eq 0) {
			throw "No categories were selected."
		}
		break
	}
	catch {
		Write-Warning $_.Exception.Message
	}
}

$SelectedCategories = @(
	$AvailableCategories |
		Where-Object { $SelectedIndexes -contains $_.Index }
)

$SelectedCategoryNames = @($SelectedCategories | Select-Object -ExpandProperty Name)

$SelectedExactDomains = @(
	$SelectedCategories |
		ForEach-Object { $_.ExactDomains } |
		Where-Object { $_ } |
		Sort-Object -Unique
)

$SelectedSubdomainDomains = @(
	$SelectedCategories |
		ForEach-Object { $_.SubtreeDomains } |
		Where-Object { $_ } |
		Sort-Object -Unique
)

$DomainCategoryName = @{}
foreach ($Category in $SelectedCategories) {
	foreach ($Domain in @($Category.ExactDomains)) {
		$DomainCategoryName["exact|$Domain"] = $Category.Name
	}
	foreach ($Domain in @($Category.SubtreeDomains)) {
		$DomainCategoryName["subtree|$Domain"] = $Category.Name
	}
}

Write-Host "`nSelected categories: $($SelectedCategoryNames.Count)" -ForegroundColor Green
$SelectedCategoryNames | ForEach-Object { Write-Host "  + $_" }
Write-Host "Selected exact hosts:             $($SelectedExactDomains.Count)"
Write-Host "Selected domains with subdomains: $($SelectedSubdomainDomains.Count)"

# =========================
# DNS server selection
# =========================

Write-Host "`nChoose DNS server for managed NRPT rules..." -ForegroundColor Cyan

for ($i = 0; $i -lt $DnsServerOptions.Count; $i++) {
	Write-Host ("{0,2}. {1}" -f ($i + 1), $DnsServerOptions[$i].Name)
}

$CustomDnsIndex = $DnsServerOptions.Count + 1
Write-Host ("{0,2}. Enter manually" -f $CustomDnsIndex)

while ($true) {
	$DnsSelection = (Read-Host "`nWhich DNS server should be used").Trim()


	$DnsSelectionNumber = 0
	if (-not [int]::TryParse($DnsSelection, [ref]$DnsSelectionNumber) -or
		$DnsSelectionNumber -lt 1 -or
		$DnsSelectionNumber -gt $CustomDnsIndex) {
		Write-Warning "Choose a number from 1 to $CustomDnsIndex."
		continue
	}

	if ($DnsSelectionNumber -le $DnsServerOptions.Count) {
		$SelectedDns = $DnsServerOptions[$DnsSelectionNumber - 1]
		$GatewayHost = $SelectedDns.Host
		$DohTemplate = $SelectedDns.DohTemplate
		break
	}

	$CustomDns = (Read-Host "Hostname or full DoH URL (for example dns.example.com or https://dns.example.com/dns-query)").Trim()
	if (-not $CustomDns) {
		Write-Warning "The DNS address cannot be empty."
		continue
	}

	try {
		if ($CustomDns -match '^https://') {
			$CustomUri = [Uri]$CustomDns
			if (-not $CustomUri.Host) {
				throw "Could not determine the hostname from the URL."
			}

			$GatewayHost = $CustomUri.Host
			$DohTemplate = $CustomUri.AbsoluteUri.TrimEnd('/')
		}
		elseif ($CustomDns -match '^[a-zA-Z0-9.-]+$') {
			$GatewayHost = $CustomDns.TrimEnd('.')
			$DohTemplate = "https://$GatewayHost/dns-query"
		}
		else {
			throw "Enter a hostname or an HTTPS DoH URL."
		}

		break
	}
	catch {
		Write-Warning $_.Exception.Message
	}
}

Write-Host "Selected DNS: $GatewayHost" -ForegroundColor Green
Write-Host "DoH template: $DohTemplate"

# =========================
# 3. Resolve current gateway IPs
# =========================

Write-Host "`n[3/7] Resolving selected DNS server..."

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
	throw "Could not resolve IPv4 addresses for $GatewayHost"
}

Write-Host "Gateway IP:"
$GatewayIPs | ForEach-Object { Write-Host "  $_" }

# =========================
# 4. Register IPs as DoH servers
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
# 5. Remove previous managed NRPT rules
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
# 6. Create NRPT rules only for selected categories
# =========================

Write-Host "`n[6/7] Creating selected NRPT rules..."

$Created = 0
$CreatedRules = @()

foreach ($Domain in $SelectedExactDomains) {
	$CategoryName = $DomainCategoryName["exact|$Domain"]

	$CreatedRule = Add-DnsClientNrptRule `
		-Namespace $Domain `
		-NameServers $GatewayIPs `
		-DisplayName "malw [$CategoryName] exact: $Domain" `
		-Comment $RuleMarker `
		-PassThru

	$CreatedRules += $CreatedRule
	$Created++
}

foreach ($Domain in $SelectedSubdomainDomains) {
	$Namespace = ".$Domain"
	$CategoryName = $DomainCategoryName["subtree|$Domain"]

	$CreatedRule = Add-DnsClientNrptRule `
		-Namespace $Namespace `
		-NameServers $GatewayIPs `
		-DisplayName "malw [$CategoryName] subtree: $Domain" `
		-Comment $RuleMarker `
		-PassThru

	$CreatedRules += $CreatedRule
	$Created++
}

Write-Host "Created: $Created rules"

# =========================
# 7. Flush cache and show result
# =========================

Write-Host "`n[7/7] Flushing DNS cache..."
Clear-DnsClientCache

Write-Host "`n=== DONE ===" -ForegroundColor Green

Write-Host "`nDNS server:"
$GatewayIPs | ForEach-Object { Write-Host "  $_ -> $DohTemplate" }

Write-Host "`nEnabled categories:"
$SelectedCategoryNames | ForEach-Object { Write-Host "  + $_" }

Write-Host "`nEffective malw NRPT rules:"
if ($CreatedRules.Count -gt 0) {
    $CreatedRules |
        Select-Object DisplayName, Namespace, NameServers |
        Format-Table -AutoSize
}
else {
    Write-Host "  None"
}