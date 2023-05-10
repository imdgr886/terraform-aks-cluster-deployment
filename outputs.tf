output "client_certificate" {
  sensitive = true
  value     = module.aks.client_certificate
}

output "client_key" {
  sensitive = true
  value     = module.aks.client_key
}

output "cluster_ca_certificate" {
  sensitive = true
  value     = module.aks.client_certificate
}

output "kubelet_identity" {
  sensitive = true
  value     = module.aks.kubelet_identity
}

output "kube_config" {
  sensitive = true
  value     = module.aks.kube_config_raw
}

output "cluster_password" {
  sensitive = true
  value     = module.aks.password
}

output "cluster_username" {
  sensitive = true
  value     = module.aks.username
}

output "public_ip" {
  value = data.azurerm_public_ip.pip.ip_address
}
