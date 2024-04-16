"""
File: greeterCrud.py

Description: Workflow support layer for the greeterApi

Known Issues:
- None
"""

from .models import ReqHelloPerson


class GreeterCrud:
    """This class performs CRUD operations as a service layer for our API"""

    def set_hello_message(self, person: ReqHelloPerson) -> dict:
        """Utility function to generate name"""
        if person.last_name is None:
            person.last_name = "None"
        name = f"{person.first_name} {person.last_name}"
        return {"Hello": name}
