FROM ubuntu:22.04

LABEL maintainer="Thuy Dinh <thuydx@zendgroup.vn>" \
      author="Thuy Dinh" \
      description="Optimized PHP-FPM 8.4 + Node.js 25 + Composer image"

ARG PHP_VERSION=8.4
ARG NODE_VERSION=25.1.0
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    NVM_DIR=/usr/local/nvm \
    PATH=/usr/local/nvm/versions/node/v${NODE_VERSION}/bin:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------
# 1️⃣ System base + PHP runtime
# ----------------------------------------------------------------------
RUN sed -i 's|http://archive.ubuntu.com|http://vn.archive.ubuntu.com|g' /etc/apt/sources.list && \
    apt-get update && apt-get -y upgrade && apt-get autoremove -y && apt-get clean && \
    apt-get install -y --no-install-recommends software-properties-common curl ca-certificates gnupg lsb-release && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update && apt-get install -y --no-install-recommends \
      php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-mysql \
      php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl \
      php${PHP_VERSION}-xml php${PHP_VERSION}-intl php${PHP_VERSION}-opcache php${PHP_VERSION}-bcmath \
      php${PHP_VERSION}-redis php${PHP_VERSION}-soap php${PHP_VERSION}-imap php${PHP_VERSION}-gmp \
      unzip git vim sudo openssh-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Update pip and install cryptography and pyjwt
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3 && \
    pip install --no-cache-dir --root-user-action=ignore --upgrade "setuptools<81" && \
    pip install --no-cache-dir --upgrade cryptography pyjwt

# ----------------------------------------------------------------------
# 2️⃣ Composer
# ----------------------------------------------------------------------
RUN curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ----------------------------------------------------------------------
# 3️⃣ Node.js (via NVM)
# ----------------------------------------------------------------------
ENV NODE_VERSION=25.1.0
ENV NVM_DIR=/usr/local/nvm

RUN apt-get update && apt-get install -y curl ca-certificates libatomic1 && \
    mkdir -p "$NVM_DIR" && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION} && \
    npm install -g npm@latest && \
    rm -rf /root/.npm /root/.cache "$NVM_DIR/.cache"


# ----------------------------------------------------------------------
# 4️⃣ SSH + PHP config + directories
# ----------------------------------------------------------------------
RUN mkdir -p /run/php /var/run/sshd /var/log/xdebug && \
    chown -R root:root /run/php /var/run/sshd && \
    chmod 755 /var/run/sshd /run/php && \
    echo 'root:Docker!' | chpasswd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

COPY ./conf.d/app-fpm.ini /etc/php/${PHP_VERSION}/fpm/conf.d/
COPY ./conf.d/app-xdebug.ini /etc/php/${PHP_VERSION}/fpm/conf.d/
COPY ./php-fpm.d/ /etc/php/${PHP_VERSION}/fpm/pool.d/

RUN mkdir -p /run/php-fpm /var/tmp/php-fpm /usr/local/.nvm /var/log/xdebug /var/run/sshd /root/.ssh

# ----------------------------------------------------------------------
# 5️⃣ Non-root user (optional)
# ----------------------------------------------------------------------
RUN groupadd -g 1000 dev && useradd -u 1000 -ms /bin/bash -g dev dev

# ----------------------------------------------------------------------
# 6️⃣ Entrypoint
# ----------------------------------------------------------------------
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000 9003 22
ENTRYPOINT ["/entrypoint.sh"]
