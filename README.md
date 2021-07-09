# Unity Cloud Diagnostics Pipeline Setup
.
Please click on the link below to setup unity cloud diganostics pipeline

[![Deploy Azure Resources using ARM template](https://docs.microsoft.com/en-us/azure/media/template-deployments/deploy-to-azure.svg "Deploy Azure Resources using ARM template")](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvineetgarhewal%2FUnityCloudDiagnosticsSetup%2Fmain%2FARMDeploymentTemplate%2FARMTemplateDeployment.json)

Please note: You should be the owner of the sub or can create a managed identity from the subscription.

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
3.	Currently only collection with “logging” is supported. Provide invalid kibana URL in “kargo-collect-config.json” so only fluentd logs are collected.
4.	More number of parallel writes to kusto cluster can cause out of memory (OOM) error, as per the known issue list by ADF team (From their CRI handling experiences).

Pre-requisites
Requirement for Linux and Windows environment:
Python 3.7 +
pip install schedule
pip install requests
az cli
kubectl 1.18+
MSI credentials to access storage

Follow the below steps to run script:
•	Set Path: /home/phoenixjumpboxuser/demo
•	(for Linux) export KUBECONFIG=group-maint.conf
•	(for Windows ) set  KUBECONFIG=group-maint.conf 
•	cmd: python3 KargoCollector.py -m 2
Note: m is the duration in minutes.
Kubeconfig file needs to be fetched from K8 master (/etc/kubernetes/<kubeconfig>)) and copy it to jump server. This needs to be set as env parameter (export KUBECONFIG)
Example : /etc/kubernetes/ group-maint.conf
 
Note: by default, the tar.gz file is in the “data” directory 

  
