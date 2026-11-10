# backup.ps1 - Backup-automation
# Läser config.json (skapad av Terraform), tar en backup av källmappen,
# tar bort gamla backuper och verifierar att backupen lyckades.
#
# Körs så här:   .\backup.ps1
# Annan config:  .\backup.ps1 -ConfigPath .\annan.json

param(
    [string]$ConfigPath = "$PSScriptRoot/config.json"
)

# Loggfilen sätts när vi har läst config.json
$LogFile = $null

# --- Funktion 1: skriver ett meddelande till skärmen och till loggfilen ---
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$time] [$Level] $Message"

    if ($Level -eq "ERROR") {
        Write-Host $line -ForegroundColor Red
    }
    else {
        Write-Host $line
    }

    if ($LogFile) {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8
    }
}

# --- Funktion 2: läser config.json och gör om den till ett objekt ---
function Read-Config {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Hittar inte $Path. Kör 'terraform apply' först."
    }

    return Get-Content -Path $Path -Raw | ConvertFrom-Json
}

# --- Funktion 3: packar källmappen till en zip-fil ---
function New-Backup {
    param(
        [string]$SourceDir,
        [string]$BackupDir,
        [string]$ProjectName
    )

    if (-not (Test-Path $SourceDir)) {
        throw "Källmappen $SourceDir finns inte."
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $zipPath = Join-Path $BackupDir "$ProjectName-$stamp.zip"

    Compress-Archive -Path "$SourceDir/*" -DestinationPath $zipPath
    return $zipPath
}

# --- Funktion 4: tar bort de äldsta backuperna om det finns för många ---
function Remove-OldBackups {
    param(
        [string]$BackupDir,
        [int]$MaxBackups
    )

    # Nyast först. @() gör att det alltid blir en array.
    $backups = @(Get-ChildItem -Path $BackupDir -Filter "*.zip" | Sort-Object Name -Descending)
    $removed = 0

    if ($backups.Count -gt $MaxBackups) {
        $oldBackups = $backups | Select-Object -Skip $MaxBackups

        foreach ($old in $oldBackups) {
            Remove-Item -Path $old.FullName
            Write-Log "Tog bort gammal backup: $($old.Name)"
            $removed++
        }
    }
    else {
        Write-Log "Inga gamla backuper att ta bort ($($backups.Count) av max $MaxBackups)"
    }

    return $removed
}

# --- Funktion 5: kontrollerar att backupen innehåller alla filer ---
function Test-Backup {
    param(
        [string]$ZipPath,
        [string]$SourceDir
    )

    if (-not (Test-Path $ZipPath)) {
        Write-Log "Backup-filen finns inte: $ZipPath" "ERROR"
        return $false
    }

    # Packar upp till en tillfällig mapp och jämför antal filer
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "backup-test-$(Get-Random)"
    Expand-Archive -Path $ZipPath -DestinationPath $tempDir

    $sourceCount = @(Get-ChildItem -Path $SourceDir -File -Recurse).Count
    $backupCount = @(Get-ChildItem -Path $tempDir -File -Recurse).Count

    Remove-Item -Path $tempDir -Recurse -Force

    if ($sourceCount -eq $backupCount) {
        Write-Log "Verifiering OK: $backupCount av $sourceCount filer finns i backupen"
        return $true
    }
    else {
        Write-Log "Verifiering misslyckades: $backupCount av $sourceCount filer finns i backupen" "ERROR"
        return $false
    }
}

# --- Huvudprogrammet ---
try {
    $config = Read-Config -Path $ConfigPath

    # Sökvägarna i config.json är relativa till projektmappen
    $sourceDir = Join-Path $PSScriptRoot $config.source_dir
    $backupDir = Join-Path $PSScriptRoot $config.backup_dir
    $logDir = Join-Path $PSScriptRoot $config.log_dir
    $LogFile = Join-Path $logDir "backup.log"

    Write-Log "Startar backup för projektet $($config.project_name)"

    $zipPath = New-Backup -SourceDir $sourceDir -BackupDir $backupDir -ProjectName $config.project_name
    Write-Log "Backup skapad: $zipPath"

    $removed = Remove-OldBackups -BackupDir $backupDir -MaxBackups $config.max_backups
    $ok = Test-Backup -ZipPath $zipPath -SourceDir $sourceDir

    if ($ok) {
        Write-Log "Klart. $removed gamla backuper togs bort."
        exit 0
    }
    else {
        Write-Log "Backupen gick inte att verifiera." "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Något gick fel: $($_.Exception.Message)" "ERROR"
    exit 1
}
