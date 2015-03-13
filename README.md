## Script for non-interactive Ubuntu upgrade between LTS releases

Script for non-interactive upgrading Ubuntu 12.04 to 14.04. May be handy if you're updating lot of servers simultaneously.

Script

- Stores backup of /etc directory in /var/backups.
- Creates list of installed packages with versions.
- Performs system update to the most recent state.
- Configures apt for non-ineractive behaviour.
- Upgrades OS to the next LTS release using do-release-upgrade.
- Removes apt non-interactive config.
- Reboots a server.

If there is a config for the particular service, config is not changed. Configs are created for newly installed services.
For details check apt configuration options and the following part of script:

```
cat <<EOT >> /etc/apt/apt.conf.d/local
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOT
```

## Usage

- Clone repository to the target server, make script executable and execute on behalf of root.
