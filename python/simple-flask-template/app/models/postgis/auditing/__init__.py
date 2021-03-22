"""SQLAlchemy models for the auditing tables."""

from app import db


class Auditing(db.Model):
    """ORM for auditing.api_audit table."""

    __tablename__ = 'api_audit'
    __table_args__ = {'schema': 'auditing'}

    id = db.Column(db.BigInteger, primary_key=True)
    # Let this use the column default.
    # request_date = db.Column(db.Date)
    referring_service = db.Column(db.String(25))
    request_type = db.Column(db.String(6))
    request_path = db.Column(db.Text)
    header_in = db.Column(db.Text)
    header_out = db.Column(db.Text)
    payload_in = db.Column(db.Text)
    payload_out = db.Column(db.Text)
    response_code = db.Column(db.SmallInteger)
    exception_msg = db.Column(db.Text)
    correlation_id = db.Column(db.Text)

    def __repr__(self):
        """Printable representation of Auditing object."""
        return '<Auditing_id {}>'.format(self.id)
