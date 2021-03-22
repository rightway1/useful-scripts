from logging import Filter
from logging.config import dictConfig

import flask
from pythonjsonlogger.jsonlogger import JsonFormatter


def configure_logging(app):
    """Configure the logging.

    This boils down to a mix of
    * http://flask.pocoo.org/docs/1.0/logging/#basic-configuration

    """
    if app.config.get('USE_JSON_LOGGING', False):
        formatter_class = "app.utils.logging_util.CustomJsonFormatter"
    else:
        formatter_class = "logging.Formatter"

    dictConfig({
        'version': 1,
        'filters': {
            'add_correlation_id': {
                '()': 'app.utils.logging_util.AddCorrelationIdFilter',
            },
        },
        'formatters': {
            'default': {
                'format': '%(asctime)s.%(msecs)03d %(levelname)8s %(process)5d --- [%(thread)s] %(name)-30s : [%(correlation_id)s] %(message)s',
                'datefmt': '%Y-%m-%d %H:%M:%S',
                "()": formatter_class,
            }
        },
        'handlers': {
            'wsgi': {
                'class': 'logging.StreamHandler',
                'stream': 'ext://flask.logging.wsgi_errors_stream',
                'formatter': 'default',
                'filters': ['add_correlation_id'],
            }
        },
        'root': {
            'level': app.config.get('LOG_LEVEL', 'DEBUG'),
            'handlers': ['wsgi']
        }
    })


class AddCorrelationIdFilter(Filter):
    """A log filter class that populate record's correlation IDs."""

    def filter(self, record):
        """Add a correlation_id field to log records when possible."""
        from .audit_util import get_correlation_id

        # A correlation_id is available only when we're in a request_context.
        if flask.has_request_context():
            record.correlation_id = get_correlation_id()
        else:
            record.correlation_id = ""

        return True


class CustomJsonFormatter(JsonFormatter):
    """A formatter class that issues single-line JSON log messages."""

    def process_log_record(self, log_record):
        """Override the JsonFormatter method to rename a few fields.

        Rename log record fields:
            * `thread` -> `tid`
            * `process` -> `pid`
            * `levelname` -> `log_level`
        """
        log_record["tid"] = log_record.pop('thread', None)
        log_record["pid"] = log_record.pop('process', None)
        log_record["log_level"] = log_record.pop('levelname', None)
        log_record["asctime"] += ".%03d" % log_record.pop("msecs", 0)
        return super().process_log_record(log_record)
