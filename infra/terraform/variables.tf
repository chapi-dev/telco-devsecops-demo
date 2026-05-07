variable "location" {
  description = "Azure region for the demo."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group that holds AKS, ACR and the managed identity."
  type        = string
  default     = "rg-telco-demo"
}

variable "acr_name" {
  description = "Globally-unique ACR name (5-50 lowercase alphanumeric)."
  type        = string
  default     = "acrtelcodemo"
}

variable "aks_name" {
  description = "AKS cluster name."
  type        = string
  default     = "aks-telco-demo"
}

variable "aks_node_count" {
  description = "Initial node count in the system pool."
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for the system pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "managed_identity_name" {
  description = "User-assigned managed identity used by GitHub Actions via OIDC."
  type        = string
  default     = "mi-github-oidc"
}

variable "github_owner" {
  description = "GitHub user/org that owns the demo repo."
  type        = string
  default     = "chapi-dev"
}

variable "github_repo" {
  description = "GitHub repo name."
  type        = string
  default     = "telco-devsecops-demo"
}

variable "github_branch" {
  description = "Branch authorised to mint OIDC tokens to Azure."
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    project     = "telco-devsecops-demo"
    environment = "demo"
    owner       = "chapi-dev"
  }
}
