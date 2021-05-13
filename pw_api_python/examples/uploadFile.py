#!/usr/bin/env python

import json 
import requests
import sys 
import time

from client import Client

# inputs
pw_url = "https://noaa.parallel.works"
api_key = "ab9373dc77838d6df3c23bde2d8a84e3" # noaamaster api key

jsonfile = "test_upload.json"

# create a new Parallel Works client
c = Client(pw_url,api_key)

# upload the input dataset from the desktop
print("")
print("Uploading JSON File...")
upload_dir = "/pw/storage"
upload = c.upload_dataset(jsonfile,upload_dir)
print(upload)
