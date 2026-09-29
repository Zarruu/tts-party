$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Invoke-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Name,
        [string[]]$Arguments = @()
    )

    $tool = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $tool) {
        [Console]::Error.WriteLine("FAILED: $Label (perintah '$Name' tidak ditemukan di PATH).")
        exit 127
    }

    Write-Host "`n==> $Label"
    & $tool.Source @Arguments
    $status = $LASTEXITCODE
    if ($status -ne 0) {
        [Console]::Error.WriteLine("FAILED: $Label (exit $status).")
        exit $status
    }
}

Invoke-Check -Label 'Format (StyLua)' -Name 'stylua' -Arguments @('--check', 'src', 'tests')
Invoke-Check -Label 'Lint (Selene)' -Name 'selene' -Arguments @('src', 'tests')

$rojo = @(Get-Command 'rojo' -CommandType Application -ErrorAction SilentlyContinue) | Select-Object -First 1
$luauLsp = @(Get-Command 'luau-lsp' -CommandType Application -ErrorAction SilentlyContinue) | Select-Object -First 1
if ($null -ne $rojo -and $null -ne $luauLsp) {
    Invoke-Check -Label 'Generate Rojo sourcemap' -Name 'rojo' -Arguments @('sourcemap', 'default.project.json', '-o', 'sourcemap.json')
    Invoke-Check -Label 'Analyze Luau types' -Name 'luau-lsp' -Arguments @('analyze', '--sourcemap', 'sourcemap.json', 'src')
} else {
    Write-Host "`nSKIP: type analysis requires both rojo and luau-lsp on PATH."
}

Invoke-Check -Label 'Unit tests (Lune)' -Name 'lune' -Arguments @('run', 'tests/run')
Write-Host "`nAll available checks passed."
