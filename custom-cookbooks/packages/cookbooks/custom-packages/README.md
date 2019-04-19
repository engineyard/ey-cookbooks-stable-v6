## custom-packages

This is a wrapper cookbook for the `packages` recipe. This is designed to help you customize what packages will be installed on your environment without having to modify the `packages` recipe.

## Installation

For simplicity, we recommend that you create the cookbooks directory at the root of your application. If you prefer to keep the infrastructure code separate from application code, you can create a new repository.

Our main recipes have the `packages` recipe but it is not included by default. To use the `packages` recipe, you should copy this recipe, `custom-packages`. You should not copy the actual `packages` recipe. That is managed by Engine Yard.

1. Edit `cookbooks/ey-custom/recipes/after-main.rb` and add

  ```
  include_recipe 'custom-packages'
  ```

2. Edit `cookbooks/ey-custom/metadata.rb` and add

  ```
  depends 'custom-packages'
  ```

3. Copy `custom-cookbooks/packages/cookbooks/custom-packages` to `cookbooks/`

  ```
  cd ~ # Change this to your preferred directory. Anywhere but inside the application

  git clone https://github.com/engineyard/ey-cookbooks-stable-v6
  cd ey-cookbooks-stable-v6
  cp custom-cookbooks/packages/cookbooks/custom-packages /path/to/app/cookbooks/
  ```

4. Download the ey-core gem on your local machine and upload the recipes

  ```
  gem install ey-core
  ey-core recipes upload --environment=<nameofenvironment> --file=<pathtocookbooksfolder> --apply
  ```

## Customizations

All customizations go to `cookbooks/custom-packages/attributes/default.rb`.

### Install a package

To install a package, modify the `install` array inside `default['packages']`:

```
default['packages'].tap do |packages|
  packages['install'] = [
    {'name' => "sphinxsearch", 'version' => "2.2.11-2"},
    {'name' => "wkhtmltopdf"}
  ]
end
```
