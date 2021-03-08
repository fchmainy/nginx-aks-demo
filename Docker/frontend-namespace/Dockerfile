FROM ubuntu:18.04
MAINTAINER Fouad Chmainy <fchmainy@gmail.com>
ENV DEBIAN_FRONTEND=noninteractive

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    # Install git
    git \
    # Install apache
    apache2 \
    # Install php 7.2
    libapache2-mod-php7.2 \
    php7.2-cli \
    php7.2-json \
    php7.2-curl \
    php7.2-fpm \
    php7.2-gd \
    php7.2-ldap \
    php7.2-mbstring \
    php7.2-mysql \
    php7.2-soap \
    php7.2-sqlite3 \
    php7.2-xml \
    php7.2-zip \
    php7.2-intl \
    php-imagick \
    # Install tools
    nano \
    tree \
    curl \
    netcat \
    net-tools \
    iputils-ping \
    locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# to be able to use "nano" with shell on "docker exec -it [CONTAINER ID] bash"
ENV TERM xterm

COPY index.php /var/www/html

# Enable apache mods.
RUN a2enmod php7.2
RUN a2enmod rewrite
RUN apt-get install locales
RUN locale-gen fr_FR.UTF-8
RUN locale-gen en_US.UTF-8

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i -e 's/^error_reporting\s*=.*/error_reporting = E_ALL/' /etc/php/7.2/apache2/php.ini
RUN sed -i -e 's/^display_errors\s*=.*/display_errors = On/' /etc/php/7.2/apache2/php.ini
RUN sed -i -e 's/^zlib.output_compression\s*=.*/zlib.output_compression = Off/' /etc/php/7.2/apache2/php.ini

RUN sed -i "s/80/8080/g" /etc/apache2/ports.conf
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

COPY generator.conf /etc/apache2/sites-available/
RUN a2ensite generator.conf

RUN a2dissite 000-default

RUN chgrp -R www-data /var/www
RUN find /var/www -type d -exec chmod 777 {} +
RUN find /var/www -type f -exec chmod 777 {} +
RUN chmod -R 777 /var/log/apache2/error.log
RUN chmod -R 777 /var/log/apache2/other_vhosts_access.log
RUN chmod -R 777 /var/log/apache2/access.log
RUN chmod -R 777 /var/run/apache2/
RUN chmod -R 777 /var/www/html/


EXPOSE 8080

WORKDIR /var/www/html

RUN rm index.html

#HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost:8080 || exit 1

CMD apachectl -D FOREGROUND

