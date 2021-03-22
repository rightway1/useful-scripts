from unittest.mock import Mock

from flask import Response

from app.utils.content_type import extend_content_type


def test_extend_content_type():

    # Arrange
    content_type = 'application/json'
    charset = 'utf-8'

    @extend_content_type
    def func():
        return Mock(spec=Response, content_type=content_type, charset=charset)

    # Act
    response = func()

    # Assert
    assert response.content_type == content_type + ';charset=' + charset


def test_extend_content_type_does_nothing_when_not_flask_response():

    # Arrange
    mock_response = Mock()

    @extend_content_type
    def func():
        return mock_response

    # Act
    response = func()

    # Assert
    assert response == mock_response
