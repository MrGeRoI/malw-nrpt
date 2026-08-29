#Requires -RunAsAdministrator

param(
    # "All" keeps the current behavior. Specify category names to run unattended,
    # for example: -Categories OpenAI,Google,Grok
    [string[]]$Categories
)

$ErrorActionPreference = "Stop"

$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$SourceUrl = "https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/hosts"

$BeginMarker = "# >>> dns.malw.link managed block >>>"
$EndMarker   = "# <<< dns.malw.link managed block <<<"

Write-Host "Downloading dns.malw.link hosts..."

try {
    $Response = Invoke-WebRequest -Uri $SourceUrl -UseBasicParsing
    $RemoteHosts = $Response.Content
}
catch {
    Write-Error "Failed to download hosts: $($_.Exception.Message)"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($RemoteHosts)) {
    Write-Error "Downloaded hosts is empty. Nothing was changed."
    exit 1
}

if ($RemoteHosts -notmatch "dns\.malw\.link") {
    Write-Error "Downloaded file does not look like dns.malw.link hosts. Nothing was changed."
    exit 1
}

# Categories are maintained upstream as section comments in the hosts file.
# Entries before the first category are service infrastructure and are always kept.
$Lines = $RemoteHosts -split "\r?\n"
$CategoryNames = [System.Collections.Generic.List[string]]::new()

foreach ($Line in $Lines) {
    if ($Line -match "^#\s+(.+?)\s*$" -and
        $Line -notmatch "^###\s+dns\.malw\.link:" -and
        $Matches[1] -notmatch ":") {
        $CategoryName = $Matches[1].Trim()
        if (-not $CategoryNames.Contains($CategoryName)) {
            $CategoryNames.Add($CategoryName)
        }
    }
}

if ($CategoryNames.Count -eq 0) {
    Write-Error "No domain categories were found in the downloaded hosts file. Nothing was changed."
    exit 1
}

if (-not $Categories -or $Categories.Count -eq 0) {
    Write-Host ""
    Write-Host "Available domain categories:"
    for ($Index = 0; $Index -lt $CategoryNames.Count; $Index++) {
        Write-Host ("  {0,2}. {1}" -f ($Index + 1), $CategoryNames[$Index])
    }

    $Selection = Read-Host "Enter numbers or names separated by commas; press Enter or type All for all categories"
    if ([string]::IsNullOrWhiteSpace($Selection)) {
        $Categories = @("All")
    }
    else {
        $Categories = $Selection -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
}

$IncludeAllCategories = $Categories | Where-Object { $_ -ieq "All" }
$SelectedCategories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($Category in $Categories) {
    $ResolvedCategory = $null

    if ($Category -match "^\d+$") {
        $CategoryIndex = [int]$Category
        if ($CategoryIndex -ge 1 -and $CategoryIndex -le $CategoryNames.Count) {
            $ResolvedCategory = $CategoryNames[$CategoryIndex - 1]
        }
    }
    else {
        $ResolvedCategory = $CategoryNames | Where-Object { $_ -ieq $Category } | Select-Object -First 1
    }

    if (-not $IncludeAllCategories -and -not $ResolvedCategory) {
        Write-Error "Unknown domain category: $Category"
        Write-Host "Use a number from the displayed list, an exact category name, or All."
        exit 1
    }

    if ($ResolvedCategory) {
        [void]$SelectedCategories.Add($ResolvedCategory)
    }
}

if ($IncludeAllCategories) {
    Write-Host "Selected categories: all"
}
else {
    Write-Host ("Selected categories: " + (($SelectedCategories | Sort-Object) -join ", "))
}

Write-Host "Creating backup..."

$BackupPath = "$HostsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    Copy-Item -LiteralPath $HostsPath -Destination $BackupPath -Force
}
catch {
    Write-Error "Failed to create backup: $($_.Exception.Message)"
    exit 1
}

Write-Host "Backup: $BackupPath"

try {
    $CurrentHosts = [System.IO.File]::ReadAllText($HostsPath)
}
catch {
    Write-Error "Failed to read system hosts: $($_.Exception.Message)"
    exit 1
}

# Remove the previously managed dns.malw.link block.
$EscapedBegin = [regex]::Escape($BeginMarker)
$EscapedEnd   = [regex]::Escape($EndMarker)

$Pattern = "(?ms)^\s*$EscapedBegin.*?^\s*$EscapedEnd[^\r\n]*(?:\r?\n)?"

$CleanHosts = [regex]::Replace(
    $CurrentHosts,
    $Pattern,
    ""
).TrimEnd()

# Remove repository header because we add our own header, then keep selected sections.
$CurrentCategory = $null
$FilteredLines = foreach ($Line in $Lines) {
    if ($Line -match "^###\s+dns\.malw\.link:") {
        continue
    }

    if ($Line -match "^#\s+(.+?)\s*$" -and
        $Line -notmatch "^###\s+dns\.malw\.link:" -and
        $Matches[1] -notmatch ":") {
        $CurrentCategory = $Matches[1].Trim()
        if ($IncludeAllCategories -or $SelectedCategories.Contains($CurrentCategory)) {
            $Line
        }
        continue
    }

    if (-not $CurrentCategory -or $IncludeAllCategories -or $SelectedCategories.Contains($CurrentCategory)) {
        $Line
    }
}

$ManagedContent = ($FilteredLines -join "`r`n").Trim()

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$NewHosts = @"
$CleanHosts

$BeginMarker
# Source: https://github.com/ImMALWARE/dns.malw.link
# Updated: $Timestamp
$ManagedContent
$EndMarker
"@

Write-Host "Updating system hosts..."

try {
    # UTF-8 without BOM
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText(
        $HostsPath,
        $NewHosts,
        $Utf8NoBom
    )
}
catch {
    Write-Error "Failed to write system hosts: $($_.Exception.Message)"
    Write-Host "Backup is available at:"
    Write-Host $BackupPath
    exit 1
}

Write-Host "Flushing DNS cache..."

ipconfig /flushdns | Out-Null

Write-Host ""
Write-Host "Done."
Write-Host "dns.malw.link hosts block has been updated."
Write-Host "Other hosts entries were preserved."
