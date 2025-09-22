Here's a comprehensive list of VPS management commands for Ubuntu:
SSH INTO VPS
# ssh root@148.230.94.85


System Updates & Upgrades
# Update package lists
apt update
systemctl status prometheus
systemctl status grafana-server
lsof -i :9090
fuser -k 9090/tcp

# Upgrade installed packages
apt upgrade

# Full system upgrade (handles dependencies)
apt full-upgrade

# Distribution upgrade
apt dist-upgrade

# Auto-remove unused packages
apt autoremove

# Clean package cache
apt autoclean
apt clean

# List upgradable packages
apt list --upgradable

# Check security updates
unattended-upgrades --dry-run


Copy

Insert at cursor
bash
System Information
# System info
uname -a
lsb_release -a
hostnamectl

# Resource usage
htop
top
free -h
df -h
lsof

# Network info
ip addr show
netstat -tulpn
ss -tulpn

Copy

Insert at cursor
bash
Package Management
# Search packages
apt search <package>

# Install packages
apt install <package>

# Remove packages
apt remove <package>
apt purge <package>

# Show package info
apt show <package>
apt policy <package>

Copy

Insert at cursor
bash
Security & Monitoring
# Check running services
systemctl status
systemctl list-units --type=service

# Firewall status
ufw status
iptables -L

# Check logs
journalctl -f
tail -f /var/log/syslog
tail -f /var/log/auth.log

# Process monitoring
ps aux
pstree

Copy

Insert at cursor
bash
Essential VPS Setup Commands
# Enable automatic security updates
dpkg-reconfigure -plow unattended-upgrades

# Update timezone
timedatectl set-timezone UTC

# Configure firewall
ufw enable
ufw allow ssh
ufw allow 80
ufw allow 443

# Check disk usage
ncdu /

Copy

Insert at cursor
bash
Quick VPS maintenance routine:

apt update && apt upgrade -y && apt autoremove -y && apt autoclean

Copy

Insert at cursor
bash
Now you can SSH to your VPS without the host key error!