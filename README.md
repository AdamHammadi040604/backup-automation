# Backup-automation med Terraform och PowerShell

Examinerande projekt i kursen Infrastruktur konfigurering och deployment med programmering.

**GitHub-repository:** https://github.com/AdamHammadi040604/backup-automation

## Mål

Målet är att automatisera säkerhetskopiering av en mapp. I stället för att kopiera
filer för hand ska ett kommando ta en backup, rensa bort gamla backuper och
kontrollera att backupen blev rätt.

Projektet visar en kedja där två verktyg samverkar: Terraform skapar strukturen
och PowerShell gör jobbet.

## Metod

| Steg | Verktyg | Vad som händer |
|------|---------|----------------|
| 1 | Terraform | Skapar mapparna `data/`, `backups/` och `logs/`, testfiler och `config.json` |
| 2 | PowerShell | Läser `config.json` och packar `data/` till en zip-fil i `backups/` |
| 3 | PowerShell | Tar bort de äldsta backuperna om det finns fler än `max_backups` |
| 4 | PowerShell | Verifierar att zip-filen innehåller lika många filer som källmappen |
| 5 | PowerShell | Loggar alla steg med tidsstämpel i `logs/backup.log` |

Kopplingen mellan verktygen är `config.json`. Terraform skriver filen utifrån
variablerna i `variables.tf`, och PowerShell läser den. Ändrar man en variabel i
Terraform ändras alltså beteendet i PowerShell utan att skriptet behöver röras.

### Filer

| Fil | Innehåll |
|-----|----------|
| `main.tf` | Provider och resurser (config, testfiler, mappar) |
| `variables.tf` | Variabler: projektnamn, mappar, antal backuper, testfiler |
| `outputs.tf` | Visar vad som skapades |
| `backup.ps1` | Skriptet som tar backup, rensar och verifierar |

### Funktioner i backup.ps1

| Funktion | Uppgift |
|----------|---------|
| `Write-Log` | Skriver ett meddelande med tidsstämpel till skärmen och loggfilen |
| `Read-Config` | Läser `config.json` och gör om den till ett objekt |
| `New-Backup` | Packar källmappen till en zip-fil med datum och tid i namnet |
| `Remove-OldBackups` | Tar bort de äldsta backuperna med en `foreach`-loop |
| `Test-Backup` | Packar upp backupen tillfälligt och jämför antal filer |

### Så kör man projektet

Kräver Terraform och PowerShell. Kör i projektmappen:

```powershell
terraform init
terraform apply -auto-approve
.\backup.ps1
```

Ändra ett värde utan att röra koden:

```powershell
terraform apply -auto-approve -var="max_backups=5"
```

## Resultat

Terraform skapar sex resurser och visar en sammanfattning:

```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

summary = "Projekt 'backup-projekt': data/ säkerhetskopieras till backups/, max 3 backuper sparas"
```

Körs `terraform apply` en gång till ändras ingenting, eftersom allt redan stämmer
med koden:

```
No changes. Your infrastructure matches the configuration.
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

Skriptet tar en backup och verifierar den:

```
[2026-11-10 14:26:26] [INFO] Startar backup för projektet backup-projekt
[2026-11-10 14:26:26] [INFO] Backup skapad: C:\Users\adamh\Documents\backup-automation\backup-automation\backups\backup-projekt-20261110-142626.zip
[2026-11-10 14:26:26] [INFO] Inga gamla backuper att ta bort (1 av max 3)
[2026-11-10 14:26:26] [INFO] Verifiering OK: 3 av 3 filer finns i backupen
[2026-11-10 14:26:26] [INFO] Klart. 0 gamla backuper togs bort.
```

När det finns fler än tre backuper tar skriptet bort den äldsta och loggar
raden `Tog bort gammal backup` med filens namn.

Om `config.json` saknas stoppar felhanteringen skriptet med ett tydligt meddelande:

```
[2026-11-10 14:26:44] [ERROR] Något gick fel: Hittar inte .\finns-inte.json. Kör 'terraform apply' först.
```

## Reflektion

Själva kodningen gick bra. Jag har programmerat i andra språk tidigare, så
funktioner, loopar och villkor i PowerShell kändes bekanta även om syntaxen
var ny.

Det svåraste var att hantera sökvägar. På en dator med många filer vill man
inte skriva in långa sökvägar för hand i koden. Jag löste det genom att lägga
mapparna som variabler i Terraform, så att de hamnar i config.json och skriptet
bygger sökvägen utifrån mappen där det självt ligger. Jag fick också felsöka
att Terraform inte hittades i terminalen, vilket berodde på att PATH inte hade
uppdaterats efter installationen.

Jag lärde mig att Terraform och PowerShell inte pratar direkt med varandra,
utan samverkar genom en gemensam fil. Terraform skriver config.json och
PowerShell läser den. Därför spelar ordningen roll: körs skriptet innan
terraform apply saknas filen och skriptet stannar med ett felmeddelande.

Med mer tid skulle jag bygga ett gränssnitt där man kan välja vilka mappar som
ska säkerhetskopieras, se status och synka backupen till en annan plats.