
Param($containerName='reports', 
    $KUBEHUNTER_HTML_REPORT_NAME="kube_hunter_reports.html", 
    $OPA_HTML_REPORT_NAME = "opa_gatekeeper_reports.html",
    $EXTRACT_LOGS_NAMESPACE="devops-addons")
#Install the required modules.
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted  
Install-Module PSSlack
Install-Module Az.Storage
Install-Module Az.Accounts
Install-Module powershell-yaml
#Import them
Import-Module Az.Storage
Import-Module Az.Accounts
Import-Module PSSlack
Import-Module powershell-yaml
#Login to Azure
az login --service-principal --username $ENV:ARM_CLIENT_ID --password $ENV:ARM_CLIENT_SECRET --tenant $ENV:ARM_TENANT_ID
$spnSecret = ConvertTo-SecureString -AsPlainText $ENV:ARM_CLIENT_SECRET -Force
$credentials = New-Object System.Management.Automation.PSCredential($ENV:ARM_CLIENT_ID, $spnSecret)

Login-AzAccount -ServicePrincipal -Tenant $ENV:ARM_TENANT_ID -Credential $credentials
Select-AzSubscription -Subscription $env:ARM_SUBSCRIPTION_ID 
#Set the subscription context
az account set -s $env:ARM_SUBSCRIPTION_ID 
#Login to the cluster.
az aks Get-Credentials -g $env:K8S_RG_NAME  -n $env:K8S_NAME --overwrite-existing --admin


Function SendReporttoSlack($HTML_REPORT_NAME,$SLACK_TITLE, $SLACK_PRE_TEXT)
{
    Set-AzCurrentStorageAccount -ResourceGroupName $env:SA_RG_NAME  -Name $ENV:SA_NAME
    if(($env:containerName).Length -ne 0)
    {
        $containerName = $env:containerName
    }
    $blobName = "$env:K8S_NAME/$HTML_REPORT_NAME"
    $destinationFileName = "$HTML_REPORT_NAME"
    Set-AzStorageBlobContent -Container "$containerName" -File "$destinationFileName" `
    -Blob "$blobName" -Force 
    #wait a moment for the blob to show up!
    Start-Sleep -S 60
    $StartTime = Get-Date 
    $EndTime = (Get-Date).AddHours(24)
    $sasToken = New-AzStorageBlobSASToken -Container $containerName -Blob $blobName  -Permission rl -StartTime $StartTime -ExpiryTime $EndTime
    $URL = "https://"+ "$env:SA_NAME" + ".blob.core.windows.net/" + $containerName + "/" + $blobName + $sasToken
    
    
    $SLACK_CHANNEL_TOKEN = $env:SLACK_CHANNEL_TOKEN
    $att = New-SlackMessageAttachment -Color $_PSSlackColorMap.green `
                        -Title $SLACK_TITLE  `
                        -TitleLink $url `
                        -Pretext $SLACK_PRE_TEXT `
                        -Fallback 'IIS and Website validation reports' 
    Send-SlackMessage -Uri $SLACK_CHANNEL_TOKEN -Attachments $att 
}

if(($env:EXTRACT_LOGS_NAMESPACE).Length -ne 0)
    {
        $EXTRACT_LOGS_NAMESPACE = $env:EXTRACT_LOGS_NAMESPACE
    }
Function GenerateKubeHunterReports()
{
    if(($env:KUBEHUNTER_HTML_REPORT_NAME).Length -ne 0)
    {
        $KUBEHUNTER_HTML_REPORT_NAME = $env:KUBEHUNTER_HTML_REPORT_NAME
    }
    $SLACK_TITLE = "Click here to download kube-hunter vulnerability report for $env:K8S_NAME"
    $SLACK_PRE_TEXT = "kube-hunter vulnerability report"
    #find the pod name
    $podsjson = kubectl get pods -n devops-addons -o json | convertfrom-json
    $kube_hunter_pod_name = ($podsjson.items | where {$_.metadata.name -like "*kube-hunter*" -and $_.status.phase -like "*Succeeded*"}).metadata.name
    Write-Output "Pod name is -- $kube_hunter_pod_name"
    $logs = kubectl logs $kube_hunter_pod_name  -n $EXTRACT_LOGS_NAMESPACE
    
    $date = Get-Date -Format yyyy-MM 
    #after midnight date might change so just look for year and month pattern
    foreach($line in $logs){if($line -notlike "*$date*"){$json+=$line}}    
    $Vulnerabilities = ($json | ConvertFrom-Json | select vulnerabilities).Vulnerabilities
    /scripts/GenKubeHunterHTMLReport.ps1 -K8S_NAME $env:K8S_NAME -vulnerabilities $Vulnerabilities -htmlReportName "$KUBEHUNTER_HTML_REPORT_NAME"
   #Send the report to Slack.
   SendReporttoSlack $KUBEHUNTER_HTML_REPORT_NAME $SLACK_TITLE $SLACK_PRE_TEXT
}

GenerateKubeHunterReports
Function GenerateOPAReports()
{
    if(($env:OPA_HTML_REPORT_NAME).Length -ne 0)
    {
        $OPA_HTML_REPORT_NAME = $env:OPA_HTML_REPORT_NAME
    }    
    $SLACK_TITLE = "Click here to download OPA-Gatekeeper Compliance report for $env:K8S_NAME"
    $SLACK_PRE_TEXT = "OPA-Gatekeeper Compliance report"
    $json = (kubectl get constraints -o yaml) | ConvertFrom-Yaml | ConvertTo-Json -Depth 100 | ConvertFrom-Json

    /scripts/GenOPAHTMLReport.ps1 -K8S_NAME $env:K8S_NAME -json $json -htmlReportName "$OPA_HTML_REPORT_NAME"
   #Send the report to Slack.
   SendReporttoSlack $OPA_HTML_REPORT_NAME $SLACK_TITLE $SLACK_PRE_TEXT
}
GenerateOPAReports