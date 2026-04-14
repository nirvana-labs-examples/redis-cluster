output "vm_ids" {
  description = "Redis VM IDs"
  value       = nirvana_compute_vm.redis[*].id
}

output "vm_public_ips" {
  description = "Redis VM public IPs"
  value       = nirvana_compute_vm.redis[*].public_ip
}

output "vm_private_ips" {
  description = "Redis VM private IPs"
  value       = nirvana_compute_vm.redis[*].private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = nirvana_networking_vpc.redis.id
}

output "node_count" {
  description = "Number of Redis nodes"
  value       = var.node_count
}

output "redis_port" {
  description = "Redis port"
  value       = var.redis_port
}

output "sentinel_port" {
  description = "Sentinel port"
  value       = var.sentinel_port
}

output "master_node" {
  description = "Initial master node (first node)"
  value = {
    name       = "${var.vm_name}-1"
    public_ip  = nirvana_compute_vm.redis[0].public_ip
    private_ip = nirvana_compute_vm.redis[0].private_ip
  }
}
