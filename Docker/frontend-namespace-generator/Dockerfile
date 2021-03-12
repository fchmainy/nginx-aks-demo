FROM php:7.2-apache

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    # Install git
    git \
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
RUN mkdir /var/www/html/images
COPY ./images /var/www/html/images

# Enable apache mods.
RUN apt-get install locales
RUN locale-gen fr_FR.UTF-8
RUN locale-gen en_US.UTF-8

RUN sed -i "s/80/8080/g" /etc/apache2/ports.conf
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

COPY generator.conf /etc/apache2/sites-available/
RUN a2ensite generator.conf

RUN a2dissite 000-default

RUN chgrp -R www-data /var/www
RUN find /var/www -type d -exec chmod 777 {} +
RUN find /var/www -type f -exec chmod 777 {} +

EXPOSE 8080

WORKDIR /var/www/html

HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost:8080 || exit 1

CMD apachectl -D FOREGROUND