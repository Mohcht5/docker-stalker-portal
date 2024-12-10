FROM ubuntu:14.04

ENV stalker_version 550
ENV stalker_zip ministra-5.5.0.zip

# إعداد بيئة غير تفاعلية
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# تحديث النظام وتثبيت الحزم الأساسية
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get install -y -u apache2 nginx memcached mysql-server php5 php5-mysql php-pear nodejs upstart npm php5-mcrypt openssh-client expect mysql-client unzip

# تثبيت Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# تثبيت Node.js و npm
RUN npm config set strict-ssl false
RUN npm install -g npm@2.15.11
RUN ln -s /usr/bin/nodejs /usr/bin/node

# تثبيت Phing
RUN pear channel-discover pear.phing.info
RUN pear install -Z phing/phing

# ضبط إعدادات MySQL
RUN echo "max_allowed_packet = 32M" >> /etc/mysql/my.cnf
RUN service mysql start && mysql -u root -e "GRANT ALL PRIVILEGES ON stalker_db.* TO stalker@localhost IDENTIFIED BY '1' WITH GRANT OPTION;" && mysql -u root -e "GRANT ALL PRIVILEGES ON stalker_db.* TO root@localhost IDENTIFIED BY '1' WITH GRANT OPTION;"

# إضافة ملفات Stalker Portal
COPY ${stalker_zip} /
RUN unzip ${stalker_zip} -d stalker_portal
RUN mv stalker_portal/* /var/www/stalker_portal
RUN rm -rf stalker_portal
RUN rm -rf ${stalker_zip}

# إعداد PHP و Apache
RUN php5enmod mcrypt
RUN echo "short_open_tag = On" >> /etc/php5/apache2/php.ini
RUN a2enmod rewrite
RUN a2enmod remoteip
RUN sed -i 's/Listen 80/Listen 88/' /etc/apache2/ports.conf

# إعداد قاعدة البيانات
RUN service mysql start && service memcached start && cd /var/www/stalker_portal/deploy/ && expect -c 'set timeout 9000; spawn phing; expect "Enter password:"; send "1\r"; expect eof;'

# نسخ ملفات التكوين
COPY conf/nginx/*.conf /etc/nginx/conf.d/
COPY conf/apache2/*.conf /etc/apache2/sites-available/
COPY conf/apache2/conf-available/*.conf /etc/apache2/conf-available/

# تمكين إعدادات Apache
RUN a2enconf remoteip

# إضافة script للتشغيل
COPY entrypoint.sh /

# فتح المنافذ اللازمة
EXPOSE 88
EXPOSE 80

# تنفيذ الـ entrypoint
ENTRYPOINT ["/entrypoint.sh"]
