from app.services.{{ cookiecutter.package_name }}.{{ cookiecutter.package_name }}_service import {{ cookiecutter.resource_name }}Service

RESOURCE_ID = 'fake-resource-id'


def test_get_resource():
    # Act
    result = {{ cookiecutter.resource_name }}Service().get_resource(RESOURCE_ID)

    # Assert
    assert result.id == RESOURCE_ID


def test_create_resource():
    # Act
    result = {{ cookiecutter.resource_name }}Service().create_resource(RESOURCE_ID)

    # Assert
    assert result.id == RESOURCE_ID


def test_delete_resource():
    # Act
    result = {{ cookiecutter.resource_name }}Service().delete_resource(RESOURCE_ID)

    # Assert
    assert result is None
