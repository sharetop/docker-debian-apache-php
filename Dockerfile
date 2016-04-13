FROM debian:latest

RUN apt-get update \
	&& apt-get install -y apache2 php5 php5-dev php5-gd php5-mysql php5-curl --no-install-recommends

ENV PHP_INI_DIR /usr/local/etc/php

RUN rm -rf /var/www/html \
	&& mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
	&& chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html

RUN apt-get install -y autoconf gcc make --no-install-recommends

RUN cd /etc/apache2/mods-enabled \
	&& ln -s ../mods-available/rewrite.load rewrite.load \
	&& ln -s ../mods-available/authz_groupfile.load authz_groupfile.load \
	&& ln -s ../mods-available/reqtimeout.load reqtimeout.load \
	&& ln -s ../mods-available/reqtimeout.conf reqtimeout.conf \
	&& ln -s ../mods-available/headers.load headers.load

COPY mongo-1.6.13.tgz /tmp/mongo-1.6.13.tgz
RUN cd /tmp \
	&& tar zxvf mongo-1.6.13.tgz \
	&& cd mongo-1.6.13 \
	&& phpize \
	&& ./configure \
	&& make \
	&& make install \
	&& mv modules/mongo.so /usr/lib/php5/20131226/mongo.so \
	&& make clean

COPY redis-2.2.7.tgz /tmp/redis-2.2.7.tgz
RUN cd /tmp \
	&& tar zxvf redis-2.2.7.tgz \
	&& cd redis-2.2.7 \
	&& phpize \
	&& ./configure \
	&& make \
	&& make install \
	&& mv modules/redis.so /usr/lib/php5/20131226/redis.so \
	&& make clean


COPY mongo.ini /etc/php5/apache2/conf.d/mongo.ini
COPY redis.ini /etc/php5/apache2/conf.d/redis.ini

RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.dist
COPY apache2.conf /etc/apache2/apache2.conf


VOLUME ["/var/www/html"]

RUN rm -r -f /var/lib/apt/lists/* \
	&& rm /etc/apache2/conf-enabled/* /etc/apache2/sites-enabled/*

COPY apache2-foreground /usr/local/bin/
WORKDIR /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]

