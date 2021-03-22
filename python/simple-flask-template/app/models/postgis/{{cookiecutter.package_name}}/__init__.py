class {{ cookiecutter.resource_name }}(object):
    """ORM/sqlalchemy in real life."""

    def __init__(self, id):
        """Constructor."""
        self.id = id

    def __repr__(self):
        """Printable representation of {{ cookiecutter.resource_name }} object."""
        return '<name {}>'.format(self.id)
