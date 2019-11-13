# custom-snaps-removal

The sidekiq Cookbook creates a sidekiq script that runs Sidekiq and a monit
config file. Each application on the environment will get its own sidekiq
workers.

You need to add the sidekiq gem to your app.

## Installation

For simplicity, we recommend that you create the `cookbooks/` directory at the
root of your application. If you prefer to keep the infrastructure code separate
from application code, you can create a new repository.

Our main recipes have the `sidekiq` Cookbook but it is not included by default.
To use the `sidekiq` cookbook, you should copy this cookbook
`custom-sidekiq`. You should not copy the actual `sidekiq` recipe as
this is managed by Engine Yard.

1. Edit `cookbooks/ey-custom/recipes/after-main.rb` and add

    include_recipe 'custom-sidekiq'

2. Edit `cookbooks/ey-custom/metadata.rb` and add

    depends 'custom-sidekiq'

3. Copy `custom-cookbooks/sidekiq/cookbooks/custom-sidekiq` to `cookbooks/`

    cd ~ # Change this to your preferred directory. Anywhere but inside the
         # application

    git clone https://github.com/engineyard/ey-cookbooks-stable-v6
    cd ey-cookbooks-stable-v6
    cp custom-cookbooks/sidekiq/cookbooks/custom-sidekiq /path/to/app/cookbooks/

	If you do not have `cookbooks/ey-custom` on your app repository, you can copy
`custom-cookbooks/sidekiq/cookbooks/ey-custom` to `/path/to/app/cookbooks` as well.

4. Create or modify `config/initializers/sidekiq.rb`:

```
redis_config = YAML.load_file(Rails.root + 'config/redis.yml')[Rails.env]

Sidekiq.configure_server do |config|
  config.redis = {
    url: "redis://#{redis_config['host']}:#{redis_config['port']}"
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "redis://#{redis_config['host']}:#{redis_config['port']}"
  }
end
```

The above code parses `config/redis.yml` to determine the Redis host. If you're using the [Redis recipe](https://github.com/engineyard/ey-cookbooks-stable-v6/tree/next-release/custom-cookbooks/redis), it creates a `/data/<app_name>/shared/config/redis.yml` for you.

During deployment, the file `/data/<app_name>/current/config/redis.yml` is automatically symlinked to `/data/<app_name>/shared/config/redis.yml`.
