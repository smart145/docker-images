FROM circleci/php:7.4.11
LABEL maintainer="Eliurkis Diaz <eliurkis@gmail.com>"

RUN sudo apt-get update && \
    sudo apt-get install -yq --no-install-recommends \
    libsqlite3-dev zlib1g-dev libpng-dev libxss1 libjpeg62 libgbm-dev \
    libfontconfig1 libxrender1 libxcomposite-dev libxcursor1 libxi6 libgconf-2-4 \
    libxtst6 libnss3 libgdk-pixbuf2.0-0 libgtk-3-0 libasound2 \
    && sudo pecl install pcov && sudo docker-php-ext-enable pcov \
    && sudo docker-php-ext-install -j$(nproc) zip gd pdo_mysql exif bcmath sockets pcntl

## Install libpng12
RUN sudo wget http://nl.archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb
RUN sudo dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb

RUN sudo rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

## Install Node
RUN curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
RUN sudo apt-get install -y nodejs
