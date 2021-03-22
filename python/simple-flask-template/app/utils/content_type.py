from functools import wraps

from flask import Response


def extend_content_type(f):
    """Add charset to content-type header."""
    @wraps(f)
    def decorated(*args, **kwargs):

        response = f(*args, **kwargs)
        if isinstance(response, Response):
            response.content_type += f';charset={response.charset}'
        return response
    return decorated
