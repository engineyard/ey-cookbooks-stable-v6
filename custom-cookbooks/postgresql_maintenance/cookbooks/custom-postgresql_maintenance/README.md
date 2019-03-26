# custom-postgresql_maintenance

This is a wrapper cookbook around Engine Yard's `postgresql_maintenance` cookbook.  It allows customization of the cronjob that weekly vacuum all databases.

## Installation

For simplicity, we recommend that you create the cookbooks directory at the root
of your application. If you prefer to keep the infrastructure code separate from
application code, you can create a new repository.

Our main cookbook have the `postgresql_maintenance` cookbook but it is not included by default.
To use the `postgresql_maintenance` cookbook, you should copy this cookbook, `custom-postgresql_maintenance`.
You should not copy the actual `postgresql_maintenance` recipe. That is managed by Engine
Yard.

1. Edit `cookbooks/ey-custom/recipes/after-main.rb` and add

  ```
  include_recipe 'custom-postgresql_maintenance'
  ```

2. Edit `cookbooks/ey-custom/metadata.rb` and add

  ```
  depends 'custom-postgresql_maintenance'
  ```

3. Copy `custom-cookbooks/packages/cookbooks/custom-postgresql_maintenance` to `cookbooks/`

  ```
  cd ~ # Change this to your preferred directory. Anywhere but inside the application

  git clone https://github.com/engineyard/ey-cookbooks-stable-v5
  cd ey-cookbooks-stable-v5
  cp custom-cookbooks/packages/cookbooks/custom-postgresql_maintenance /path/to/app/cookbooks/
  ```

4. Download the ey-core gem on your local machine and upload the recipes

  ```
  gem install ey-core
  ey-core recipes upload --environment=<nameofenvironment> --file=<pathtocookbooksfilder> --apply
  ```

## Customizations

All customizations go to `cookbooks/custom-postgresql_maintenance/attributes/default.rb`.

```
default['postgresql_maintenance']['vacuumdb_cron_minute'] = '0'
default['postgresql_maintenance']['vacuumdb_cron_hour'] = '0'
default['postgresql_maintenance']['vacuumdb_cron_day'] = '*'
default['postgresql_maintenance']['vacuumdb_cron_month'] = '*'
default['postgresql_maintenance']['vacuumdb_cron_weekday'] = '0'

# this will vacuum all dbs
default['postgresql_maintenance']['vacuumdb_command'] = '/usr/bin/vacuumdb -U postgres --all'
```
