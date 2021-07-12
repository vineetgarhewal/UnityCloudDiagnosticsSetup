param(
    [string] [Parameter(Mandatory=$true)] $clusterUrl,
    [string] [Parameter(Mandatory=$true)] $dbName,
    [string] [Parameter(Mandatory=$true)] $logsTableName,
    [string] [Parameter(Mandatory=$true)] $metricsTableName
)

Write-Host $clusterUrl
Write-Host $dbName
Write-Host $logsTableName
Write-Host $metricsTableName


$token=(Get-AzAccessToken -ResourceUrl $clusterUrl).Token

$header = @{
 "Authorization"="Bearer $token"
 "Content-Type"="application/json"
}


$body = @{
 "db"="$dbName"
 "csl"=".create table [$logsTableName]  ([defectid]:string,[filepath]:string,[_index]:string,[_type]:string,[_id]:string,[_source] : dynamic,[_source_stream] : string,[_source_docker_container_id]: string,[_source_kubernetes_container_name] : string,[_source_kubernetes_namespace_name] : string,[_source_kubernetes_pod_name] : string,[_source_kubernetes_container_image] : string,[_source_kubernetes_host] : string,[_source_time]: datetime ,[_source_pei] : string,[_source_supi] : string,[_source_tid] : string,[_source_pduSessionid] : string,[_source_pcfid] : string,[_source_method] : string,[_source_eventLogger] : string,[_source_debug_string] : string,[_source_severity] : string)"
} | ConvertTo-Json
$result = Invoke-RestMethod -Uri "$clusterUrl/v1/rest/mgmt" -Method 'Post' -Body $body -Headers $header 


$body = @{
 "db"="$dbName"
 "csl"=".create table [$metricsTableName]  ([defectid]:string,[filepath]:string,[metric]:dynamic,[metricname]:string,[job]:string,[namespace]:string,[pod]:string,[quantile]:string,[state]:string,[type]:string,[event]:string,[database]:string,[values]:dynamic)"
} | ConvertTo-Json
$result = Invoke-RestMethod -Uri "$clusterUrl/v1/rest/mgmt" -Method 'Post' -Body $body -Headers $header 


$body = @{
 "db"="$dbName"
 "csl"=".show tables"
} | ConvertTo-Json
$result = Invoke-RestMethod -Uri "$clusterUrl/v1/rest/mgmt" -Method 'Post' -Body $body -Headers $header 
$result | ConvertTo-Json -Depth 5
