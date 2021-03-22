from marshmallow import fields

from app.models.dtos.{{ cookiecutter.package_name }}.base_dto import BaseSchema


class {{ cookiecutter.resource_name }}Schema(BaseSchema):
    """Marshmallow schema for {{ cookiecutter.package_name }} model."""

    id = fields.Str()
