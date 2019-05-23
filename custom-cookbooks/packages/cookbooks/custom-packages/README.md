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

### Install a package from a repository

To install a package from a different repository, you need to add the key and source to apt.
For example, to install yarn from their own repository, their instructions tell you to run the following commands on the command line
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

Instead of running those commands, you can use the recipe to add the key and source and to install the package.
1) add the URL of the gpg key to 'keys'
2) add the name and content of the apt source to 'apt_sources'
3) add the package to 'install'

```
default['packages'].tap do |packages|
  packages['keys'] = [
    {"url" => "https://dl.yarnpkg.com/debian/pubkey.gpg"}

    # adding the fingerprint is optional
    # if you add the fingerprint, the key will only be downloaded once
    # {"url" => "https://dl.yarnpkg.com/debian/pubkey.gpg", "fingerprint" => "23E7166788B63E1E"}
  ]

  packages['apt_sources'] = [
    {"name" => "yarn", "content" => "deb https://dl.yarnpkg.com/debian/ stable main"}
  ]

  packages['install'] = [
    {'name' => 'yarn'}
  ]
end
```
