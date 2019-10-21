FROM ubuntu
RUN apt-get update \
	&& apt-get install -y cron socat
RUN apt-get -y install --no-install-recommends wget gnupg ca-certificates \
	&& wget https://openresty.org/package/pubkey.gpg \
	&& apt-key add pubkey.gpg \
	&& rm pubkey.gpg \
	&& apt-get -y install --no-install-recommends software-properties-common \
	&& add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
	&& apt-get update \
	&& apt-get install -y openresty 
RUN ln -s /usr/local/openresty/nginx/logs/error.log /var/log/error.log
COPY nginx.conf /opt/luarestyaccess.site/
COPY sites-enabled /opt/luarestyaccess.site/
COPY ssl /opt/luarestyaccess.site/
COPY lua /opt/luarestyaccess.site/
RUN ln -s /opt/luarestyaccess.site/lua /etc/openresty/lua \
	&& ln -s /opt/luarestyaccess.site/ssl /etc/openresty/ssl \
	&& ln -s /opt/luarestyaccess.site/sites-enabled /etc/openresty/sites-enabled \
	&& rm /etc/openresty/nginx.conf \
	&& ln -s /opt/luarestyaccess.site/nginx.conf /etc/openresty/nginx.conf
RUN opm get supereldar/lua-resty-access
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
