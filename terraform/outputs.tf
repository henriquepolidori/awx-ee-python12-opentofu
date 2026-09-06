output "file_path" {
  description = "Caminho do arquivo gerado pelo OpenTofu"
  value       = local_file.hello.filename
}

output "content" {
  description = "Conteúdo gravado no arquivo"
  value       = local_file.hello.content
}
