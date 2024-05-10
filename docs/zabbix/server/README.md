#Zabbix Agent 2

## Install Zabbix repository
```bash
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu24.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu24.04_all.deb
apt update
```
## Install Zabbix server, frontend, agent
```bash
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
```
## Create initial database
```bash
mysql -uroot -p
mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> quit;
```
## IMPORT
 ```bash
 zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```
1. Disable log_bin_trust_function_creators option after importing database schema.
```bash
mysql -uroot -p
password
mysql> set global log_bin_trust_function_creators = 0;
mysql> quit;
```
2. Configure the database for Zabbix server
```bash
vi /etc/zabbix/zabbix_server.conf
```
## Start Zabbix server and agent processes
```bash
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2
```
![Zabbix agent2 activity](https://img.shields.io/github/commit-activity/m/zabbix/zabbix?label=Zabbix%20server%20Activity&style=social)
