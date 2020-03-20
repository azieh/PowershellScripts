


$PWord = ConvertTo-SecureString -String '***' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList '***', $PWord
#       Skip checking certificate CA&CN as we are using selfsigned one
$soptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
$remoteSession = New-PSSession -ComputerName 'xxx' -Port 5985 -Credential $cred -SessionOption $soptions #-UseSSL
Invoke-Command -Session $remoteSession -ScriptBlock {
    ### Request MACHINE DEPENDENT CSR for domain
    ### Based on https://4sysops.com/archives/create-a-certificate-request-with-powershell/
    function Get-DomainCSR {
        param ( [string]$CertName )
        $CSRPath = "d:\operational\temp"
        $Signature = '$Windows NT$' 
        $INF = @"
[Version]
Signature="$Signature" 
[NewRequest]
RequestType=PKCS10
Subject="CN=$CertName, O=ABB Information Systems Ltd., L=Baden, C=CH"
KeyLength=2048
Exportable=TRUE
MachineKeySet=TRUE
ProviderName="Microsoft RSA SChannel Cryptographic Provider"
ProviderType=12
KeySpec=1
SMIME=FALSE
[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1
"@
        write-Host "Certificate Request is being generated `r "
        md $CSRPath -force
        $INF | out-file -filepath "$CSRPath\$($CertName)_.inf" -force
        certreq -new "$CSRPath\$($CertName)_.inf" "$CSRPath\$($CertName)_.csr"
        if ($?) {
            write-output "Certificate Request has been generated:"
            Get-Content $CSRPath\$($CertName)_.csr | write-output
        }
        else {
            Write-Host ERROR: Failed with $?
            $errorsEncountered += $module
            ###       shitty sleep just for DEBUG
            sleep 3
        }
    }
    Get-DomainCSR "domain.com"
    
}