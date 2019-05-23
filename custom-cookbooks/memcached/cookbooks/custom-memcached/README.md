# Memcached

The memcached cookbook installs memcached and monitors it with monit. A `/data/app_name/shared/config/memcached.yml` is generated for each application on the environment.

You need to add a memcached client to your app.

## Installation

For simplicity, we recommend that you create the `cookbooks/` directory at the
root of your application. If you prefer to keep the infrastructure code separate
from application code, you can create a new repository.

Our main recipes have the `memcached` cookbook but it is not included by default.
To use the `memcached` cookbook, you should copy the cookbook
`custom-memcached`. You should not copy the actual `memcached` recipe as
that is managed by Engine Yard.

  1. Edit `cookbooks/ey-custom/recipes/after-main.rb` and add

  ```
    include_recipe 'custom-memcached'
  ```

  2. Edit `cookbooks/ey-custom/metadata.rb` and add

  ```
    depends 'custom-memcached'
  ```

  3. Copy `custom-cookbooks/memcached/cookbooks/custom-memcached` to `cookbooks/`

  ```
    cd ~ # Change this to your preferred directory. Anywhere but inside the
         # application

    git clone https://github.com/rupikakapoor/ey-cookbooks-dev-v6.git
    cd ey-cookbooks-dev-v6
    cp custom-cookbooks/memcached/cookbooks/custom-memcached /path/to/app/cookbooks/
  ```

  4. Download the ey-core gem on your local machine and upload the recipes

  ```
    gem install ey-core
    ey-core recipes upload --environment=<nameofenvironment> --file=<pathtocookbooksfolder> --apply
  ```

## Customizations

All customizations go to `cookbooks/custom-memcached/attributes/default.rb`.

### Choose the instances that run the recipe

By default, the recipe runs on a utility instance named 'memcached'. This is configured in `attributes/default.rb`. This will run the memcached daemon on the utility instance named 'memcached' and create a `/data/appname/shared/config/memcached.yml` file that points to the private IP of the memcached instance.

```
  # Install memcached on a utility instance named 'memcached'
  memcached['install_type'] = 'NAMED_UTILS'
  memcached['utility_name'] = 'memcached'
```

To install memcached on all app instances, comment out the block above and set `memcached['install_type']` to 'ALL_APP_INSTANCES'. This will run the memcached daemon on all app instances and create a `/data/appname/shared/config/memcached_custom.yml` file that points to the private IPs of all the app instances. The memcache client will be responsible for sharding the data across all the instances running memcached

```
  # Install memcached on all app instances
  #memcached['install_type'] = 'ALL_APP_INSTANCES'
```

To install memcached in a solo environment, use the set `install_type` to `ALL_APP_INSTANCES`.

_NOTE: This recipe does not uninstall memcached. If you use the ALL\_APP\_INSTANCES install\_type, then switch to NAMED\_UTILS, memcached will still be installed and running on the app instances. You can uninstall memcached on the app instances by running `monit stop memcached && rm /etc/monit.d/memcached.monitrc && sleep 30 && monit reload`._

### Adjust memory usage

```
  # Amount of memory in MB to be used by memcached
  memcached['memusage'] = 1024
```

### Adjust the growth factor

```
  # Increase the growth factor.
  # Try this if you allocated more memory to memcached
  # and you're seeing lots of partially-filled slabs
  # memcached['misc_opts'] = '-f 1.5'
  # See https://blog.engineyard.com/2015/fine-tuning-memcached
```

## Running on multiple instances

The recipe will create a `memcached.yml` for you. This contains the list of hostnames of the memcached instances. It is up to you to parse this configuration file and initialize your memcached client accordingly - please consult your memcached client's documentation.

If you have a running memcached cluster and add a new memcached node, (e.g. `memcached['install_type'] = 'ALL_APP_INSTANCES'` and you add a new app instance), the recipe will update `memcached.yml` for you but you need to restart the application to load the new `memcached.yml`.

## Restarting your application

This recipe does NOT restart your application. The reason for this is that shipping
your application and rebuilding your instances (i.e. running chef) are not
always done at the same time. It is best to restart your application
when you ship (deploy) your application code.

