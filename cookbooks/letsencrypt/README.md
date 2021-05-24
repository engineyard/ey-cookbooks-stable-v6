**letsencrypt**
==========

This installs and sets up the optional LetsEncrypt recipe on the engineyard stack. 


**Installation**
=========

**Prerequisites**

* Have a [certificate](https://support.cloud.engineyard.com/hc/en-us/articles/205407488-Obtain-and-Install-SSL-Certificates-for-Applications#topic8) applied to the [environment](https://support.cloud.engineyard.com/hc/en-us/articles/205407488-Obtain-and-Install-SSL-Certificates-for-Applications#topic12). 


**Environment Variables**

There are several environmental variables needed to be used with the LetsEncrypt recipe. To enable the recipe set `EY_LETSENCRYPT_ENABLED` to `TRUE`. This will install certbot on all application instances.

To automatically create a certificate or SAN certiciate:

* Set the following environmenta variables. `EY_LE_MAIN_DOMAIN` as your main domain e.g. `Engineyard.com` 
* Set the environment variable `EY_LE_DOMAINS` with any additional domains seperated with a space. The main domain **must** come first e.g. `Engineyard.com Example.com`.




**Notes**

* Upon a takeover you will need to run the two final steps if you're using a wildcard certificate
* If you're using a multi-application environment setup. Set the variable `EY_LE_MAIN_APP_NAME` to the application you wish to use LetsEncrypt with.


**Upcoming Changes**

Wildcard integration
