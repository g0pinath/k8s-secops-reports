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
The below secrets needs to be created in GIT.
- DEPLOY_TOKEN_GITHUB - This is required for the workflow to create git deployments. The default token doesnt have the permissions, use your git account to create a PAT with permissions to create deployments in git.
- ARM_CLIENT_ID - SPN client ID - this should be able to login to the cluster and have reader access, and editor access on the storage account.
- ARM_CLIENT_SECRET - SPN client secret
- ARM_TENANT_ID - SPN Azure AD tenant ID
- ARM_SUBSCRIPTION_ID  - Subscription ID where the AKS cluster exists
- SLACK_CHANNEL_TOKEN - the webhook for the slack channel
- DOCKER_REGISTRY_PASSWORD - if you dont intend to update the scripts and push to your docker registry, then skip this.
- DEV_AZURE_CREDENTIALS - this should contain clientid, clientsecret, tenantid and subscriptionid in JSON format.
       {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>"        
        }
- Review the dev-k8s-secops-reports-build-deploy.yml file and update the below variables accordingly.
  - K8S_RG_NAME - Resource group name where AKS exists.
  - DOCKER_REGISTRY_USER - if you dont intend to update the scripts and push to your docker registry, then skip this.
  - K8S_NAME - AKS name you are connecting to.
  - REPO_NAME - If you are forking, change this to your docker repo name
  - SA_RG_NAME - Storage account RG name where the HTML reports will be checked into.
  - SA_NAME - Storage account  name where the HTML reports will be checked into.
  - BUILD_REQUIRED - set this to FALSE, if you are using this workflow only for deploying. You can use the docker registry image g0pinath/k8s-secops-reports in this case

### List of workflows and their description.
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
$env:EXTRACT_LOGS_NAMESPACE - default is devops-addons, this is the namespace where kube-hunter and kube-bench are running.

# Future - WIP
**Validate the cluster against AKS checklist**
  The idea is to validate your cluster against best practices guide put together by MS.https://www.the-aks-checklist.com/
  You can have your own standards too and validate against that.
