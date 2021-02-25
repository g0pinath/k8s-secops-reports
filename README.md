# k8s-secops-reports

## Introduction

This repo the following and reports them to DefectDojo.
  
 **Container Image Scan**
  * Scan (using Clair CLI) all of the images used by Deployment, StatefulSet and Cronjobs
  * On the application repo, scan the image on every commit to a develop branch. If the results are acceptable, commit them to the container registry or fail the workflow/pipeline.
  * Scan the dockerfile to ensure that distroless image is used

**OWAS Scan of App Endpoints**
  * Scan the applications publicly exposed URLs using OWASP ZAP proxy.

**Kubernetes Vulnerability Scan**
  * Scan the kubernetes cluster using Kube-bench.
  * Scan the Kubernetes cluster using kube-hunter

**Kubernetes Policy Status Report***
  * Report the status of Gatekeeper policies that are not compliant. 
  _Note:_Policies that are set to audit instead of fail(like say a label checker - we dont want to push back too much and hold a Prod Release hostage, just because they missed a label) needs to be reported so we can follow-up and ensure that it stays compliant.

**Validate the cluster against AKS checklist**
  * WIP.
  The idea is to validate your cluster against best practices guide put together by MS.https://www.the-aks-checklist.com/
  You can have your own standards too and validate against that.
