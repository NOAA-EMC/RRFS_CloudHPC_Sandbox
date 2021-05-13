# NOAA Cluster Automation on Parallel Works

This repo uses the Parallel Works REST API to start a group of clusters, wait for their master node IP addresses, then runs example ssh commands using the fetched IP addresses of the started master nodes.

To run the example, install python3 and the requests library:

```
pip3 install requests
```

Add your Parallel Works API Key (acquired from the ACCOUNT tab when logged into PW) to a ~/.ssh/pw_api.key file. You can "export HOSTALIASES=$HOME/.hosts" to pick up the generated ip addresses of the cluster names to your user host file.

Once your API key is added, run the below script to start your account's Parallel Works clusters (comma separated values):

```
python3 startClusters.py pcluster_noaa,gcluster_noaa
```

This command will start the pcluster_noaa and gcluster_noaa clusters in your account. Once running, it will run a sample sinfo command and output the results. Please ensure your public key is added to the Parallel Works cluster config page to allow ssh access.

To stop the clusters, you can run the command below (command separated values):

```
python3 stopClusters.py pcluster_noaa,gcluster_noaa
```

Example output below:

```
root@lab01:/pw/core/matthew/pw_api_python# python3 startClusters.py gcluster_noaa,gcluster_noaa_pg                                                                                                                                                                                       

Starting clusters: ['gcluster_noaa', 'gcluster_noaa_pg']

Running as user Matthew.Shaxted...

Checking cluster status gcluster_noaa...
Starting cluster gcluster_noaa...
success: gcluster_noaa resource started

Checking cluster status gcluster_noaa_pg...
Starting cluster gcluster_noaa_pg...
success: gcluster_noaa_pg resource started

Waiting for 2 cluster(s) to start...
gcluster_noaa {}
gcluster_noaa_pg {}
gcluster_noaa {'registeredWorkers': 0, 'requestedWorkers': 1, 'masterNode': None}
gcluster_noaa_pg {'registeredWorkers': 0, 'requestedWorkers': 1, 'masterNode': None}
gcluster_noaa {'registeredWorkers': 1, 'requestedWorkers': 1, 'masterNode': '34.122.239.42'}
gcluster_noaa 34.122.239.42
gcluster_noaa_pg {'registeredWorkers': 1, 'requestedWorkers': 1, 'masterNode': '34.123.25.96'}
gcluster_noaa_pg 34.123.25.96

Started all clusters... writing hosts file
SUCCESS - the /root/.hosts was updated.

Running test ssh commands on the clusters...

gcluster_noaa: "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null Matthew.Shaxted@34.122.239.42 sinfo"
Warning: Permanently added '34.122.239.42' (ECDSA) to the list of known hosts.
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
compute*     up   infinite    144  idle~ matthewshaxted-gclusternoaa-00153-compute-0-[0-143]


gcluster_noaa_pg: "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null Matthew.Shaxted@34.123.25.96 sinfo"
Warning: Permanently added '34.123.25.96' (ECDSA) to the list of known hosts.
PARTITION         AVAIL  TIMELIMIT  NODES  STATE NODELIST
compute*             up   infinite    144  idle~ matthewshaxted-gclusternoaapg-00003-compute-0-[0-143]
compute_exclusive    up   infinite    144  idle~ matthewshaxted-gclusternoaapg-00003-compute-1-[0-143]
```