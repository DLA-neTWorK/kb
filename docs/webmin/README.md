# Webmin Installation

This guide provides instructions for installing Webmin via apt on Ubuntu 24 using the official repository.

## Installation Steps
```bash
# Download the repository setup script
curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh

# Execute the script to add the Webmin repository
sh setup-repos.sh

# Install Webmin using apt-get
sudo apt-get install webmin --install-recommends
```
## UFW Firewall
```bash
if ! sudo ufw status | grep -q '10000/tcp'; then
  # Add the firewall rule
  sudo ufw allow 10000/tcp
fi
```
## Accessing Webmin
https://fqdn:10000

## References
[Webmin Download Page](https://webmin.com/download/)

[Webmin GitHub Repository](https://github.com/webmin/webmin/)

![Last commit](https://img.shields.io/github/last-commit/webmin/webmin?style=social) 
![Webmin Version](https://img.shields.io/github/v/tag/webmin/webmin?label=version&style=social)

