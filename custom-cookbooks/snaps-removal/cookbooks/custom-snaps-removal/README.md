# custom-snaps-removal

The Cookbook places and runs a bash script which will unmount and remove any snaps.

## Installation

For simplicity, we recommend that you create the `cookbooks/` directory at the
root of your application. If you prefer to keep the infrastructure code separate
from application code, you can create a new repository.

1. Edit `cookbooks/ey-custom/recipes/after-main.rb` and add

```
include_recipe 'custom-snaps-removal'
```

2. Edit `cookbooks/ey-custom/metadata.rb` and add

```
depends 'custom-snaps-removal'
```

3. Copy `custom-cookbooks/snaps-removal/cookbooks/custom-snaps-removal` to `cookbooks/`

```
cd ~ # Change this to your preferred directory. Anywhere but inside the application

git clone https://github.com/engineyard/ey-cookbooks-stable-v6
cd ey-cookbooks-stable-v6
cp custom-cookbooks/snaps-removal/cookbooks/custom-snaps-removal /path/to/app/cookbooks/
```

If you do not have `cookbooks/ey-custom` on your app repository, you can copy
`custom-cookbooks/snaps-removal/cookbooks/ey-custom` to `/path/to/app/cookbooks` as well.
