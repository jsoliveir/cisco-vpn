# https://github.com/wppurking/ocserv-docker
FROM alpine:latest

RUN apk update && apk add musl-dev iptables gnutls-dev gnutls-utils readline-dev libnl3-dev lz4-dev libseccomp-dev libev-dev

RUN buildDeps="xz openssl gcc autoconf make linux-headers"; \
	set -x \
	&& apk add $buildDeps \
	&& wget http://ocserv.gitlab.io/www/download.html -O download.html \
	&& OC_VERSION=`sed -n 's/^.*The latest version of ocserv is \(.*\)$/\1/p' download.html` \
    && OC_FILE="ocserv-${OC_VERSION}" \
	&& wget https://www.infradead.org/ocserv/download/$OC_FILE.tar.xz \
	&& tar xJf $OC_FILE.tar.xz && rm -fr $OC_FILE.tar.xz \
	&& cd $OC_FILE && ./configure && make && make install \
	&& rm -rf ./$OC_FILE && apk del --purge $buildDeps

WORKDIR /etc/ocserv
COPY templates/ certs/

# generate [ca]
RUN certtool --generate-privkey --outfile certs/ca-key.pem \
    && certtool \
    --generate-self-signed \
    --load-privkey certs/ca-key.pem \
    --outfile certs/ca-cert.pem \
    --template certs/ca.tpl

# generate [ca + server]
RUN certtool --generate-privkey --outfile key.pem \
    && certtool \
    --generate-certificate \
    --load-privkey key.pem \
    --load-ca-certificate certs/ca-cert.pem \
    --load-ca-privkey certs/ca-key.pem \
    --template certs/server.tpl \
    --outfile cert.pem 

COPY startup.sh /usr/local/bin/startup
RUN chmod +x /usr/local/bin/startup

ENTRYPOINT [/usr/local/bin/startup]