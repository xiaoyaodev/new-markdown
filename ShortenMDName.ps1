$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$classes = 'HKCU:\Software\Classes'
$extPath = Join-Path $classes '.md'
$displayName = 'Markdown'

# --- back up the .md key once (never overwrite the first backup) ---
if (-not (Test-Path "$dir\md-backup.reg")) {
    & reg.exe export 'HKCU\Software\Classes\.md' "$dir\md-backup.reg" /y | Out-Null
}

if (-not (Test-Path $extPath)) { New-Item -Path $extPath -Force | Out-Null }
$progId = (Get-Item $extPath).GetValue('')
if (-not $progId) { $progId = (Get-Item 'Registry::HKEY_CLASSES_ROOT\.md').GetValue('') }
if (-not $progId) { throw 'No .md association found.' }
Write-Host "Current .md type: $progId"

# --- only READ the current open command / icon; the editor's own
#     registration is never modified ---
$src = "Registry::HKEY_CLASSES_ROOT\$progId"
$openCmd = (Get-Item "$src\shell\open\command").GetValue('')
$icon = $null
if (Test-Path "$src\DefaultIcon") { $icon = (Get-Item "$src\DefaultIcon").GetValue('') }

# --- create a dedicated type for .md with the short name ---
$newId = 'UserMarkdownFile'
$dst = Join-Path $classes $newId
New-Item -Path "$dst\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path $dst -Name '(Default)' -Value $displayName
Set-ItemProperty -Path $dst -Name 'FriendlyTypeName' -Value $displayName
Set-ItemProperty -Path "$dst\shell\open\command" -Name '(Default)' -Value $openCmd
if ($icon) {
    New-Item -Path "$dst\DefaultIcon" -Force | Out-Null
    Set-ItemProperty -Path "$dst\DefaultIcon" -Name '(Default)' -Value $icon
}

# --- point .md at the dedicated type, add the New-menu entry ---
Set-ItemProperty -Path $extPath -Name '(Default)' -Value $newId
New-Item -Path "$extPath\ShellNew" -Force | Out-Null
Set-ItemProperty -Path "$extPath\ShellNew" -Name 'NullFile' -Value ''

# --- refresh Explorer so the New menu picks it up ---
Stop-Process -Name explorer -Force
Start-Sleep -Milliseconds 800
Start-Process explorer.exe
Write-Host ''
Write-Host 'Done: the New menu entry for .md is now named "Markdown".'
