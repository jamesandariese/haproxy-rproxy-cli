A reverse proxy config generator for haproxy (that also runs haproxy)

This generates a very basic config for those who don't need a non-basic config.

To use with docker-compose:
```
version: '3'

services:
  server:
    image: quay.io/jamesandariese/haproxy-rproxy-cli:0.0.1
    restart: always
    network_mode: host
    command:
     - plex.contoso.com:192.168.1.2:32400
     - minio.contoso.internal:10.1.1.3:53713
```
