#Requires -Version 5.1
<#
.SYNOPSIS
    PC TuneUp の配布物を作る。
.DESCRIPTION
    dist\PCTuneUp-<version>-portable.zip  インストール不要版 (展開してそのまま使える)
    dist\PCTuneUp-<version>-setup.exe     インストーラー (Inno Setup が必要)

    exe のコンパイルには Windows に同梱されている csc.exe を使うため、
    .NET SDK などを別途入れる必要はありません。
.PARAMETER Version
    付けない場合は app\lib\Core.ps1 に書かれているバージョンを使います。
.PARAMETER Repo
    更新の確認先 (GitHub の owner/repo)。配布物に update-channel.json として埋め込みます。
.PARAMETER SkipInstaller
    インストーラーを作らず、portable zip だけ作ります。
#>
[CmdletBinding()]
param(
    [string]$Version,
    [string]$Repo = 'hidetako/pc-tuneup-desktop',
    [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $PSScriptRoot
$app   = Join-Path $root 'app'
$dist  = Join-Path $root 'dist'
$obj   = Join-Path $root 'obj'
$stage = Join-Path $dist 'stage\PCTuneUp'

function Step { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }

function Write-UpdateChannel {
    <#
      配布物に同梱する update-channel.json を書く。
      本体はこのファイルがあるときだけ更新を確認する (開発用クローンには無い)。
      Kind は portable / setup で挙動が変わるため、zip と インストーラーで書き分ける。
      JSON なので BOM は付けない。
    #>
    param([Parameter(Mandatory)][ValidateSet('portable', 'setup')][string]$Kind)
    $obj = [ordered]@{
        Repo    = $Repo
        Version = $Version
        Kind    = $Kind
        Built   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    $path = Join-Path $stage 'update-channel.json'
    # 5.1 と 7 で同じ形になるよう PSCustomObject にしてから変換する
    [System.IO.File]::WriteAllText($path, ([pscustomobject]$obj | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
}

function Find-Iscc {
    @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

# ---- 1. 本体 (submodule) があるか ----------------------------------------
if (-not (Test-Path -LiteralPath (Join-Path $app 'PCTuneUp.ps1'))) {
    throw "app\PCTuneUp.ps1 がありません。先に submodule を取得してください: git submodule update --init --recursive"
}

# ---- 2. バージョン --------------------------------------------------------
if (-not $Version) {
    $core = Get-Content -LiteralPath (Join-Path $app 'lib\Core.ps1') -Raw -Encoding UTF8
    if ($core -match "Version\s*=\s*'([0-9]+\.[0-9]+\.[0-9]+)'") { $Version = $Matches[1] }
    else { throw 'app\lib\Core.ps1 からバージョンを読み取れません。-Version で指定してください' }
}
if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') { throw "バージョンの形式が不正です: $Version (例 1.0.0)" }
Step "バージョン $Version"

# ---- 3. 出力先を作り直す --------------------------------------------------
foreach ($d in $dist, $obj) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force } }
New-Item -ItemType Directory -Path $stage -Force | Out-Null
New-Item -ItemType Directory -Path $obj -Force | Out-Null

# ---- 4. 本体ファイルを集める ----------------------------------------------
Step '本体ファイルを集めています'
foreach ($f in 'PCTuneUp.ps1', 'PCTuneUp.cmd', 'pc_maintenance_icon.ico', 'README.md') {
    $src = Join-Path $app $f
    if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $stage }
}
foreach ($d in 'lib', 'gui') {
    Copy-Item -LiteralPath (Join-Path $app $d) -Destination $stage -Recurse
}
Write-UpdateChannel -Kind 'portable'
Step "更新の確認先: $Repo"

# ---- 5. ランチャー exe をコンパイル ---------------------------------------
Step 'PCTuneUp.exe をコンパイルしています'
$csc = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) { throw 'csc.exe が見つかりません (.NET Framework 4.x が必要です)' }

$assemblyInfo = Join-Path $obj 'AssemblyInfo.cs'
@"
using System.Reflection;
using System.Runtime.InteropServices;
[assembly: AssemblyTitle("PC TuneUp")]
[assembly: AssemblyProduct("PC TuneUp")]
[assembly: AssemblyDescription("Windows 11 の不要ファイル・設定・セキュリティを点検して修復します")]
[assembly: AssemblyCompany("hidetako")]
[assembly: AssemblyCopyright("Copyright (c) 2026 hidetako")]
[assembly: AssemblyVersion("$Version.0")]
[assembly: AssemblyFileVersion("$Version.0")]
[assembly: ComVisible(false)]
"@ | Set-Content -LiteralPath $assemblyInfo -Encoding UTF8

$exe = Join-Path $stage 'PCTuneUp.exe'
$cscArgs = @(
    '/nologo', '/target:winexe', '/platform:anycpu', '/optimize+', '/codepage:65001',
    "/out:$exe",
    "/win32icon:$(Join-Path $app 'pc_maintenance_icon.ico')",
    "/win32manifest:$(Join-Path $root 'src\app.manifest')",
    '/reference:System.dll', '/reference:System.Drawing.dll', '/reference:System.Windows.Forms.dll',
    (Join-Path $root 'src\Launcher.cs'),
    $assemblyInfo
)
& $csc @cscArgs
if ($LASTEXITCODE -ne 0) { throw "csc.exe が失敗しました (終了コード $LASTEXITCODE)" }
if (-not (Test-Path -LiteralPath $exe)) { throw 'PCTuneUp.exe が生成されませんでした' }
Step "できました: $exe"

# ---- 6. portable zip ------------------------------------------------------
Step 'portable zip を作っています'
$zip = Join-Path $dist "PCTuneUp-$Version-portable.zip"
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal
Step "できました: $zip"

# ---- 7. インストーラー ----------------------------------------------------
if ($SkipInstaller) {
    Step 'インストーラーは -SkipInstaller によりスキップしました'
} else {
    $iscc = Find-Iscc
    if (-not $iscc) {
        Step 'Inno Setup が見つからないので winget で入れます'
        try {
            & winget install --id JRSoftware.InnoSetup --silent --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Warning "winget での導入に失敗しました: $($_.Exception.Message)"
        }
        $iscc = Find-Iscc
    }
    if ($iscc) {
        Step 'インストーラーをビルドしています'
        # インストーラーで入れた版は、更新もインストーラーで行える
        Write-UpdateChannel -Kind 'setup'
        & $iscc "/DAppVersion=$Version" "/DStageDir=$stage" "/DOutputDir=$dist" "/DRepoRoot=$root" (Join-Path $root 'packaging\PCTuneUp.iss')
        if ($LASTEXITCODE -ne 0) { throw "ISCC.exe が失敗しました (終了コード $LASTEXITCODE)" }
    } else {
        Write-Warning 'Inno Setup が無いためインストーラーは作れませんでした。portable zip だけ出来ています。'
        Write-Warning 'https://jrsoftware.org/isdl.php から入れるか、-SkipInstaller を付けてこの警告を消してください。'
    }
}

# ---- 8. チェックサム ------------------------------------------------------
# 本体の更新機能が、ダウンロードしたファイルの破損・取り違えを検出するのに使う。
Step 'SHA256SUMS.txt を作っています'
$artifacts = @(Get-ChildItem -LiteralPath $dist -File | Where-Object { $_.Extension -in '.exe', '.zip' } | Sort-Object Name)
$lines = foreach ($a in $artifacts) {
    '{0}  {1}' -f (Get-FileHash -LiteralPath $a.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $a.Name
}
[System.IO.File]::WriteAllText(
    (Join-Path $dist 'SHA256SUMS.txt'),
    (($lines -join "`r`n") + "`r`n"),
    (New-Object System.Text.UTF8Encoding($false)))

Step '完成'
Get-ChildItem -LiteralPath $dist -File | ForEach-Object { '  {0}  ({1:N1} MB)' -f $_.Name, ($_.Length / 1MB) }
