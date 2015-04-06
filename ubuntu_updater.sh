#!/usr/bin/env bash
set -o pipefail

LOG_FILE="/var/log/release-upgrade-$(date +'%F_%H-%M-%S').log"
CURRENT_VERSION="12.04" # Should be LTS release
BACKUP_DIR="/var/backups"

mkdir ${BACKUP_DIR}
# Create backup of /etc dir
cp -a /etc ${BACKUP_DIR}

# Create backup of installed packages along with versions. Just in case we need some rollback you
# can try to restore using apt-get -y --force-yes install $(cat package-list.txt) command
# It's not expected to work properly after upgrade due to differences in versions between Ubuntu releases.
# Try to restore only if do-release-upgrade fails for some reason.
# Not using dpkg-query -l because it adds some trash at the start of file.
dpkg -l | grep '^ii' | awk '{print $2 "=" $3}' > ${BACKUP_DIR}/package-list.txt

# Check if we're actually upgrading from correct LSB version.
lsb_release -a | grep ${CURRENT_VERSION}
if [ "$?" != "0" ]; then
  echo "It looks like current system is not Ubuntu ${CURRENT_VERSION}, check script and if it still suits your needs update CURRENT_VERSION variable. Exiting.
" | tee -a ${LOG_FILE}
  exit 1
fi

rm -rf /var/lib/apt/lists/*  # Otherwise apt-get update may complain 'Failed to fetch... Hash Sum mismatch'

export DEBIAN_FRONTEND=noninteractive
apt-get update | tee -a ${LOG_FILE}
apt-get -y --force-yes upgrade | tee -a ${LOG_FILE}
apt-get -y --force-yes install update-manager-core | tee -a ${LOG_FILE}

# Check if update-manager will try to upgrade to the next LTS release.
grep 'Prompt=lts' /etc/update-manager/release-upgrades
if [ "$?" != "0" ]; then
  echo "It looks like update manager is not configured to upgrade to the next LTS release, exiting." | tee -a ${LOG_FILE}
  exit 1
fi

echo "\nCreating apt config file to force non-interactive behaviour\n" >> ${LOG_FILE}

cat <<EOT >> /etc/apt/apt.conf.d/local
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOT

apt-get install update-manager-core | tee -a ${LOG_FILE}
do-release-upgrade -f DistUpgradeViewNonInteractive >> -a ${LOG_FILE}

apt-get -y --force-yes install --reinstall chef | tee -a ${LOG_FILE}
rm /etc/apt/apt.conf.d/local # Remove non-interactive config for apt

shutdown -r now
