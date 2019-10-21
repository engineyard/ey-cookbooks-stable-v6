# Configuration Via Environment Variables

Many features in an Engine Yard Cloud stable-v6 environment can now be enabled
and configured via [environment variables](https://support.cloud.engineyard.com/hc/en-us/articles/360007661794).

This makes working with the Engine Yard Cloud platform much easier and 
removes the need for custom Chef recipes in many cases.

A list of supported settings is documented in the next section.
If you are missing a setting, please request it by [opening a GitHub issue](https://github.com/engineyard/ey-cookbooks-stable-v6/issues/new).

## Supported Settings

| Environment Variable            | Default Value | Description                                                                                             |
| ------------------------------- | ------------- | ------------------------------------------------------------------------------------------------------- |
| `EY_RUBY_VERSION`               | N/A           | Sets the exact version of Ruby. (e.g. "2.7.0-preview1")                                                 |
| `EY_ENABLE_UNATTENDED_UPGRADES` | `false`       | Enables periodic security upgrades via Ubuntu's unattended-upgrades.                                    |
| `EY_REDIS_ENABLED`              | `false`       | Sets up Redis. [More details here](./cookbooks/redis/README.md#environment-variables)                   |
| `EY_REDIS_VERSION`              | N/A           | Sets a custom version for Redis. [More details here](./cookbooks/redis/README.md#environment-variables) |
| `EY_MEMCACHED_ENABLED`          | `false`       | Sets up Memcached. [More details here](./cookbooks/memcached/README.md#environment-variables)           |

## Contribution Guidelines

The usual [contribution guidelines](./CONTRIBUTING.md) apply.

Additionally, please adhere to the following specific rules:
1. Use the `fetch_env_var` helper in `cookbooks/ey-lib/libraries/env_vars.rb`
2. Add "enabled" flags logic to `cookbooks/ey-base/recipes/custom.rb`
3. Binary flags need to match against `/^TRUE$/i`
4. Make sure the default core cookbooks attributes are sensible defaults
5. Introduce additional variables to configure **important** settings as you see fit
6. Keep the naming of the variables consistent
   1. Variables must be prefixed with `EY_`
   2. Variable names should be declarative in nature (`EY_SOMETHING_ENABLED` rather than `EY_ENABLE_SOMETHING`)
7. Document every new variable introduced in the [section above](#supported-variables).
   If the variable needs further documentation, put it in a separate file and link to it from the description column
