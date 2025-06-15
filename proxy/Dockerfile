FROM httpd
COPY --chmod=664 nextcloud.conf /usr/local/apache2/conf/nextcloud.conf
COPY --chmod=664 collabora.conf /usr/local/apache2/conf/collabora.conf
RUN set -ex; \
    sed -i \
            -e '/^Listen /d' \
            -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
            -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
            -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
            -e 's/^#\(LoadModule .*mod_headers.so\)/\1/' \
            -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
            -e 's/^#\(LoadModule .*mod_proxy_wstunnel.so\)/\1/' \
            -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        /usr/local/apache2/conf/httpd.conf; \
    echo "Include conf/collabora.conf" | tee -a /usr/local/apache2/conf/httpd.conf; \
    echo "Include conf/nextcloud.conf" | tee -a /usr/local/apache2/conf/httpd.conf;