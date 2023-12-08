#!/bin/bash

set -e

MYSQL_DATABASE=$1
MYSQL_USERNAME=$2
MYSQL_PASSWORD=$3

PROJECT_DIR="/var/www/html/personal-blog/backend"

# make dir if not exists (first deploy)
mkdir -p $PROJECT_DIR

cd $PROJECT_DIR

git config --global --add safe.directory $PROJECT_DIR

# the project has not been cloned yet (first deploy)
if [ ! -d $PROJECT_DIR"/.git" ]; then
  GIT_SSH_COMMAND='ssh -i /home/stanko/.ssh/id_rsa -o IdentitiesOnly=yes' git clone https://github.com/Stanko172/personal-blog-backend.git .
else
  GIT_SSH_COMMAND='ssh -i /home/stanko/.ssh/id_rsa -o IdentitiesOnly=yes' git pull
fi

composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# initialize .env if does not exist (first deploy)
if [ ! -f $PROJECT_DIR"/env" ]; then
    cp .env.example .env
    sed -i "/DB_DATABASE/c\DB_DATABASE=$MYSQL_DATABASE" $PROJECT_DIR"/.env"
    sed -i "/DB_USERNAME/c\DB_USERNAME=$MYSQL_USERNAME" $PROJECT_DIR"/.env"
    sed -i "/DB_PASSWORD/c\DB_PASSWORD=$MYSQL_PASSWORD" $PROJECT_DIR"/.env"
    sed -i '/QUEUE_CONNECTION/c\QUEUE_CONNECTION=database' $PROJECT_DIR"/.env"
    php artisan key:generate
fi

sudo chown -R www-data:www-data $PROJECT_DIR

php artisan storage:link
php artisan optimize:clear

php artisan down

php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan up
