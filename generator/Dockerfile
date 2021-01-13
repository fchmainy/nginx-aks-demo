FROM ubuntu:18.04
MAINTAINER Fouad Chmainy <fchmainy@f5.com>
ENV DEBIAN_FRONTEND=noninteractive

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    netcat \
    net-tools \
    tree \
    python \
    python-requests \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# to be able to use "nano" with shell on "docker exec -it [CONTAINER ID] bash"
ENV TERM xterm

COPY generator.py /

# Run.
#RUN python generator.py &

EXPOSE 80

WORKDIR /
CMD ["python", "generator.py"]
HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost:80 || exit 1


