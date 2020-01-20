function InvokeCcrp {
    param (
        $api = '',
        $env = 'prod',
        $auth = ''
    )

    $headers = @{
        'ccrpApiVersion' = '1.0';
        'email'          = 'tomasz.kaczor@pl.abb.com', 'ziemowit.kustra@pl.abb.com', 'adrian.wasielewski@pl.abb.com', 'tomasz.platek@pl.abb.com', 'andrzej.zezula@pl.abb.com' | Get-Random;
        'xOriginAppName' = 'mobile';
        'Content-Type'   = 'application/json';
        'Authorization'  = $auth
    }
    $timeIn = Get-Date
    try {
        $url = 'https://abb-ccrp-api-proxy-'+$env+'.ir-e1.cloudhub.io/api/'+$api
        Invoke-WebRequest $url -Method 'GET' -Headers $headers | Out-Null
        
    }
    catch {
        Write-Host $_.Exception.Response.StatusCode.value__
    }
    $timeEnd = Get-Date
    $timeOut = NEW-TIMESPAN -Start $timeIn -End $timeEnd
    Write-Host $env $timeOut $api 
}

while ($true) {
    
    $myIssue = 'my/issues?page=1&pageSize=30'
    # InvokeCcrp -api $myIssue -env 'prod' -auth 'Basic Y2NycC1saWdodC11c2VyOkF2NFhkODNJTDA1NndYSHF2NDlw'
     InvokeCcrp -api $myIssue -env 'stage' -auth 'Basic Y2NycC1saWdodC11c2VyLXN0YWdlOktyV2tINDhnY1ZrekdHeWR2SE1H'
    #InvokeCcrp -api $myIssue -env 'dev' -auth 'Basic cmVzdFVzZXI6RXFOcklPMkcxYWVwdnBIdGZBMmc='
    Start-Sleep -Seconds 1
    $myIssue = 'hc'
    # InvokeCcrp -api $myIssue -env 'prod' -auth 'Basic Y2NycC1saWdodC11c2VyOkF2NFhkODNJTDA1NndYSHF2NDlw'
     InvokeCcrp -api $myIssue -env 'stage' -auth 'Basic Y2NycC1saWdodC11c2VyLXN0YWdlOktyV2tINDhnY1ZrekdHeWR2SE1H'
    #InvokeCcrp -api $myIssue -env 'dev' -auth 'Basic cmVzdFVzZXI6RXFOcklPMkcxYWVwdnBIdGZBMmc='

}
