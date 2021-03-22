import requests

RESOURCE_ID = 'fake-resource-id'


def test_api_get(external_app):

    # Act
    app, root = external_app
    response = requests.get(root + 'v1/{{cookiecutter.package_name}}/' + RESOURCE_ID, headers={'authorization': 'Bearer mytoken'})
    response_dict = response.json()

    # Assert
    assert response.status_code == 200
    assert response_dict['id'] == RESOURCE_ID


def test_api_post(external_app):

    # Act
    app, root = external_app
    response = requests.post(root + 'v1/{{cookiecutter.package_name}}/' + RESOURCE_ID, headers={'authorization': 'Bearer mytoken'})
    response_dict = response.json()

    # Assert
    assert response.status_code == 201
    assert response_dict['id'] == RESOURCE_ID


def test_api_delete(external_app):

    # Act
    app, root = external_app
    response = requests.delete(root + 'v1/{{cookiecutter.package_name}}/' + RESOURCE_ID, headers={'authorization': 'Bearer mytoken'})

    # Assert
    assert response.status_code == 204
    assert len(response.content) == 0
