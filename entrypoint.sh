#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# Production-Grade Entrypoint for PHP-FPM + SSH + Node/NVM + Composer environment
# ------------------------------------------------------------------------------

PUID=${PUID:-1000}
PGID=${PGID:-1000}
TZ=${TZ:-UTC}
PHP_VERSION=${PHP_VERSION:-8.5}
PHP_FPM_BIN="php-fpm${PHP_VERSION}"
PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
PHP_RUN_DIR="/run/php-fpm"

# === Ensure required directories exist ===
mkdir -p "$PHP_RUN_DIR" /var/run/sshd /var/log/php /var/log/sshd
chown -R root:root "$PHP_RUN_DIR" /var/run/sshd
chmod 755 /var/run/sshd

# === Start SSHD in background ===
if command -v /usr/sbin/sshd >/dev/null 2>&1; then
  echo "[INFO] Starting sshd..."
  /usr/sbin/sshd || echo "[WARN] sshd failed to start (non-fatal)"
fi

# ------------------------------------------------------------------------------
# Diagnostics
# ------------------------------------------------------------------------------
echo "[INFO] HOSTNAME:${HOSTNAME}, PHP:${PHP_VERSION}, TZ:${TZ}, PUID:${PUID}, PGID:${PGID}"
echo "[INFO] bash: $(bash --version | head -n1)"
command -v curl >/dev/null 2>&1 && echo "[INFO] curl: $(curl --version | head -n1)" || true
command -v git >/dev/null 2>&1 && echo "[INFO] git: $(git --version)" || true
command -v php >/dev/null 2>&1 && echo "[INFO] PHP $(php -v | head -n1)" || true
command -v composer >/dev/null 2>&1 && echo "[INFO] composer $(composer --version)" || true
command -v node >/dev/null 2>&1 && echo "[INFO] node $(node --version)" || true
command -v npm >/dev/null 2>&1 && echo "[INFO] npm $(npm --version)" || true

# ------------------------------------------------------------------------------
# Graceful shutdown
# ------------------------------------------------------------------------------
trap 'echo "[INFO] Stopping php-fpm..."; \
      pid=$(cat /run/php-fpm/php-fpm.pid 2>/dev/null || echo ""); \
      [ -n "$pid" ] && kill -TERM "$pid" 2>/dev/null || true; \
      exit 0' SIGTERM SIGINT

# ------------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------------
echo "[INFO] Starting PHP-FPM ${PHP_VERSION}..."

if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec "$PHP_FPM_BIN" -F -y "$PHP_FPM_CONF"
fi
