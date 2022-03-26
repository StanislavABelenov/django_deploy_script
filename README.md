# django_deploy_script
Small script for the django project deploy in clear server

## Quick start
```sh
wget https://raw.githubusercontent.com/kosty1301/django_deploy_script/main/django_deploy.sh
```
```sh
sudo chmod +x django_deploy.sh
```
```sh
./django_deploy.sh <url for your git repo...>
```
### Use this script only on a clean server otherwise you may lose your nginx settings!
* the old nginx configuration will be moved to the home directory
## Support
* Ubuntu 18.04 LTS (tested)
