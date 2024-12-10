#!/bin/bash

# إعداد ملفات التهيئة
cp -f /opt/conf/nginx/*.conf /etc/nginx/conf.d/
cp -f /opt/conf/apache2/*.conf /etc/apache2/sites-available/
cp -f /opt/conf/apache2/conf-available/*.conf /etc/apache2/conf-available/
cp -f /opt/conf/custom.ini /var/www/stalker_portal/server/

# ضبط المنطقة الزمنية
if [ -n "${TZ}" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
fi

# استعادة قاعدة البيانات الافتراضية
if [ $(ls /var/lib/mysql | wc -l) -eq 0 ]; then
    echo "Copying default DB schema to /var/lib/mysql"
    cp -rf /root/mysql_default/* /var/lib/mysql/
    chown -R mysql:mysql /var/lib/mysql
fi

# بدء MySQL وإعداد القاعدة إذا لزم الأمر
service mysql start
if [ $(ls /opt/conf/mysql/*.sql | wc -l) -eq 1 ]; then
    echo "Restoring dump to stalker_db database..."
    sqldump=$(ls -t /opt/conf/mysql/*.sql | head -n 1)
    mysql -u stalker -p1 -e 'DROP DATABASE stalker_db;'
    mysql -u stalker -p1 -e 'CREATE DATABASE stalker_db;'
    mysql -u stalker -p1 stalker_db < $sqldump
    rm -f $sqldump
fi

# تشغيل الخدمات الضرورية
services=(mysql memcached cron apache2 nginx)
while true; do
    for service in "${services[@]}"; do
        if [ $(pgrep $service | wc -l) -eq 0 ]; then
            echo "Service $service is not running. Starting it..."
            if [ "$service" != "cron" ]; then
                service $service start
            else
                cron
            fi
        fi
    done
    sleep 5
done
