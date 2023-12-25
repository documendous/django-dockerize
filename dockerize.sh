#!/usr/bin/env bash

MASTER_PROJECT_NAME="master-project"
PYTHON_VERSION="3.11.4"
DJANGO_PROJECT_NAME="myproject"
DB_NAME="myproject"
DB_USER="admin"
DB_PASS="admin"
VIRTUAL_ENV=".venv"

clear; reset;

function create_master_project() {
    echo "Re-creating $MASTER_PROJECT_NAME if exists ..."
    rm -rf $MASTER_PROJECT_NAME
    mkdir $MASTER_PROJECT_NAME
    echo "  Done"
}

function set_runtime() {
    echo "Setting runtime ..."
    echo "python-$PYTHON_VERSION" > runtime.txt
    echo "  Done"
}

function build_virtual_env() {
    echo "Building virtual environment ..."
    if python -m venv $VIRTUAL_ENV; then
        source $VIRTUAL_ENV/bin/activate
        echo "  Done"
    else
        echo "  Error: Failed to create the virtual environment."
        exit 1
    fi
}

function setup_pip() {
    echo "Setting up pip and pip-tools ..."
    if pip install --upgrade pip; then
        if pip install pip-tools; then
            cp -v ../files/requirements.in .
            echo "  Done"

            echo "Running pip-compile and installing packages ..."
            if pip-compile; then
                if pip-sync; then
                    echo "  Done"
                else
                    echo "  Error: Failed to sync packages."
                    exit 1
                fi
            else
                echo "  Error: Failed to compile requirements."
                exit 1
            fi
        else
            echo "  Error: Failed to install pip-tools."
            exit 1
        fi
    else
        echo "  Error: Failed to upgrade pip."
        exit 1
    fi
}


function create_django_project() {
    echo "Setting up Django project ..."
    django-admin startproject $DJANGO_PROJECT_NAME &&
    echo "  Done"
}

function add_env_files() {
    echo "Adding environment files ..."
    sed "s/\$DB_NAME/${DB_NAME}/g" ../files/.env.dev > .env.dev
    sed "s/\$DB_USER/${DB_USER}/g" .env.dev > .env.dev.tmp
    mv .env.dev.tmp .env.dev
    sed "s/\$DB_PASS/${DB_PASS}/g" .env.dev > .env.dev.tmp
    mv .env.dev.tmp .env.dev

    sed "s/\$DB_NAME/${DB_NAME}/g" ../files/.env.prod > .env.prod
    sed "s/\$DB_USER/${DB_USER}/g" .env.prod > .env.prod.tmp
    mv .env.prod.tmp .env.prod
    sed "s/\$DB_PASS/${DB_PASS}/g" .env.prod > .env.prod.tmp
    mv .env.prod.tmp .env.prod
    
    sed "s/\$DB_NAME/${DB_NAME}/g" ../files/.env.prod.db > .env.prod.db
    sed "s/\$DB_USER/${DB_USER}/g" .env.prod.db > .env.prod.db.tmp
    mv .env.prod.db.tmp .env.prod.db
    sed "s/\$DB_PASS/${DB_PASS}/g" .env.prod.db > .env.prod.db.tmp
    mv .env.prod.db.tmp .env.prod.db
    echo "  Done"
}

function add_docker_files() {
    echo "Adding docker-compose files ..."
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/docker-compose.yml > ./docker-compose.yml
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/docker-compose.prod.yml > ./docker-compose.prod.yml
    echo "  Done"

    echo "Adding Dockerfiles ..."
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/Dockerfile > $DJANGO_PROJECT_NAME/Dockerfile
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/Dockerfile.prod > $DJANGO_PROJECT_NAME/Dockerfile.prod
    echo "  Done"

    echo "Adding entrypoint files ..."
    cp -v ../files/entrypoint.* $DJANGO_PROJECT_NAME/.
    echo "  Done"
}

function setup_nginx() {
    echo "Setting up Nginx ..."
    mkdir nginx
    cp ../files/nginx/Dockerfile nginx/.
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/nginx/nginx.conf > nginx/nginx.conf
    echo "  Done"
}

function add_scripts() {
    echo "Additional scripts ..."
    cp ../files/createadmin.sh $DJANGO_PROJECT_NAME/.
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/setadminpw.py > $DJANGO_PROJECT_NAME/setadminpw.py
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/getdeps.sh > ./getdeps.sh
    chmod +x ./getdeps.sh
    cp ../files/dev-up.sh .
    cp ../files/prod-up.sh .
    echo "  Done"
}

function add_django_settings() {
    # echo 'STATIC_ROOT = BASE_DIR / "staticfiles"' >> $DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/settings.py
    sed "s/\$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/g" ../files/settings.py > $DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/settings.py
    echo "  Done"

}

function show_directions() {
    echo "Your Django project $MASTER_PROJECT_NAME should be set up with docker."
    echo "Now, cd into " $MASTER_PROJECT_NAME
    echo "Run source $VIRTUAL_ENV/bin/activate"
    echo "Run ./getdeps.sh"
    echo "And then run either (sudo) ./dev-up.sh or (sudo) ./prod-up.sh"
}

create_master_project;
cd $MASTER_PROJECT_NAME &&
set_runtime;
build_virtual_env;
setup_pip;
create_django_project;
add_env_files &&
add_docker_files &&
setup_nginx;
add_scripts &&
add_django_settings &&
show_directions;
