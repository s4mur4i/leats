#!/bin/bash
export basedn="dc=example,dc=com"
export password="{SSHA}e0ZCdm9SKnRtSfjE9mWG+yC7IYNqnLVa"
/etc/rc.d/init.d/slapd stop 2>/dev/null 
yum -y install openldap-servers openldap-clients
sed -i 's/SLAPD_LDAPI=.*/SLAPD_LDAPI=yes/' /etc/sysconfig/ldap
sed -i 's/SLAPD_LDAP=.*/SLAPD_LDAPI=yes/' /etc/sysconfig/ldap
sed -i 's/SLAPD_LDAPS=.*/SLAPD_LDAPI=yes/' /etc/sysconfig/ldap
if [ -f /etc/openldap/slapd.conf ] ; then
	rm /etc/openldap/slapd.conf
fi
echo -e "pidfile     /var/run/openldap/slapd.pid\nargsfile    /var/run/openldap/slapd.args">/etc/openldap/slapd.conf
rm -rf /etc/openldap/slapd.d/* 
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d 
sed -i 's/olcAccess:.*/olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break/' /etc/openldap/slapd.d/cn=config/olcDatabase\={0}config.ldif
if [ -f /etc/openldap/slapd.d/cn=config/olcDatabase\={1}monitor.ldif ] ; then
        rm /etc/openldap/slapd.d/cn=config/olcDatabase\={1}monitor.ldif
fi
echo -e "dn: olcDatabase={1}monitor\nobjectClass: olcDatabaseConfig\nolcDatabase: {1}monitor\nolcAccess: {1}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break\nolcAddContentAcl: FALSE\nolcLastMod: TRUE\nolcMaxDerefDepth: 15\nolcReadOnly: FALSE\nolcMonitoring: FALSE\nstructuralObjectClass: olcDatabaseConfig\ncreatorsName: cn=config\nmodifiersName: cn=config" > /etc/openldap/slapd.d/cn=config/olcDatabase\={1}monitor.ldif\n
chown -R ldap. /etc/openldap/slapd.d 
chmod -R 700 /etc/openldap/slapd.d 
/etc/rc.d/init.d/slapd start 
chkconfig slapd on 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /scripts/openldap/backend.ldif 
ldapadd -x -D cn=admin,dc=example,dc=com -w Password -f /scripts/openldap/frontend.ldif

#### http://www.server-world.info/en/note?os=CentOS_6&p=ldap
