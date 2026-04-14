<div align="center">
  <a href="https://nirvanalabs.io">
    <img src="https://nirvanalabs.io/brand-kit/logo/nirvana-logo-color-black-text.svg" alt="Nirvana Labs" width="320" />
  </a>

  [Sign Up](https://nirvanalabs.io/sign-up) · [Docs](https://docs.nirvanalabs.io) · [API](https://docs.nirvanalabs.io/api) · [Examples](https://github.com/nirvana-labs-examples) · [Terraform](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest) · [TypeScript SDK](https://www.npmjs.com/package/@nirvana-labs/nirvana) · [Go SDK](https://github.com/Nirvana-Labs/nirvana-go) · [CLI](https://github.com/nirvana-labs/nirvana-cli) · [MCP](https://www.npmjs.com/package/@nirvana-labs/nirvana-mcp)
</div>

---

# Redis Cluster on Nirvana Labs

Deploy a high-availability Redis cluster with Sentinel failover on Nirvana Labs cloud infrastructure.

## Features

- Multi-node Redis cluster (1 master + N replicas)
- Redis Sentinel for automatic failover
- Password authentication
- Optimized memory and persistence settings
- Automatic master election on failure
- AOF and RDB persistence enabled

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        VPC                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   redis-1   │  │   redis-2   │  │   redis-3   │     │
│  │   (master)  │  │  (replica)  │  │  (replica)  │     │
│  │             │  │             │  │             │     │
│  │  Redis:6379 │  │  Redis:6379 │  │  Redis:6379 │     │
│  │  Sentinel:  │  │  Sentinel:  │  │  Sentinel:  │     │
│  │    26379    │  │    26379    │  │    26379    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│         │                │                │            │
│         └────────────────┼────────────────┘            │
│                          │                             │
│                   Sentinel Quorum                      │
│               (automatic failover)                     │
└─────────────────────────────────────────────────────────┘
```

## Structure

```
.
├── terraform/          # Infrastructure provisioning
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/            # Redis + Sentinel installation
│   ├── playbook.yml
│   ├── ansible.cfg
│   ├── inventory.ini.example
│   └── templates/
│       ├── redis-master.conf.j2
│       ├── redis-replica.conf.j2
│       └── sentinel.conf.j2
├── scripts/
│   └── generate-inventory.sh
└── README.md
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.9 (for automated method)
- Nirvana Labs account and API key
- SSH key pair

## Resources Created

| Resource | Specification |
|----------|---------------|
| VPC | With subnet in us-sva-2 |
| Firewall | Ports 22, 6379, 26379, 16379 |
| VMs | 3x (2 vCPU, 4 GB RAM, 64 GB SSD) |

## Quick Start

### 1. Provision Infrastructure

```bash
cd terraform

export NIRVANA_LABS_API_KEY="your-api-key"

terraform init
terraform plan -var='ssh_public_key=ssh-ed25519 AAAA...' -var='project_id=your-project-id'
terraform apply -var='ssh_public_key=ssh-ed25519 AAAA...' -var='project_id=your-project-id'
```

Note the `vm_public_ips` output.

---

### 2. Install Redis Cluster

Choose one of the following methods:

---

#### Option A: Automated (Ansible)

```bash
# Generate inventory from terraform output
cd ..
./scripts/generate-inventory.sh

# Run playbook
cd ansible
ansible-playbook playbook.yml
```

The playbook will:
- Install Redis on all nodes
- Configure master and replicas
- Set up Sentinel on all nodes
- Display connection credentials

---

#### Option B: Manual Installation

SSH into each VM and install Redis:

```bash
ssh ubuntu@<vm_ip>

# Add Redis repository
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# Install Redis
sudo apt update
sudo apt install -y redis-server
```

**On Master (first node):**

```bash
sudo tee /etc/redis/redis.conf << EOF
bind 0.0.0.0
port 6379
requirepass YOUR_PASSWORD
masterauth YOUR_PASSWORD
appendonly yes
EOF

sudo systemctl restart redis-server
```

**On Replicas:**

```bash
sudo tee /etc/redis/redis.conf << EOF
bind 0.0.0.0
port 6379
requirepass YOUR_PASSWORD
masterauth YOUR_PASSWORD
replicaof MASTER_IP 6379
appendonly yes
EOF

sudo systemctl restart redis-server
```

**Sentinel on all nodes:**

```bash
sudo tee /etc/redis/sentinel.conf << EOF
port 26379
sentinel monitor mymaster MASTER_IP 6379 2
sentinel auth-pass mymaster YOUR_PASSWORD
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
EOF

sudo redis-sentinel /etc/redis/sentinel.conf
```

---

### 3. Connect to Redis

Connect to master:

```bash
redis-cli -h <master_ip> -p 6379 -a <password>
```

Get current master from Sentinel:

```bash
redis-cli -h <any_node_ip> -p 26379 SENTINEL get-master-addr-by-name mymaster
```

Check replication status:

```bash
redis-cli -h <master_ip> -p 6379 -a <password> INFO replication
```

## Terraform Variables

| Name | Description | Default |
|------|-------------|---------|
| `project_id` | Nirvana Labs project ID | - |
| `region` | Deployment region | `us-sva-2` |
| `vm_name` | VM name prefix | `redis` |
| `node_count` | Number of Redis nodes (min 3) | `3` |
| `vcpu` | vCPUs per node | `2` |
| `memory_gb` | Memory per node in GB | `4` |
| `boot_volume_gb` | Boot volume in GB (min 64) | `64` |
| `ssh_public_key` | SSH public key | - |
| `redis_port` | Redis port | `6379` |
| `sentinel_port` | Sentinel port | `26379` |
| `redis_allowed_cidr` | CIDR for Redis access | `0.0.0.0/0` |

## Outputs

| Name | Description |
|------|-------------|
| `vm_ids` | Redis VM IDs |
| `vm_public_ips` | Redis VM public IPs |
| `vm_private_ips` | Redis VM private IPs |
| `vpc_id` | VPC ID |
| `node_count` | Number of nodes |
| `master_node` | Initial master node info |

## Sentinel Failover

Sentinel automatically handles failover:

1. **Detection**: Sentinels monitor the master
2. **Agreement**: Quorum (2 of 3) must agree master is down
3. **Election**: Sentinels elect a new master from replicas
4. **Promotion**: Selected replica becomes new master
5. **Reconfiguration**: Other replicas point to new master

Test failover manually:

```bash
# Force failover
redis-cli -h <sentinel_ip> -p 26379 SENTINEL failover mymaster

# Check new master
redis-cli -h <sentinel_ip> -p 26379 SENTINEL get-master-addr-by-name mymaster
```

## Redis Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxmemory` | 70% of RAM | Maximum memory usage |
| `maxmemory-policy` | `volatile-lru` | Eviction policy |
| `appendonly` | `yes` | AOF persistence |
| `appendfsync` | `everysec` | AOF sync frequency |

## Customizing Configuration

Override Ansible variables:

```bash
ansible-playbook playbook.yml \
  -e "redis_maxmemory_policy=allkeys-lru" \
  -e "sentinel_quorum=2" \
  -e "sentinel_down_after=10000"
```

## Security Recommendations

1. **Restrict access**: Set `redis_allowed_cidr` to your app's IP range
2. **Use strong passwords**: Auto-generated 24-char password
3. **Enable TLS**: For production, configure Redis TLS
4. **Firewall**: Only open required ports

## Monitoring

Check cluster health:

```bash
# Replication info
redis-cli -h <master_ip> -p 6379 -a <password> INFO replication

# Sentinel status
redis-cli -h <any_ip> -p 26379 SENTINEL masters
redis-cli -h <any_ip> -p 26379 SENTINEL replicas mymaster
```

## Clean Up

```bash
cd terraform
terraform destroy -var='ssh_public_key=...' -var='project_id=...'
```
