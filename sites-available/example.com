# redirect https
server {
    listen 80;
    server_name example.com *.example.com;

    location /.well-known/acme-challenge {
        root /var/www/letsencrypt;
    }
    rewrite ^ https://$server_name$request_uri? permanent;
}

# HTTPS server

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com *.example.com;

    root /var/www/example.com/www;
    include sites-additional-conf/security.conf;
    include sites-additional-conf/general.conf;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.html index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }


    error_page 404 /index.php;

    location ~ ^(/_matrix|/_synapse/client) {
        # note: do not add a path (even a single /) after the port in `proxy_pass`,
        # otherwise nginx will canonicalise the URI and cause signature verification
        # errors.
        proxy_pass http://172.16.0.0:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;

        # Nginx by default only allows file uploads up to 1M in size
        # Increase client_max_body_size to match max_upload_size defined in homeserver.yaml
        client_max_body_size 50M;
    }

    location ~ \.php$ {
	    include sites-additional-conf/fastcgi.conf;
    }
}

server {
        listen 8448 ssl;
        listen [::]:8448 ssl;
        server_name example.com;

        location / {
            proxy_pass http://172.16.0.0:8008;
            proxy_set_header X-Forwarded-For $remote_addr;
        }
}



server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name sub.example.com;

    root /var/www/example.com/sub;
    index index.html index.htm;
    include sites-additional-conf/security.conf;
    include sites-additional-conf/general.conf;

    location / {
        try_files $uri $uri/ /index.html;
    }
    location ~ \.php$ {
		include sites-additional-conf/fastcgi.conf;
	}
}
