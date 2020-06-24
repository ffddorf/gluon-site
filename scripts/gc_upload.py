#!/usr/bin/env python3
#Arguments:
#argv[1] = bucket name
#argv[2] = remote path
#argv[3] = local file

from sys import argv, stderr
from os import environ
from json import loads as json_loads
from pathlib import Path
from gcloud import storage
from oauth2client.service_account import ServiceAccountCredentials

if not len(argv) < 4:
  if 'GOOGLE_AUTH' in environ:
    credentials_dict = json_loads(environ['GOOGLE_AUTH'])
    credentials = ServiceAccountCredentials.from_json_keyfile_dict(credentials_dict)
    client = storage.Client(credentials=credentials, project=credentials_dict["project_id"])
    bucket = client.get_bucket(argv[1])
    blob = bucket.blob("{}/{}".format(argv[2], Path(argv[3]).name))
    blob.upload_from_filename(argv[3])
    print("Upload done")
  else:
    print("Please set $GOOGLE_AUTH environment variable to contain service_account.json".format(argv[0]), file=stderr)
else:
  print("{0} <bucket name> <remote path> <local file>".format(argv[0]), file=stderr)
