haproxy
========

Installs and configures haproxy for application server instances (app and app_master).

Environment Variable :

EY_HEALTHCHECK_DOMAIN_OVERRIDE : By Default this recipe picks up first entry from nginx vhost. This ENV can be used to override the health-check domain in case there are wildcrd/reged in nginx vhosts