"""
File: 

Description:

Known Issues:
- 
"""

from pydantic import BaseModel, Field


class ReqHelloPerson(BaseModel):
    """A wrapper object for details of who to greet."""

    first_name: str = Field(alias="firstName", default=None)
    last_name: str = Field(alias="lastName", default=None)
