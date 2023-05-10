
provider "kubernetes" {
  host                   = module.aks.host
  username               = module.aks.username
  password               = module.aks.password
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)

}

provider "kubectl" {
  load_config_file       = false
  host                   = module.aks.host
  username               = module.aks.username
  password               = module.aks.password
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)


}

resource "random_password" "app_key" {
  length = 16
}

data "dotenv" "production" {
  filename = ".env"
}
resource "kubernetes_secret" "app" {
  metadata {
    name = "app-config"
  }
  data = merge(data.dotenv.production.env, {
    APP_KEY       = random_password.app_key.result
    DB_CONNECTION = "postgresql://${azurerm_postgresql_flexible_server.postgresql_server.administrator_login}:${azurerm_postgresql_flexible_server.postgresql_server.administrator_password}@${azurerm_postgresql_flexible_server.postgresql_server.fqdn}:5432/${var.db_name}?sslmode=require"
  })

  depends_on = [
    module.aks
  ]

}

data "kubectl_file_documents" "docs" {
  content = file("deployment.yml")
}

resource "kubectl_manifest" "app" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
  force_new = true
  depends_on = [
    kubernetes_config_map.app,
    module.aks
  ]
}
