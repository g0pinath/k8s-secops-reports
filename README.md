# Introduction

This repo extracts the logs from kubehunter, kube-bench and OPA gatekeeper constraints and publishes them as readable reports.
This is when you are running multiple clusters and would like to consolidate these reports into a slack channel or email based alerts for monitoring/operations team.

- DefectDojo natively supports kube-bench, so we publish the JSON reports to DefectDojo for kube-bench.
- kubehunter and OPA gatekeeper reports are sent to Slack.
- Scan the container images(for the pods in the cluster) using clair CLI and report via Slack(WIP)
- Scan the publicly exposed endpoints using OWASP ZAP and publish them in DefectDojo(WIP)
  
# Usage

## Pre-requsites:
- An existing AKS cluster with RBAC enabled. It's assumed that you have kube-hunter, kube-bench and OPA deployed in devops-addons namespace.

`There must be atleast one pod that is in completed state for kube-hunter and kube-bench, if not use the below command to start a job. Only if the job completed, we have log output to extract.`

`kubectl create job --from=cronjob/<kube-hunter-cronjobname> kube-hunter-abc -n devops-addons`
`kubectl create job --from=cronjob/<kube-bench-cronjobname> kube-bench-abc -n devops-addons`

- The SPN(Azure app registration) needs to have Azure RBAC permissions of "Azure Kubernetes Service RBAC Reader" or above.
- The SPN also needs contributor access on the storage account to which the HTML reports will be checked-in to.
## Option 1: Setup Git Action Workflows that runs on a schedule and sends the reports to Slack and DefectDojo.
The below secrets needs to be created in GIT. The below secrets are consumed as env vars by the workflows in Git.
| EnvVarName | Description |
| - | - |
| DEV_ARM_CLIENT_ID |  SPN client ID - this should be able to login to the cluster and have reader access, and editor access on the storage account. |
| DEV_ARM_CLIENT_SECRET | SPN client secret |
| DEV_ARM_TENANT_ID | SPN Azure AD tenant ID |
| DEV_ARM_SUBSCRIPTION_ID | Subscription ID where the AKS cluster exists |
| DEV_K8S_RG_NAME |  Resource group name where AKS exists.|
| DEV_K8S_NAME | AKS name you are connecting to. |
| DEV_SA_RG_NAME | Storage account RG name where the HTML reports will be checked into. |
| DEV_SA_NAME |  Storage account  name where the HTML reports will be checked into. |
| DEV_REPORTS_STORAGE_KEY |  Storage account Key for 'DEV_SA_NAME' where the HTML reports will be checked into. |
| SLACK_CHANNEL_TOKEN |  the webhook for the slack channel |
| DEPLOY_TOKEN_GITHUB |  This is required for the workflow to create git deployments. The default token doesnt have the permissions, use your git account to create a PAT with permissions to create deployments in git. |
| DOCKER_REGISTRY_PASSWORD |  if you dont intend to update the scripts and push to your docker registry, then skip this. |
| DEV_AZURE_CREDENTIALS |  this should contain clientid, clientsecret, tenantid and subscriptionid in JSON format                                                   {"clientId": "<GUID>", "clientSecret": "<GUID>", "subscriptionId": "<GUID>", "tenantId": "<GUID>"}|
| DD_ADMIN_PWD | DefectDojo admin password - this is used to publish kube-bench reports |


- The below env vars are hardcoded in the workflow file and needs to be reviewed and updated accordingly.

| EnvVarName | WorkFlowToReview | Description |
| - | - | - |
| DOCKER_REGISTRY_USER | Dev-K8S-SecOps-Reports-BuildNDeploy |  if you dont intend to update the scripts and push to your docker registry, then skip this. |
| k8sNamespace | Dev-K8S-SecOps-Reports-BuildNDeploy | where should this solution that sends the Slack reports be deployed to? - default is devops-addons |
| DOCKER_REGISTRY_USER | Dev-K8S-SecOps-Reports-BuildNDeploy |  Change this to your Docker hub registry user, if you intend to update the code and push it to your registry. BUILD_REQUIRED should be set to TRUE in this case with your password, so the build can be pushed to your registry. |
| BUILD_REQUIRED | Dev-K8S-SecOps-Reports-BuildNDeploy |  set this to FALSE, if you are using this workflow only for deploying. You can use the docker registry image g0pinath/k8s-secops-reports in this case |
| Kube_Bench_Engagement_Name | Publish-Kube-Bench-reports-2DefectDojo | The engagement name in DefectDojo, default is kube-bench |
| DD_Admin_User | Publish-Kube-Bench-reports-2DefectDojo | DefectDojo admin username |
| HTML_REPORT_NAME | Send-Kube-Hunter-Results-2Slack, Send-OPA-Gatekeeper-Compliance-2Slack | to override default values. |
| EXTRACT_LOGS_NAMESPACE | Send-Kube-Hunter-Results-2Slack, Send-OPA-Gatekeeper-Compliance-2Slack | Where the kube-hunter and kube-bench are running - default is devops-addons, if your kube-hunter and kube-bench jobs arent running on this namespace, then update the correct one.|


- Run the workflow 'Dev-K8S-SecOps-Reports-BuildNDeploy' to deploy the CronJob in the cluster.
- Run the following workflows as per your requirements.
  - 'Publish-Kube-Bench-reports-2DefectDojo' - Review Publish-Kube-Bench-reports-2DefectDojo.yml  and update the DefectDojo URL to match your setup. Also, update the environment variables as required.
  - 'Send-Kube-Hunter-Results-2Slack ' - Review Send-Kube-Hunter-Results-2Slack.yml  and update the environment variables as required - for exampl
  - 'Send-OPA-Gatekeeper-Compliance-2Slack' - Review Send-OPA-Gatekeeper-Compliance-2Slack.yml  and update the DefectDojo URL to match your setup. Also, update the environment variables as required.

## Option 2: Deploy via helm - Setup CronJobs inside the cluster and they will generate and send the reports.

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
| k8sNamespace |  Where to deploy this helm chart? |

### Optional (to override the defaults)
| EnvVarName | Description |
| - | - |
| KUBEHUNTER_HTML_REPORT_NAME |  default is kube_hunter_reports.html |
| OPA_HTML_REPORT_NAME | default is opa_gatekeeper_reports.html |
| containerName |  default is reports - this container must exist or the script will fail. |
| EXTRACT_LOGS_NAMESPACE |  default is devops-addons, this is the namespace where kube-hunter and kube-bench are running. |

From the root folder of this repo execute the below from PowerShell

`helm upgrade --install html-reporting-app ./charts/html-reporting-app --namespace $env:k8sNamespace --wait --set buildID=latest -f ./charts/html-reporting-app/dev.values.yaml --set envVars.ARM_CLIENT_ID="$ENV:ARM_CLIENT_ID"  --set envVars.ARM_CLIENT_SECRET="$ENV:ARM_CLIENT_SECRET" --set envVars.ARM_TENANT_ID="$ENV:ARM_TENANT_ID"  --set envVars.ARM_SUBSCRIPTION_ID="$ENV:ARM_SUBSCRIPTION_ID" --set envVars.K8S_RG_NAME="$ENV:K8S_RG_NAME"  --set envVars.K8S_NAME="$ENV:K8S_NAME" --set envVars.SA_RG_NAME="$ENV:SA_RG_NAME"  --set envVars.SA_NAME="$ENV:SA_NAME" --set envVars.SLACK_CHANNEL_TOKEN="$ENV:SLACK_CHANNEL_TOKEN" `

## Option 3: Run on ad-hoc basis via docker (from powershell)

Remember that there should be atleast one pod that is completed state for kube-hunter and kube-bench for the script to extract the logs from.

Set the following environment variables 
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
| EXTRACT_LOGS_NAMESPACE | where the kube-hunter and kube-bench pods are running - default is devops-addons |

` docker run  -e ARM_CLIENT_ID="$env:ARM_CLIENT_ID" -e ARM_TENANT_ID="$env:ARM_TENANT_ID" -e ARM_CLIENT_SECRET="$env:ARM_CLIENT_SECRET"  -e ARM_SUBSCRIPTION_ID="$env:ARM_SUBSCRIPTION_ID" -e K8S_RG_NAME="$env:K8S_RG_NAME" -e K8S_NAME="$env:K8S_NAME" -e SA_RG_NAME="$env:SA_RG_NAME"  -e SA_NAME="$env:SA_NAME"  -e SLACK_CHANNEL_TOKEN="$env:SLACK_CHANNEL_TOKEN" -e EXTRACT_LOGS_NAMESPACE="$env:EXTRACT_LOGS_NAMESPACE" g0pinath/k8s-secops-reports:latest `

## Workflow Status
 | Name | Trigger | Status |
  | - | - | - |
  Release Drafter | When a Git release is published. | ![Release Drafter](https://github.com/g0pinath/k8s-secops-reports/workflows/Release%20Drafter/badge.svg)<br>
  Publish-Kube-Bench-reports-2DefectDojo | Runs on schedule | ![Publish-Kube-Bench-reports-2DefectDojo](https://github.com/g0pinath/k8s-secops-reports/workflows/Publish-Kube-Bench-reports-2DefectDojo/badge.svg)<br>
  Dev-K8S-SecOps-Reports-BuildNDeploy | on commit to Develop branch. |![Dev-K8S-SecOps-Reports-BuildNDeploy](https://github.com/g0pinath/k8s-secops-reports/workflows/Dev-K8S-SecOps-Reports-BuildNDeploy/badge.svg)<br>
  Send-Kube-Hunter-Results-2Slack | Runs on schedule |![Send-Kube-Hunter-Results-2Slack](https://github.com/g0pinath/k8s-secops-reports/workflows/Send-Kube-Hunter-Results-2Slack/badge.svg)<br>
  Send-OPA-Gatekeeper-Compliance-2Slack |Runs on schedule|![Send-OPA-Gatekeeper-Compliance-2Slack](https://github.com/g0pinath/k8s-secops-reports/workflows/Send-OPA-Gatekeeper-Compliance-2Slack/badge.svg)| 
  create-release-package|publish the package for every release|![LintCodeBase](https://github.com/g0pinath/k8s-secops-reports/workflows/create-release-package/badge.svg)| 

# Future - WIP
**Validate the cluster against AKS checklist**
  The idea is to validate your cluster against best practices guide put together by MS.https://www.the-aks-checklist.com/
  You can have your own standards too and validate against that.
