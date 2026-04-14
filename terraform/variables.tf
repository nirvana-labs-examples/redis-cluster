variable "project_id" {
  description = "Nirvana Labs project ID"
  type        = string
}

variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "us-sva-2"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "redis-vpc"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "redis-subnet"
}

variable "vm_name" {
  description = "VM name prefix"
  type        = string
  default     = "redis"
}

variable "node_count" {
  description = "Number of Redis nodes (minimum 3 for HA)"
  type        = number
  default     = 3
}

variable "vcpu" {
  description = "Number of vCPUs per node"
  type        = number
  default     = 2
}

variable "memory_gb" {
  description = "Memory size in GB per node"
  type        = number
  default     = 4
}

variable "boot_volume_gb" {
  description = "Boot volume size in GB (min 64 for ABS)"
  type        = number
  default     = 64
}

variable "os_image" {
  description = "OS image name"
  type        = string
  default     = "ubuntu-noble-2025-10-01"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "public_ip_enabled" {
  description = "Enable public IP for VMs"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "redis_allowed_cidr" {
  description = "CIDR allowed for Redis access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "sentinel_port" {
  description = "Sentinel port"
  type        = number
  default     = 26379
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["redis", "terraform"]
}
