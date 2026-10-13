<#
.SYNOPSIS
    Competitive feature scan for an MCP server against others in the same
    niche on the official MCP registry (registry.modelcontextprotocol.io).

.DESCRIPTION
    1. Queries the registry for a keyword (e.g. "godot").
    2. Filters out our own io.github.sandraschi/* entries.
    3. For each competitor with a GitHub repo, fetches README.md (main/master)
       directly via Invoke-RestMethod (raw.githubusercontent.com is plain HTTP,
       no proxy/tool quirks -- see mcp-registry-api-calling-method memory note).
    4. Extracts Highlights/Features/Comparison-style sections via regex.
    5. Writes one consolidated markdown scaffold: registry version/status table
       + per-competitor extracted feature sections, ready for manual "filch"
       review against our own README's ## Features section.

.NOTES
    Does NOT call any LLM. This is pure data-gathering -- the actual "what
    should we borrow" judgment call stays a human/Claude review step over the
    output file. Registry search is a substring match on name/description
    only, not a semantic search, so skim results for false positives/misses.

.EXAMPLE
    .\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile D:\temp\godot-competitor-scan.md
#>
param(
    [Parameter(Mandatory=$true)][string]$Keyword,
    [Parameter(Mandatory=$true)][string]$OwnRepoPath,
    [string]$OutFile = "C:\temp\competitor-scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').md",
    [int]$Limit = 100
)

function Get-CompetitorReadme {
    param([string]$RepoUrl)
    if ($RepoUrl -notmatch 'github\.com/([^/]+)/([^/]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$',''
    foreach ($branch in @('main','master')) {
        $url = "https://raw.githubusercontent.com/$owner/$repo/$branch/README.md"
        try {
            return Invoke-RestMethod -Uri $url -ErrorAction Stop
        } catch { continue }
    }
    return $null
}

function Extract-Sections {
    param([string]$Markdown)
    # Grab any section whose header matches common competitive-signal headers.
    $pattern = '(?ms)^#{1,3}\s*(Highlights|Features|Tools|Comparison|How [Ii]t [Cc]ompares|Why(?: this one)?)\s*$(.*?)(?=^#{1,3}\s|\z)'
    $matches = [regex]::Matches($Markdown, $pattern)
    $out = ""
    foreach ($m in $matches) {
        $out += "### $($m.Groups[1].Value)`n$($m.Groups[2].Value.Trim())`n`n"
    }
    if (-not $out) { $out = "*(no Highlights/Features/Comparison/Why section found -- skim full README manually)*`n" }
    return $out
}

Write-Host "Querying registry for '$Keyword'..."
$reg = Invoke-RestMethod "https://registry.modelcontextprotocol.io/v0/servers?search=$Keyword&limit=$Limit"

$rows = $reg.servers | ForEach-Object {
    $s = $_.server; $m = $_._meta.'io.modelcontextprotocol.registry/official'
    if ($m.isLatest) {
        [PSCustomObject]@{
            name    = $s.name
            version = $s.version
            desc    = $s.description
            repo    = $s.repository.url
            isOwn   = $s.name -match 'sandraschi'
        }
    }
} | Sort-Object name -Unique

$own = @($rows | Where-Object { <#
.SYNOPSIS
    Competitive feature scan for an MCP server against others in the same
    niche on the official MCP registry (registry.modelcontextprotocol.io).

.DESCRIPTION
    1. Queries the registry for a keyword (e.g. "godot").
    2. Filters out our own io.github.sandraschi/* entries.
    3. For each competitor with a GitHub repo, fetches README.md (main/master)
       directly via Invoke-RestMethod (raw.githubusercontent.com is plain HTTP,
       no proxy/tool quirks -- see mcp-registry-api-calling-method memory note).
    4. Extracts Highlights/Features/Comparison-style sections via regex.
    5. Writes one consolidated markdown scaffold: registry version/status table
       + per-competitor extracted feature sections, ready for manual "filch"
       review against our own README's ## Features section.

.NOTES
    Does NOT call any LLM. This is pure data-gathering -- the actual "what
    should we borrow" judgment call stays a human/Claude review step over the
    output file. Registry search is a substring match on name/description
    only, not a semantic search, so skim results for false positives/misses.

.EXAMPLE
    .\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile D:\temp\godot-competitor-scan.md
#>
param(
    [Parameter(Mandatory=$true)][string]$Keyword,
    [Parameter(Mandatory=$true)][string]$OwnRepoPath,
    [string]$OutFile = "C:\temp\competitor-scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').md",
    [int]$Limit = 100
)

function Get-CompetitorReadme {
    param([string]$RepoUrl)
    if ($RepoUrl -notmatch 'github\.com/([^/]+)/([^/]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$',''
    foreach ($branch in @('main','master')) {
        $url = "https://raw.githubusercontent.com/$owner/$repo/$branch/README.md"
        try {
            return Invoke-RestMethod -Uri $url -ErrorAction Stop
        } catch { continue }
    }
    return $null
}

function Extract-Sections {
    param([string]$Markdown)
    # Grab any section whose header matches common competitive-signal headers.
    $pattern = '(?ms)^#{1,3}\s*(Highlights|Features|Tools|Comparison|How [Ii]t [Cc]ompares|Why(?: this one)?)\s*$(.*?)(?=^#{1,3}\s|\z)'
    $matches = [regex]::Matches($Markdown, $pattern)
    $out = ""
    foreach ($m in $matches) {
        $out += "### $($m.Groups[1].Value)`n$($m.Groups[2].Value.Trim())`n`n"
    }
    if (-not $out) { $out = "*(no Highlights/Features/Comparison/Why section found -- skim full README manually)*`n" }
    return $out
}

Write-Host "Querying registry for '$Keyword'..."
$reg = Invoke-RestMethod "https://registry.modelcontextprotocol.io/v0/servers?search=$Keyword&limit=$Limit"

$rows = $reg.servers | ForEach-Object {
    $s = $_.server; $m = $_._meta.'io.modelcontextprotocol.registry/official'
    if ($m.isLatest) {
        [PSCustomObject]@{
            name    = $s.name
            version = $s.version
            desc    = $s.description
            repo    = $s.repository.url
            isOwn   = $s.name -match 'sandraschi'
        }
    }
} | Sort-Object name -Unique

$own = $rows | Where-Object { $_.isOwn }
$competitors = @($rows | Where-Object { -not <#
.SYNOPSIS
    Competitive feature scan for an MCP server against others in the same
    niche on the official MCP registry (registry.modelcontextprotocol.io).

.DESCRIPTION
    1. Queries the registry for a keyword (e.g. "godot").
    2. Filters out our own io.github.sandraschi/* entries.
    3. For each competitor with a GitHub repo, fetches README.md (main/master)
       directly via Invoke-RestMethod (raw.githubusercontent.com is plain HTTP,
       no proxy/tool quirks -- see mcp-registry-api-calling-method memory note).
    4. Extracts Highlights/Features/Comparison-style sections via regex.
    5. Writes one consolidated markdown scaffold: registry version/status table
       + per-competitor extracted feature sections, ready for manual "filch"
       review against our own README's ## Features section.

.NOTES
    Does NOT call any LLM. This is pure data-gathering -- the actual "what
    should we borrow" judgment call stays a human/Claude review step over the
    output file. Registry search is a substring match on name/description
    only, not a semantic search, so skim results for false positives/misses.

.EXAMPLE
    .\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile D:\temp\godot-competitor-scan.md
#>
param(
    [Parameter(Mandatory=$true)][string]$Keyword,
    [Parameter(Mandatory=$true)][string]$OwnRepoPath,
    [string]$OutFile = "C:\temp\competitor-scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').md",
    [int]$Limit = 100
)

function Get-CompetitorReadme {
    param([string]$RepoUrl)
    if ($RepoUrl -notmatch 'github\.com/([^/]+)/([^/]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$',''
    foreach ($branch in @('main','master')) {
        $url = "https://raw.githubusercontent.com/$owner/$repo/$branch/README.md"
        try {
            return Invoke-RestMethod -Uri $url -ErrorAction Stop
        } catch { continue }
    }
    return $null
}

function Extract-Sections {
    param([string]$Markdown)
    # Grab any section whose header matches common competitive-signal headers.
    $pattern = '(?ms)^#{1,3}\s*(Highlights|Features|Tools|Comparison|How [Ii]t [Cc]ompares|Why(?: this one)?)\s*$(.*?)(?=^#{1,3}\s|\z)'
    $matches = [regex]::Matches($Markdown, $pattern)
    $out = ""
    foreach ($m in $matches) {
        $out += "### $($m.Groups[1].Value)`n$($m.Groups[2].Value.Trim())`n`n"
    }
    if (-not $out) { $out = "*(no Highlights/Features/Comparison/Why section found -- skim full README manually)*`n" }
    return $out
}

Write-Host "Querying registry for '$Keyword'..."
$reg = Invoke-RestMethod "https://registry.modelcontextprotocol.io/v0/servers?search=$Keyword&limit=$Limit"

$rows = $reg.servers | ForEach-Object {
    $s = $_.server; $m = $_._meta.'io.modelcontextprotocol.registry/official'
    if ($m.isLatest) {
        [PSCustomObject]@{
            name    = $s.name
            version = $s.version
            desc    = $s.description
            repo    = $s.repository.url
            isOwn   = $s.name -match 'sandraschi'
        }
    }
} | Sort-Object name -Unique

$own = @($rows | Where-Object { <#
.SYNOPSIS
    Competitive feature scan for an MCP server against others in the same
    niche on the official MCP registry (registry.modelcontextprotocol.io).

.DESCRIPTION
    1. Queries the registry for a keyword (e.g. "godot").
    2. Filters out our own io.github.sandraschi/* entries.
    3. For each competitor with a GitHub repo, fetches README.md (main/master)
       directly via Invoke-RestMethod (raw.githubusercontent.com is plain HTTP,
       no proxy/tool quirks -- see mcp-registry-api-calling-method memory note).
    4. Extracts Highlights/Features/Comparison-style sections via regex.
    5. Writes one consolidated markdown scaffold: registry version/status table
       + per-competitor extracted feature sections, ready for manual "filch"
       review against our own README's ## Features section.

.NOTES
    Does NOT call any LLM. This is pure data-gathering -- the actual "what
    should we borrow" judgment call stays a human/Claude review step over the
    output file. Registry search is a substring match on name/description
    only, not a semantic search, so skim results for false positives/misses.

.EXAMPLE
    .\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile D:\temp\godot-competitor-scan.md
#>
param(
    [Parameter(Mandatory=$true)][string]$Keyword,
    [Parameter(Mandatory=$true)][string]$OwnRepoPath,
    [string]$OutFile = "C:\temp\competitor-scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').md",
    [int]$Limit = 100
)

function Get-CompetitorReadme {
    param([string]$RepoUrl)
    if ($RepoUrl -notmatch 'github\.com/([^/]+)/([^/]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$',''
    foreach ($branch in @('main','master')) {
        $url = "https://raw.githubusercontent.com/$owner/$repo/$branch/README.md"
        try {
            return Invoke-RestMethod -Uri $url -ErrorAction Stop
        } catch { continue }
    }
    return $null
}

function Extract-Sections {
    param([string]$Markdown)
    # Grab any section whose header matches common competitive-signal headers.
    $pattern = '(?ms)^#{1,3}\s*(Highlights|Features|Tools|Comparison|How [Ii]t [Cc]ompares|Why(?: this one)?)\s*$(.*?)(?=^#{1,3}\s|\z)'
    $matches = [regex]::Matches($Markdown, $pattern)
    $out = ""
    foreach ($m in $matches) {
        $out += "### $($m.Groups[1].Value)`n$($m.Groups[2].Value.Trim())`n`n"
    }
    if (-not $out) { $out = "*(no Highlights/Features/Comparison/Why section found -- skim full README manually)*`n" }
    return $out
}

Write-Host "Querying registry for '$Keyword'..."
$reg = Invoke-RestMethod "https://registry.modelcontextprotocol.io/v0/servers?search=$Keyword&limit=$Limit"

$rows = $reg.servers | ForEach-Object {
    $s = $_.server; $m = $_._meta.'io.modelcontextprotocol.registry/official'
    if ($m.isLatest) {
        [PSCustomObject]@{
            name    = $s.name
            version = $s.version
            desc    = $s.description
            repo    = $s.repository.url
            isOwn   = $s.name -match 'sandraschi'
        }
    }
} | Sort-Object name -Unique

$own = $rows | Where-Object { $_.isOwn }
$competitors = $rows | Where-Object { -not $_.isOwn }

Write-Host "Found $($rows.Count) latest entries ($($competitors.Count) competitors, $($own.Count) ours)."

$ownReadmePath = Join-Path $OwnRepoPath "README.md"
$ownReadme = if (Test-Path $ownReadmePath) { Get-Content $ownReadmePath -Raw -Encoding UTF8 } else { "" }
$ownFeatures = Extract-Sections -Markdown $ownReadme

$md = @()
$md += "# Competitor scan: '$Keyword' -- $(Get-Date -Format 'yyyy-MM-dd')"
$md += ""
$md += "## Registry snapshot"
$md += ""
$md += "| Server | Version | Description |"
$md += "|---|---|---|"
foreach ($r in $rows) {
    $marker = if ($r.isOwn) { "**[OURS]** " } else { "" }
    $md += "| $marker$($r.name) | $($r.version) | $($r.desc) |"
}
$md += ""
$md += "## Our features ($($own.name -join ', '))"
$md += ""
$md += $ownFeatures
$md += "---"
$md += ""
$md += "## Competitor feature extracts"
$md += ""

foreach ($c in $competitors) {
    Write-Host "Fetching README for $($c.name)..."
    $readme = Get-CompetitorReadme -RepoUrl $c.repo
    $md += "### $($c.name) (v$($c.version))"
    $md += ""
    $md += "$($c.repo)"
    $md += ""
    if ($readme) {
        $md += Extract-Sections -Markdown $readme
    } else {
        $md += "*(README fetch failed -- check repo/branch manually: $($c.repo))*"
        $md += ""
    }
    $md += "---"
    $md += ""
}

$md -join "`n" | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Written to $OutFile"
.isOwn })
$competitors = $rows | Where-Object { -not $_.isOwn }

Write-Host "Found $($rows.Count) latest entries ($($competitors.Count) competitors, $($own.Count) ours)."

$ownReadmePath = Join-Path $OwnRepoPath "README.md"
$ownReadme = if (Test-Path $ownReadmePath) { Get-Content $ownReadmePath -Raw -Encoding UTF8 } else { "" }
$ownFeatures = Extract-Sections -Markdown $ownReadme

$md = @()
$md += "# Competitor scan: '$Keyword' -- $(Get-Date -Format 'yyyy-MM-dd')"
$md += ""
$md += "## Registry snapshot"
$md += ""
$md += "| Server | Version | Description |"
$md += "|---|---|---|"
foreach ($r in $rows) {
    $marker = if ($r.isOwn) { "**[OURS]** " } else { "" }
    $md += "| $marker$($r.name) | $($r.version) | $($r.desc) |"
}
$md += ""
$md += "## Our features ($($own.name -join ', '))"
$md += ""
$md += $ownFeatures
$md += "---"
$md += ""
$md += "## Competitor feature extracts"
$md += ""

foreach ($c in $competitors) {
    Write-Host "Fetching README for $($c.name)..."
    $readme = Get-CompetitorReadme -RepoUrl $c.repo
    $md += "### $($c.name) (v$($c.version))"
    $md += ""
    $md += "$($c.repo)"
    $md += ""
    if ($readme) {
        $md += Extract-Sections -Markdown $readme
    } else {
        $md += "*(README fetch failed -- check repo/branch manually: $($c.repo))*"
        $md += ""
    }
    $md += "---"
    $md += ""
}

$md -join "`n" | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Written to $OutFile"
.isOwn })

Write-Host "Found $($rows.Count) latest entries ($($competitors.Count) competitors, $($own.Count) ours)."

$ownReadmePath = Join-Path $OwnRepoPath "README.md"
$ownReadme = if (Test-Path $ownReadmePath) { Get-Content $ownReadmePath -Raw -Encoding UTF8 } else { "" }
$ownFeatures = Extract-Sections -Markdown $ownReadme

$md = @()
$md += "# Competitor scan: '$Keyword' -- $(Get-Date -Format 'yyyy-MM-dd')"
$md += ""
$md += "## Registry snapshot"
$md += ""
$md += "| Server | Version | Description |"
$md += "|---|---|---|"
foreach ($r in $rows) {
    $marker = if ($r.isOwn) { "**[OURS]** " } else { "" }
    $md += "| $marker$($r.name) | $($r.version) | $($r.desc) |"
}
$md += ""
$md += "## Our features ($($own.name -join ', '))"
$md += ""
$md += $ownFeatures
$md += "---"
$md += ""
$md += "## Competitor feature extracts"
$md += ""

foreach ($c in $competitors) {
    Write-Host "Fetching README for $($c.name)..."
    $readme = Get-CompetitorReadme -RepoUrl $c.repo
    $md += "### $($c.name) (v$($c.version))"
    $md += ""
    $md += "$($c.repo)"
    $md += ""
    if ($readme) {
        $md += Extract-Sections -Markdown $readme
    } else {
        $md += "*(README fetch failed -- check repo/branch manually: $($c.repo))*"
        $md += ""
    }
    $md += "---"
    $md += ""
}

$md -join "`n" | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Written to $OutFile"
.isOwn })
$competitors = @($rows | Where-Object { -not <#
.SYNOPSIS
    Competitive feature scan for an MCP server against others in the same
    niche on the official MCP registry (registry.modelcontextprotocol.io).

.DESCRIPTION
    1. Queries the registry for a keyword (e.g. "godot").
    2. Filters out our own io.github.sandraschi/* entries.
    3. For each competitor with a GitHub repo, fetches README.md (main/master)
       directly via Invoke-RestMethod (raw.githubusercontent.com is plain HTTP,
       no proxy/tool quirks -- see mcp-registry-api-calling-method memory note).
    4. Extracts Highlights/Features/Comparison-style sections via regex.
    5. Writes one consolidated markdown scaffold: registry version/status table
       + per-competitor extracted feature sections, ready for manual "filch"
       review against our own README's ## Features section.

.NOTES
    Does NOT call any LLM. This is pure data-gathering -- the actual "what
    should we borrow" judgment call stays a human/Claude review step over the
    output file. Registry search is a substring match on name/description
    only, not a semantic search, so skim results for false positives/misses.

.EXAMPLE
    .\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile D:\temp\godot-competitor-scan.md
#>
param(
    [Parameter(Mandatory=$true)][string]$Keyword,
    [Parameter(Mandatory=$true)][string]$OwnRepoPath,
    [string]$OutFile = "C:\temp\competitor-scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').md",
    [int]$Limit = 100
)

function Get-CompetitorReadme {
    param([string]$RepoUrl)
    if ($RepoUrl -notmatch 'github\.com/([^/]+)/([^/]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$',''
    foreach ($branch in @('main','master')) {
        $url = "https://raw.githubusercontent.com/$owner/$repo/$branch/README.md"
        try {
            return Invoke-RestMethod -Uri $url -ErrorAction Stop
        } catch { continue }
    }
    return $null
}

function Extract-Sections {
    param([string]$Markdown)
    # Grab any section whose header matches common competitive-signal headers.
    $pattern = '(?ms)^#{1,3}\s*(Highlights|Features|Tools|Comparison|How [Ii]t [Cc]ompares|Why(?: this one)?)\s*$(.*?)(?=^#{1,3}\s|\z)'
    $matches = [regex]::Matches($Markdown, $pattern)
    $out = ""
    foreach ($m in $matches) {
        $out += "### $($m.Groups[1].Value)`n$($m.Groups[2].Value.Trim())`n`n"
    }
    if (-not $out) { $out = "*(no Highlights/Features/Comparison/Why section found -- skim full README manually)*`n" }
    return $out
}

Write-Host "Querying registry for '$Keyword'..."
$reg = Invoke-RestMethod "https://registry.modelcontextprotocol.io/v0/servers?search=$Keyword&limit=$Limit"

$rows = $reg.servers | ForEach-Object {
    $s = $_.server; $m = $_._meta.'io.modelcontextprotocol.registry/official'
    if ($m.isLatest) {
        [PSCustomObject]@{
            name    = $s.name
            version = $s.version
            desc    = $s.description
            repo    = $s.repository.url
            isOwn   = $s.name -match 'sandraschi'
        }
    }
} | Sort-Object name -Unique

$own = @($rows | Where-Object { <#
.SYNOPSIS
    Competitive feature scan for an MCP server against others in the same
    niche on the official MCP registry (registry.modelcontextprotocol.io).

.DESCRIPTION
    1. Queries the registry for a keyword (e.g. "godot").
    2. Filters out our own io.github.sandraschi/* entries.
    3. For each competitor with a GitHub repo, fetches README.md (main/master)
       directly via Invoke-RestMethod (raw.githubusercontent.com is plain HTTP,
       no proxy/tool quirks -- see mcp-registry-api-calling-method memory note).
    4. Extracts Highlights/Features/Comparison-style sections via regex.
    5. Writes one consolidated markdown scaffold: registry version/status table
       + per-competitor extracted feature sections, ready for manual "filch"
       review against our own README's ## Features section.

.NOTES
    Does NOT call any LLM. This is pure data-gathering -- the actual "what
    should we borrow" judgment call stays a human/Claude review step over the
    output file. Registry search is a substring match on name/description
    only, not a semantic search, so skim results for false positives/misses.

.EXAMPLE
    .\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile D:\temp\godot-competitor-scan.md
#>
param(
    [Parameter(Mandatory=$true)][string]$Keyword,
    [Parameter(Mandatory=$true)][string]$OwnRepoPath,
    [string]$OutFile = "C:\temp\competitor-scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').md",
    [int]$Limit = 100
)

function Get-CompetitorReadme {
    param([string]$RepoUrl)
    if ($RepoUrl -notmatch 'github\.com/([^/]+)/([^/]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$',''
    foreach ($branch in @('main','master')) {
        $url = "https://raw.githubusercontent.com/$owner/$repo/$branch/README.md"
        try {
            return Invoke-RestMethod -Uri $url -ErrorAction Stop
        } catch { continue }
    }
    return $null
}

function Extract-Sections {
    param([string]$Markdown)
    # Grab any section whose header matches common competitive-signal headers.
    $pattern = '(?ms)^#{1,3}\s*(Highlights|Features|Tools|Comparison|How [Ii]t [Cc]ompares|Why(?: this one)?)\s*$(.*?)(?=^#{1,3}\s|\z)'
    $matches = [regex]::Matches($Markdown, $pattern)
    $out = ""
    foreach ($m in $matches) {
        $out += "### $($m.Groups[1].Value)`n$($m.Groups[2].Value.Trim())`n`n"
    }
    if (-not $out) { $out = "*(no Highlights/Features/Comparison/Why section found -- skim full README manually)*`n" }
    return $out
}

Write-Host "Querying registry for '$Keyword'..."
$reg = Invoke-RestMethod "https://registry.modelcontextprotocol.io/v0/servers?search=$Keyword&limit=$Limit"

$rows = $reg.servers | ForEach-Object {
    $s = $_.server; $m = $_._meta.'io.modelcontextprotocol.registry/official'
    if ($m.isLatest) {
        [PSCustomObject]@{
            name    = $s.name
            version = $s.version
            desc    = $s.description
            repo    = $s.repository.url
            isOwn   = $s.name -match 'sandraschi'
        }
    }
} | Sort-Object name -Unique

$own = $rows | Where-Object { $_.isOwn }
$competitors = $rows | Where-Object { -not $_.isOwn }

Write-Host "Found $($rows.Count) latest entries ($($competitors.Count) competitors, $($own.Count) ours)."

$ownReadmePath = Join-Path $OwnRepoPath "README.md"
$ownReadme = if (Test-Path $ownReadmePath) { Get-Content $ownReadmePath -Raw -Encoding UTF8 } else { "" }
$ownFeatures = Extract-Sections -Markdown $ownReadme

$md = @()
$md += "# Competitor scan: '$Keyword' -- $(Get-Date -Format 'yyyy-MM-dd')"
$md += ""
$md += "## Registry snapshot"
$md += ""
$md += "| Server | Version | Description |"
$md += "|---|---|---|"
foreach ($r in $rows) {
    $marker = if ($r.isOwn) { "**[OURS]** " } else { "" }
    $md += "| $marker$($r.name) | $($r.version) | $($r.desc) |"
}
$md += ""
$md += "## Our features ($($own.name -join ', '))"
$md += ""
$md += $ownFeatures
$md += "---"
$md += ""
$md += "## Competitor feature extracts"
$md += ""

foreach ($c in $competitors) {
    Write-Host "Fetching README for $($c.name)..."
    $readme = Get-CompetitorReadme -RepoUrl $c.repo
    $md += "### $($c.name) (v$($c.version))"
    $md += ""
    $md += "$($c.repo)"
    $md += ""
    if ($readme) {
        $md += Extract-Sections -Markdown $readme
    } else {
        $md += "*(README fetch failed -- check repo/branch manually: $($c.repo))*"
        $md += ""
    }
    $md += "---"
    $md += ""
}

$md -join "`n" | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Written to $OutFile"
.isOwn })
$competitors = $rows | Where-Object { -not $_.isOwn }

Write-Host "Found $($rows.Count) latest entries ($($competitors.Count) competitors, $($own.Count) ours)."

$ownReadmePath = Join-Path $OwnRepoPath "README.md"
$ownReadme = if (Test-Path $ownReadmePath) { Get-Content $ownReadmePath -Raw -Encoding UTF8 } else { "" }
$ownFeatures = Extract-Sections -Markdown $ownReadme

$md = @()
$md += "# Competitor scan: '$Keyword' -- $(Get-Date -Format 'yyyy-MM-dd')"
$md += ""
$md += "## Registry snapshot"
$md += ""
$md += "| Server | Version | Description |"
$md += "|---|---|---|"
foreach ($r in $rows) {
    $marker = if ($r.isOwn) { "**[OURS]** " } else { "" }
    $md += "| $marker$($r.name) | $($r.version) | $($r.desc) |"
}
$md += ""
$md += "## Our features ($($own.name -join ', '))"
$md += ""
$md += $ownFeatures
$md += "---"
$md += ""
$md += "## Competitor feature extracts"
$md += ""

foreach ($c in $competitors) {
    Write-Host "Fetching README for $($c.name)..."
    $readme = Get-CompetitorReadme -RepoUrl $c.repo
    $md += "### $($c.name) (v$($c.version))"
    $md += ""
    $md += "$($c.repo)"
    $md += ""
    if ($readme) {
        $md += Extract-Sections -Markdown $readme
    } else {
        $md += "*(README fetch failed -- check repo/branch manually: $($c.repo))*"
        $md += ""
    }
    $md += "---"
    $md += ""
}

$md -join "`n" | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Written to $OutFile"
.isOwn })

Write-Host "Found $($rows.Count) latest entries ($($competitors.Count) competitors, $($own.Count) ours)."

$ownReadmePath = Join-Path $OwnRepoPath "README.md"
$ownReadme = if (Test-Path $ownReadmePath) { Get-Content $ownReadmePath -Raw -Encoding UTF8 } else { "" }
$ownFeatures = Extract-Sections -Markdown $ownReadme

$md = @()
$md += "# Competitor scan: '$Keyword' -- $(Get-Date -Format 'yyyy-MM-dd')"
$md += ""
$md += "## Registry snapshot"
$md += ""
$md += "| Server | Version | Description |"
$md += "|---|---|---|"
foreach ($r in $rows) {
    $marker = if ($r.isOwn) { "**[OURS]** " } else { "" }
    $md += "| $marker$($r.name) | $($r.version) | $($r.desc) |"
}
$md += ""
$md += "## Our features ($($own.name -join ', '))"
$md += ""
$md += $ownFeatures
$md += "---"
$md += ""
$md += "## Competitor feature extracts"
$md += ""

foreach ($c in $competitors) {
    Write-Host "Fetching README for $($c.name)..."
    $readme = Get-CompetitorReadme -RepoUrl $c.repo
    $md += "### $($c.name) (v$($c.version))"
    $md += ""
    $md += "$($c.repo)"
    $md += ""
    if ($readme) {
        $md += Extract-Sections -Markdown $readme
    } else {
        $md += "*(README fetch failed -- check repo/branch manually: $($c.repo))*"
        $md += ""
    }
    $md += "---"
    $md += ""
}

$md -join "`n" | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Written to $OutFile"

