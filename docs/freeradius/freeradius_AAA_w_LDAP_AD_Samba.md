# Comprehensive Guide to Setting Up FreeRADIUS with LDAP/AD/Samba and NAS Devices

# Introduction
This guide provides steps to configure FreeRADIUS for user authentication via LDAP/AD/Samba and to interact with different Network Access Servers (NAS) like MikroTik and Juniper.

# Prerequisites
- A working FreeRADIUS installation
# Certs
- Download Cambium certificates from Cambium Networks and place the contents in the respective directories: https://support.cambiumnetworks.com/file/c73b92e64bbea7239e19f59c4e29dff361d2cf6a
#
  private key password = /etc/freeradius/certs/serverpassword.txt \
  private key = /etc/freeradius/certs/aaasvr_key.pem \
  certificate file = /etc/freeradius/certs/aaasvr_cert.pem \
  ca file = /etc/freeradius/certs/cacert_aaasvr.pem
# Dictionary
- Download dictionary.canopy file and place the file in the respective directories: https://support.cambiumnetworks.com/file/0cf0506f9b5dbe327c5786fc4dc84402524b8b79
 # 
``` bash
cp dictionary.canopy /usr/share/freeradius/dictionary.canopy
``` 
``` bash
vi /usr/share/freeradius/dictionary
```
and add a reference to dictionary.canopy file 
``` bash
$INCLUDE dictionary.canopy
```
# AD/Samba Integration
``` bash
vi /etc/samba/smb.conf
```
``` bash
[global]
   workgroup = WORKGROUP
   security = ads
   realm = REALM.LOCAL
   server string = %h server (Samba, Ubuntu)
;   interfaces = 127.0.0.0/8 eth0
;   bind interfaces only = yes
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   panic action = /usr/share/samba/panic-action %d
   server role = member server
   obey pam restrictions = yes
   unix password sync = no
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = no
   map to guest = bad user
;   logon path = \\%N\profiles\%U
;   logon drive = H:
;   logon script = logon.cmd
; add user script = /usr/sbin/adduser --quiet --disabled-password --gecos "" %u
; add machine script  = /usr/sbin/useradd -g machines -c "%u machine account" -d /var/lib/samba -s /bin/false %u
; add group script = /usr/sbin/addgroup --force-badname %g
;   include = /home/samba/etc/smb.conf.%m
   idmap config * :              backend = tdb
   idmap config * :              range   = 3000-7999
   idmap config WORKGROUP : backend = rid
   idmap config WORKGROUP : range   = 100000-999999
   template shell = /bin/bash
   usershare allow guests = yes
   winbind refresh tickets = Yes
   winbind use default domain = yes
   winbind enum users = yes
   winbind enum groups = yes
   winbind nested groups = yes
```
# LDAP
``` bash
vi /etc/freeradius/mods-enabled/ldap 
```
``` bash
ldap {
        server = '192.168.10.78'
        port = 3268
        identity = 'user@domain.local'
        password = XXXXXXXXX
        base_dn = 'dc=domain,dc=local'
        sasl {
        }
        update {
                control:Password-With-Header    += 'userPassword'
                control:NT-Password             := 'ntPassword'
                control:                        += 'radiusControlAttribute'
                request:                        += 'radiusRequestAttribute'
                reply:                          += 'radiusReplyAttribute'
        }
        user_dn = "LDAP-UserDn"
        user {
                base_dn = "${..base_dn}"
                filter = "(sAMAccountName=%{%{Stripped-User-Name}:-%{User-Name}})"
                sasl {
                }
        }
        group {
                base_dn = "${..base_dn}"
                filter = '(objectClass=Group)'
                membership_attribute = 'memberOf'
        }
        profile {
        }
        client {
                base_dn = "${..base_dn}"
                filter = '(objectClass=radiusClient)'
                template {
                }
                attribute {
                        ipaddr                          = 'radiusClientIdentifier'
                        secret                          = 'radiusClientSecret'
                }
        }
        accounting {
                reference = "%{tolower:type.%{Acct-Status-Type}}"
                type {
                        start {
                                update {
                                        description := "Online at %S"
                                }
                        }
                        interim-update {
                                update {
                                        description := "Last seen at %S"
                                }
                        }
                        stop {
                                update {
                                        description := "Offline at %S"
                                }
                        }
                }
        }
        post-auth {
                update {
                        description := "Authenticated at %S"
                }
        }
        options {
                chase_referrals = yes
                rebind = yes
                res_timeout = 10
                srv_timelimit = 3
                net_timeout = 1
                idle = 60
                probes = 3
                interval = 3
                ldap_debug = 0x0028
        }
        tls {
        }
        pool {
                start = ${thread[pool].start_servers}
                min = ${thread[pool].min_spare_servers}
                max = ${thread[pool].max_servers}
                spare = ${thread[pool].max_spare_servers}
                uses = 0
                retry_delay = 30
                lifetime = 0
                idle_timeout = 60
        }
}
  
```
# MSCHAP
``` bash
vi /etc/freeradius/mods-enabled/mschap
```
``` bash
mschap {
        use_mppe = yes
        require_encryption = yes
        require_strong = yes
        ntlm_auth = "/usr/bin/ntlm_auth --request-nt-key --allow-mschapv2 --username=%{%{Stripped-User-Name}:-%{%{User-Name}:-None}} --challenge=%{%{mschap:Challenge}:-00} --nt-response=%{%{mschap:NT-Response}:-00}"
        pool {
                start = ${thread[pool].start_servers}
                min = ${thread[pool].min_spare_servers}
                max = ${thread[pool].max_servers}
                spare = ${thread[pool].max_spare_servers}
                uses = 0
                retry_delay = 30
                lifetime = 86400
                cleanup_interval = 300
                idle_timeout = 600
        }
        passchange {
        }
}
```
# EAP
``` bash
vi /etc/freeradius/mods-enabled/eap
```
``` bash
eap {
        default_eap_type = peap
        timer_expire = 60
        ignore_unknown_eap_types = no
        cisco_accounting_username_bug = no
        max_sessions = ${max_requests}
        md5 {
        }
        gtc {
                auth_type = PAP
        }
        tls-config tls-common {
                private_key_password = password
                private_key_file = /etc/freeradius/certs/aaasvr_key.pem
                certificate_file = /etc/freeradius/certs/aaasvr_cert.pem
                ca_file = /etc/freeradius/certs/cacert_aaasvr.pem
                ca_path = ${cadir}
                cipher_list = "DEFAULT"
                cipher_server_preference = no
                tls_min_version = "1.0"
                tls_max_version = "1.3"
                ecdh_curve = ""
                cache {
                        enable = yes
                        lifetime = 24 
                        name = "EAP module"
                        persist_dir = "${logdir}/tlscache"
                        store {
                                Tunnel-Private-Group-Id
                        }
                }
                verify {
                }
                ocsp {
                        enable = no
                        override_cert_url = yes
                        url = "http://127.0.0.1/ocsp/"
                }
        }
        tls {
                tls = tls-common
        }
        ttls {
                tls = tls-common
                default_eap_type = mschapv2
                copy_request_to_tunnel = yes
                use_tunneled_reply = yes
                virtual_server = "inner-tunnel"
        }
        peap {
                tls = tls-common
                default_eap_type = mschapv2
                copy_request_to_tunnel = yes
                use_tunneled_reply = yes
                virtual_server = "inner-tunnel"
        }
        mschapv2 {
        }
}
```
# Clients
``` bash
vi /etc/freeradius/clients.conf
```
``` bash
client 192.168.1.0/24 {
  ipaddr = 192.168.1.0/24
  secret = secret1
  nastype = cambium #cambium,mikrotik,juniper only one
}
```
# sites-enabled default
``` bash
vi /etc/freeradius/sites-enabled/default 
```
``` bash
server default {
listen {
        type = auth+acct
        ipaddr = *
        port = 0
#       interface = eth0
#       clients = per_socket_clients
        recv_buff = 65536
        limit {
              max_connections = 16
              lifetime = 0
              idle_timeout = 30
        }
}
authorize {
#       filter_username
#       filter_password
        preprocess
#       operator-name
#       cui
        auth_log
#       chap
        mschap
#       digest
#       rewrite_called_station_id
#       dpsk
#       wimax
#       suffix
#       ntdomain
#       unix
#       files
#       -sql
#       smbpasswd
        Autz-Type New-TLS-Connection {
                  ok
        }
        ldap {
        }
        expiration
        logintime
#       pap

        #
        if (LDAP-Group == 'LDAPGROUP_Admin') {
            if ("%{client:nas_type}" == "cambium") {
                update reply {
                   &reply:Cambium-Canopy-UserLevel := '3',
                   &reply:Cambium-Canopy-UserMode := '0'
                }
            }
            if ("%{client:nas_type}" == "mikrotik") {
                update reply {
                   &reply:Mikrotik-Group := full
                }
            }
            if ("%{client:nas_type}" == "juniper") {
                update reply {
                    &reply:Juniper-Local-User-Name := "SU"
                }
            }
            ok
        }
        elsif (LDAP-Group == 'LDAP_Helpdesk') {
            if ("%{client:nas_type}" == "cambium") {
                update reply {
                    &reply:Cambium-Canopy-UserLevel := '1',
                    &reply:Cambium-Canopy-UserMode := '1'
                }
            }
            if ("%{client:nas_type}" == "mikrotik") {
                update reply {
                    &reply:Mikrotik-Group := read
                }
            }
            if ("%{client:nas_type}" == "juniper") {
                update reply {
                    &reply:Juniper-Local-User-Name := "RO"
                }
            }
            ok
        }
        else {
            reject
        }
        eap {
                ok = return
                updated = return
        }

}
authenticate {
#       Auth-Type PAP {
#               pap
#       }
#       Auth-Type CHAP {
#               chap
#       }
        Auth-Type MS-CHAP {
                mschap
        }
        mschap
#       digest
        eap
}
preacct {
        preprocess
        acct_unique
        suffix
        files
}
accounting {
        detail
        unix
#        -sql
        exec
        attr_filter.accounting_response
}
session {
}
post-auth {
        if (session-state:User-Name && reply:User-Name && request:User-Name && (reply:User-Name == request:User-Name)) {
                update reply {
                        &User-Name !* ANY
                }
        }
        update {
                &reply: += &session-state:
        }
#        -sql
        exec
        #remove_reply_message_if_eap
        Post-Auth-Type REJECT {
#                -sql
                attr_filter.access_reject
                eap
                remove_reply_message_if_eap
        }
        Post-Auth-Type Challenge {
        }
        Post-Auth-Type Client-Lost {
        }
        if (EAP-Key-Name && &reply:EAP-Session-Id) {
                update reply {
                        &EAP-Key-Name := &reply:EAP-Session-Id
                }
        }
}
pre-proxy {
}
post-proxy {
        eap
}
}

```
