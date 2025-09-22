# 🖥️ VPS Setup Guide - Hostinger Production Deployment

## 🌏 VPS Configuration

**Target VPS Details**:
- **Host**: `148.230.94.85` (Hostinger VPS)
- **IPv6**: `2a02:4780:2d:b8bd::1`
- **SSH User**: `root`
- **SSH Port**: `22`
- **OS**: Ubuntu 22.04 LTS

## 🔐 SSH Key Setup

### 1. Generate SSH Key Pair

```bash
# Generate ed25519 SSH key
ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/hostinger_vps_key -C "github-actions@beaconagilehub"

# Set permissions
chmod 600 ~/.ssh/hostinger_vps_key
chmod 644 ~/.ssh/hostinger_vps_key.pub
```

### 2. Deploy Public Key to VPS

```bash
# Copy public key to VPS
ssh-copy-id -i ~/.ssh/hostinger_vps_key.pub root@148.230.94.85

# Test connection
ssh -i ~/.ssh/hostinger_vps_key root@148.230.94.85 "echo 'SSH successful'"
```

### 3. Configure GitHub Secrets

Add these secrets to your repository:

| Secret Name | Value |
|-------------|-------|
| `VPS_SSH_PRIVATE_KEY` | Contents of `~/.ssh/hostinger_vps_key` |
| `VPS_HOST` | `148.230.94.85` |
| `VPS_USER` | `root` |
| `VPS_PORT` | `22` |

```bash
# Copy private key content for GitHub secret
cat ~/.ssh/hostinger_vps_key | pbcopy  # macOS
cat ~/.ssh/hostinger_vps_key | xclip -selection clipboard  # Linux
```

## 🚀 VPS Environment Setup

### Automated Setup Script

```bash
#!/bin/bash
# vps-setup.sh
set -euo pipefail

echo "🚀 Setting up VPS for DevSecOps deployment..."

# Update system
apt-get update -y && apt-get upgrade -y

# Install essential packages
apt-get install -y curl wget gnupg lsb-release ca-certificates \
    software-properties-common apt-transport-https ufw fail2ban \
    htop vim git jq

# Install Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Configure firewall
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Configure fail2ban
systemctl enable fail2ban
systemctl start fail2ban
tee /etc/fail2ban/jail.d/ssh.conf << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF
systemctl restart fail2ban

# Create application directories
mkdir -p /opt/devsecops-app/{config,logs,data,backups}
chmod 755 /opt/devsecops-app

# Create health check script
tee /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
APP_URL="http://localhost:3000/health"

if curl -f -s "$APP_URL" > /dev/null; then
    echo "✅ Health check passed at $(date)"
else
    echo "❌ Health check failed at $(date)"
    cd /opt/devsecops-app
    docker-compose restart app || echo "Failed to restart application"
fi
EOF
chmod +x /usr/local/bin/health-check.sh

# Setup health check cron (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/health-check.sh >> /var/log/health-check.log 2>&1") | crontab -

echo "🎉 VPS setup completed!"
```

### Execute Setup

```bash
# Copy and run setup script
scp vps-setup.sh root@148.230.94.85:/tmp/
ssh root@148.230.94.85 "chmod +x /tmp/vps-setup.sh && /tmp/vps-setup.sh"
```

## 🐳 Docker Compose Configuration

```yaml
# /opt/devsecops-app/docker-compose.yml
version: '3.8'

services:
  app:
    image: ghcr.io/papaert-cloud/beaconagilehub-security-ci-cdpipelines:production-latest
    container_name: devsecops-app-production
    restart: unless-stopped
    ports:
      - "80:3000"
      - "443:3000"
    environment:
      - NODE_ENV=production
      - DEPLOYMENT_ID=${DEPLOYMENT_ID:-manual}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    volumes:
      - app-data:/app/data
    labels:
      - "com.devsecops.environment=production"
    networks:
      - devsecops-network

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower-production
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 */6 * * *
    networks:
      - devsecops-network

volumes:
  app-data:

networks:
  devsecops-network:
    driver: bridge
```

## 🧪 Testing & Validation

```bash
# Test SSH connection
ssh -i ~/.ssh/hostinger_vps_key root@148.230.94.85 "echo 'Connection test passed'"

# Test Docker
ssh -i ~/.ssh/hostinger_vps_key root@148.230.94.85 "docker --version && docker-compose --version"

# Test application health
curl -f http://148.230.94.85/health || echo "App not yet deployed"
```

## 🔒 Security Checklist

- ✅ SSH key-based authentication only
- ✅ UFW firewall (ports 22, 80, 443 only)
- ✅ Fail2ban protection (3 attempts = 1 hour ban)
- ✅ Automatic health checks (5-minute intervals)
- ✅ Container restart on failure
- ✅ Watchtower automatic updates (6-hour intervals)
- ✅ Minimal attack surface

## 🔧 Troubleshooting

### SSH Issues

```bash
# Debug SSH connection
ssh -vvv -i ~/.ssh/hostinger_vps_key root@148.230.94.85

# Check SSH service
ssh root@148.230.94.85 "systemctl status sshd"
```

### Container Issues

```bash
# Check container status
ssh root@148.230.94.85 "docker ps -a"

# View logs
ssh root@148.230.94.85 "docker logs devsecops-app-production --tail 50"

# Restart application
ssh root@148.230.94.85 "cd /opt/devsecops-app && docker-compose restart"
```

### Health Check Issues

```bash
# Manual health check
ssh root@148.230.94.85 "/usr/local/bin/health-check.sh"

# Check health check logs
ssh root@148.230.94.85 "tail -f /var/log/health-check.log"
```

## 📊 Monitoring

- **Health Checks**: Every 5 minutes via cron
- **Container Updates**: Every 6 hours via Watchtower
- **Security**: Fail2ban monitoring
- **System**: Manual weekly checks recommended

---

> **Ready for secure VPS deployment!** This setup provides production-grade security and automation for your DevSecOps pipeline.