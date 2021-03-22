from flask import jsonify, make_response
from flask_restful import Resource

from app.models.dtos.{{ cookiecutter.package_name }}.{{ cookiecutter.package_name }}_dto import {{ cookiecutter.resource_name }}Schema
from app.services.{{ cookiecutter.package_name }}.{{ cookiecutter.package_name }}_service import {{ cookiecutter.resource_name }}Service
from app.utils.auth_util import authenticate
from app.utils.content_type import extend_content_type
from app.utils.error_util import handle_exception


class {{ cookiecutter.resource_name }}Api(Resource):
    """{{ cookiecutter.resource_name }} API."""

    method_decorators = [handle_exception, authenticate, extend_content_type]

    def get(self, resource_id=None):
        """
        Get {{ cookiecutter.resource_name }}.

        Returns the {{ cookiecutter.resource_name }}.
        ---
        tags:
          - Get {{ cookiecutter.resource_name }}
        produces:
          - application/json
        parameters:
          - name: authorization
            in: header
            description: Bearer token
            example: Bearer <your-token-here>
            required: true
            type: string
          - name: correlation-id
            in: header
            description: Optional request correlation-id
            example: c9f45437-aead-407b-bb1a-debedfa0d0db
            required: false
            type: string
          - name: resource_id
            in: path
            description: Resource ID to retrieve
            example: ABC123
            required: true
            type: string
        responses:
          200:
            description: Resource description
          404:
            description: Resource not found
          403:
            description: Access denied
          500:
            description: Internal Server Error

        """
        resource = {{ cookiecutter.resource_name }}Service().get_resource(resource_id)
        resource_json = {{ cookiecutter.resource_name }}Schema().dump(resource)
        response = make_response(jsonify(resource_json.data))
        return response

    def post(self, resource_id=None):
        """
        Create {{ cookiecutter.resource_name }}.

        Returns the created {{ cookiecutter.resource_name }}.
        ---
        tags:
          - Create {{ cookiecutter.resource_name }}
        produces:
          - application/json
        parameters:
          - name: authorization
            in: header
            description: Bearer token
            example: Bearer <your-token-here>
            required: true
            type: string
          - name: correlation-id
            in: header
            description: Optional request correlation-id
            example: c9f45437-aead-407b-bb1a-debedfa0d0db
            required: false
            type: string
          - name: resource_id
            in: path
            description: Resource ID to create
            example: ABC123
            required: true
            type: string
        responses:
          201:
            description: Resource description
          404:
            description: Resource not found
          403:
            description: Access denied
          500:
            description: Internal Server Error

        """
        resource = {{ cookiecutter.resource_name }}Service().create_resource(resource_id)
        resource_json = {{ cookiecutter.resource_name }}Schema().dump(resource)
        response = make_response(jsonify(resource_json.data), 201)
        return response

    def delete(self, resource_id=None):
        """
        Delete {{ cookiecutter.resource_name }}.

        Returns 204 no content
        ---
        tags:
          - Delete {{ cookiecutter.resource_name }}
        parameters:
          - name: authorization
            in: header
            description: Bearer token
            example: Bearer <your-token-here>
            required: true
            type: string
          - name: correlation-id
            in: header
            description: Optional request correlation-id
            example: c9f45437-aead-407b-bb1a-debedfa0d0db
            required: false
            type: string
          - name: resource_id
            in: path
            description: Resource ID to delete
            example: ABC123
            required: true
            type: string
        responses:
          204:
            description: No Content
          404:
            description: Resource not found
          403:
            description: Access denied
          500:
            description: Internal Server Error

        """
        {{ cookiecutter.resource_name }}Service().delete_resource(resource_id)
        response = make_response('', 204)
        return response
