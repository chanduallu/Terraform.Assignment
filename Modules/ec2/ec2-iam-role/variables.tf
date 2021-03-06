variable "name" {
  description = "The name of the IAM Role."
}

variable "assume_role_policy" {
  description = "Assume Role Policy."
  default     = ""
}

variable "force_detach_policies" {
  description = "Forcibly detach the policy of the role."
  default     = false
}

variable "path" {
  description = "The path to the IAM Role."
  default     = "/"
}

variable "description" {
  description = "The description of the IAM Role."
  default     = "This IAM Role generated by Terraform."
}

variable "policy_arn" {
  description = "Attache the policies to the IAM Role."
  type        = list(string)
}

