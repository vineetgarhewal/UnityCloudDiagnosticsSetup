#!/usr/bin/env python3

from subprocess import PIPE, Popen
import schedule
import sys,getopt,os
import json

COLLECTION_TYPE_PROMETHEUS = "prometheus"
COLLECTION_TYPE_LOGGING = "logging"

COLLECTION_CONFIG_MAPPING = { 
        COLLECTION_TYPE_LOGGING: "kargo-log-collection-config.json" ,
        COLLECTION_TYPE_PROMETHEUS : "kargo-prometheus-collection-config.json" 
}

KARGO_CONFIG_MAPPING = {    
        COLLECTION_TYPE_LOGGING: "kargo-log-endpoint-config.json" ,
        COLLECTION_TYPE_PROMETHEUS : "kargo-prometheus-endpoint-config.json"
}

UNITYCLOUD_KARGO_MODULE = 'kubectl-afn-kargo-collect'                    
STORAGE_INFO_FILE = 'storage-account-info.json'
AUTH_TYPE_CONNECTION_STRING = 'connectionstring'
AUTH_TYPE_IDENTITY = 'identity'

def pushToCommonStorage(collectionType,scanfolder,destinationType,authType):

    localFolder = scanfolder
    f = open(STORAGE_INFO_FILE, 'r')
    data = json.load(f)   
    storageContainer = data['Storage']['logsBlobContainerName'] if collectionType == COLLECTION_TYPE_LOGGING else data['Storage']['metricsBlobContainerName']
    storageAccountName = data['Storage']['AccountName']
    stroageConnectionString = data['Storage']['ConnectionString']
    f.close()
    verbose = True
    
    if verbose: print("scanning folder...")
    
    for file in os.listdir(localFolder):
        if file.endswith(".tar.gz"):
            if verbose: print("found file... ",file)
            localpath = os.path.join(localFolder, file)
            if destinationType == "azblob":
                cmd1 = "az login --identity"
                cmd2 = f"az storage blob upload -c {storageContainer} --account-name {storageAccountName} -f {localpath} -n {file}"
                if AUTH_TYPE_IDENTITY == authType:
                    if verbose: print("az login...")
                    os.system(cmd1)
                    cmd2 = f"{cmd2} --auth-mode login"
                elif AUTH_TYPE_CONNECTION_STRING == authType:
                    if verbose: print("configuring the upload command to use the connection string...")
                    cmd2 = f'{cmd2} --connection-string "{stroageConnectionString}"'
                if verbose: print("upload to blob...")
                os.system(cmd2)
                if verbose: print("deleting local file... ")
                os.remove(localpath)
                if verbose: print("deleted...")      
 
def executeCommand(cmd,collectionType,outputfolder,destinationType,authType):
    print(f"Running command ...{cmd}")
    p = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True, universal_newlines=True)
    output, error = p.communicate()
    output = output.splitlines()
    if len(error) > 0 :
      raise AssertionError(f"Unexpected error command::{cmd},Error::{error}")    
    print(*output, sep ="\n")
    pushToCommonStorage(collectionType,outputfolder,destinationType,authType)    
    return output, error


def runScheduledJobs(run_module,collectType,scanfolder,storageType,authenticationType,period):
    schedule.every(period).minutes.do(executeCommand,cmd=run_module,collectionType=collectType,outputfolder=scanfolder,destinationType=storageType,authType=authenticationType)
    print(f'Collection scheduled to run every {period} minutes')
    while True:
        schedule.run_pending()

def usage():
    print ('python KargoCollector.py -k <kubeConfigFile> -c <collectionTye> [-m <durationInMinutes>] [-o <outputfolder>] [-s <storageType>] [-i <identityType>]')
    

if __name__=='__main__':
   
   period = 15
   #TODO:: output folder for metrics and logs   
   parentfolder = "data"
   logOutoutFolder = f"{parentfolder}{os.path.sep}{COLLECTION_TYPE_LOGGING}"
   prometheusOutputFolder = f"{parentfolder}{os.path.sep}{COLLECTION_TYPE_PROMETHEUS}"   
   storageType = "azblob"
   authType = "identity"
   kubeconfigFile = None
   collectionType = None
   outputFolderoverriden = False
   
   if not os.path.isdir(parentfolder):
       os.makedirs(logOutoutFolder)
       os.makedirs(prometheusOutputFolder)
       
   argv = sys.argv[1:]
   try:
      opts, args = getopt.getopt(argv,"k:c:m:o:s:i:h",["kubeConfigFile=","collectionTye=","durationmins=","outputfolder=","storageType=","identityType=","help"])
   except getopt.GetoptError:
      usage()
      sys.exit(2)
   for opt, arg in opts:
      if opt in ("-h", "--help"):
         usage()
         sys.exit()
      elif opt in ("-k", "--kubeConfigFile"):
         kubeconfigFile = arg
      elif opt in ("-c", "--collectionTye"):
         collectionType = arg
      elif opt in ("-m", "--durationmins"):
         period = int(arg)
      elif opt in ("-o", "--outputFolder"):
         outputfolder = arg
         outputFolderoverriden = True
      elif opt in ("-s", "--storageType"):
         storageType = arg
      elif opt in ("-i", "--identityType"):
         authType = arg
      else:
         print("Error: Unhandled option. Exiting...")
         usage()
         sys.exit(-1)

   if kubeconfigFile is None or collectionType is None or collectionType not in (COLLECTION_TYPE_LOGGING,COLLECTION_TYPE_PROMETHEUS):
       print("Error: Either the kubeconfigFile path or the Collection Type is missing. The collection type should be either of prometheus or logging.")
       sys.exit(-1)

   if not outputFolderoverriden:       
      outputfolder = logOutoutFolder if COLLECTION_TYPE_LOGGING == collectionType else prometheusOutputFolder
                  
   # set KUBECONFIG env variable
   os.environ["KUBECONFIG"] = kubeconfigFile   
   COLLECTION_CONFIG_FILE = COLLECTION_CONFIG_MAPPING.get(collectionType)
   KARGO_CONFIG_FILE = KARGO_CONFIG_MAPPING.get(collectionType)
   
   run_module = f'python {UNITYCLOUD_KARGO_MODULE} -l {outputfolder} -n {KARGO_CONFIG_FILE} -c {COLLECTION_CONFIG_FILE} -d {period}'

   print("Starting the collector...")
   out = executeCommand(run_module,collectionType,outputfolder,storageType,authType)
   runScheduledJobs(run_module,collectionType,outputfolder,storageType,authType,period)
