
#Login to Azure
az login --service-principal --username $ENV:ARM_CLIENT_ID --password $ENV:ARM_CLIENT_SECRET --tenant $ENV:ARM_TENANT_ID
#Set the subscription context
az account set -s $env:ARM_SUBSCRIPTION_ID 
#Login to the cluster.

az aks Get-Credentials -g $env:K8S_RG_NAME  -n $env:K8S_NAME --overwrite-existing --admin

Function SendKubeHunterReportstoSlack()
{
    
    #find the pod name
    $podsjson = kubectl get pods -n devops-addons -o json | convertfrom-json
    $kube_hunter_pod_name = ($podsjson.items | where {$_.metadata.name -like "*kube-hunter*" -and $_.status.phase -like "*Succeeded*"}).metadata.name
    Write-Output "Pod name is -- $kube_hunter_pod_name"
    $logs = kubectl logs $kube_hunter_pod_name  -n $env:EXTRACT_LOGS_NAMESPACE
    
    $date = Get-Date -Format yyyy-MM 
    #after midnight date might change so just look for year and month pattern
    foreach($line in $logs){if($line -notlike "*$date*"){$json+=$line}}
    
    $Vulnerabilities = ($json | ConvertFrom-Json | select vulnerabilities).Vulnerabilities
    .\scripts\GenKubeHunterHTMLReport.ps1 -K8S_NAME $env:K8S_NAME -vulnerabilities $Vulnerabilities -htmlReportName "$env:HTML_REPORT_NAME"
        
}

Function SendOPAReportstoSlack()
{
    
}