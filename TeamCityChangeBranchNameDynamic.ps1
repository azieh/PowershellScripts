$branchName = "refs/heads/release/"##"%build.branchName%"
$filteredBranchName = [regex]::match($branchName,'\d+(\.\d+)+').Groups[0].Value
$buildCounter = "%build.counter%"
Write-Host $filteredBranchName
$currentVerison = "%Version%"
Write-Host $currentVerison
if ($filteredBranchName -ne $currentVerison -and $branchName -NotLike "*release*" ) { 
    $buildCounter = 1
    $baseUri = "http://xc-s-aiw0233.xc.abb.com:8282/app/rest/buildTypes/Ccrp_Stage_CiRelease/"
    $buildCounterUri = $baseUri + "settings/buildNumberCounter"
    $buildVersionUri = $baseUri + "parameters/Version"
    $TeamCityPassword = "eyJ0eXAiOiAiVENWMiJ9.SVVhQ0RicWdwd3VtZE9uTzZkVE1xYnVPNmtr.NWFhN2EzM2YtODI0ZC00NGVhLTlmODktNTVkNTBhZDRjYjY5"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $TeamCityPassword")
    $headers.Add("Content-Type", "text/plain")
    (Invoke-RestMethod -Method Put -Headers $headers -Uri $buildCounterUri -Body $buildCounter)
    (Invoke-RestMethod -Method Put -Headers $headers -Uri $buildVersionUri -Body $filteredBranchName)
    
}
if($branchName -NotLike "*release*"){
    Write-Host "##teamcity[buildNumber '$filteredBranchName.$buildCounter']"
}
