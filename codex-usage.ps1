# On-demand plan-usage check for Codex CLI: % used and reset time for your
# ChatGPT/Codex plan windows (5h and/or weekly), read from local session logs.
# Codex has no statusline hook, so run this manually:
#   powershell -File codex-usage.ps1
$Esc = [char]27

function Get-WindowLabel($window) {
    $mins = $window.window_minutes
    if ($mins -ge 1440) { "{0:N1}-day window" -f ($mins / 1440) }
    elseif ($mins -ge 60) { "{0:N1}-hour window" -f ($mins / 60) }
    else { "$mins-minute window" }
}

function Format-Span($span) {
    if ($span.TotalSeconds -le 0) { "already" }
    elseif ($span.TotalHours -ge 24) { "in {0}d {1}h" -f [int]$span.TotalDays, $span.Hours }
    elseif ($span.TotalHours -ge 1) { "in {0}h {1}m" -f [int]$span.TotalHours, $span.Minutes }
    else { "in {0}m" -f [int]$span.TotalMinutes }
}

function Show-Window($window) {
    if (-not $window) { return }
    $pct = [math]::Round($window.used_percent)
    $barWidth = 10
    $filled = [math]::Min($barWidth, [math]::Floor(($pct / 100) * $barWidth))
    $bar = ("#" * $filled) + ("-" * ($barWidth - $filled))
    $color = if ($pct -ge 100) { "38;5;196" } elseif ($pct -ge 75) { "38;5;214" } else { "38;5;108" }

    $resetsAt = [DateTimeOffset]::FromUnixTimeSeconds($window.resets_at).ToLocalTime()
    $resetText = Format-Span ($resetsAt - (Get-Date))
    $label = Get-WindowLabel $window

    [Console]::Write("${Esc}[${color}m[$bar] $pct% used${Esc}[0m - $label, resets $resetText ($($resetsAt.ToString('yyyy-MM-dd HH:mm')))`n")
}

# Rate-limit snapshots only arrive on some turns, and only on the session that
# was active when the API last reported them - scan sessions newest-first,
# and within each file scan backwards, until the most recent snapshot turns up.
$sessions = Get-ChildItem -Path "$HOME\.codex\sessions" -Recurse -Filter "rollout-*.jsonl" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

$rateLimits = $null
$sourceFile = $null
foreach ($session in $sessions) {
    $lines = Get-Content $session.FullName -ErrorAction SilentlyContinue
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        try {
            $entry = $lines[$i] | ConvertFrom-Json
            if ($entry.payload.rate_limits) {
                $rateLimits = $entry.payload.rate_limits
                $sourceFile = $session.Name
                break
            }
        } catch {}
    }
    if ($rateLimits) { break }
}

if (-not $rateLimits) {
    Write-Host "No usage data found yet under ~\.codex\sessions. Run a Codex session first."
    exit 0
}

Write-Host "$sourceFile  (plan: $($rateLimits.plan_type))"
Show-Window $rateLimits.primary
Show-Window $rateLimits.secondary
