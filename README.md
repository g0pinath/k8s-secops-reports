# Introduction

This repo extracts the logs from kubehunter, kube-bench and OPA gatekeeper constraints and publishes them as readable reports.
This is when you are running multiple clusters and would like to consolidate these reports into a slack channel or email based alerts for monitoring/operations team.

- DefectDojo natively supports kube-bench, so we publish the JSON reports to DefectDojo for kube-bench.
- kubehunter and OPA gatekeeper reports are sent to Slack.
- Scan the container images(for the pods in the cluster) using clair CLI and report via Slack.
- Scan the publicly exposed endpoints using OWASP ZAP and publish them in DefectDojo.
  
# Usage

## Pre-requsites:
- An existing AKS cluster with RBAC enabled.
- The SPN(Azure app registration) needs to have Azure RBAC permissions of "Azure Kubernetes Service RBAC Reader" or above.
- The SPN also needs contributor access on the storage account to which the HTML reports will be checked-in to.
## Option 1: Setup Git Action Workflows that runs on a schedule and reports.

### List of workflows and their description.

**Kubernetes Vulnerability Scan**
  * Scan the kubernetes cluster using Kube-bench.
  * Scan the Kubernetes cluster using kube-hunter

**Kubernetes Policy Status Report***
  * Report the status of Gatekeeper policies that are not compliant. 
 
  `Note: Policies that are set to audit instead of fail(like say a label checker - we dont want to push back too much and hold a Prod Release hostage, just because they missed a label) needs to be reported so we can follow-up and ensure that it stays compliant.`

## Option 2: Setup CronJobs inside the cluster and they will generate and send the reports.

Set the following environment variables and run the helm chart.
### Mandatory environment variables
$ENV:ARM_CLIENT_ID - SPN client ID - this should be able to login to the cluster and have reader access, and editor access on the storage account.
$ENV:ARM_CLIENT_SECRET - SPN client secret
$ENV:ARM_TENANT_ID - SPN Azure AD tenant ID
$env:ARM_SUBSCRIPTION_ID  - Subscription ID where the AKS cluster exists
$env:K8S_RG_NAME - Resource group name where AKS exists.
$env:K8S_NAME - AKS name you are connecting to.
$env:SA_RG_NAME - Storage account RG name where the HTML reports will be checked into.
$ENV:SA_NAME - Storage account  name where the HTML reports will be checked into.
$env:SLACK_CHANNEL_TOKEN - the webhook for the slack channel
### Optional (to override the defaults)
$env:KUBEHUNTER_HTML_REPORT_NAME - default is kube_hunter_reports.html
$env:OPA_HTML_REPORT_NAME - default is opa_gatekeeper_reports.html
$env:containerName - default is reports
$env:EXTRACT_LOGS_NAMESPACE - default is devops-addons

# Future - WIP
**Validate the cluster against AKS checklist**
  The idea is to validate your cluster against best practices guide put together by MS.https://www.the-aks-checklist.com/
  You can have your own standards too and validate against that.
