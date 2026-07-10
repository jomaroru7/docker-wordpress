#!/bin/bash
set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# Ensure mu-plugins directory exists
mkdir -p /var/www/html/wp-content/mu-plugins
chown -R www-data:www-data /var/www/html/wp-content/mu-plugins || true

# Ensure the default WordPress filesystem is available before continuing
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "WordPress config not found yet; continuing startup."
fi

# Ensure base apache permissions are healthy
chown -R www-data:www-data /var/www/html 2>/dev/null || true
chmod -R u+rwX /var/www/html 2>/dev/null || true

# If HEADLESS is not true, fall back to original entrypoint
if [ "${HEADLESS:-false}" != "true" ]; then
  exec docker-entrypoint.sh "$@"
fi

## Wait for DB to be available by testing port connectivity
RETRIES=60
SLEEP=2
i=0
until nc -z db 3306 2>/dev/null; do
  if [ $i -ge $RETRIES ]; then
    echo "Timeout waiting for database; handing over to original entrypoint."
    exec docker-entrypoint.sh "$@"
  fi
  echo "Waiting for database to be ready... ($i/$RETRIES)"
  sleep $SLEEP
  i=$((i+1))
done


## Ensure the default WordPress filesystem is available before continuing
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "WordPress config not found yet; continuing startup."
fi

# Make sure Apache can read/write the WordPress directory after bind mounts
chown -R www-data:www-data /var/www/html 2>/dev/null || true
chmod -R u+rwX /var/www/html 2>/dev/null || true
## If WP is not installed, attempt a silent install using env variables (or sensible defaults).
if ! wp core is-installed --allow-root --path=/var/www/html; then
  echo "WordPress not installed; performing automatic install..."
  SITE_URL=${WORDPRESS_SITE_URL:-https://localhost}
  SITE_TITLE=${WORDPRESS_SITE_TITLE:-WordPress}
  ADMIN_USER=${WORDPRESS_ADMIN_USER:-admin}
  ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD:-admin}
  ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL:-admin@example.com}
  wp core install --url="$SITE_URL" --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASSWORD" \
    --admin_email="$ADMIN_EMAIL" --skip-email --allow-root --path=/var/www/html || true
  echo "Automatic install attempted."
fi

echo "Installing and activating headless plugins..."
wp plugin install wp-graphql --activate --allow-root --path=/var/www/html || true
wp plugin install jwt-authentication-for-wp-rest-api --activate --allow-root --path=/var/www/html || true

## Create a mu-plugin to allow CORS for one or more frontend origins
# Supports FRONTEND_URLS (comma-separated) or fallback to FRONTEND_URL
cat > /var/www/html/wp-content/mu-plugins/headless-cors.php <<'PHP'
<?php
add_action('init', function() {
  if (defined('WP_CLI') && WP_CLI) return;

  $allowed = getenv('FRONTEND_URLS') ?: getenv('FRONTEND_URL');
  if (!$allowed) return;

  $allowed_list = array_map('trim', explode(',', $allowed));
  $origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';
  if ($origin && in_array($origin, $allowed_list, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    if ('OPTIONS' === $_SERVER['REQUEST_METHOD']) { status_header(200); exit; }
  }
});
PHP

chown www-data:www-data /var/www/html/wp-content/mu-plugins/headless-cors.php || true

echo "Headless setup complete; handing over to original entrypoint."
exec docker-entrypoint.sh "$@"
