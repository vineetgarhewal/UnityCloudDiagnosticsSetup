# Unity Cloud Diagnostics Pipeline Setup

Please click on the link below to setup unity cloud diganostics pipeline

[![Deploy Azure Resources using ARM template](https://docs.microsoft.com/en-us/azure/media/template-deployments/deploy-to-azure.svg "Deploy Azure Resources using ARM template")](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvineetgarhewal%2FUnityCloudDiagnosticsSetup%2Fmain%2FARMDeploymentTemplate%2FARMTemplateDeployment.json)

# Kargo periodic collector tool

Download KargoCollector.zip

Overview

The Kargo periodic collector tool and ingestion pipeline enables:
•	To periodically collects the kargo logs based on the configurable parameters.
•	To automatically uploads to the Azure blob or SFTP for ingestion to the Azure kusto on the Windows environment.
•	To automatically uploads to the Azure blob for ingestion to the Azure kusto on the Linux environment.
•	To use Azure kusto queries to process logs data and return the results of this processing.
The tool currently supports Windows and Linux environments.

Known limitations
1.	This periodically collects the kargo logs based on the configurable parameters.
2.	Kargo output file is present in the pod also. It needs to be manually deleted else the K8 node may go for reboot because the disk size overflow.
3.	Currently only collection with “logging”  and "prometheus" is supported. Provide invalid kibana dashboard in “kargo-log-collection-config.json” so only fluentd logs are collected.
4.	More number of parallel writes to kusto cluster can cause out of memory (OOM) error, as per the known issue list by ADF team (From their CRI handling experiences).

Pre-requisites
Requirement for Linux and Windows environment:
Python 3.7 + ( set alias python=python3 , if required )
pip install schedule
pip install requests
az cli
kubectl 1.18+
MSI credentials to access storage
StorageAccount connection-string for VM deployed in private network.

Follow the below steps to run script:
•	Set Path: /{PathToKargoCollector}/KargoCollector
•	Kubeconfig file needs to be fetched from K8 master (/etc/kubernetes/<kubeconfig>)) and copy it to jump server. This file path needs to be set as argument while running the script.
 Example : /etc/kubernetes/ group-maint.conf
•	Set elastic search endpoint details under kargo-log-endpoint-config.json
 {
        "loggingConfig": {
                "elasticPassword": "<your-password>",
                "elasticURL": "<your-elastic-url>",
                "elasticUserName": "<your-username>"
        }
}
•	Set prometheus endpoint under kargo-prometheus-endpoint-config.json
 {
    "prometheusConfig": {
        "URL" : "http://<Valid-PrometheusIP>:<Valid-PrometheusPort>"
    }
}
•	Set storage account name , logsBlobContainerName , metricsBlobContainerName and ConnectionString ( as per requirement ) under storage-account-info.json
 {
    "Storage": {
                "AccountName": "<Place-Your-storageAccountName-Here>",
                "logsBlobContainerName": "<Place-Your-logsBlobContainerName-Here>",
	            			"metricsBlobContainerName": "<Place-Your-metricsBlobContainerName-Here>",
                "ConnectionString": "<Place-Your-StorageAccount-ConnectionString-Here>"
        }
}
•	Execution command: python KargoCollector.py -k <kubeConfigFile> -c <collectionTye> [-m <durationInMinutes>] [-o <outputfolder>] [-s <storageType>] [-i <identityType>]
Note: 
 k is the path to kubeconfig file ( mandatory )
 c is to specify the type of collcection . Currently supported are "prometheus" or "logging". (mandatory)
 m is the duration in minutes. default 15 minutes
 o is the folder where the tar.gz be pulled locally from the kargo server. default is "data\logging" or "data\prometheus" folder on the same path.
 s currently its optional , we only support "azblob" as remote storage
 i is for the identity of the machine, by default its managed identity. We can set is to "connectionstring".
 
 Example:
 
 A.  To execute script to fetch logs for every 2 minutes from a system having managed identity
 
     collector> python KargoCollector.py -k group-maint.conf -c logging -m 2 
 
 B.  To execute script to fetch logs for every 2 minutes from a system having connection string to storage blob
 
     collector> python KargoCollector.py -k group-maint.conf -c logging -m 2 -i connectionstring
 
 C.  To execute script to fetch prometheus metrics for every 2 minutes from a system having managed identity.
 
     collector> python KargoCollector.py -k group-maint.conf -c prometheus -m 2 
 
 D.  To execute script to fetch prometheus metrics for every 2 minutes from a system having connection string to storage blob
 
     collector> python KargoCollector.py -k group-maint.conf -c prometheus -m 2 -i connectionstring

 Note: by default, the tar.gz file is in the “data\logging” directory for logs collection and “data\prometheus” for prometheus metrics collection.
