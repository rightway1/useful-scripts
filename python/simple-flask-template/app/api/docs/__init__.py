from flask import jsonify, make_response, current_app
from flask_restful import Resource
from flask_swagger import swagger

from app import app


class SwaggerDocsApi(Resource):
    """Swagger Spec API."""

    def get(self):
        """Endpoint to expose swagger docs JSON.

        To be consumed by Swagger-UI app.

        Returns:
            Json for Swagger

        """
        swag = swagger(app)
        swag['info']['version'] = "1.0"
        swag['info']['title'] = "{{ cookiecutter.resource_name }} API"
        swag['basePath'] = current_app.config.get('BASE_PATH', '')
        response = make_response(jsonify(swag))
        return response
