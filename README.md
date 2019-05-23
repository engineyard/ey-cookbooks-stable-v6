## Basic stuff

Consult [Cooking V6 spreadsheet](https://docs.google.com/spreadsheets/d/1-21XaN8wVH1KAmeyv-jwfOIzZemYQU1a7ywgd6VgqfA/edit#gid=0) for the latest update on V6 cookbooks.

Chef recipes' structure on V6 is identical to V5 one. The repository is divided into `cookbooks` and `custom-cookbooks` directories and custom recipes have to be included into `cookbooks/ey-custom/metadata.rb` and `cookbooks/ey-custom/recipes/after-main.rb`. There is a single chef run executing the main recipes and then the custom ones defined on files above.


Consider the following before starting porting/QAing recipes:

- Use account [EngineyardCookbooksQA](https://cloud.engineyard.com/admin/accounts/EngineyardCookbooksQA) for testing 
- Use `US East (N. Virginia)` region.
- Use `TODO` app. This app requires DB.
- Use `stable-v6 1.0` stack, use latest stack release.


*REMEMBER TO STOP/TERMINATE YOUR INSTANCES ONCE TESTING IS DONE*

*Remember to log time spent on Cookbooks on a ZD ticket (internal) to keep your stats healthy*

### Need to run chef with recipes modified locally on instance?

```
/opt/chef/embedded/bin/chef-solo -j /etc/chef/dna.json -c /etc/chef/solo.rb > /var/log/chef.manual.log 2>&1
```

## Ready to commit changes?

Clone this repo:

```
git clone https://github.com/engineyard/ey-cookbooks-dev-v6
cd ey-cookbooks-dev-v6
```

Create new branch and checkout:

```
git branch <new-branch>
git checkout <new-branch>
```

**STOP! Make changes to files before proceeding to next step**

Push/commit/push:

```
git push -u origin <new-branch>
git commit -a -m "helpful message" 
git push
```

Create Pull Request:

- This has to be done against `next-release` branch
- Ping Dimitris to merge


 

## Info - Help
For any issue you may encounter reach the following people:

1. Dimitris Dalianis
2. Johann Fueschl
3. Christopher Rigor




 
