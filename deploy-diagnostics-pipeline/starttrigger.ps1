param(
    [string] [Parameter(Mandatory=$true)] $subscriptionId,
    [string] [Parameter(Mandatory=$true)] $resourceGroup,
    [string] [Parameter(Mandatory=$true)] $dataFactoryName,
    [string] [Parameter(Mandatory=$true)] $logsTriggerName,
    [string] [Parameter(Mandatory=$true)] $metricsTriggerName
)

Write-Host $subscriptionId
Write-Host $resourceGroup
Write-Host $dataFactoryName
Write-Host $logsTriggerName
Write-Host $metricsTriggerName

$token=(Get-AzAccessToken).Token

$header = @{
 "Authorization"="Bearer $token"
 "Content-Type"="application/json"
} 

$uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/triggers/$logsTriggerName/start?api-version=2018-06-01"

$result = Invoke-RestMethod -Uri $uri -Method 'Post' -Headers $header 

$uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/triggers/$logsTriggerName/?api-version=2018-06-01"
Invoke-RestMethod -Uri $uri -Method 'Get' -Headers $header | ConvertTo-Json -Depth 5

$uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/triggers/$metricsTriggerName/start?api-version=2018-06-01"

$result = Invoke-RestMethod -Uri $uri -Method 'Post' -Headers $header 

$uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/triggers/$metricsTriggerName/?api-version=2018-06-01"
Invoke-RestMethod -Uri $uri -Method 'Get' -Headers $header | ConvertTo-Json -Depth 5