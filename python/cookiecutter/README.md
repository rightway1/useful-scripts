# Cookiecutter Python Microservice Generator

## Purpose
This [cookiecutter](https://github.com/audreyr/cookiecutter) generates a starter flask-restul / marshmallow-sqlalchemy project.

### Included in the starter
- Authentication
- Error handling
- Cryptography
- Feature flags
- Configurable Logging
- Configurable Auditing
- Swagger spec endpoint: `/v1/spec.json`
- Healthcheck endpoint: `/health`
- Sample CRUD resource endpoints: `/v1/resource/<resource_id>`
- Layered architecture example
- Example pytest unit test
- Example pytest integration test
- PEP8 Linter: `flake8`
- Example configuration
- Dockerfile and docker entry point script
- Build and Deployment Pipeline code
- Build Pipeline linting
- Build Pipeline unit tests
- Build Pipeline docker image push to registry
- Build Pipeline gitlab tag of master branch builds
- Deployment Pipeline integration tests

## Development Setup

Dependencies:
- Python 3.6.x
- virtualenvwrapper
- cookiecutter

### Create a new project, initialise a git repo and create a virtualenv
```
sudo apt install cookiecutter
cookiecutter git@mygitrepo/cookiecutter-api.git
```

### Answer prompts
You can leave all defaults and change them later once the project is generated.
- `resource_name`: what resource name will this REST endpoint mainly deal with?
- `package_name`: will be derived from resource_name but you have a say.
- `project_name`: as above.
- `external_port`: Host port mapped at docker run time.

At this point:
- A new project has been generated in your current directory.
- A git repo has been initialised for the new project.
- A virtualenv has been created, named after `project_name`, associated with the project directory and all dependencies pip installed.

### Activate the virtualenv, check PEP8, run tests.
```
workon <project_name>
export CRYPTO_KEY=<find it in keepass>
flake8
pytest
```
## Run local docker container
After cloning this repo, from its project root directory run
```
$ docker-compose up --build
```

### Run the API.
```
workon <project_name>
export CRYPTO_KEY=<find it in keepass>
export FLASK_APP=autoapp.py
flask run --port=5000
```
The starter service will serve:
- GET http://localhost:5000/v1/spec.json
- [GET|POST|DELETE] http://localhost:5000/v1/package_name/anything

### Problems?
Most likely the post_gen hook is unhappy with your virtualenv arrangements. You can clone this repo, delete the hook (post_gen_project.sh) and run cookiecutter from your local machine rather than gitlab.
```
git clone git@mygitrepo/cookiecutter-api.git
rm cookiecutter-api/hooks/post_gen_project.sh
cookiecutter cookiecutter-api
```

