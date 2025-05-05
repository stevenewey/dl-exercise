variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.31"
}

variable "core_node_count" {
  type        = number
  description = "Number of nodes in the core managed node group"
  default     = 3
}

variable "core_node_ami_type" {
  type        = string
  description = "AMI type (OS + arch) for core managed node group"
  default     = "AL2023_ARM_64_STANDARD"
}

variable "core_node_instance_types" {
  type        = list(string)
  description = "Instance type(s) for core managed node group"
  default     = ["m7g.large"]
}
