#!/bin/bash

# Update system packages and install Nginx
apt update
apt install -y nginx

# Install necessary network tools
apt --no-install-recommends -y install iputils-ping mtr traceroute

# Add PHP repository and install PHP 8.2 along with required extensions
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
apt update -y
apt -y install php8.2 php8.2-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} nginx

# Set up Nginx configuration for Looking Glass
cd /var/www/html
git clone https://github.com/Clashplayer-PROTECT/lookingglass-only-ipv6.git
cd lookingglass-only-ipv6

# Remove default Nginx configurations
cd /etc/nginx/sites-available/
rm -f default
cd /etc/nginx/sites-enabled/
rm -f default

# Create a new Nginx configuration for Looking Glass
echo 'server {
    listen 80;
    listen [::]:80 ipv6only=on;
    server_name lg-demo.com;  # Replace with your domain name

    root /var/www/html/lookingglass-only-ipv6/;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;  # Ensure the socket path is correct
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    error_log  /var/log/nginx/lookingglass-error.log;
    access_log /var/log/nginx/lookingglass-access.log;
   sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100m;
    server_tokens off;
    gzip on;
    open_file_cache max=100;

}' | sudo tee /etc/nginx/sites-available/lg.conf

# Enable the new Nginx configuration
ln -s /etc/nginx/sites-available/lg.conf /etc/nginx/sites-enabled/
systemctl restart nginx

cd /var/www/
echo "Ready"
