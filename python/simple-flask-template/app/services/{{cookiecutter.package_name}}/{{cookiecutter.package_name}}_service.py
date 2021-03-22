from app.models.postgis.{{ cookiecutter.package_name }} import {{ cookiecutter.resource_name }}


class {{ cookiecutter.resource_name }}Service:
    """Service for API."""

    def get_resource(self, resource_id):
        """Get {{ cookiecutter.resource_name }}."""
        return {{ cookiecutter.resource_name }}(resource_id)

    def create_resource(self, resource_id):
        """Create {{ cookiecutter.resource_name }}."""
        return self.get_resource(resource_id)

    def delete_resource(self, resource_id):
        """Delete {{ cookiecutter.resource_name }}."""
        pass
