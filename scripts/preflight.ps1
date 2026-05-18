<#
.SYNOPSIS
    Run the same validations CI runs, locally, before you push.

.DESCRIPTION
    Mirrors every job in .github/workflows/ci.yml so that flag-mismatches
    against the same tool versions surface here, not on GitHub:
      1. markdownlint-cli2                  (Markdown lint job)
      2. lychee link check                  (Markdown link-check job)
      3. actionlint                         (actionlint job)
      4. az bicep build / build-params      (Bicep build job)

    Tools are pinned to the same versions CI uses. Missing binaries are
    auto-downloaded into ./.tools/ (gitignored). Exits 1 on the first
    failed check.

.NOTES
    Versions:
      - markdownlint-cli2:        v0.22.x (matches DavidAnson/markdownlint-cli2-action@v18)
      - lychee:                   v0.23.0 (matches lycheeverse/lychee-action@v2 default)
      - actionlint:               local ./actionlint.exe (existing)
      - az bicep:                 whatever `az` ships locally

    Keep the lychee `$lycheeArgs` block byte-identical with the `args:` in
    .github/workflows/ci.yml — a cross-file CI test enforces this drift.
#>

[CmdletBinding()]
param(
    [switch] $SkipLychee,
    [switch] $SkipBicep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $repoRoot
try {
    $toolsDir = Join-Path $repoRoot '.tools'
    if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

    $failures = New-Object System.Collections.Generic.List[string]

    function Write-Stage([string] $name) {
        Write-Host ''
        Write-Host "==> $name" -ForegroundColor Cyan
    }

    function Record-Result([string] $name, [bool] $ok) {
        if ($ok) {
            Write-Host "    PASS  $name" -ForegroundColor Green
        } else {
            Write-Host "    FAIL  $name" -ForegroundColor Red
            $failures.Add($name)
        }
    }

    # -----------------------------------------------------------------
    # 1. markdownlint-cli2 — mirrors `Markdown lint` job in ci.yml
    # -----------------------------------------------------------------
    Write-Stage 'markdownlint-cli2 (**/*.md, ignoring node_modules + .actionlint)'
    & npx --yes markdownlint-cli2 "**/*.md" "#node_modules" "#.actionlint"
    Record-Result 'markdownlint-cli2' ($LASTEXITCODE -eq 0)

    # -----------------------------------------------------------------
    # 2. lychee link check — mirrors `Markdown link check` job in ci.yml
    # -----------------------------------------------------------------
    if (-not $SkipLychee) {
        Write-Stage 'lychee link check (downloads .tools/lychee.exe on first run)'

        $lycheeVersion = 'v0.23.0'  # KEEP IN SYNC WITH lycheeverse/lychee-action@v2 default
        $lycheeExe = Join-Path $toolsDir 'lychee.exe'

        if (-not (Test-Path $lycheeExe)) {
            # Windows release is a single signed .exe (no zip).
            $asset = 'lychee-x86_64-windows.exe'
            $url = "https://github.com/lycheeverse/lychee/releases/download/lychee-$lycheeVersion/$asset"
            Write-Host "    downloading $url"
            Invoke-WebRequest -Uri $url -OutFile $lycheeExe -UseBasicParsing
            if (-not (Test-Path $lycheeExe)) {
                throw "lychee binary not found at $lycheeExe after download"
            }
        }

        # Lychee options come from lychee.toml at repo root (auto-discovered
        # by lychee). Only file globs are passed here — keep this list in
        # sync with the `args:` block of the `Link check (lychee)` step in
        # .github/workflows/ci.yml.
        $lycheeArgs = @(
            'docs/**/*.md'
            'sprints/*.md'
            '.github/*.md'
            'AGENTS.md'
            'README.md'
        )

        & $lycheeExe @lycheeArgs
        Record-Result 'lychee' ($LASTEXITCODE -eq 0)
    } else {
        Write-Host '    SKIP  lychee (–SkipLychee)' -ForegroundColor Yellow
    }

    # -----------------------------------------------------------------
    # 3. actionlint — mirrors `actionlint (workflows)` job in ci.yml
    # -----------------------------------------------------------------
    Write-Stage 'actionlint (.github/workflows/*.yml)'
    $actionlintExe = Join-Path $repoRoot 'actionlint.exe'
    if (-not (Test-Path $actionlintExe)) {
        Write-Host '    actionlint.exe missing — install from https://github.com/rhysd/actionlint/releases' -ForegroundColor Yellow
        $failures.Add('actionlint (binary missing)')
    } else {
        # PowerShell does not auto-expand globs for native binaries — resolve to a file list.
        $workflowFiles = Get-ChildItem -Path (Join-Path $repoRoot '.github\workflows') -Filter '*.yml' -File -ErrorAction SilentlyContinue
        if (-not $workflowFiles) {
            Write-Host '    no workflow files found under .github/workflows' -ForegroundColor Yellow
            Record-Result 'actionlint' $true
        } else {
            & $actionlintExe -color @($workflowFiles.FullName)
            Record-Result 'actionlint' ($LASTEXITCODE -eq 0)
        }
    }

    # -----------------------------------------------------------------
    # 4. az bicep build / build-params — mirrors `Bicep build` job in ci.yml
    # -----------------------------------------------------------------
    if (-not $SkipBicep) {
        Write-Stage 'az bicep build (infra/**/*.bicep, infra/**/*.bicepparam)'

        $bicepFiles  = Get-ChildItem -Path 'infra' -Filter *.bicep      -Recurse -File -ErrorAction SilentlyContinue
        $paramFiles  = Get-ChildItem -Path 'infra' -Filter *.bicepparam -Recurse -File -ErrorAction SilentlyContinue

        if (-not $bicepFiles -and -not $paramFiles) {
            Write-Host '    NOTE  no infra/**/*.bicep[param] files yet — nothing to build.' -ForegroundColor Yellow
        } else {
            foreach ($f in $bicepFiles) {
                $rel = Resolve-Path -Relative $f.FullName
                Write-Host "    build  $rel"
                & az bicep build --file $f.FullName --stdout > $null
                Record-Result "bicep build $rel" ($LASTEXITCODE -eq 0)
            }
            foreach ($f in $paramFiles) {
                $rel = Resolve-Path -Relative $f.FullName
                Write-Host "    build-params  $rel"
                & az bicep build-params --file $f.FullName --stdout > $null
                Record-Result "bicep build-params $rel" ($LASTEXITCODE -eq 0)
            }
        }
    } else {
        Write-Host '    SKIP  bicep (–SkipBicep)' -ForegroundColor Yellow
    }

    # -----------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------
    Write-Host ''
    if ($failures.Count -eq 0) {
        Write-Host 'preflight: ALL CHECKS PASSED' -ForegroundColor Green
        exit 0
    } else {
        Write-Host "preflight: FAILED ($($failures.Count))" -ForegroundColor Red
        $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
} finally {
    Pop-Location
}
