from flask import Flask, request
from utils import *
import json

app = Flask("__name__")

@app.route("/loadSheet", methods=["POST"])
def loadSheet():
    try:
        key = json.loads(request.data)["key"]
        emails = getEmails(key)
        return {"emails": emails}
    except Exception as e:
        print(e)
    return "hello world"
