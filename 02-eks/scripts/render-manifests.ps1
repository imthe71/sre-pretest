[CmdletBinding()]
param(
  [string]$ValuesFile = (Join-Path $PSScriptRoot "..\k8s\values.env"),
  [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\work\rendered-k8s"),
  [switch]$IncludeTlsExample
)

$ErrorActionPreference = "Stop"
$sourceDirectory = Join-Path $PSScriptRoot "..\k8s"

if (-not (Test-Path -LiteralPath $ValuesFile)) {
  throw "Values file not found: $ValuesFile. Copy k8s/values.env.example to k8s/values.env first."
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $ValuesFile) {
  $trimmed = $line.Trim()
  if (-not $trimmed -or $trimmed.StartsWith("#")) { continue }

  $parts = $trimmed.Split("=", 2)
  if ($parts.Count -ne 2 -or -not $parts[0].Trim()) {
    throw "Invalid values line: $line"
  }
  $values[$parts[0].Trim()] = $parts[1].Trim()
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$files = Get-ChildItem -LiteralPath $sourceDirectory -Filter "*.yaml" | Sort-Object Name

foreach ($file in $files) {
  if ($file.Name -eq "app-ingress.tls.example.yaml" -and -not $IncludeTlsExample) { continue }

  $content = Get-Content -LiteralPath $file.FullName -Raw
  foreach ($key in $values.Keys) {
    $content = $content.Replace(('${' + $key + '}'), $values[$key])
  }

  $missing = [regex]::Matches($content, '\$\{[A-Z0-9_]+\}') | ForEach-Object Value | Select-Object -Unique
  if ($missing) {
    throw "Unresolved placeholders in $($file.Name): $($missing -join ', ')"
  }

  Set-Content -LiteralPath (Join-Path $OutputDirectory $file.Name) -Value $content -Encoding utf8
}

Write-Host "Rendered $((Get-ChildItem -LiteralPath $OutputDirectory -Filter '*.yaml').Count) manifest files to $OutputDirectory"
