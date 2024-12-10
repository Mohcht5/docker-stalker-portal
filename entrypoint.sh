#!/bin/bash

echo "Starting Ministra/Stalker Portal setup for Koyeb..."

# نسخ ملفات التكوين
cp -f /opt/conf/nginx/*.conf /etc/nginx/conf.d/
cp -f /opt/conf/custom.ini /var/www/stalker_portal/server/

# ضبط المنطقة الزمنية
if [ -n "${TZ}" ]; then
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

# التأكد من تشغيل Nginx
service nginx start

echo "Setup completed. Starting Nginx server..."
while true; do
  if [ $(pgrep nginx | wc -l) -eq 0 ]; then
    echo "Nginx is not running. Starting..."
    service nginx start
  fi
  sleep 5
done
