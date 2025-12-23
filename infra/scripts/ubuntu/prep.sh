#!/bin/bash

# Cleaning logs.
if [ -f /var/log/audit/audit.log ]; then
  cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
  cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
  cat /dev/null > /var/log/lastlog
fi

# Cleaning udev rules.
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
  rm /etc/udev/rules.d/70-persistent-net.rules
fi

# Cleaning the /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

# Cleaning the SSH host keys
rm -f /etc/ssh/ssh_host_*

# Cleaning the machine-id
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Cleaning the shell history
unset HISTFILE
history -cw
echo > ~/.bash_history
rm -fr /root/.bash_history

# Truncating hostname, hosts, resolv.conf and setting hostname to localhost
truncate -s 0 /etc/{hostname,hosts,resolv.conf}
hostnamectl set-hostname localhost

# Cleans apt-get.
echo '> Cleaning apt-get ...'
apt-get clean
apt-get autoremove

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
echo '> Cleaning cloud-init ...'
sudo cloud-init clean -s -l

# stop puppet, diable puppet, remove certs
systemctl stop puppet
systemctl disable puppet
echo -e [main]\\nca_server = puppet-ca.abc.corp\\n[agent]\\nserver_list = puppet-adc.abc.corp:8140,puppet-edc.abc.corp:8140 > /etc/puppetlabs/puppet/puppet.conf
rm -rf /etc/puppetlabs/puppet/ssl/
