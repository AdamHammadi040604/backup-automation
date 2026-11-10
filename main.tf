# main.tf - Backup-automation
# Terraform skapar strukturen som PowerShell-skriptet sedan arbetar med.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Resource 1: konfigurationsfilen som backup.ps1 läser
resource "local_file" "config" {
  filename = "${path.module}/config.json"
  content = jsonencode({
    project_name = var.project_name
    source_dir   = var.source_dir
    backup_dir   = var.backup_dir
    log_dir      = var.log_dir
    max_backups  = var.max_backups
  })
}

# Resource 2: testfiler i källmappen (en fil per namn i listan)
resource "local_file" "testdata" {
  for_each = toset(var.test_files)

  filename = "${path.module}/${var.source_dir}/${each.value}"
  content  = "Testfil ${each.value} i projektet ${var.project_name}\n"
}

# Resource 3: backup-mappen (.keep gör att mappen skapas fast den är tom)
resource "local_file" "backup_keep" {
  filename = "${path.module}/${var.backup_dir}/.keep"
  content  = ""
}

# Resource 4: logg-mappen
resource "local_file" "log_keep" {
  filename = "${path.module}/${var.log_dir}/.keep"
  content  = ""
}
