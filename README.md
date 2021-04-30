# Introduction

This repo extracts the logs from kubehunter, kube-bench and OPA gatekeeper constraints and publishes them as readable reports.
This is when you are running multiple clusters and would like to consolidate these reports into a slack channel or email based alerts for monitoring/operations team.

- DefectDojo natively supports kube-bench, so we publish the JSON reports to DefectDojo for kube-bench.
- kubehunter and OPA gatekeeper reports are sent to Slack.
- Scan the container images(for the pods in the cluster) using clair CLI and report via Slack.
- Scan the publicly exposed endpoints using OWASP ZAP and publish them in DefectDojo.
  
# Usage

## Pre-requsites:
- An existing AKS cluster with RBAC enabled. It's assumed that you have kube-hunter, kube-bench and OPA deployed in devops-addons namespace.

`There must be atleast one pod that is in completed state for kube-hunter and kube-bench, if not use the below command to start a job. Only if the job completed, we have log output to extract.`

`kubectl create job --from=cronjob/<kube-hunter-cronjobname> kube-hunter-abc -n devops-addons`
`kubectl create job --from=cronjob/<kube-bench-cronjobname> kube-bench-abc -n devops-addons`

- The SPN(Azure app registration) needs to have Azure RBAC permissions of "Azure Kubernetes Service RBAC Reader" or above.
- The SPN also needs contributor access on the storage account to which the HTML reports will be checked-in to.
## Option 1: Setup Git Action Workflows that runs on a schedule and reports.
The below secrets needs to be created in GIT.
| EnvVarName | Description |
| - | - |
| ARM_CLIENT_ID |  SPN client ID - this should be able to login to the cluster and have reader access, and editor access on the storage account. |
| ARM_CLIENT_SECRET | SPN client secret |
| ARM_TENANT_ID | SPN Azure AD tenant ID |
| ARM_SUBSCRIPTION_ID | Subscription ID where the AKS cluster exists |
| K8S_RG_NAME |  Resource group name where AKS exists.|
| K8S_NAME | AKS name you are connecting to. |
| SA_RG_NAME | Storage account RG name where the HTML reports will be checked into. |
| SA_NAME |  Storage account  name where the HTML reports will be checked into. |
| SLACK_CHANNEL_TOKEN |  the webhook for the slack channel |
| DEPLOY_TOKEN_GITHUB |  This is required for the workflow to create git deployments. The default token doesnt have the permissions, use your git account to create a PAT with permissions to create deployments in git. |
| DOCKER_REGISTRY_PASSWORD |  if you dont intend to update the scripts and push to your docker registry, then skip this. |
| DEV_AZURE_CREDENTIALS |  this should contain clientid, clientsecret, tenantid and subscriptionid in JSON format.
       {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>"        
        }
        |


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

- Run the workflow 'Dev-K8S-SecOps-Reports-BuildNDeploy' to deploy the CronJob in the cluster.
- Run the following workflows as per your requirements.
  - 'Publish-Kube-Bench-reports-2DefectDojo' - Review Publish-Kube-Bench-reports-2DefectDojo.yml  and update the DefectDojo URL to match your setup. Also, update the environment variables as required.
  - 'Send-Kube-Hunter-Results-2Slack ' - Review Send-Kube-Hunter-Results-2Slack .yml  and update the environment variables as required - for exampl
  - 'Send-OPA-Gatekeeper-Compliance-2Slack' - Review Send-OPA-Gatekeeper-Compliance-2Slack.yml  and update the DefectDojo URL to match your setup. Also, update the environment variables as required.

## Option 2: Setup CronJobs inside the cluster and they will generate and send the reports.

Set the following environment variables and run the helm chart.
### Mandatory environment variables
| EnvVarName | Description |
| - | - |
| ARM_CLIENT_ID |  SPN client ID - this should be able to login to the cluster and have reader access, and editor access on the storage account. |
| ARM_CLIENT_SECRET | SPN client secret |
| ARM_TENANT_ID | SPN Azure AD tenant ID |
| ARM_SUBSCRIPTION_ID | Subscription ID where the AKS cluster exists |
| K8S_RG_NAME |  Resource group name where AKS exists.|
| K8S_NAME | AKS name you are connecting to. |
| SA_RG_NAME | Storage account RG name where the HTML reports will be checked into. |
| SA_NAME |  Storage account  name where the HTML reports will be checked into. |
| SLACK_CHANNEL_TOKEN |  the webhook for the slack channel |

### Optional (to override the defaults)
| EnvVarName | Description |
| - | - |
| KUBEHUNTER_HTML_REPORT_NAME |  default is kube_hunter_reports.html |
| OPA_HTML_REPORT_NAME | default is opa_gatekeeper_reports.html |
| containerName |  default is reports |
| EXTRACT_LOGS_NAMESPACE |  default is devops-addons, this is the namespace where kube-hunter and kube-bench are running. |


From the root folder of this repo execute the below from PowerShell

`helm upgrade --install $project ./charts/$project --namespace $env:k8sNamespace --wait --set buildID=$RunID -f ./charts/$project/dev.values.yaml --set envVars.ARM_CLIENT_ID="$ENV:ARM_CLIENT_ID"  --set envVars.ARM_CLIENT_SECRET="$ENV:ARM_CLIENT_SECRET" --set envVars.ARM_TENANT_ID="$ENV:ARM_TENANT_ID"  --set envVars.ARM_SUBSCRIPTION_ID="$ENV:ARM_SUBSCRIPTION_ID" --set envVars.K8S_RG_NAME="$ENV:K8S_RG_NAME"  --set envVars.K8S_NAME="$ENV:K8S_NAME" --set envVars.SA_RG_NAME="$ENV:SA_RG_NAME"  --set envVars.SA_NAME="$ENV:SA_NAME" --set envVars.SLACK_CHANNEL_TOKEN="$ENV:SLACK_CHANNEL_TOKEN" `
### List of workflows and their description.

# Future - WIP
**Validate the cluster against AKS checklist**
  The idea is to validate your cluster against best practices guide put together by MS.https://www.the-aks-checklist.com/
  You can have your own standards too and validate against that.
