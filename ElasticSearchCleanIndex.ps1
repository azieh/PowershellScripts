Write-Host "Elasticsearch index cleanup"

$uri = $ElasticSearch_url + "/_all/"

Write-Host "Try to delete index at" + $uri

try {

    Invoke-WebRequest -Uri $uri -Method Delete 
    Write-Host "Index cleaned successfully"
}
catch {
    Write-Host "Index cleaned faild, propably service is stoped. Process can be continued"
}
