**letsencrypt**
==========

This installs and sets up the optional LetsEncrypt recipe on the engineyard stack. 


**Installation**
=========

**Prerequisites**

* Have a [certificate](https://support.cloud.engineyard.com/hc/en-us/articles/205407488-Obtain-and-Install-SSL-Certificates-for-Applications#topic8) applied to the [environment](https://support.cloud.engineyard.com/hc/en-us/articles/205407488-Obtain-and-Install-SSL-Certificates-for-Applications#topic12) 

* Have the application deployed successfully

**Environment Variables**

There are several environmental variables needed to be used with the LetsEncrypt recipe. To enable the recipe set `EY_LETSENCRYPT_ENABLED` to `TRUE`. This will install certbot on all application instances


**SAN Certificate Setup**

To automatically create a certificate or SAN certiciate:

* Make sure a certificate is applied to the environment using the documentation above. This certificate will be for configuration reasons only and not seen by visitors, so can be a self-signed one, with a name that highlights letsencrypts use, e.g. `using-letsencrypt`
* Set the environment variable `EY_LE_DOMAINS` with any additional domains seperated with a space. The main domain **must** come first e.g. `Engineyard.com www.Engineyard.com Example.com`
* 


**Wildcard Certificate Setup**

To automatically create a wildcard certificate

* Make sure a certificate is applied to the environment using the documentation above. This certificate will be for configuration reasons only and not seen by visitors, so can be a self-signed one, with a name that highlights letsencrypts use, e.g. `using-letsencrypt`
* Set the environment variable `EY_LE_DOMAINS` with the domain you wish to set up e.g. `*.engineyard.com`
* Set the environment variable `EY_LE_USE_WILDCARD` to `TRUE`
* Set the environment variable `EY_LE_DNS_TYPE` to one of the supported DNS providers listed below
* Set the environemnt variable `EY_LE_DNS_AUTH_INFO` to the API information for said DNS provider. The formatting can be found under the third party documentation link


**Notes**

* If you're using a multi-application environment setup set the variable `EY_LE_MAIN_APP_NAME` to the application you wish to use LetsEncrypt with

* `www` is not included so you may wish to use `www.example.com` and `example.com` if you're using a SAN certificate

* Route53 provider (AWS). Requires the custom variable `AWS_CONFIG_FILE` to be set as `/opt/.letsencrypt-secrets`


**Supported DNS Providers**

* cloudflare - https://certbot-dns-cloudflare.readthedocs.io/en/stable/

* cloudxns - https://certbot-dns-cloudxns.readthedocs.io/en/stable/

* digitalocean - https://certbot-dns-digitalocean.readthedocs.io/en/stable/

* dnsimple - https://certbot-dns-dnsimple.readthedocs.io/en/stable/

* dnsmadeeasy - https://certbot-dns-dnsmadeeasy.readthedocs.io/en/stable/

* gehirn - https://certbot-dns-gehirn.readthedocs.io/en/stable/

* google - https://certbot-dns-google.readthedocs.io/en/stable/

* linode - https://certbot-dns-linode.readthedocs.io/en/stable/

* luadns - https://certbot-dns-luadns.readthedocs.io/en/stable/

* nsone - https://certbot-dns-nsone.readthedocs.io/en/stable/

* ovh - https://certbot-dns-ovh.readthedocs.io/en/stable/

* rfc2136 - https://certbot-dns-rfc2136.readthedocs.io/en/stable/

* route53 - https://certbot-dns-route53.readthedocs.io/en/stable/

* sakuracloud - https://certbot-dns-sakuracloud.readthedocs.io/en/stable/
