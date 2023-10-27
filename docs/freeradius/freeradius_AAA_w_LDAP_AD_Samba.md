# Comprehensive Guide to Setting Up FreeRADIUS with LDAP/AD/Samba and NAS Devices

# Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [LDAP/AD/Samba Integration](#ldapadsamba-integration)
- [Configuring clients.conf](#configuring-clientsconf)
- [Configuring sites-enabled/default](#configuring-sites-enabledefault)
- [Verification Commands](#verification-commands)
- [Troubleshooting](#troubleshooting)
- [Conclusion](#conclusion)

# Introduction
This guide provides steps to configure FreeRADIUS for user authentication via LDAP/AD/Samba and to interact with different Network Access Servers (NAS) like MikroTik and Juniper.

# Prerequisites
- A working FreeRADIUS installation
- Access to LDAP/AD/Samba server
- NAS devices (MikroTik, Juniper, etc.)

# Installation
Install FreeRADIUS and its LDAP modules...
``` bash
sudo apt-get install freeradius freeradius-ldap
```
# LDAP/AD/Samba Integration
Edit the /etc/freeradius/3.0/mods-enabled/ldap file and configure the LDAP settings...
``` bash
ldap {
  server = "ldap://your-ldap-server"
  identity = "cn=admin,dc=example,dc=com"
  password = your_password
  ...
}
```
# Configuring "clients.conf"
Add your NAS devices in /etc/freeradius/3.0/clients.conf...
``` bash
client 192.168.1.0/24 {
  ipaddr = 192.168.1.1
  secret = secret1
  shortname = mikrotik
  nastype = other
}
```
# Configuring "sites-enabled/default"
Edit /etc/freeradius/3.0/sites-enabled/default to include logic based on LDAP groups and NAS types...
``` bash
server default {
    listen {
        type = auth
        ipaddr = *
        port = 0
    }
    listen {
        ipaddr = *
        port = 0
        type = acct
    }
    authorize {
        preprocess
        chap
        mschap
        digest
        eap {
            ok = return
        }
        # LDAP Module for AD integration
        ldap
        
        if (LDAP-Group == 'RW_Admin') {
            update reply {
                Service-Type = Administrative-User,
        Mikrotik-Group := "full",
        Reply-Message := "Adtran-RW",
        Reply-Message := "Sudo-Allowed",
        Juniper-Local-User-Name := "j-admin"
            }
        }
        elsif (LDAP-Group == 'RO_Helpdesk') {
            update reply {
                Service-Type = NAS-Prompt-User,
        Mikrotik-Group := "read",
        Reply-Message := "Adtran-RO",
        Reply-Message := "Sudo-Not-Allowed",
        Juniper-Local-User-Name := "j-read"
            }
        }
        else {
            # Reject the request
            reject
        }
        
        if (NAS-Identifier == 'mikrotik') {
            update reply {
                Mikrotik-Group := "read"
            }
        }
        elsif (NAS-Identifier == 'adtran') {
            update reply {
                Reply-Message := "Adtran-RO"
            }
        }
        elsif (NAS-Identifier == 'juniper') {
            update reply {
                Juniper-Local-User-Name := "j-read"
            }
        }
        elsif (NAS-Identifier == 'linux_server') {
            update reply {
                Reply-Message := "Sudo-Not-Allowed"
            }
        }
    }
    authenticate {
        pap
        chap
        mschap
        # LDAP for authentication
        ldap
    }
}
```
# Verification Commands
#MikroTik
Use MikroTik-specific commands to verify RW or RO access.
##Juniper
RW: configure followed by set system login message "Test RW access" and rollback.
RO: show system uptime.

# Troubleshooting

# Conclusion
This guide provides a comprehensive overview of setting up FreeRADIUS with LDAP/AD/Samba integration and NAS devices...

