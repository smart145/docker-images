FROM circleci/php:7.3.7-stretch
LABEL maintainer="Eliurkis Diaz <eliurkis@gmail.com>"

RUN sudo apt-get update && sudo apt-get install -y libsqlite3-dev zlib1g-dev libpng-dev libxss1 \
    && sudo docker-php-ext-install -j$(nproc) zip gd pdo_mysql exif bcmath sockets

## Install libpng12
RUN sudo wget http://nl.archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb
RUN sudo dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb

RUN sudo rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

## Install Node
RUN curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
RUN sudo apt-get install -y nodejs