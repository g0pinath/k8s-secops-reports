# Introduction

This repo extracts the logs from kubehunter, kube-bench and OPA gatekeeper constraints and publishes them as readable reports.
This is when you are running multiple clusters and would like to consolidate these reports into a slack channel or email based alerts for monitoring/operations team.

- DefectDojo natively supports kube-bench, so we publish the JSON reports to DefectDojo for kube-bench.
- kubehunter and OPA gatekeeper reports are sent to Slack.
- Scan the container images(for the pods in the cluster) using clair CLI and report via Slack.
- Scan the publicly exposed endpoints using OWASP ZAP and publish them in DefectDojo.
  
# Usage

## Option 1: Setup Git Action Workflows that runs on a schedule and reports.

### List of workflows and their description.

**Kubernetes Vulnerability Scan**
  * Scan the kubernetes cluster using Kube-bench.
  * Scan the Kubernetes cluster using kube-hunter

**Kubernetes Policy Status Report***
  * Report the status of Gatekeeper policies that are not compliant. 
 
  `Note: Policies that are set to audit instead of fail(like say a label checker - we dont want to push back too much and hold a Prod Release hostage, just because they missed a label) needs to be reported so we can follow-up and ensure that it stays compliant.`

## Option 2: Setup CronJobs inside the cluster and they will generate and send the reports.




# Future - WIP
**Validate the cluster against AKS checklist**
  The idea is to validate your cluster against best practices guide put together by MS.https://www.the-aks-checklist.com/
  You can have your own standards too and validate against that.
