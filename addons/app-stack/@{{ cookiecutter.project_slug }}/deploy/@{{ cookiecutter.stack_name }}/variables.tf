variable "environment" {
  description = "Value of the environment tag"
  type        = string
}

variable "github_org" {
  description = "Name of the GitHub organization"
  type        = string
  default     = "@{{ cookiecutter.github_org }}"
}

variable "github_repo" {
  description = "Name of the GitHub repository"
  type        = string
  default     = "@{{ cookiecutter.github_repo }}"
}
