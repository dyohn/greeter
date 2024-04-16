# File: greeterApi.py
#
# Description: A collection of endpoints for various styles of greetings
#
# Known Issues:
# - None

from fastapi import FastAPI

from . import GreeterCrud
from .models import ReqHelloPerson

app = FastAPI()

crud = GreeterCrud()


@app.get("/")
def hello(person: ReqHelloPerson):
    """Endpoint to say hello to the provided person"""
    return crud.set_hello_message(person)
