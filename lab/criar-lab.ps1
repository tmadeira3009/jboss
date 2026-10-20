<#
.SYNOPSIS
  Laboratório RHCJA no Windows — cria os base directories limpos (simple/node1/node2).
  Mesma lógica do criar-lab.sh: copia $JBOSS_HOME\domain, renomeia o host e apaga
  os blocos <servers> / <server-groups> (estado inicial da prova).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File criar-lab.ps1
  powershell -ExecutionPolicy Bypass -File criar-lab.ps1 -Modo tudo
  powershell -ExecutionPolicy Bypass -File criar-lab.ps1 -JbossHome C:\eap -LabDir D:\lab
#>
param(
    [ValidateSet('simple', 'tudo')]
    [string]$Modo = 'simple',

    [string]$JbossHome = $env:JBOSS_HOME,

    [string]$LabDir = $env:LAB_DIR
)

$ErrorActionPreference = 'Stop'

if (-not $LabDir) { $LabDir = Join-Path $env:USERPROFILE 'lab-eap' }
if (-not $JbossHome) {
    Write-Host 'ERRO: JBOSS_HOME nao definido.' -ForegroundColor Red
    Write-Host '      Rode:  setx JBOSS_HOME C:\eap    (depois abra um NOVO terminal)'
    Write-Host '      ou use: -JbossHome C:\eap'
    exit 1
}
$JbossHome = $JbossHome.TrimEnd('\')
if (-not (Test-Path (Join-Path $JbossHome 'domain\configuration\host.xml'))) {
    Write-Host "ERRO: EAP nao encontrado em '$JbossHome' (falta domain\configuration\host.xml)" -ForegroundColor Red
    exit 1
}

$alvos = if ($Modo -eq 'tudo') { @('simple', 'node1', 'node2') } else { @('simple') }

Write-Host "EAP: $JbossHome"
Write-Host "Lab: $LabDir"

foreach ($nome in $alvos) {
    $dest = Join-Path $LabDir $nome
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path (Join-Path $JbossHome 'domain\*') -Destination $dest -Recurse -Force

    # host.xml: renomeia o host para <nome> e apaga o bloco <servers> inteiro
    $hx = Join-Path $dest 'configuration\host.xml'
    $xml = [IO.File]::ReadAllText($hx)
    $nomeLocal = $nome
    $xml = [regex]::Replace($xml, '(<host\b[^>]*?\bname=")[^"]*(")',
        { param($m) $m.Groups[1].Value + $nomeLocal + $m.Groups[2].Value })
    $xml = [regex]::Replace($xml, '(?s)<servers>.*?</servers>', '')
    [IO.File]::WriteAllText($hx, $xml)

    # domain.xml: apaga o bloco <server-groups> inteiro
    $dx = Join-Path $dest 'configuration\domain.xml'
    $dxXml = [IO.File]::ReadAllText($dx)
    $dxXml = [regex]::Replace($dxXml, '(?s)<server-groups>.*?</server-groups>', '')
    [IO.File]::WriteAllText($dx, $dxXml)

    # confere o resultado
    $hxNovo = [IO.File]::ReadAllText($hx)
    $dxNovo = [IO.File]::ReadAllText($dx)
    $okNome = $hxNovo -match ('name="' + [regex]::Escape($nome) + '"')
    $okServers = ($hxNovo -notmatch '<servers')
    $okGroups = ($dxNovo -notmatch '<server-groups')

    if ($okNome -and $okServers -and $okGroups) {
        Write-Host "  [OK] $dest  (host name='$nome', sem servers/server-groups)" -ForegroundColor Green
        Write-Host "       Sobe com: $JbossHome\bin\domain.bat -Djboss.domain.base.dir=$dest"
    } else {
        Write-Host "  [ERRO] $dest (nome=$okNome servers=$okServers groups=$okGroups)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ''
Write-Host 'Pronto! Depois: powershell -ExecutionPolicy Bypass -File checar-lab.ps1'
