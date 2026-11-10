# variables.tf - Värden som går att ändra utan att röra main.tf

variable "project_name" {
  description = "Namn på projektet, används i namnet på backup-filerna"
  type        = string
  default     = "backup-projekt"
}

variable "source_dir" {
  description = "Mappen som ska säkerhetskopieras"
  type        = string
  default     = "data"
}

variable "backup_dir" {
  description = "Mappen där backuperna sparas"
  type        = string
  default     = "backups"
}

variable "log_dir" {
  description = "Mappen där loggfilen sparas"
  type        = string
  default     = "logs"
}

variable "max_backups" {
  description = "Hur många backuper som ska sparas innan de äldsta tas bort"
  type        = number
  default     = 3
}

variable "test_files" {
  description = "Testfiler som skapas i källmappen"
  type        = list(string)
  default     = ["rapport.txt", "kunder.txt", "anteckningar.txt"]
}
