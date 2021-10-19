FROM ubuntu:18.04
FROM node:12
MAINTAINER Fouad Chmainy <fchmainy@f5.com>
ENV DEBIAN_FRONTEND=noninteractive

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
ENV TZ=Europe/Paris

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update -yq && apt-get upgrade -yq && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    netcat \
    net-tools \
    tree \
    git sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /

RUN curl -sL https://deb.nodesource.com/setup_11.x | sudo bash - && \
    apt-get install -yq nodejs #build-essentials
RUN npm install -g json-server
RUN echo "NODE Version:" && node --version
RUN echo "NPM Version:" && npm --version

ENV TERM xterm

COPY animals.json /

EXPOSE 8080

WORKDIR /
CMD ["json-server", "--host", "0.0.0.0", "--port", "8080" , "--watch", "animals.json"]

HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost:8080 || exit 1


