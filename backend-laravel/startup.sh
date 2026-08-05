#!/bin/sh
set -e

cat > /etc/nginx/sites-enabled/default <<'EOF'
server {
    listen 8080;
    server_name _;

    root /home/site/wwwroot/public;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_index index.php;
        fastcgi_pass 127.0.0.1:9000;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx start 2>/dev/null || nginx
exec php-fpm
