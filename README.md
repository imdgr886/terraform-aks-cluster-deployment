An Out of Box Terraform Template
---

This template will create a AKS cluster with Application Gateway, Postgresql and Public IP. And can deploy your project with a k8s manifest file, just fill content by yourself.  
  
The db connection params will be saved in secret pod named `app-config`

# What will this template do?   

- Resource Group  
- VNet  
- Subnet  
- AKS  
- Application Gateway Ingress Controller (AGIC)  
- Public IP   
- Postgsql (flexible db)  
- Container Insight  
- Log Analytics  
etc.  

# Quick Start

- Install azure-cli  
- Azure-cli login  
- Create .env file even if you don't need  
- Run `terraform init` 
- Run `terraform plan` and `terraform apply`  
