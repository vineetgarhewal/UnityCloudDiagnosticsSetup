# Cloud Logs Exposure (CLX) Tool Setup

## Introduction
This page describes the usage of Cloud Exposure Tool for Unity Cloud logs and metrics. It covers the following topics in details below -
* Set up the Azure resources for ingesting the logs and metrics
* Set up the KargoToolCollector to fetch the logs and metrics and upload to the blob storage
* Query the logs and metrics from Azure Data Explorer 
* Sample Queries

## Provision Azure Services for diagnostics pipeline

#### Overview
Diagnostics Pipeline depends on the Azure Data Factory to read the logs from Azure Blob Storage and ingest into Azure Data Explorer to make it query-able throgh KQL Queries and be able to view using Grafana dashboard. 

<details>
  <summary>High level architecture of the CLX tool</summary>
  <img src="/images/Architecture.JPG" />
</details>

#### Azure Resouce Deployment 
Please click on the link below to setup Diagnostics pipeline for Logs and Metrics for Unity Cloud components. This may take upto 25-30 minutes. 

#### Pre-requisites
1. You need to be the owner of the Azure subscription where these resources are being created.
2. MSI identity should have following roles assigned to it: Storage Blob Data Container, Storage Queue Data Contributor

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvineetgarhewal%2FUnityCloudDiagnosticsSetup%2Fmain%2FARMDeploymentTemplate%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fvineetgarhewal%2FUnityCloudDiagnosticsSetup%2Fmain%2FARMDeploymentTemplate%2Fazuredeploy.json)

#### Instructions
Please follow the steps to setup and verify the pipeline deployment (click to expand)
<details>
  <summary>Deploy Azure resource using custom arm template deployment </summary>
  <img src="/images/CreateDeployment.JPG" />
</details>

<details>
  <summary>Verify the deployment status</summary>
  <img src="/images/DeploymentComplete.JPG" />
</details>

<details>
  <summary>Verify the deployed resources in resource group</summary>
  <img src="/images/ResourceGroup.JPG" />
</details>

<details>
  <summary>Get the Azure Data Explorer Url</summary>
  <img src="/images/DeploymentOutput.JPG" />
</details>


<details>
  <summary>Verify the Azure Blob Storage containers for the Logs and Metrics</summary>
  <img src="/images/Storage.JPG" />
</details>

## Run the Kargo Logs and Metrics collector tool on the jumpbox

#### Overview
The Kargo periodic collector tool is a simple python script which:
1. Periodically collects the kargo logs from the Kargo tool based on the configurable parameters. 
2. Uploads to the Azure Blob Container for the ingestion. 
The tool currently supports Windows and Linux environments.


#### Known limitations
1. Kargo output file is present in the pod also. It needs to be manually deleted or else the K8 node may go for reboot because of the disk size overflow.
3. Currently only collection with “logging”  and "prometheus" is supported. Provide invalid kibana dashboard in “kargo-log-collection-config.json” so only fluentd logs are collected.
4. More number of parallel writes to kusto cluster can cause out of memory (OOM) error.


#### Pre-requisites
1. Requirement for Linux and Windows environment:
2. Python 3.7 + ( create a symlink: sudo ln -s /usr/bin/python3 /usr/bin/python , if required )
3. pip install schedule
4. pip install requests
5. az cli
6. kubectl 1.18+
8. Azure Blob Storage account (azure resource created in the steps above) connection-string .

#### Instructions
Please follow the steps mentioned below to run the script:
1. Set Path: /{PathToKargoCollector}/KargoCollector
2. chmod 755 KargoCollector.py
3. chmod 755 kubectl-afn-kargo-collect
4. Kubeconfig file needs to be fetched from K8 master (/etc/kubernetes/<kubeconfig>)) and copy it to jump server. This file path needs to be set as argument while running the script. 
Example : /etc/kubernetes/ group-maint.conf
3. Set elastic search endpoint details under kargo-log-endpoint-config.json
```json	
 {
        "loggingConfig": {
                "elasticPassword": "<your-password>",
                "elasticURL": "<your-valid-elastic-url>",
                "elasticUserName": "<your-username>",
	        "kibanaURL": "<your-valid-kibana-url>"
        }
}
```
4. Set prometheus endpoint under kargo-prometheus-endpoint-config.json
```json	
 {
    "prometheusConfig": {
        "URL" : "http://<Valid-PrometheusIP>:<Valid-PrometheusPort>"
    }
}
```
5. Set storage account name , logsBlobContainerName , metricsBlobContainerName and ConnectionString ( as per requirement ) under storage-account-info.json
   Use the portal to retrive the deployment resources to set the values.	
 ```json
{
    "Storage": {
                "AccountName": "<Place-Your-storageAccountName-Here>",
                "logsBlobContainerName": "<Place-Your-logsBlobContainerName-Here>",
                "metricsBlobContainerName": "<Place-Your-metricsBlobContainerName-Here>",
                "ConnectionString": "<Place-Your-StorageAccount-ConnectionString-Here>"
        }
}
```
6. Execution command: python KargoCollector.py -k <kubeConfigFile> -c <collectionTye> [-m <durationInMinutes>] [-o <outputfolder>] [-s <storageType>] [-i <identityType>]

#### Note: 
1. k is the path to kubeconfig file ( mandatory )
2. c is to specify the type of collcection . Currently supported are "prometheus" or "logging". (mandatory)
3. m is the duration in minutes. default 15 minutes
4. o is the folder where the tar.gz be pulled locally from the kargo server. default is "data\logging" or "data\prometheus" folder on the same path.
5. s currently its optional , we only support "azblob" as remote storage
6. i is for the identity of the machine, by default its managed identity. We can set is to "connectionstring".
	
	
#### Examples: 
 A.  To execute script to fetch logs for every 2 minutes from a system having managed identity  
     ```
     collector> python KargoCollector.py -k group-maint.conf -c logging -m 2 
     ```  
     <details>
          <summary>Log collection using managed identity</summary>
          <img src="/images/LogCollectionUsingManagedIdentity.JPG" />
     </details>
	
 B.  To execute script to fetch logs for every 2 minutes from a system having connection string to storage blob  
     ```
     collector> python KargoCollector.py -k group-maint.conf -c logging -m 2 -i connectionstring
     ```  
     <details>
	<summary>Log collection using blob connection string</summary>
     	<img src="/images/LogCollectionUsingConnectionString.JPG" />
     </details>	  
	
 C.  To execute script to fetch prometheus metrics for every 2 minutes from a system having managed identity.
 
     collector> python KargoCollector.py -k group-maint.conf -c prometheus -m 2 
 
 D.  To execute script to fetch prometheus metrics for every 2 minutes from a system having connection string to storage blob
 
     collector> python KargoCollector.py -k group-maint.conf -c prometheus -m 2 -i connectionstring

 Note: by default, the tar.gz file is in the “data\logging” directory for logs collection and “data\prometheus” for prometheus metrics collection.



## Query the Logs and Metrics
This seconds describes few sample queries. You can construct your own queries based on your necessity. Please refer [KQL quick reference](https://docs.microsoft.com/en-us/azure/data-explorer/kql-quick-reference) for syntax.
	
#### Verify the pipeline is running and ingesting the data
<details>
  <summary>View the files in blob containers</summary>
  <img src="/images/FilesInLogsBlob.JPG" />
</details>
	
<details>
  <summary>Verify the pipeline runs</summary>
  <img src="/images/DataPipelineRuns.JPG" />
</details>
	
#### Query the logs
<details>
  <summary>Get the Azure Data Explorer link from deployment</summary>
  <img src="/images/DeploymentOutput.JPG" />
</details>
	
<details>
  <summary>Query the logs</summary>
  <img src="/images/Logs.JPG" />
</details>
	
## Sample KQL Queries
* Query the logs by SUPI id
```
5GDebugLogs
| where _source_supi == 'imsi-3104102570xyz'
```
	
* Query the logs by time 
```
5GDebugLogs
| where _source_time < datetime('2021-07-05T16:16:26.9529494Z')
```

* Query the logs by Tid and time range
```
let varTid = '0x7f09d66c5780';
let _start_time = datetime('2021-07-12T12:34:54.1708095Z');
let _end_time = datetime('2021-07-12T14:03:02.9320405Z');
5GDebugLogs
| where _source_tid contains varTid and _source_time between (_start_time .. _end_time)
```
							  
* Query the logs by time range
```
5GDebugLogs
| where _source_time > ago(5h) and _source_time  < ago(2h)
```
	
* Query the logs by pattern match in log
```
5GDebugLogs
| where _source.log contains 'WARNING  Duplicate session exists for new create'
```
	
* Query the logs by k8s namespace
```
5GDebugLogs
| where  _source_kubernetes_namespace_name == 'fed-smf'
```
* Find the event time an query the logs upto next 20 seconds
```
let ErrorTime = toscalar(5GDebugLogs
| where _source.log contains 'watchFileEvents'
| summarize min(_source_time));
5GDebugLogs
| where _source_time >= ErrorTime and _source_time < (ErrorTime + 20s)
```
* Find out the known issue based on pattern match 
```
let getJIRA=(log:string) {
	case(
	log contains 'WARNING  Duplicate session exists for new create', 'CN-29919',
	log contains 'ERROR response received for etcd range request; Transaction ID: 300; Response code: 460, Response message, Response message', 'CN-29360',
	log contains 'Received failure response from DB ReadAndLock. responseCode:404', 'CN-29692',
	log contains 'Get UDSF record not found', 'CN-29327',
	'CN-NotFound')
};
let getTitle=(log:string) {
	case(
	log contains 'WARNING  Duplicate session exists for new create', '[AT&T-QC TBD] 2.2.1 SMFCC (fed-smf-2.2.0-45-patch-2-2-1) did not reply to a PDU Session Establishment Request',
	log contains 'ERROR response received for etcd range request; Transaction ID: 300; Response code: 460, Response message, Response message', '[AT&T-QC-TBD] 2.2.1 BCV-UPF : UPF ip-interfaces are not coming up - issue with etcd watch and range response errors',
	log contains 'Received failure response from DB ReadAndLock. responseCode:404', '30% PDU Session Establishment Reject during traffic',
	log contains 'Get UDSF record not found', 'mongos/datashard pods Restarted during traffic',
	'Title-NotFound')
};
let getNFType=(log:string) {
	case(
	log contains 'WARNING  Duplicate session exists for new create', 'SMF',
	log contains 'ERROR response received for etcd range request; Transaction ID: 300; Response code: 460, Response message, Response message', 'UPF',
	log contains 'Received failure response from DB ReadAndLock. responseCode:404', 'SMF',
	log contains 'Get UDSF record not found', 'SMF',
	'CN-NotFound')
};
let getIssue=(log:string) {
	case(
	log contains 'WARNING  Duplicate session exists for new create', 'There were pre-existing etcd entries',
	log contains 'ERROR response received for etcd range request; Transaction ID: 300; Response code: 460, Response message, Response message', 'MongoDB',
	log contains 'Received failure response from DB ReadAndLock. responseCode:404', 'MongoDB',
	log contains 'Get UDSF record not found', 'race condition in handling multiple Create SM contexts arrive back-to-back',
	'CN-NotFound')
};
let SampleLogAnalysisPattern = datatable(pattern:string)
[
	'WARNING  Duplicate session exists for new create',
	'ERROR response received for etcd range request; Transaction ID: 300; Response code: 460, Response message',
	'Received failure response from DB ReadAndLock. responseCode:404',
	'Get UDSF record not found'
];
5GFluendDebugLogs
| where _source has_any (SampleLogAnalysisPattern)
| extend JIRA = getJIRA(_source)
| extend Title = getTitle(_source)
| extend NFType = getNFType(_source)
| extend Issue = getIssue(_source)
| distinct _index, tostring(_source), JIRA, Title, NFType, Issue, _source_time
```		
							     
							  
