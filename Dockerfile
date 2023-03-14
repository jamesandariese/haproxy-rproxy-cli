FROM haproxy

USER 0
VOLUME /tls

RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

