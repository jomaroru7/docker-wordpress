FROM wordpress:7.0-php8.2-apache

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends wget unzip ca-certificates curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /usr/local/bin/wp

COPY docker-entrypoint-initwp.sh /usr/local/bin/docker-entrypoint-initwp.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-initwp.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-initwp.sh"]
CMD ["apache2-foreground"]
