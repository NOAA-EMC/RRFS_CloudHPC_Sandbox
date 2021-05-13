import requests
import json
import pprint as pp

class Client():

    def __init__(self, url, key):
        self.url = url
        self.api = url+'/api'
        self.key = key
        self.session = requests.Session()
        self.headers = {
            'Content-Type': 'application/json'
        }
    
    def upload_dataset(self, filename, path):
        req = self.session.post(self.api + "/datasets/upload?key="+self.key,
                                data={'dir': path},
                                files={'file':open(filename, 'rb')})
        req.raise_for_status()
        data = json.loads(req.text)
        return data
    
    def download_dataset(self, file):
        url=self.api + "/datasets/download?key=" + self.key + '&file=' + file
        #print url
        req = self.session.get(url)
        req.raise_for_status()
        return req.content
    
    def find_datasets(self, path, ext=''):
        url = self.api + "/datasets/find?key=" + self.key + "&path=" + path + "&ext=" + ext
        #print url
        req = self.session.get(url)
        req.raise_for_status()
        data = json.loads(req.text)
        return data
    
    def get_job_tail(self, jid, file, lastline):
        url = self.api + "/jobs/"+jid+"/tail?key=" + self.key + "&file=" + file + "&line="+str(lastline)
        try:
            req = self.session.get(url)
            req.raise_for_status()
            data = req.text
        except:
            data = ""
        return data
    
    def start_job(self,workflow,inputs,user):
        inputs = json.dumps(inputs)
        req = self.session.post(self.api + "/tools",data={'user':user,'tool_xml': "/workspaces/"+user+"/workflows/"+workflow+"/workflow.xml",'key':self.key,'tool_id':workflow,'inputs':inputs})
        req.raise_for_status()
        data = json.loads(req.text)
        jid=data['jobs'][0]['id']
        djid=str(data['decoded_job_id'])
        return jid,djid

    def get_job_state(self, jid):
        url = self.api + "/jobs/"+ jid + "?key=" + self.key
        req = self.session.get(url)
        req.raise_for_status()
        data = json.loads(req.text)
        return data['state']

    def get_job_credit_info(self, jid):
        url = self.api + "/jobs/"+ jid + "/monitor?key=" + self.key
        req = self.session.get(url)
        req.raise_for_status()
        data = json.loads(req.text)
        # return data['info']
        return data

    def get_resources(self):
        req = self.session.get(self.api + "/resources?key=" + self.key)
        req.raise_for_status()
        data = json.loads(req.text)
        return data

    def get_resource(self, name):
        req = self.session.get(self.api + "/resources/list?key=" + self.key + "&name=" + name)
        req.raise_for_status()
        try:
            data = json.loads(req.text)
            return data
        except:
            return None
        
    def start_resource(self, name):
        req = self.session.get(self.api + "/resources/start?key=" + self.key + "&name=" + name)
        req.raise_for_status()
        return req.text

    def stop_resource(self, name):
        req = self.session.get(self.api + "/resources/stop?key=" + self.key + "&name=" + name)
        req.raise_for_status()
        return req.text

    def update_resource(self, name, params):
        update = "&name={}".format(name)
        for key, value in params.items():
            update = "{}&{}={}".format(update, key, value)
        req = self.session.post(self.api + "/resources/set?key=" + self.key + update)
        req.raise_for_status()
        return req.text
    
    def get_account(self):
        url = self.api + "/account?key=" + self.key
        req = self.session.get(url)
        req.raise_for_status()
        data = json.loads(req.text)
        return data
        