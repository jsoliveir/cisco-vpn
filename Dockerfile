# https://github.com/wppurking/ocserv-docker
FROM alpine:latest

RUN apk update && apk add \
    gnutls-utils readline-dev libnl3-dev \
    musl-dev iptables gnutls-dev \
    lz4-dev libseccomp-dev \ 
    libev-dev radcli-dev

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

WORKDIR /etc/ssl
COPY ssl/ .
# generate [ca]
RUN certtool --generate-privkey --outfile /etc/ssl/ca-key.pem \
    && certtool \
    --generate-self-signed \
    --load-privkey /etc/ssl/ca-key.pem \
    --outfile /etc/ssl/tls.crt \
    --template /etc/ssl/ca.tpl

# generate [ca + server]
RUN certtool --generate-privkey --outfile key.pem \
    && certtool \
    --generate-certificate \
    --load-privkey key.pem \
    --load-ca-certificate /etc/ssl/tls.crt \
    --load-ca-privkey /etc/ssl/ca-key.pem \
    --template /etc/ssl/server.tpl \
    --outfile /etc/ssl/tls.key 

WORKDIR /etc/ocserv
COPY startup.sh /bin/startup
RUN chmod +x /bin/startup
CMD [ "startup" ]