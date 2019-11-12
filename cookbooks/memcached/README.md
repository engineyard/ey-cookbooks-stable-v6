# Memcached

This recipe is used to run memcached on the stable-v6 stack.
It is managed by Engine Yard. 

## Installation

### Environment Variables

When the environment variable `EY_MEMCACHED_ENABLED` is set to "true", this recipe will be enabled and set up Memcahced on a utility instance named `memcached` by default.

### Custom Chef

Since this is an optional recipe, it can be installed by simply including it via a `depends` in your `ey-custom/metadata.rb` file and an `include_recipe` in the appropriate hook file.
You should not copy this recipe to your repository but instead copy custom-memcached. Please check the [custom-memcached readme](../../custom-cookbooks/memcached/cookbooks/custom-memcached) for the complete instructions.

## Contributing

We accept contributions for changes that can be used by all customers.
