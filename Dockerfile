# الأساس: استخدام إصدار مدعوم
FROM ubuntu:20.04

# إعداد متغيرات البيئة
ENV stalker_version 550
ENV stalker_zip ministra-5.5.0.zip

# تثبيت الحزم الأساسية
RUN apt-get update && apt-get install -y \
    nginx \
    php \
    php-mysql \
    unzip \
    curl \
    wget \
    locales \
    && apt-get clean

# إعداد اللغات
RUN for i in ru_RU.utf8 en_GB.utf8; do locale-gen $i; done \
    && dpkg-reconfigure locales

# تثبيت Ministra/Stalker
COPY ${stalker_zip} /
RUN unzip ${stalker_zip} -d stalker_portal \
    && mv stalker_portal/* /var/www/stalker_portal \
    && rm -rf stalker_portal ${stalker_zip}

# نسخ ملفات الإعدادات
COPY conf/nginx/*.conf /etc/nginx/conf.d/
COPY conf/custom.ini /var/www/stalker_portal/server/

# تهيئة نقطة الإقلاع
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# فتح المنافذ
EXPOSE 80

# نقطة الإقلاع
ENTRYPOINT ["/entrypoint.sh"]
