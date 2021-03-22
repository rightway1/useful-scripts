import traceback
from functools import wraps

import flask_featureflags as feature
from flask import current_app, g as flask_g
from werkzeug.exceptions import BadRequest

from app.exceptions import NotFound


def handle_exception(f):
    """Handle exceptions on behalf of decorated request handlers."""
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            return f(*args, **kwargs)

        except Exception as ex:

            flask_g.exception_msg = traceback.format_exc()

            current_app.logger.exception(ex)

            if isinstance(ex, NotFound):
                return {'Error': ex.args[0]}, 404
            if isinstance(ex, BadRequest):
                return {'Error': ex.description}, 400

            return {'Error': ex.args[0] if feature.is_active('propagates_exception') else 'Internal Server Error'}, 500

    return decorated
