FROM wordpress:7.0-php8.2-apache

ARG DEBIAN_FRONTEND=noninteractive
ARG PUID=33
ARG PGID=33

RUN apt-get update \
  && apt-get install -y --no-install-recommends wget unzip ca-certificates curl netcat-openbsd \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create a host-matching user/group to avoid permission issues when bind-mounting
# IMPORTANT: do this FIRST before copying files so chown works
RUN groupadd -g ${PGID} hostuser 2>/dev/null || true \
  && id -u hostuser >/dev/null 2>&1 || useradd -u ${PUID} -g ${PGID} -d /var/www/html -s /bin/bash hostuser || true \
  && sed -ri "s/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=hostuser/" /etc/apache2/envvars \
  && sed -ri "s/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=hostuser/" /etc/apache2/envvars \
  && chown -R hostuser:hostuser /var/www/html || true

# Enable AllowOverride for .htaccess directives to work
RUN sed -i '/<Directory \/var\/www\/html>/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Copy .htaccess for REST API and pretty permalinks
COPY .htaccess /var/www/html/.htaccess
RUN chmod 644 /var/www/html/.htaccess

# Install WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /usr/local/bin/wp

COPY docker-entrypoint-initwp.sh /usr/local/bin/docker-entrypoint-initwp.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-initwp.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-initwp.sh"]
CMD ["apache2-foreground"]
