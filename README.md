# Unity Cloud Diagnostics Pipeline Setup

## Provision Azure Services for diagnostics pipeline

#### Custom Deployment 
Please click on the link below to setup Diagnostics pipeline for Logs and Metrics for Unity Cloud components. 

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvineetgarhewal%2FUnityCloudDiagnosticsSetup%2Fmain%2FARMDeploymentTemplate%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fvineetgarhewal%2FUnityCloudDiagnosticsSetup%2Fmain%2FARMDeploymentTemplate%2Fazuredeploy.json)

#### Insructions
Please follow the steps to setup and verify the pipeline deployment
<details>
  <summary>Deploy Azure resource using custom arm template deployment.</summary>
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

## Run the Kargo Logs and Metrics collector tool on jumpbox

#### Overview
The Kargo periodic collector tool and ingestion pipeline enables:

1. To periodically collects the kargo logs based on the configurable parameters. 
2. To automatically uploads to the Azure blob or SFTP for ingestion to the Azure kusto on the Windows environment. 
3. To automatically uploads to the Azure blob for ingestion to the Azure kusto on the Linux environment.
4. To use Azure kusto queries to process logs data and return the results of this processing.
The tool currently supports Windows and Linux environments.


#### Known limitations
1. This tool periodically collects the kargo logs based on the configurable parameters.
2. Kargo output file is present in the pod also. It needs to be manually deleted else the K8 node may go for reboot because the disk size overflow.
3. Currently only collection with “logging”  and "prometheus" is supported. Provide invalid kibana dashboard in “kargo-log-collection-config.json” so only fluentd logs are collected.
4. More number of parallel writes to kusto cluster can cause out of memory (OOM) error.


#### Pre-requisites
1. Requirement for Linux and Windows environment:
2. Python 3.7 + ( set alias python=python3 , if required )
3. pip install schedule
4. pip install requests
5. az cli
6. kubectl 1.18+
7. MSI credentials to access storage
8. StorageAccount connection-string for VM deployed in private network.

#### Instructions
Please follow the steps mentioned below to run the script:
1. Set Path: /{PathToKargoCollector}/KargoCollector
2. Kubeconfig file needs to be fetched from K8 master (/etc/kubernetes/<kubeconfig>)) and copy it to jump server. This file path needs to be set as argument while running the script. 
Example : /etc/kubernetes/ group-maint.conf
3. Set elastic search endpoint details under kargo-log-endpoint-config.json
 {
        "loggingConfig": {
                "elasticPassword": "<your-password>",
                "elasticURL": "<your-elastic-url>",
                "elasticUserName": "<your-username>"
        }
}
4. Set prometheus endpoint under kargo-prometheus-endpoint-config.json
 {
    "prometheusConfig": {
        "URL" : "http://<Valid-PrometheusIP>:<Valid-PrometheusPort>"
    }
}
5. Set storage account name , logsBlobContainerName , metricsBlobContainerName and ConnectionString ( as per requirement ) under storage-account-info.json
 {
    "Storage": {
                "AccountName": "<Place-Your-storageAccountName-Here>",
                "logsBlobContainerName": "<Place-Your-logsBlobContainerName-Here>",
	            			"metricsBlobContainerName": "<Place-Your-metricsBlobContainerName-Here>",
                "ConnectionString": "<Place-Your-StorageAccount-ConnectionString-Here>"
        }
}
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
 B.  To execute script to fetch logs for every 2 minutes from a system having connection string to storage blob
 
     collector> python KargoCollector.py -k group-maint.conf -c logging -m 2 -i connectionstring
 
 C.  To execute script to fetch prometheus metrics for every 2 minutes from a system having managed identity.
 
     collector> python KargoCollector.py -k group-maint.conf -c prometheus -m 2 
 
 D.  To execute script to fetch prometheus metrics for every 2 minutes from a system having connection string to storage blob
 
     collector> python KargoCollector.py -k group-maint.conf -c prometheus -m 2 -i connectionstring

 Note: by default, the tar.gz file is in the “data\logging” directory for logs collection and “data\prometheus” for prometheus metrics collection.
