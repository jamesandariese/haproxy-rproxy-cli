#!/bin/sh

set -x
set -e

printf 'arg: "%s"\n' "$@"

mkdir -p /tls

if ! [ -f /tls/tls.crt ];then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tls/tls.crt.key -out /tls/tls.crt.crt -subj "/CN=*"
  cat /tls/tls.crt.key /tls/tls.crt.crt > /tls/tls.crt && chown 99:99 /tls/*
fi

N=0

CENTRAL="
global
  stats socket /tmp/api.sock user haproxy group haproxy mode 660 level admin expose-fd listeners
  log stdout format raw local0 info
  user haproxy
  group haproxy

defaults
  mode http
  timeout client 10s
  timeout connect 5s
  timeout server 10s
  timeout http-request 10s
  log global

frontend stats
  bind 127.0.0.1:8404
  stats enable
  stats uri /
  stats refresh 10s

backend no-match
  http-request deny deny_status 404

frontend websesprecious
  bind :80
  bind :443 ssl crt /tls/tls.crt
  http-request redirect scheme https unless { ssl_fc }
  default_backend no-match"

BACKENDS=""
CBACKEND=""

while [ $# -gt 0 ];do
  N=$(( N + 1 ))
  FQDN="${1%%:*}"
  HOST="${FQDN%%.*}"
  SLUG="$HOST$(echo $HOST | sha256sum | tr 0-9 Q-Z | tr a-z A-Z | cut -c 1-8)"
  CFG="${1#*:}"
  SERVER="$SLUG$N"
  BACKEND="$SLUG"

  if [ x"$CBACKEND" != x"$BACKEND" ];then
    CENTRAL="$CENTRAL
  use_backend $BACKEND if { hdr(host) -i -m dom $FQDN }"
    BACKENDS="$BACKENDS

backend $BACKEND"
  fi

  BACKENDS="$BACKENDS
  server $SERVER $CFG"
  CBACKEND="$BACKEND"
  shift
done

echo "$CENTRAL
$BACKENDS" > /usr/local/etc/haproxy/haproxy.cfg

exec haproxy -W -db -f /usr/local/etc/haproxy/haproxy.cfg
