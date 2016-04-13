# 执行命令如下：

docker run -it --name mywebapp -p 8801:80 -v /home/yancheng/webapp:/var/www/html debian/apache-php:0.1.1

# Dockerfile 文件说明如下：

## 源于debian:latest，这是一个干净的Debian系统
FROM debian:latest

## 先update一下，然后安装需要的软件
RUN apt-get update \
    && apt-get install -y apache2 php5 php5-dev php5-gd php5-mysql php5-curl --no-install-recommends

## 参考官网那个镜像的脚本
ENV PHP_INI_DIR /usr/local/etc/php

## 创建必要的目录，参考apache2.conf中的配置项
RUN rm -rf /var/www/html \
    && mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
    && chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html

## 准备源码编译，先安装必要的工具
RUN apt-get install -y autoconf gcc make --no-install-recommends

##  以下通过软链启用部分PHP内置的模块
RUN cd /etc/apache2/mods-enabled \
    && ln -s ../mods-available/rewrite.load rewrite.load \
    && ln -s ../mods-available/authz_groupfile.load authz_groupfile.load \
    && ln -s ../mods-available/reqtimeout.load reqtimeout.load \
    && ln -s ../mods-available/reqtimeout.conf reqtimeout.conf \
    && ln -s ../mods-available/headers.load headers.load
    
##  以下两段是分别安装mongodb和redis的操作
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

## 现在将我们的配置文件代替系统缺省的。
RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.dist
COPY apache2.conf /etc/apache2/apache2.conf

## 加个卷，一般情况下以后我们只挂载此目录
VOLUME ["/var/www/html"]

## 清除一下垃圾
RUN rm -r -f /var/lib/apt/lists/* \
    && rm /etc/apache2/conf-enabled/* /etc/apache2/sites-enabled/*

## 参考官网的脚本，做个快捷方式启动Apache
COPY apache2-foreground /usr/local/bin/

WORKDIR /var/www/html

## 暴露80端口
EXPOSE 80

## 镜像入口
CMD ["apache2-foreground"]

