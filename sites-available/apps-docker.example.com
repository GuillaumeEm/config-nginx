server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name  public-facing-service.example.com;

    include sites-additional-conf/security.conf;
    include sites-additional-conf/general.conf;

    location / {
        proxy_pass      http://172.1.1.1:9000;
    }
}
