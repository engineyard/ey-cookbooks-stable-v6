# Engine Yard Cloud v6 Chef Recipes

- This codebase and its cookbooks represent the latest version of Engine Yard's **`stable-v6-1.0`** stack.

## Dependencies

To upload and run the recipes from the CLI, you need the `ey-core` gem.

```
gem install ey-core
```

## Usage

1. Create the `cookbooks/` directory at the root of your application. If you prefer to keep the infrastructure code separate from application code, you can create a new repository.
2. For each custom cookbook that you want to use, do the following:
	- Create or edit `cookbooks/ey-custom/recipes/after-main.rb` and add the line:

	 ```
	 include_recipe 'custom-<recipe>'
	 ```
	- Create or edit `cookbooks/ey-custom/metadata.rb` and add the line `depends 'custom-<recipe>'`
		- prepend `name 'ey-custom'` to `cookbooks/ey-custom/metadata.rb` in case of a creation
	- Download this repository and copy `custom-cookbooks/<recipe>/cookbooks/custom-<recipe>` to `cookbooks`. For example, to use memcached, copy `custom-cookbooks/memcached/cookbooks/custom-memcached ` to `cookbooks/custom-memcached`.

3. To upload and apply the recipes, run

	```
	ey-core recipes upload --environment <nameofenvironment> --apply
	```

For more information about our V6 (Ubuntu 19.05) Stack, please see https://support.cloud.engineyard.com/hc/en-us/articles/360022162773-Engine-Yard-Stack-v6-Technology-Stack

## Contributing/Development

Please read our [Contributions Guidelines](https://github.com/engineyard/ey-cookbooks-stable-v5/blob/next-release/CONTRIBUTING.md).
