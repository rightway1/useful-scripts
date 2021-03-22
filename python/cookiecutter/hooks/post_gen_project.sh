#!/usr/bin/env bash

# Create virtual environment
source ~/.local/bin/virtualenvwrapper.sh
mkvirtualenv -a $(pwd) -r requirements.txt --python=/usr/bin/python3.6 {{cookiecutter.project_name}}

# freeze requirements
pip freeze > requirements.txt

# initialise local git repo
chmod +x .githooks/{pre-commit,pre-push}
git init
git config core.hooksPath .githooks
git add .
git commit -m "Initial cookiecutter project generation"
git remote add origin git@mygitrepo/python/simple-flask-template/{{cookiecutter.project_name}}.git
git push --set-upstream origin master
