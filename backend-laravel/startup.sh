#!/bin/sh
set -e

# Override konfigurasi nginx bawaan Azure App Service agar semua request
# yang bukan file fisik diteruskan ke Laravel (public/index.php).
cat > /etc/nginx/sites-enabled/default <<'EOF'
server {
    listen 8080;
    listen [::]:8080;
    server_name _;

    root /home/site/wwwroot/public;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Validasi lalu MUAT ULANG nginx. Init container Azure sudah menjalankan
# nginx + php-fpm, jadi cukup reload konfigurasi baru (bukan start/exec).
nginx -t
nginx -s reload 2>/dev/null || service nginx reload 2>/dev/null || service nginx restart
