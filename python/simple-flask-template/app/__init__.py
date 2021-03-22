from flask import Flask
from flask_cors import CORS
from flask_featureflags import FeatureFlag
from flask_marshmallow import Marshmallow
from flask_restful import Api
from flask_sqlalchemy import SQLAlchemy
from healthcheck import HealthCheck

from app.utils.logging_util import configure_logging
from app.utils.password_util import decrypt_password, PasswordDecryptionError


app = Flask(__name__)
cors = CORS(app)
feature_flags = FeatureFlag(app)
db = SQLAlchemy()
ma = Marshmallow()


def app_factory(testing=False):
    """Initialise the flask app.

    Args:
        testing (bool): True if the app integration tests are running

    Returns:
        Flask: app instance

    """
    set_config()
    configure_logging(app)
    app.testing = testing
    define_routes()
    initialise_db()

    from app.utils.audit_util import configure_audit
    configure_audit(app)
    return app


def set_config(config_file='app.cfg'):
    """Parse config from file.

    Args:
        config_file (str): Name of config file.

    """
    app.config.from_pyfile(config_file)


def default_check():
    """Check health example."""
    return True, 'UP'


def define_routes():
    """Set up routes for API."""
    # Create API instance
    api = Api(app)

    # Import resources
    from app.api.{{ cookiecutter.package_name }} import {{ cookiecutter.resource_name }}Api
    from app.api.docs import SwaggerDocsApi

    # Register resources
    try:
        api.add_resource({{ cookiecutter.resource_name }}Api, '/v1/{{ cookiecutter.package_name }}/<string:resource_id>', methods=['GET', 'POST', 'DELETE'])
        api.add_resource(SwaggerDocsApi, '/v1/spec.json', methods=['GET'])
        health = HealthCheck(app, "/health")
        health.add_check(default_check)

    except AssertionError as e:
        if app.testing:
            # If we're testing we can ignore this error, as it is a warning about registering existing routes
            pass
        else:
            raise e


def initialise_db():
    """Initialise database connection pool for app (defaults to 5 connection)."""
    try:
        decrypted_pw = decrypt_password(app.config['DATABASE_PASSWORD'])
    except PasswordDecryptionError as e:
        if app.testing:
            decrypted_pw = None
        else:
            raise e

    postgres_uri = 'postgresql://{}:{}@{}:{}/{}?application_name={{ cookiecutter.project_name }}'.format(app.config['DATABASE_USER'],
                                                                                                         decrypted_pw,
                                                                                                         app.config['DATABASE_HOST'],
                                                                                                         app.config['DATABASE_PORT'],
                                                                                                         app.config['DATABASE_NAME'])
    app.config['SQLALCHEMY_DATABASE_URI'] = postgres_uri
    # Recommended setting explicitly to suppress deprecation warning
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
