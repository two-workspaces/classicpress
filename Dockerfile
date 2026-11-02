# The upgrade queue reads ClassicPress releases from this marker. The image has no
# version tags yet, so it's pinned by digest: a moving tag would rebase every deploy
# at once. To bump, raise CP_VERSION and the digest together; the check below fails
# the build if they disagree. This fixes PHP, Apache and the version of the first
# install; after that ClassicPress updates itself from the dashboard as usual.
# upgrade: github ClassicPress/ClassicPress-release
ARG CP_VERSION=2.7.4
# upgrade: skip
FROM classicpress/classicpress:php8.3-apache@sha256:94e9f4e51ead47306ac049e5d952da3994062b6faeade7803f2f718a59afb3e8

ARG CP_VERSION
RUN grep -qF "'${CP_VERSION}" /usr/src/classicpress/wp-includes/version.php

# The stock limits reject most themes, plugins and media (2 MB uploads).
RUN printf '%s\n' 'upload_max_filesize = 128M' 'post_max_size = 128M' 'memory_limit = 256M' 'max_execution_time = 300' 'expose_php = Off' \
	> /usr/local/etc/php/conf.d/railway.ini

# Apache on Railway's $PORT, IPv6 and IPv4. Errors go to stdout: Railway paints all
# of stderr red, including Apache's startup notices.
ENV PORT=8080
RUN set -eux; \
	printf 'Listen [::]:${PORT}\nListen 0.0.0.0:${PORT}\n' > /etc/apache2/ports.conf; \
	sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/' /etc/apache2/sites-available/000-default.conf; \
	grep -q 'VirtualHost \*:${PORT}' /etc/apache2/sites-available/000-default.conf; \
	ln -sfT /dev/stdout /var/log/apache2/error.log; \
	sed -i 's/^ServerTokens OS/ServerTokens Prod/; s/^ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf; \
	mkdir -p /usr/local/share/railway; \
	echo ok > /usr/local/share/railway/healthz
COPY railway.conf /etc/apache2/conf-enabled/railway.conf

# The visitor's address: Railway's edge connects from 100.64.0.0/10 and sets X-Real-IP
# to the client. The image only trusts X-Forwarded-For from private ranges, so
# ClassicPress (comments, login limits) would otherwise see the proxy for everyone.
RUN printf '%s\n' 'RemoteIPHeader X-Real-IP' 'RemoteIPInternalProxy 100.64.0.0/10' > /etc/apache2/conf-available/remoteip.conf

COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/railway-entrypoint.sh"]
# The PHP image stops Apache with SIGWINCH; the entrypoint handles SIGTERM, which is
# also what Railway sends.
STOPSIGNAL SIGTERM
