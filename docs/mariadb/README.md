# MariaDB Installation on Ubuntu

Install MariaDB on Ubuntu 24.

## Installation

```bash
apt install mariadb-server
```
Secure MariaDB installation:
```bash
mysql_secure_installation
```
Start and enable MariaDB service:
```bash
systemctl start mariadb &&
systemctl enable mariadb
```
