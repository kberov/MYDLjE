#Example nginx configuration for MYDLjE.
#Add the something like the following to your /etc/hosts file
#127.0.0.2    example.com www.example.com cpanel.example.com mydlje.example.com
#Modify this file as you need and put it in nginx conf directory.
#Run the applications you need:
#./cpanel daemon --listen "http://127.0.0.1:8081"
#./site daemon --listen "http://127.0.0.1:8082"
#restart nginx.

###################
upstream mydlje {
    server 127.0.0.1:8080;
}

server {
  listen 81;
  server_name mydlje.example.com;
  root /home/krasi/opt/public_dev/MYDLjE;
  index index.xhtml;
  
  location ~ ^(/conf/|/log/|/perl/|/tmp/|/templates/) {
    deny all;
  }
  location /pub {
    autoindex off;  
    expires 86400;
  }
  location /index.xhtml {
  allow 127.0.0.1;
  #or allow 192.168.0.0/16;
  #just for installation
  #root /home/krasi/opt/public_dev/MYDLjE;
  }
  
  location / {
    proxy_read_timeout 300;
    proxy_pass http://mydlje ;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
###########################
upstream cpanel {
    server 127.0.0.1:8081;
}

server {
  listen 81;
  server_name cpanel.example.com;
  root /home/krasi/opt/public_dev/MYDLjE;
  location ~ ^(/conf/|/log/|/perl/|/tmp/|/templates/) {
    deny all;
  }
  location /pub {
    autoindex off;
    expires 86400;
  }

  location / {
    proxy_read_timeout 300;
    proxy_pass http://cpanel;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

}
###################
upstream site {
    server 127.0.0.1:8082;
}

server {
  listen 81;
  server_name example.com www.example.com www.example.org example.org;
  root /home/krasi/opt/public_dev/MYDLjE;
  index index.html index.htm;
  location ~ ^(/conf/|/log/|/perl/|/tmp/|/templates/) {
    deny all;
  }
  location /pub {
    autoindex off;
    expires 86400;
  }

  location / {
    proxy_read_timeout 300;
    proxy_pass http://site;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
