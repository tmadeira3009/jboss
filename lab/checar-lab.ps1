<#
.SYNOPSIS
  Laboratorio RHCJA no Windows - confere pre-requisitos, bases e portas (so leitura).
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File checar-lab.ps1
#>
param(
    [string]$JbossHome = $env:JBOSS_HOME,

    [string]$LabDir = $env:LAB_DIR
)

if (-not $LabDir) { $LabDir = Join-Path $env:USERPROFILE 'lab-eap' }

$ok = 0
$falhas = 0

function Check([bool]$cond, [string]$msg) {
    if ($cond) {
        Write-Host "  [OK] $msg" -ForegroundColor Green
        $script:ok++
    } else {
        Write-Host "  [XX] $msg" -ForegroundColor Red
        $script:falhas++
    }
}

Write-Host '== Pre-requisitos =='
$temJava = [bool](Get-Command java -ErrorAction SilentlyContinue)
if (-not $temJava -and $env:JAVA_HOME) { $temJava = Test-Path (Join-Path $env:JAVA_HOME 'bin\java.exe') }
Check $temJava 'java no PATH'
$temEap = $false
if ($JbossHome) { $temEap = Test-Path (Join-Path $JbossHome 'domain\configuration\host.xml') }
Check $temEap "EAP em $JbossHome"

Write-Host '== Base directories =='
$algum = $false
foreach ($nome in @('simple', 'node1', 'node2')) {
    $dest = Join-Path $LabDir $nome
    if (-not (Test-Path $dest)) { continue }
    $algum = $true
    $hxPath = Join-Path $dest 'configuration\host.xml'
    $dxPath = Join-Path $dest 'configuration\domain.xml'
    if (-not (Test-Path $hxPath) -or -not (Test-Path $dxPath)) {
        Check $false "${nome}: base incompleta (falta host.xml/domain.xml) - rode criar-lab.ps1 de novo"
        continue
    }
    $hx = [IO.File]::ReadAllText($hxPath)
    $dx = [IO.File]::ReadAllText($dxPath)
    Check ($hx -notmatch '<servers') "${nome}: dominio limpo (sem servers padrao)"
    Check ($dx -notmatch '<server-groups') "${nome}: sem server-groups padrao"
    Check ($hx -match ('name="' + [regex]::Escape($nome) + '"')) "${nome}: nome do host correto"
}
if (-not $algum) {
    Write-Host "  (nenhuma base criada ainda em $LabDir - rode criar-lab.ps1)"
}

Write-Host '== Servidor no ar? =='
$net = netstat -ano 2>$null
if ($net -match ':9990\s+.*LISTENING') {
    Write-Host '  [OK] 9990 responde (console ativo)' -ForegroundColor Green
} else {
    Write-Host '  [--] 9990 nao responde (esperado se o dominio esta parado)'
}
if ($net -match ':8080\s+.*LISTENING') {
    Write-Host '  [OK] 8080 responde (servidor de apps ativo)' -ForegroundColor Green
} else {
    Write-Host '  [--] 8080 nao responde (esperado se o dominio esta parado)'
}

Write-Host ''
Write-Host "Resultado: $ok ok, $falhas problema(s)."
if ($falhas -gt 0) { exit 1 } else { exit 0 }
