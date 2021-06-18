#!/usr/bin/env python3

"""
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

import json,requests,sys,time,os
from client import Client

# inputs
pw_url = "https://noaa.parallel.works"

# specify the clusters to start and wait for activation
#clusters = ["gcluster_noaa"]
clusters = [x.lower() for x in sys.argv[1].split(',')]

print('\nStarting clusters:',clusters)

# used to run test ssh commands after the clusters start
# ensure your public key is added to the cluster configuration on Parallel Works

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
        if cluster['status'] == "off":
            # if resource not on, start it
            print("Starting cluster",cluster_name+"...")
            time.sleep(2) # throttle cluster start requests
            print(c.start_resource(cluster_name))
        else:
            print(cluster_name,"already running...")
    else:
        print("No cluster found.")
        sys.exit(1)

print("\nWaiting for",len(clusters),"cluster(s) to start...")

laststate = {}
started = []

while True:
    
    current_state = c.get_resources()

    for cluster in current_state:
      
      #print(cluster['name'],cluster['status'])
      
      if cluster['name'].lower() in clusters and cluster['status'] == 'on':
      
        if cluster['name'].lower() not in started:
    
          state = cluster['state']
    
          if cluster['name'].lower() not in laststate:
              print(cluster['name'].lower(),state)
              laststate[cluster['name'].lower()] = state
          
          elif laststate[cluster['name'].lower()] != state:
              print(cluster['name'].lower(),state)
              laststate[cluster['name'].lower()] = state
      
          # if state == 'ok':
          #     break
          # elif (state == 'deleted' or state == 'error'):
          #     raise Exception('Simulation had an error. Please try again')
          
          if 'masterNode' in cluster['state']:
            if cluster['state']['masterNode'] != None:
              ip = cluster['state']['masterNode'] 
              entry = ' '.join([cluster['name'].lower(), ip])
              print(entry)
              cluster_hosts.append(entry)
              started.append(cluster['name'].lower())
      
    if len(started) == len(clusters):
      print('\nStarted all clusters... writing hosts file')
      break
    
    time.sleep(5)

# Generate the user's local .hosts file
with open(hostsfile, 'w+') as f:
  f.writelines("%s\n" % l for l in cluster_hosts)
  print('SUCCESS - the', hostsfile, 'was updated.')
  f.close() 
  
# run example ssh command on each started cluster

print("\nRunning test ssh commands on the clusters...")
import subprocess

testcmd = "sinfo"

for ei,entry in enumerate(cluster_hosts):
  
  if ei > 0: # skip the host header
  
    name = entry.split()[0]
    ip = entry.split()[1]
    
    cmd = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s@%s %s" % (user,ip,testcmd)
    
    print("")
    print(name+':','"'+cmd+'"')
    
    out = subprocess.check_output(
          cmd,
          stderr=subprocess.STDOUT,
          shell=True).decode(sys.stdout.encoding)
          
    print(out)

