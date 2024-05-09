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
## References
- [MariaDB Download Page](https://mariadb.org/download/)
- ![MariaDB Version](https://img.shields.io/github/v/tag/mariadb/server?label=version&style=social)
- [MariaDB GitHub Repository](https://github.com/MariaDB/server)
- ![Last commit](https://img.shields.io/github/last-commit/MariaDB/server?style=social)

