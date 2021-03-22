"""Functions related to auditing.

The data and metadata of the incoming requests and outgoing responses will be
inserted in the audit table of the database.

So far, we only deal with these queries that make it to our route handlers (queries
to route that do not exist, or that have the wrong VERB, etc., are not seen here).
"""

from uuid import uuid4

import flask_featureflags as audit_method
from flask import current_app, g as flask_g, request

from app.models.postgis.auditing import Auditing

CORRELATION_ID_HEADER = "Correlation-Id"
DUMMY_CORRELATION_ID = "00000000-0000-0000-0000-000000000000"


def configure_audit(app):
    """Configure the auditing.

    :param app: the flask application, of type flask.Flask
    :return: None
    """
    # Obtain a correlation ID as soon as possible
    app.before_request(_obtain_correlation_id)

    # The function that will record the request in the audit database:
    # this needs to be the last thing that does anything with the query,
    # else we will not record everything that is sent.
    app.after_request_funcs.setdefault(None, []).insert(0, _record_audit_information)
    # The function that will inject the correlation ID header
    app.after_request(_add_correlation_id_header)


def _obtain_correlation_id():
    """Create/reuse and store a correlation_id for the request.

    This is meant to be executed only once, presumably as part of a before_request()
    hook.  This function stores a correlation_id for the current request.  This can
    either be one provided by the client (by way of the Correlation-Id" heaader), or
    generated here.

    :return: None
    """
    # This should be called once.
    if flask_g.get("correlation_id"):
        #
        # We should ideally raise an exception here, but the testing framework
        # fails when we do so, as before_request() does not work the same way
        # during tests...
        #
        # raise Exception("A correlation ID has already been created.")
        flask_g.get("correlation_id")

    # Temporarily use a dummy value here, so as to avoid recursion if an exception
    # is triggered below: the logger calls the present function -- if the present
    # function calls the logger without care, we're in trouble.
    flask_g.correlation_id = DUMMY_CORRELATION_ID

    flask_g.correlation_id = request.headers.get(CORRELATION_ID_HEADER, str(uuid4()))


def _add_correlation_id_header(response):
    """Add a correlation ID to the response.

    :param response: the response to modify, of type response_class()
    :return: the same response, with the correlation ID header added.
    """
    correlation_id = get_correlation_id()
    response.headers[CORRELATION_ID_HEADER] = correlation_id
    return response


def get_correlation_id():
    """Return the current correlation ID.

    The function _create_correlation_id must have been called first.

    :return: a correlation-ID, of type string
    """
    if flask_g.get("correlation_id"):
        return flask_g.get("correlation_id")
    else:
        # We need a dummy correlation ID before anything gets logged.
        flask_g.correlation_id = DUMMY_CORRELATION_ID
        raise Exception("A correlation ID has NOT been created yet.")


def get_referring_service():
    """Get the current referring service."""
    return flask_g.get("referring_service")


def set_referring_service(referrer):
    """Set the current referring service.

    Called during authentication to globally store the referrer
    """
    current_app.logger.debug("Setting referring service to '%s'" % referrer)
    flask_g.referring_service = referrer


def _record_audit_information(response):
    """Update the audit db table to record the current request.

    :param response: the response to modify, of type response_class()
    :return: the same response, unmodified.
    """
    if not audit_method.is_active(request.method):
        current_app.logger.debug("Skipping audit record for method '%s'" % request.method)
        return response
    else:
        current_app.logger.debug("Filling audit record for method '%s'" % request.method)

    from app import db
    try:
        record = Auditing()
        # Add any exception that may have occurred.
        record.exception_msg = str(flask_g.get("exception_msg"))
        # Add the correlation ID.
        record.correlation_id = get_correlation_id()
        # Add referring service
        record.referring_service = flask_g.get("referring_service")
        # Add request data to the record
        _fill_in_request(record)
        # Add response data to the record
        _fill_in_response(record, response)
        # The current session (db.session) may be in a broken state, so we're better off
        # creating a new session.  Luckily, sessions carry their factory around.
        session = db.session.session_factory()
        session.add(record)
        session.commit()
    except Exception:
        current_app.logger.exception("Failed to record auditing information")
    return response


def _fill_in_request(record):
    """Fill in the audit record fields corresponding to the current request."""
    # record_id = db.Column(db.BigInteger, primary_key=True)
    # request_date = db.Column(db.Date)
    # referring_service = db.Column(db.String(25))
    record.request_type = request.method
    record.request_path = request.full_path
    record.header_in = str(request.headers)
    payload_in = request.get_data(as_text=True)
    if payload_in:
        record.payload_in = payload_in


def _fill_in_response(record, response):
    """Fill in the audit record fields corresponding to the current response."""
    record.header_out = str(response.headers)
    if response.is_json:
        payload_out = response.get_data(as_text=True)
        if payload_out:
            record.payload_out = payload_out
    record.response_code = response.status_code
