## shared_db

This recipe symlinks the `database.yml` file from one application to another in a multiple-application environment.

## Installation

For simplicity, we recommend that you create the cookbooks directory at the root of your application. If you prefer to keep the infrastructure code separate from application code, you can create a new repository.

To use the `shared_db` recipe, you should copy this recipe, `shared_db`.

1. Edit `cookbooks/ey-custom/recipes/after-main.rb` and add

  ```
  include_recipe 'shared_db'
  ```

2. Edit `cookbooks/ey-custom/metadata.rb` and add

  ```
  depends 'shared_db'
  ```

3. Copy `custom-cookbooks/shared_db/cookbooks/shared_db` to `cookbooks/`

  ```
  cd ~ # Change this to your preferred directory. Anywhere but inside the application

  git clone https://github.com/engineyard/ey-cookbooks-stable-v6
  cd ey-cookbooks-stable-v6
  cp custom-cookbooks/shared_db/cookbooks/shared_db /path/to/app/cookbooks/
  ```

4. Download the ey-core gem on your local machine and upload the recipes

  ```
  gem install ey-core
  ey-core recipes upload --environment=<nameofenvironment> --file=<pathtocookbooksfolder> --apply
  ```

## Customizations

All customizations go to `cookbooks/shared_db/attributes/default.rb`.

### Applications involved

Modify the `app` and `parent_app` variables accordingly. `app` is an array of applications that you wish to write the shared database configuration to while `parent_app` is the name of the application with db credentials you want to use.
