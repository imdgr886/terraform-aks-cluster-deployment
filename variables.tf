variable "location" {
  default = "eastus"
}

variable "prefix" {
  default = "app"
}

variable "acr_id" {
  description = "The `id` of Azure Container Registry where you store docker images"
  type        = string
}

variable "db_name" {

}
