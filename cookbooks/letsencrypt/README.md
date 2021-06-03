**letsencrypt**
==========

This installs and sets up the optional LetsEncrypt recipe on the engineyard stack. 


**Installation**
=========

**Prerequisites**

* Have a [certificate](https://support.cloud.engineyard.com/hc/en-us/articles/205407488-Obtain-and-Install-SSL-Certificates-for-Applications#topic8) applied to the [environment](https://support.cloud.engineyard.com/hc/en-us/articles/205407488-Obtain-and-Install-SSL-Certificates-for-Applications#topic12) 


**Environment Variables**

There are several environmental variables needed to be used with the LetsEncrypt recipe. To enable the recipe set `EY_LETSENCRYPT_ENABLED` to `TRUE`. This will install certbot on all application instances

To automatically create a certificate or SAN certiciate:

* Make sure a certificate is applied to the environment using the documentation above. This certificate will be for configuration reasons only and not seen by visitors, so can be a self-signed one, with a name that highlights letsencrypt's use, e.g. `using-letsencrypt`
* Set the environmental variable `EY_LE_MAIN_DOMAIN` as your main domain e.g. `Engineyard.com`
* Set the environment variable `EY_LE_DOMAINS` with any additional domains seperated with a space. The main domain **must** come first e.g. `Engineyard.com www.Engineyard.com Example.com`




**Notes**

* If you're using a multi-application environment setup set the variable `EY_LE_MAIN_APP_NAME` to the application you wish to use LetsEncrypt with
* `www` is not included so you may wish to use `www.example.com` and `example.com`


**Upcoming Changes**

Wildcard integration
