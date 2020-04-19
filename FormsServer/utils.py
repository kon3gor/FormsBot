import pickle
import os.path
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request


SCOPES = ['https://www.googleapis.com/auth/spreadsheets.readonly']
SAMPLE_SPREADSHEET_ID = '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms'

def init():
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    service = build('sheets', 'v4', credentials=creds)

    return service


def getEmails(id):
    service = init()
    sheet = service.spreadsheets()
    result = sheet.values().get(spreadsheetId=id, range="A2:A").execute()

    values = result.get("values")
    result = []
    for mail in values:
        result.append(mail[0])

    return result

