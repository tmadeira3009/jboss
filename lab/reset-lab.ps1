<#
.SYNOPSIS
  Laboratório RHCJA no Windows — apaga as bases para refazer do zero.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File reset-lab.ps1      # pede confirmacao 'sim'
  powershell -ExecutionPolicy Bypass -File reset-lab.ps1 -y   # sem perguntar
#>
param(
    [switch]$y,

    [string]$LabDir = $env:LAB_DIR
)

if (-not $LabDir) { $LabDir = Join-Path $env:USERPROFILE 'lab-eap' }

if (-not $y) {
    $resp = Read-Host "Isso apaga simple/node1/node2 em '$LabDir'. Digite 'sim' para confirmar"
    if ($resp -ne 'sim') {
        Write-Host 'Cancelado.' -ForegroundColor Yellow
        exit 1
    }
}

foreach ($nome in @('simple', 'node1', 'node2')) {
    $dest = Join-Path $LabDir $nome
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
        Write-Host "  [OK] removido $dest" -ForegroundColor Green
    }
}

Write-Host 'Laboratorio zerado. Recrie com: criar-lab.ps1 [simple|tudo]'
