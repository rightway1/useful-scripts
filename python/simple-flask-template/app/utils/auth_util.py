from functools import wraps

from flask import request, current_app
from flask_restful import abort

from app.utils.audit_util import set_referring_service
from app.utils.password_util import decrypt_password, PasswordDecryptionError


def authenticate(f):
    """Handle authentication on behalf of decorated request handlers."""
    @wraps(f)
    def decorated(*args, **kwargs):

        bearer_token = request.headers.get('authorization')

        try:
            credentials = current_app.config['CREDENTIALS']
            valid_tokens = {decrypt_password(token): referrer for token, referrer in credentials.items()}

            assert bearer_token in valid_tokens

            set_referring_service(valid_tokens.get(bearer_token))

        except (AssertionError, PasswordDecryptionError):
            abort(403)

        return f(*args, **kwargs)

    return decorated
