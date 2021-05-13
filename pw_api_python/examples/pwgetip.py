#!/usr/bin/env python3

"""
  The purpose of this script is to generate a local .hosts file with the current IPs
  of the active clusters the user owns.

  This script will automatically connect to the NOAA ParallelWorks gateway to retrieve
  information about the current clusters using the user's API key.

  Critical files that must exist:

    $HOME/.ssh/pw_api.key - this file must contain the API key in the first and only
                            line.  Treat this file as any secure file and place in 
                            .ssh directory.  Change permissions to mode 600.

  New files created:
    $HOME/.hosts - this is a new file created every time the script is run.  
                   Do not modify this file externally as any change will be 
                   lost.  If no active clusters exists, the file will be created
                   with one commented line.  For the hosts to be recognized,
                   the HOSTALIASES environment variable must point to this
                   file (i.e. export HOSTALIASES=$HOME/.hosts).
"""

import requests
import json
import os
import sys

# Get user specific files
homedir = os.environ['HOME']
# The .hosts file will get re-written every time
hostsfile = homedir + '/.hosts'
keyfile = homedir + '/.ssh/pw_api.key'

# Prepare a header to go into the user's .hosts file
cluster_hosts = [f'# Generated Automatically ' + os.path.basename(__file__)]

# get my personal API key
try:
  f = open(keyfile, "r")
  my_key = f.readline().strip()
  f.close()
except IOError: 
  # Error out if there's no key
  # could be improved by looking for an environment variable 
  # or asking the user to enter the key
  print("Error: API file", keyfile, "does not appear to exist.")
  sys.exit(1)

#print(my_key)
# setup the user-specific url from which to get the data
url_resources = "https://noaa.parallel.works/api/resources?key=" + my_key
# get the data
res = requests.get(url_resources)
#print(res)

if res:
  # get the data from the json
  # print ("Connection successful")
  #print ("status := ", res.status_code)
  # The data is in json format
  data = res.json()

  # Iterate over each cluster
  # if it's active get the IP of the masternode to store in the .hosts file
  for cluster in data:
    #print(cluster)
    if cluster['status'] == 'on':
      # get the cluster type that becomes our 'hostname" to associate with the IP
      # aws - pcluster, GCP - gcluster, azure - acluster (?)
      # use as ssh gcluster or ssh pcluster, etc.
      name = cluster['type']
      ip = cluster['state']['masterNode'] 
      entry = ' '.join([name, ip])
      print (entry)
      cluster_hosts.append(entry)
  # print (cluster_hosts)
  
  # Generate the user's local .hosts file
  with open(hostsfile, 'w+') as f:
    f.writelines("%s\n" % l for l in cluster_hosts)
    print('SUCCESS - the', hostsfile, 'was updated.')
  f.close() 
  
else:
  print ("Connection unsuccessful - can't connect to Parallel Works NOAA gateway")
  print ("status := ", res.status_code)

