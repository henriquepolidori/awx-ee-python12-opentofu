terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Recurso simples que não exige credenciais de nuvem.
# Serve apenas para validar o fluxo AWX -> EE -> OpenTofu ponta a ponta.
resource "local_file" "hello" {
  filename = "${path.module}/output/hello.txt"
  content  = <<-EOT
    Hello from OpenTofu!
    Ambiente: ${var.environment}
    Gerado via AWX Job Template.
  EOT
}
