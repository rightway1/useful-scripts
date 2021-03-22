from app import db, ma


class BaseSchema(ma.ModelSchema):
    """Base schema for all marshmallow DTOs."""

    class Meta:
        """Add the DB session to the meta class.

        This enables loading nested schemas from a
        single bit of JSON.
        """

        sqla_session = db.session
