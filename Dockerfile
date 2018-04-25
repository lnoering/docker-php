FROM centos:7
MAINTAINER "Leonardo" <lnoering@gmail.com>

LABEL \
	name="PHP-FPM 7.2 Image" \
	image="php" \
	vendor="lnoering" \
	license="The Unlicense" \
	build-date="2018-24-04"

# User/Group
ENV PHP_USER="phpfpm" \
	PHP_GROUP="phpfpm" \
	PHP_UID="1000" \
	PHP_GID="1000" \
	PHP_VERSION=7.2.5  \
	NGINX_USER="nginx"

RUN yum -y update --exclude=iputils

RUN yum -y install 	gcc \
					gcc-c++ \
					libxml2-devel \
					pkgconfig \
					openssl-devel \
					bzip2-devel \
					curl-devel \
					libpng-devel \
					libjpeg-devel \
					libXpm-devel \
					freetype-devel \
					gmp-devel \
					libmcrypt-devel \
					mariadb-devel \
					aspell-devel \
					recode-devel \
					autoconf \
					bison \
					re2c \
					libicu-devel \
					make \
					wget

RUN mkdir /usr/local/php7

WORKDIR /usr/local/php7

RUN wget https://github.com/php/php-src/archive/php-${PHP_VERSION}.tar.gz && \
	tar -xzf php-${PHP_VERSION}.tar.gz && \
	rm -rf php-${PHP_VERSION}.tar.gz

RUN mv php-src-php-${PHP_VERSION} php-${PHP_VERSION}

WORKDIR /usr/local/php7/php-${PHP_VERSION}

RUN ./buildconf --force
RUN ./configure --prefix=/usr/local/php7 \
    --with-config-file-path=/usr/local/php7/etc \
    --with-config-file-scan-dir=/usr/local/php7/etc/conf.d \
    --enable-bcmath \
    --with-bz2 \
    --with-curl \
    --enable-filter \
    --enable-fpm \
    --with-gd \
    --enable-gd-native-ttf \
    --with-freetype-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --enable-intl \
    --enable-mbstring \
    --with-mcrypt \
    --enable-mysqlnd \
    --with-mysql-sock=/var/lib/mysql/mysql.sock \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-pdo-sqlite \
    --disable-phpdbg \
    --disable-phpdbg-webhelper \
    --enable-opcache \
    --with-openssl \
    --enable-simplexml \
    --with-sqlite3 \
    --enable-xmlreader \
    --enable-xmlwriter \
    --enable-zip \
    --with-zlib

RUN make -j2 && \
	make install

RUN mkdir /usr/local/php7/etc/conf.d

COPY data/entrypoint.sh /entrypoint.sh
COPY data/www.conf /usr/local/php7/etc/php-fpm.d/www.conf
COPY data/php-fpm.conf /usr/local/php7/etc/php-fpm.conf

RUN touch /usr/local/php7/etc/conf.d/modules.ini && \
	echo -e "# Zend OPcache\nzend_extension=opcache.so" > /usr/local/php7/etc/conf.d/modules.ini && \
	sed -i -e 's/www-data/${PHP_USER}/g' /usr/local/php7/etc/php-fpm.d/www.conf && \
	sed -i -e 's/www-data-listen/${PHP_USER}/g' /usr/local/php7/etc/php-fpm.d/www.conf && \
	ln -s /usr/local/php7/sbin/php-fpm /usr/sbin/php-fpm && \
	mkdir /run/php/

# Date timezone
# sed 's#;date.timezone\([[:space:]]*\)=\([[:space:]]*\)*#date.timezone\1=\2\"'"$PHP_TIMEZONE"'\"#g' $PHP_DIRECTORY/php.ini > $PHP_DIRECTORY/php.ini.tmp
# mv $PHP_DIRECTORY/php.ini.tmp $PHP_DIRECTORY/php.ini

RUN groupadd --system ${PHP_USER} && \
	useradd --system -m -d /var/www  -s /usr/sbin/nologin -g ${PHP_USER} ${PHP_GROUP}

# RUN chkconfig --add php-fpm && \
# 	chkconfig --levels 235 php-fpm on && \
# 	chkconfig php-fpm on

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]