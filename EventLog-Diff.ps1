# TABARC-Code
# Report Windows events added since the last recorded event ID.
[CmdletBinding()]
param(
  [ValidateSet('System','Application','Security')][string]$LogName = 'System',
  [ValidateRange(1,10000)][int]$MaxEvents = 500,
  [string]$SnapshotPath = '',
  [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SnapshotPath) {
  $SnapshotPath = Join-Path (Join-Path $PSScriptRoot 'snapshots') "$LogName.json"
}

$latest = Get-WinEvent -LogName $LogName -MaxEvents 1 -ErrorAction Stop
$latestId = [long]$latest.RecordId
$previousId = $null

if (Test-Path -LiteralPath $SnapshotPath -PathType Leaf) {
  $previous = Get-Content -LiteralPath $SnapshotPath -Raw | ConvertFrom-Json -ErrorAction Stop
  if ($previous.LogName -ne $LogName) { throw 'Snapshot belongs to a different event log.' }
  $previousId = [long]$previous.LastRecordId
}

if ($null -eq $previousId) {
  Write-Host "First snapshot: $LogName at record $latestId. Run again to show new events."
} elseif ($latestId -lt $previousId) {
  Write-Warning "Record IDs went backwards ($previousId to $latestId). The log may have been cleared or replaced."
} elseif ($latestId -eq $previousId) {
  Write-Host "No new $LogName events."
} else {
  $xpath = "*[System[EventRecordID > $previousId]]"
  $events = @(Get-WinEvent -LogName $LogName -FilterXPath $xpath -MaxEvents $MaxEvents -ErrorAction Stop)
  $report = @($events | Sort-Object RecordId | ForEach-Object {
    [pscustomobject]@{
      LogName = $LogName
      RecordId = $_.RecordId
      TimeCreated = $_.TimeCreated
      Level = $_.LevelDisplayName
      Provider = $_.ProviderName
      EventId = $_.Id
      Message = $_.Message
    }
  })
  Write-Host "Found $($report.Count) new events in $LogName."
  if ($report.Count -ge $MaxEvents) {
    Write-Warning "The event limit was reached; older new events may have been omitted."
  }
  if ($ReportPath) {
    $reportFolder = Split-Path -Parent ([IO.Path]::GetFullPath($ReportPath))
    if (-not (Test-Path -LiteralPath $reportFolder)) {
      New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
    }
    ConvertTo-Json -InputObject $report -Depth 5 |
      Set-Content -LiteralPath $ReportPath -Encoding UTF8
  }
  $report
}

$snapshotFolder = Split-Path -Parent ([IO.Path]::GetFullPath($SnapshotPath))
if (-not (Test-Path -LiteralPath $snapshotFolder)) {
  New-Item -ItemType Directory -Path $snapshotFolder -Force | Out-Null
}
[pscustomobject]@{
  LogName = $LogName
  LastRecordId = $latestId
  CapturedAt = (Get-Date).ToUniversalTime().ToString('o')
} | ConvertTo-Json -Depth 3 |
  Set-Content -LiteralPath $SnapshotPath -Encoding UTF8
