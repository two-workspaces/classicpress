#!/bin/bash
# Railway entrypoint for ClassicPress: installed on first boot with a generated admin
# password (no public installer, not even for a moment), Apache sized from the plan's
# memory.
set -euo pipefail

# Railway flattens the image layers, which brings back the mpm_event links the PHP
# image deleted, and Apache then refuses to start: "AH00534: More than one MPM
# loaded". mod_php needs prefork only.
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*

# Prefork runs one process per concurrent request. Budget 64 MB a worker after 256 MB
# for Apache and OPcache, sized from the plan's memory limit, never from the host's CPUs.
mem=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
[ "$mem" = max ] && mem=$((8 << 30))
workers=$(( (mem / 1048576 - 256) / 64 ))
workers=$(( workers < 4 ? 4 : workers > 64 ? 64 : workers ))
printf '<IfModule mpm_prefork_module>\n\tMaxRequestWorkers %s\n</IfModule>\n' "$workers" \
  > /etc/apache2/conf-enabled/zz-workers.conf

wp() { setpriv --reuid=www-data --regid=www-data --init-groups env HOME=/tmp php /usr/local/bin/wp --path=/var/www/html "$@"; }

# Copy ClassicPress onto the volume and write wp-config.php, with its salts randomized
# once and kept on the volume. Upstream's entrypoint does this for any apache2* command.
docker-entrypoint.sh apache2 -v >/dev/null 2>&1

# On a fresh deploy MariaDB may still be initializing.
for i in $(seq 90); do
  php -r 'mysqli_report(MYSQLI_REPORT_OFF);
          exit(@mysqli_connect(getenv("CLASSICPRESS_DB_HOST"), getenv("CLASSICPRESS_DB_USER"),
                               getenv("CLASSICPRESS_DB_PASSWORD"), getenv("CLASSICPRESS_DB_NAME")) ? 0 : 1);' && break
  [ "$i" = 90 ] && { echo "railway: database not reachable after 3 minutes"; exit 1; }
  sleep 2
done

if ! wp core is-installed 2>/dev/null; then
  echo "railway: first boot, installing ClassicPress"
  wp core install --url="https://${RAILWAY_PUBLIC_DOMAIN:?no public domain; generate one in the service settings}" \
    --title="My ClassicPress Site" --admin_user=admin --admin_password="${CP_ADMIN_PASSWORD:?CP_ADMIN_PASSWORD is not set}" \
    --admin_email="${CP_ADMIN_EMAIL:-admin@example.com}" --skip-email
  wp rewrite structure '/%postname%/'  # the image's .htaccess already routes pretty URLs
  # WP-CLI doesn't make $cp_db_version global, so the install stores it empty and
  # every wp-admin page then redirects to the database upgrade screen.
  wp eval 'include ABSPATH . WPINC . "/version.php"; update_option( "cp_db_version", $cp_db_version );'
fi

exec apache2-foreground
