#!/bin/sh

iptables -t nat -A POSTROUTING -j MASQUERADE

ocserv -f -d 3