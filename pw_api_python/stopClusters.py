#!/usr/bin/env python3

"""
  This script will automatically connect to the NOAA ParallelWorks gateway to retrieve
  information about the current clusters using the user's API key.

  Critical files that must exist:

    $HOME/.ssh/pw_api.key - this file must contain the API key in the first and only
                            line.  Treat this file as any secure file and place in 
                            .ssh directory.  Change permissions to mode 600.
"""

import json,requests,sys,time,os
from client import Client

# inputs
pw_url = "https://noaa.parallel.works"

# specify the clusters to start and wait for activation
#clusters = ["gcluster_noaa"]
clusters = sys.argv[1].split(',')

# used to run test ssh commands after the clusters start
# ensure your public key is added to the cluster configuration on Parallel Works

# Get user specific files
homedir = os.environ['HOME']
keyfile = homedir + '/.ssh/pw_api.key'

# get my personal API key
try:
  f = open(keyfile, "r")
  api_key = f.readline().strip()
  f.close()
except IOError: 
  # Error out if there's no key
  # could be improved by looking for an environment variable 
  # or asking the user to enter the key
  print("Error: API file", keyfile, "does not appear to exist.")
  sys.exit(1)

# create a new Parallel Works client
c = Client(pw_url,api_key)

# get the account username
account = c.get_account()

user = account['info']['username']
print("\nRunning as user",user+'...')

for cluster_name in clusters:

    print("\nChecking cluster status",cluster_name+"...")
    
    # check if resource exists and is on
    cluster=c.get_resource(cluster_name)
    if cluster:
        if cluster['status'] == "on":
            # if resource not on, start it
            print("Stopping cluster",cluster_name+"...")
            time.sleep(2) # throttle cluster start requests
            print(c.stop_resource(cluster_name))
        else:
            print(cluster_name,"already stopped...")
    else:
        print("No cluster found.")
        #sys.exit(1)

print("\nStopped",len(clusters),"clusters...\n")

