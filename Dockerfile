FROM ubuntu:20.04

# تحديد النسخة
ENV stalker_version 550
ENV stalker_zip ministra-5.5.0.zip
ENV TZ=Africa/Casablanca

# إعداد المنطقة الزمنية
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# تحديث النظام وتثبيت الحزم المطلوبة
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y apache2 nginx memcached mysql-server php php-mysql php-pear nodejs npm unzip php-mbstring php-xml tzdata

# إعداد Node.js
RUN npm config set strict-ssl false
RUN npm install -g npm@latest
RUN ln -s /usr/bin/nodejs /usr/bin/node

# إعداد Phing
RUN pear channel-discover pear.phing.info
RUN pear install -Z phing/phing

# إعداد MySQL
RUN echo "max_allowed_packet = 32M" >> /etc/mysql/my.cnf

# إعداد Apache و PHP
RUN sed -i 's/Listen 80/Listen 88/' /etc/apache2/ports.conf
RUN echo "short_open_tag = On" >> /etc/php/7.4/apache2/php.ini
RUN a2enmod rewrite
RUN a2enmod remoteip

# إعداد قاعدة البيانات
RUN service mysql start && \
    mysql -u root -e "CREATE DATABASE stalker_db;" && \
    mysql -u root -e "GRANT ALL PRIVILEGES ON stalker_db.* TO 'stalker'@'localhost' IDENTIFIED BY '1';" && \
    mysql -u root -e "FLUSH PRIVILEGES;"

# إضافة اللغات
RUN for i in ru_RU.utf8 en_GB.utf8 uk_UA.utf8 pl_PL.utf8 el_GR.utf8 nl_NL.utf8 it_IT.utf8 de_DE.utf8 sk_SK.utf8 es_ES.utf8 bg_BG.utf8 en_IE.utf8; do locale-gen $i; done
RUN dpkg-reconfigure locales

# نسخ الملفات
COPY ${stalker_zip} /
RUN unzip ${stalker_zip} -d stalker_portal
RUN mv stalker_portal/* /var/www/stalker_portal
RUN rm -rf stalker_portal ${stalker_zip}

# إعداد ملفات Nginx و Apache
COPY conf/nginx/*.conf /etc/nginx/conf.d/
COPY conf/apache2/*.conf /etc/apache2/sites-available/
COPY conf/apache2/conf-available/*.conf /etc/apache2/conf-available/

# إنشاء قاعدة البيانات الافتراضية
RUN mkdir /root/mysql_default && cp -rf /var/lib/mysql/* /root/mysql_default/

# نسخ سكريبت البداية
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 88 80
ENTRYPOINT ["/entrypoint.sh"]
