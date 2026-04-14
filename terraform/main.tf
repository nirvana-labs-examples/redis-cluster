terraform {
  required_providers {
    nirvana = {
      source = "nirvana-labs/nirvana"
    }
  }
}

provider "nirvana" {}

# VPC for Redis Cluster
resource "nirvana_networking_vpc" "redis" {
  name        = var.vpc_name
  region      = var.region
  project_id  = var.project_id
  subnet_name = var.subnet_name
  tags        = var.tags
}

# Firewall rule - SSH access
resource "nirvana_networking_firewall_rule" "redis_ssh" {
  vpc_id              = nirvana_networking_vpc.redis.id
  name                = "redis-ssh"
  protocol            = "tcp"
  source_address      = var.ssh_allowed_cidr
  destination_address = nirvana_networking_vpc.redis.subnet.cidr
  destination_ports   = ["22"]
  tags                = var.tags
}

# Firewall rule - Redis access
resource "nirvana_networking_firewall_rule" "redis_db" {
  vpc_id              = nirvana_networking_vpc.redis.id
  name                = "redis-db"
  protocol            = "tcp"
  source_address      = var.redis_allowed_cidr
  destination_address = nirvana_networking_vpc.redis.subnet.cidr
  destination_ports   = [tostring(var.redis_port)]
  tags                = var.tags
}

# Firewall rule - Sentinel access
resource "nirvana_networking_firewall_rule" "redis_sentinel" {
  vpc_id              = nirvana_networking_vpc.redis.id
  name                = "redis-sentinel"
  protocol            = "tcp"
  source_address      = var.redis_allowed_cidr
  destination_address = nirvana_networking_vpc.redis.subnet.cidr
  destination_ports   = [tostring(var.sentinel_port)]
  tags                = var.tags
}

# Firewall rule - Redis cluster bus (internal communication)
resource "nirvana_networking_firewall_rule" "redis_cluster_bus" {
  vpc_id              = nirvana_networking_vpc.redis.id
  name                = "redis-cluster-bus"
  protocol            = "tcp"
  source_address      = nirvana_networking_vpc.redis.subnet.cidr
  destination_address = nirvana_networking_vpc.redis.subnet.cidr
  destination_ports   = ["16379"]
  tags                = var.tags
}

# Redis Cluster VMs
resource "nirvana_compute_vm" "redis" {
  count = var.node_count

  name              = "${var.vm_name}-${count.index + 1}"
  project_id        = var.project_id
  region            = var.region
  os_image_name     = var.os_image
  public_ip_enabled = var.public_ip_enabled
  subnet_id         = nirvana_networking_vpc.redis.subnet.id

  cpu_config = {
    vcpu = var.vcpu
  }

  memory_config = {
    size = var.memory_gb
  }

  boot_volume = {
    size = var.boot_volume_gb
    type = "abs"
    tags = var.tags
  }

  ssh_key = {
    public_key = var.ssh_public_key
  }

  tags = var.tags
}
