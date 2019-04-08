# env_vars

This recipe is used to upload  `/data/app_name/shared/config/env.custom` and  `/data/app_name/shared/config/env.cloud` files on the stable-v6 stacks. These files are used to load environment variables for the web application; the V6 scripts for Passenger, Unicorn, Puma, as long as Sidekiq were written to source these files on startup.

Environment Variables added [via dashboard](https://support.cloud.engineyard.com/hc/en-us/articles/360007661794-Environment-Variables-and-How-to-Use-Them) are included into `env.cloud` file. Environment Variables added via `custom-env_vars` recipe are included into `env.custom` file.

The `env_vars` recipe is managed by Engine Yard. You should not copy this recipe to your repository but instead copy custom-env_vars. Please check the [custom-env_vars readme](../../custom-cookbooks/env_vars/cookbooks/custom-env_vars) for the complete instructions.

We accept contributions for changes that can be used by all customers.
