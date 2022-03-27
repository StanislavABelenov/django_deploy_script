 #!/bin/bash
cd ~
clear
if [ -z "$1" ]; then
        echo "Please start script like this - $0 https://github.com/username/project_name.git"
exit 1
fi

if [$whoami eq "root"];then
 echo "Do not run this script with root privileges"
  exit 1
   fi

# update system
        echo "System update..."
        sudo apt update >> /dev/null 2>&1 -y && sudo apt upgrade -y >> /dev/null 2>&1

# set locale
        echo "Set locale..."
        sudo sed '/# ru_RU.UTF-8 UTF-8/s/^#//' -i /etc/locale.gen
        sudo locale-gen >> /dev/null 2>&1

# install packages
        echo "install packages..."
        sudo apt install net-tools python3-pip python3-venv git nginx -y >> /dev/null 2>&1

# clone your repository
        echo "Clone your repository..."
        git clone $1 >> /dev/null 2>&1

# deploy virtual environment
        echo "Activate you environment..."
        path=$(basename $1 | sed -r 's/\..+//')
        cd $path
        python3 -m venv venv >> /dev/null 2>&1
        source venv/bin/activate

# install requirements
        echo "install requirements..."
        if [[ -e requirements.txt ]]  ;then
                pip3 install -r requirements.txt >> /dev/null 2>&1
        else
                echo "requirements.txt is lost, you can install requirements later.."
        fi

# install and configure gunicorn
        echo "install and configure gunicorn"
        pip3 install gunicorn >> /dev/null 2>&1

manage_py=$(readlink -e $(find -name  manage.py))
path_to_manage_py=$($manage_py| sed s/manage.py//)/

# make migrations
        echo "make migrations"
        $manage_py makemigrations >> /dev/null 2>&1
        $manage_py migrate >> /dev/null 2>&1

# create unit for systemd
        echo "create gunicorn unit for systemd"
        echo "
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=$(whoami)

WorkingDirectory=$(readlink -e $(find -name  manage.py | sed s/manage.py//))/

ExecStart=$(pwd)/venv/bin/gunicorn --bind 127.0.0.1:8000 $(cat $(find -name settings.py) | grep WSGI_APPLICATION | sed 's|.*= ||' | tr -d \'  | sed s/.application/:application/)

[Install]
WantedBy=multi-user.target" > gunicorn.service


sudo chmod +x gunicorn.service
sudo mv gunicorn.service /etc/systemd/system/

# configure nginx
        echo "configure nginx"
        sudo mv /etc/nginx/sites-enabled/default ~/nginx_default_old
        sudo echo "
server {
    listen 80;
    server_name $(ip -o -4 addr show eth0 | awk '{ split($4, ip_addr, "/"); print ip_addr[1] }');

    location /static/ {
        root $(readlink -e $(find -name  manage.py | sed s/manage.py//))/;
    }

    location /media/ {
        root $(readlink -e $(find -name  manage.py | sed s/manage.py//))/;
    }

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
    }
}" > default
        sudo mv default /etc/nginx/sites-enabled/
# start service
        echo "Start gunicorn and nginx service"
        sudo systemctl daemon-reload
        sudo systemctl enable gunicorn
        sudo systemctl start gunicorn
        sudo systemctl restart nginx
echo "successful"
