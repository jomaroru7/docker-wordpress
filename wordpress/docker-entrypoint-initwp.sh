#!/bin/bash
set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# Ensure mu-plugins directory exists
mkdir -p /var/www/html/wp-content/mu-plugins
chown -R www-data:www-data /var/www/html/wp-content/mu-plugins || true

# If HEADLESS is not true, fall back to original entrypoint
if [ "${HEADLESS:-false}" != "true" ]; then
  exec docker-entrypoint.sh "$@"
fi

## Wait for DB to be available so wp-cli commands can connect
RETRIES=60
SLEEP=5
i=0
until wp db check --allow-root --path=/var/www/html 2>/dev/null; do
  if [ $i -ge $RETRIES ]; then
    echo "Timeout waiting for database; handing over to original entrypoint."
    exec docker-entrypoint.sh "$@"
  fi
  echo "Waiting for database to be ready... ($i/$RETRIES)"
  sleep $SLEEP
  i=$((i+1))
done

## If WP is not installed, attempt a silent install using env variables (or sensible defaults).
if ! wp core is-installed --allow-root --path=/var/www/html; then
  echo "WordPress not installed; performing automatic install..."
  SITE_URL=${WORDPRESS_SITE_URL:-http://localhost:8000}
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

# Create a simple mu-plugin to allow CORS for the front-end origin
FRONTEND=${FRONTEND_URL:-http://localhost:3000}
cat > /var/www/html/wp-content/mu-plugins/headless-cors.php <<'PHP'
<?php
add_action('init', function() {
  if (defined('WP_CLI') && WP_CLI) return;
  $origin = getenv('FRONTEND_URL') ?: '';
  if ($origin) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    if ('OPTIONS' === $_SERVER['REQUEST_METHOD']) { status_header(200); exit; }
  }
});
PHP

chown www-data:www-data /var/www/html/wp-content/mu-plugins/headless-cors.php || true

echo "Headless setup complete; handing over to original entrypoint."
exec docker-entrypoint.sh "$@"
