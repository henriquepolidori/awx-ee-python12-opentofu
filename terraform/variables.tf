variable "environment_name" {
  description = "Nome do ambiente sendo provisionado (ex: dev, hml, prod). NAO use 'environment' - e palavra reservada no Ansible."
  type        = string
  default     = "dev"
}
