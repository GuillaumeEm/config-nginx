server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name phpapp.example.com;

    root /var/www/example.com/apps/phpapp;
    include sites-additional-conf/security.conf;
    include sites-additional-conf/general.conf;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location ~ \.php$ {
	    include sites-additional-conf/fastcgi.conf;
    }
}
