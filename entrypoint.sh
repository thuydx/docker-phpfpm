#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# Production-Grade Entrypoint for PHP-FPM + SSH + Node/NVM + Composer environment
# ------------------------------------------------------------------------------

# === Environment defaults ===
PUID=${PUID:-1000}
PGID=${PGID:-1000}
TZ=${TZ:-UTC}
PHP_VERSION=${PHP_VERSION:-8.5}
PHP_FPM_BIN="php-fpm${PHP_VERSION}"
PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
PHP_RUN_DIR="/run/php-fpm"

# === Ensure required directories exist ===
mkdir -p "$PHP_RUN_DIR" /var/run/sshd /var/log/php /var/log/sshd
chown -R root:root /run /var/run/sshd
chmod 755 /var/run/sshd

# === Start SSHD in background ===
if command -v /usr/sbin/sshd >/dev/null 2>&1; then
  echo "[INFO] Starting sshd..."
  /usr/sbin/sshd || echo "[WARN] sshd failed to start (non-fatal)"
fi

# ------------------------------------------------------------------------------
# Diagnostics Section (for transparency and quick debugging)
# ------------------------------------------------------------------------------
echo "[INFO] HOSTNAME:${HOSTNAME}, PHP:${PHP_VERSION}, TZ:${TZ}, PUID:${PUID}, PGID:${PGID}"
echo "[INFO] bash: $(bash --version | head -n1)"
command -v curl >/dev/null 2>&1 && echo "[INFO] curl: $(curl --version | head -n1)" || true
command -v git >/dev/null 2>&1 && echo "[INFO] git: $(git --version | head -n1)" || true
command -v php >/dev/null 2>&1 && echo "[INFO] PHP version $(php -v | head -n1)" || true
command -v composer >/dev/null 2>&1 && echo "[INFO] composer: $(composer --version | head -n1)" || true
command -v node >/dev/null 2>&1 && echo "[INFO] node: $(node --version 2>/dev/null || true)" || true
command -v npm >/dev/null 2>&1 && echo "[INFO] npm: $(npm --version 2>/dev/null || true)" || true
command -v nvm >/dev/null 2>&1 && echo "[INFO] nvm: $(nvm --version 2>/dev/null || true)" || true

# ------------------------------------------------------------------------------
# Port check to prevent binding conflicts
# ------------------------------------------------------------------------------
port_in_use=0
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep -q ':9000' && port_in_use=1
elif command -v netstat >/dev/null 2>&1; then
  netstat -ltnp 2>/dev/null | grep -q ':9000' && port_in_use=1
fi

if [ "$port_in_use" -eq 1 ]; then
  echo "[WARN] Port 9000 already in use; not starting php-fpm."
  ss -ltnp 2>/dev/null | grep ':9000' || true
  [ "$#" -gt 0 ] && exec "$@" || tail -f /dev/null
fi

# ------------------------------------------------------------------------------
# Graceful shutdown handling (for Docker/Kubernetes)
# ------------------------------------------------------------------------------
trap 'echo "[INFO] Stopping php-fpm..."; \
      kill -TERM $(cat /run/php-fpm/php-fpm.pid 2>/dev/null || echo 0) 2>/dev/null || true; \
      exit 0' SIGTERM SIGINT

# ------------------------------------------------------------------------------
# Healthcheck: Wait until php-fpm is ready
# ------------------------------------------------------------------------------
wait_for_fpm() {
  echo "[HEALTHCHECK] Waiting for PHP-FPM (${PHP_VERSION}) to start..."
  local retries=10
  while [ $retries -gt 0 ]; do
    if pidof "$PHP_FPM_BIN" >/dev/null; then
      echo "[HEALTHCHECK] PHP-FPM is running."
      return 0
    fi
    sleep 1
    retries=$((retries - 1))
  done
  echo "[ERROR] PHP-FPM failed to start within timeout."
  return 1
}

# ------------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------------
echo "[INFO] Starting PHP-FPM ${PHP_VERSION}..."
mkdir -p "$(dirname "$PHP_FPM_CONF")" || true

if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec "$PHP_FPM_BIN" -F -y "$PHP_FPM_CONF" &
  fpm_pid=$!
  wait_for_fpm
  wait "$fpm_pid"
fi
