#/bin/sh

# This script places the VMWare serial number into the CSR into a known attribute OID
# and used for validation when auto-signing Puppet certificate requests. Should
# live at /opt/puppet-csr.sh

if [ -d "/etc/puppet/" ]; then
  PUPDIR="/etc/puppet/"
else
  PUPDIR="/etc/puppetlabs/puppet/"
  mkdir -p $PUPDIR
fi;

SN=`sudo dmidecode | grep -i vmware | grep -i serial | cut -d "-" -f 2,3 | sed 's/-//g; s/\s//g;'`

echo "---
custom_attributes:
  1.2.840.113549.1.9.7: $SN
" > $PUPDIR/csr_attributes.yaml
