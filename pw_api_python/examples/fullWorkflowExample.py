#!/usr/bin/env python

import json 
import requests
import sys 
import time

from client import Client

# inputs
pw_url = "https://noaa.parallel.works"
api_key = "" # New api key
user = ''
workflow_name = ""
resource_name = ""
update_resource = False

inputs = {
    "inzip": "/pw/storage/test.zip"
}

# create a new Parallel Works client
c = Client(pw_url,api_key)

# adjust resources
if update_resource:
    params = {
                "max": 15,
                "min": 1 ## Will automatically turn on one node
            } 
    update = c.update_resource(resource_name, params)

    #print(c.stop_resource(resource_name))  ## You have to stop and restart a resource after updating anything other than the min and max

print("Running workflow",workflow_name,"on resource",resource_name,"...")

# check if resource exists and is on
resource=c.get_resource(resource_name)
if resource:
    if resource['status'] == "off":
        # if resource not on, start it
        print("Starting",resource_name,"...")
        print(c.start_resource(resource_name))
    else:
        print(resource_name,"already running...")
else:
    print("No resource found.")
    sys.exit(1)

# upload the input dataset from the desktop
#print("")
#print("Uploading the Input ZIP File...")
#upload_dir = "/pw/storage"
#upload = c.upload_dataset(inputs['inzip'],upload_dir)
#print(upload)

#if upload['status'] != 'success':
#    print("ERROR - upload failed")
#    sys.exit(1)

# update the input inzip definitely to be the pw path
#inputs['inzip'] = '/pw/storage/'+inputs['inzip']

# start the pw job (djid = decoded job id)
jid,djid = c.start_job(workflow_name,inputs,user)

print("")
print("Submitted Job: "+djid)
print("")

# write the jid to a file for later stop/kill
f = open('out.job','w')
f.write(str(djid))
f.close()

#stream_file = 'stream/runner.out'
stream_files = []

class StreamFile:   #Class that holds the streaming files last line and file name
    def __init__(self, name):
        self.name = name
        self.lastline = 0
        self.genlastline = 0
        self.runlastline = 0

s = StreamFile("std.out")
bat = StreamFile("run.bat")
sim_info = StreamFile("sim_info.csv")
stream_files.append(s)
stream_files.append(bat)
stream_files.append(sim_info)
print("Getting state and streaming back requested file:",s.name)

laststate=""

have_results = False

results_file = "/pw/jobs/{}/FloodResults.csv".format(djid)

trys = 0
try:
    results = c.download_dataset(results_file)  #Download FloodResults.csv
    with open("FloodResults.csv","wb") as f:
        f.write(results)
    have_results = True
    tasks = results.decode().split()[1:]
    for task in tasks: #For every task in the Results
        tokens = task.split(",")
        for file_ in tokens[2].split(";"): # Add each of the desired log files to the stream_files array
            stream_files.append(StreamFile(file_)) 
except:                                # If it is not ready yet, we'll try again later
    trys += 1



while True:
    
    time.sleep(5)
    if not have_results and trys < 50: # 50 allows for ~ 5 minutes startup time in worst case scenarios
        try:
            results = c.download_dataset(results_file)
            with open("FloodResults.csv","wb") as f:
                f.write(results)
            have_results = True
            tasks = results.decode().split()[1:]
            for task in tasks:
                tokens = task.split(",")
                for file_ in tokens[2].split(";"):
                    stream_files.append(StreamFile(file_))
        except Exception as e:
            print(Exception)
            trys += 1


    try:
        state = c.get_job_state(djid)
    except:
        state="starting"
    
    if laststate != state:
        print(state)
        laststate=state
    
    for stream in stream_files:
        tail = c.get_job_tail(djid,stream.name,stream.lastline) # this is where I get the job tail to append last line
        try:
            if (tail != "" and "error reading file" not in tail):
                with open(stream.name.split("/")[-1],"w+") as f:  #need to shorten path here to ensure writability. Other method would be to force create directories
                    f.write(tail)  #Writing these out to their own files instead of std.out
                stream.lastline+=len(list(filter(None, tail.split("\n"))))
        except Exception as e:
            print(e)
    
    ## Get run credits
    job_info = c.get_job_credit_info(djid)
    creds = job_info.get("credits",0)
    runhrs = job_info.get("runhrs",0)

    ## Do something with these variables here

    if state == 'ok':
        break
    elif (state == 'deleted' or state == 'error'):
        raise Exception('Simulation had an error. Please try again')

print("")
print("Workflow Complete...")


##Download all results files

job_prefix = "/pw/jobs/{}/".format(djid) 
simnum = 1
with open("FloodResults.csv","r") as results:
    results.readline() #Ignore Headers
    for line in results.readlines():
        tokens = line.split(",")
        res_file = tokens[3]
        zip_path = job_prefix + res_file
        try:
            results = c.download_dataset(zip_path)
            with open("res{}.zip".format(simnum),"wb") as result:
                result.write(results)
        except Exception as e:
            print("Could not download results file {}".format(res_file))
            print(e)
        simnum +=1
            

# view job files as an example
#print("")
#print("Finding CSV files in job directory (as an example)...")
#jobdir = "/pw/jobs/"+djid
#extension = "csv"
#print c.find_datasets(jobdir,ext=extension)
#print ""
#

#
# turn off the computing resources after the workflow completes
# print c.stop_resource(resource_name)


