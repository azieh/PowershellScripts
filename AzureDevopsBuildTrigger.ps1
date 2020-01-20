function QueueAzureDevOpsBuild {
    param (
        [string]$collectionurl = "",
        [string]$base64AuthInfo = "",
        [string]$releasedDefinitionId = "123"
    )
    
$json = @"
{
    "definition":{
        "id": $releasedDefinitionId
    }
"@
$uri = $collectionurl + "/build/builds?api-version=5.0"
$result = Invoke-RestMethod -Uri $uri -Method Post -Body $json -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
$buildId = $result.id
Write-Host "Succeeded queued BuildID:" $buildId  
return $result
}

function CheckAzureDevOpsBuild {
    param (
        [string]$collectionurl = "",
        [string]$base64AuthInfo = "",
        [string]$buildId = ""
    )
    
$uri = $collectionurl + "/build/builds/"+$buildId+"?api-version=5.0"
$result = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

Write-Host "Status:" $result.status  
return $result
}

$azureDevopsProjectUrl = "https://dev.azure.com/"
$azureDevopsBase64AuthInfo = "YWRyaWFuLndhc2lleDdtcGpveDRmbjNtmwaXMyYWNjdXI1bDNpMms1cQ=="
$azureDevopsReleasedDefinitionId = "14"

$build = QueueAzureDevOpsBuild -collectionurl $azureDevopsProjectUrl -base64AuthInfo $azureDevopsBase64AuthInfo -releasedDefinitionId $azureDevopsReleasedDefinitionId

while ($build.status -ne "completed") {
    Start-Sleep -s 5
    $build = CheckAzureDevOpsBuild -buildId $build.id
}