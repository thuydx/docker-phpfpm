#!/bin/bash
set -e
# start sshd as a daemon (no -D so it forks to background)
if command -v /usr/sbin/sshd >/dev/null 2>&1; then
  /usr/sbin/sshd || true
fi

# Diagnostics (non-interactive; avoid 'bash -i' which triggers job-control warnings)
echo "[INFO] HOSTNAME:$HOSTNAME, PUID:${PUID:-1000}, PGID:${PGID:-1000}, TZ:${TZ:-UTC}"
echo "bash: $(bash --version | head -n1)"
command -v dpkg >/dev/null 2>&1 && dpkg -s dash >/dev/null 2>&1 && echo "dpkg dash: $(dpkg -s dash | awk '/^Version:/ {print $2}')" || true
command -v curl >/dev/null 2>&1 && echo "curl: $(curl --version | head -n1)" || true

# Source nvm non-interactively if installed, then print versions
if [ -n "${NVM_DIR:-}" ] && [ -s "${NVM_DIR}/nvm.sh" ]; then
  # shellcheck source=/dev/null
  . "${NVM_DIR}/nvm.sh"
fi
command -v nvm >/dev/null 2>&1 && echo "nvm: $(nvm --version 2>/dev/null || true)" || true
command -v node >/dev/null 2>&1 && echo "node: $(node --version 2>/dev/null || true)" || true
command -v npm >/dev/null 2>&1 && echo "npm: $(npm --version 2>/dev/null || true)" || true

command -v git >/dev/null 2>&1 && echo "git: $(git --version | head -n1)" || true
command -v php >/dev/null 2>&1 && echo "php: $(php -v | head -n1)" || true
command -v composer >/dev/null 2>&1 && echo "composer: $(composer --version | head -n1)" || true


# Check if port 9000 is already in use
port_in_use=0
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep -q ':9000' && port_in_use=1 || port_in_use=0
elif command -v netstat >/dev/null 2>&1; then
  netstat -ltnp 2>/dev/null | grep -q ':9000' && port_in_use=1 || port_in_use=0
fi

if [ "$port_in_use" -eq 1 ]; then
  echo "[WARN] Port 9000 already in use; not starting a new php-fpm to avoid bind conflict."
  ss -ltnp 2>/dev/null | grep ':9000' || true
  if [ "$#" -gt 0 ]; then
    exec "$@"
  else
    # keep container alive if desired, otherwise exit 0
    tail -f /dev/null
  fi
fi

# If user passed a command, run it; otherwise exec php-fpm in foreground so container stays up
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec php-fpm8.4 -F -y /etc/php/8.4/fpm/php-fpm.conf
fi