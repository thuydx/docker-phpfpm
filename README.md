# Docker PHP8.1-FPM
# docker-phpfpm
Docker PHP FPM with lean ubuntu 22.04 base.

## Usage
To pull latest image:

```sh
docker pull thuydx/phpfpm:8.1
```

To use in docker-compose
```yaml
# ./docker-compose.yml
version: '3'

services:
  phpfpm:
    image: thuydx/phpfpm:8.1
    container_name: phpfpm
    volumes:
      - ./path/to/your/app:/var/www/html
      # Here you can also volume php ini settings
      # - /path/to/zz-overrides:/usr/local/etc/php/conf.d/zz-overrides.ini
    ports:
      - 9000:9000
    environment:
      - APP_NAME=App
```
To use in docker-file
```Dockerfile
FROM thuydx/phpfpm:8.1
```

### Extensions
The following PHP extensions are installed in `thuydx/phpfpm:8.1`:
```
PHP: 8.1.7
Total: 73
- apcu              - ast               - bcmath            - bz2
- calendar          - core              - ctype             - curl
- date              - dom               - ds                - exif
- ffi               - fileinfo          - filter            - ftp
- gd                - gettext           - gmp               - grpc
- hash              - iconv             - igbinary          - imap
- intl              - json              - ldap              - libxml
- maxminddb         - mbstring          - mcrypt            - memcached
- msgpack           - mysqli            - mysqlnd           - oauth
- openssl           - pcntl             - pcov              - pcre
- pdo               - pdo_mysql         - phar              - posix
- pspell            - psr               - readline          - redis
- reflection        - session           - shmop             - simplexml
- soap              - sockets           - sodium            - spl
- standard          - swoole            - sysvmsg           - sysvsem
- sysvshm           - tidy              - tokenizer         - uuid
- xdebug            - xml               - xmlreader         - xmlwriter
- xsl               - yaml              - zend opcache      - zip
- zlib
```

Disable extensions you won't need. You can add as much as you want separated by space.
```
RUN docker-php-ext-disable xdebug pcov ldap
```

> `docker-php-ext-disable` is shell script available in `thuydx/phpfpm:8.1` only and not in official PHP docker images.
