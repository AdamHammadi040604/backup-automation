# outputs.tf - Visar resultatet efter terraform apply

output "config_file" {
  description = "Sökväg till konfigurationsfilen"
  value       = local_file.config.filename
}

output "created_test_files" {
  description = "Testfilerna som skapades"
  value       = [for f in local_file.testdata : f.filename]
}

output "summary" {
  description = "Sammanfattning av vad som skapades"
  value       = "Projekt '${var.project_name}': ${var.source_dir}/ säkerhetskopieras till ${var.backup_dir}/, max ${var.max_backups} backuper sparas"
}
