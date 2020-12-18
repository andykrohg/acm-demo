## Setup
1. Deploy ACM to OpenShift using the Operator. This will be your **hub cluster**.
2. Setup managed clusters in ACM (including local cluster). Apply the label `role=feature-candidate` to one cluster, and `role=stable` to all other clusters.
3. Deploy Ansible Tower (tested with 3.7.3), ensuring that the `openshift` `google-auth` pip modules are installed. One way to do this would be use my custom task-runner image for an openshift deployment, specifying `kubernetes_task_image: quay.io/akrohg/ansible-task` in the `group_vars` of your [openshift installer](https://releases.ansible.com/ansible-tower/setup_openshift/). I installed Tower in this way on the **ACM Hub cluster**.
4. Edit the `vars` in `ansible-hook/setup/main.yml` to provide creds and endpoints for Ansible Tower, your Hub cluster, and your spoke clusters.
5. Setup for Ansible Tower. This performs the following:
* Create an API key for Tower
* Import this repo as a *Project* for Tower
* Create a Job Template in Tower to run as a post hook to the ACM Application Deployment
* Create a Secret in your **hub cluster** to authenticate to Tower
* Subscribe to the **Ansible Automation Platform Resource Operator** in your **hub cluster**
* Create `ClusterRoleBindings` required for the app service account to read node info and report what cloud it's running on. I previously included this in the app workload itself, but the Reconciliation failed from ACM - i suspect insufficient privileges.
* Install Gatekeeper for managing `K8sExternalIPs` objects in all clusters
* Install Open Policy Agent for enforcing the external-ips `Policy`
* Installs an Apache HTTPD load balancer to your **hub cluster**. Deploy an Apache HTTPD load balancer to your **hub cluster** in the **acm-demo** namespace. This will load balance between app deployments across managed clusters. No apps have been created yet, so this should initially return a 503.
```bash
ansible-playbook ansible-hook/setup/main.yml
```


## Performing the Demo
> NOTE: Run all commands against your **hub cluster**.
1. Add the app subscription:
```bash
./run-deployment.sh -s
```

This will apply `v1` of the app to your `feature-candidate` cluster. The `AnsibleJob` should run and update the `ConfigMap` of the load balancer to target your newly deployed app. This probably takes about 4 minutes. Refresh the load balancer route in your browser to see that it's now resolving.

2. Release `v1` to stable clusters:
```bash
./run-deployment.sh -v v1
```

This will apply `v1` of the app to all managed clusters (both `feature-candidate` and `stable`). A new `AnsibleJob` resource should be created which will update the load balancer to distribute traffic among all clusters. This may take another 4 minutes or so - refresh the load balancer a few times to see (based on the zone/provider reported by the app) that traffic distributed using a round robin strategy.

3. Go to Govern risk in ACM and enable the **external-ips** policy. To illustrate control over [this vulnerability](https://access.redhat.com/security/cve/cve-2020-8554). You'll notice the `Service` in v1 of the app has an `externalIPs` attribute which triggers a policy violation on all clusters. You can use the Web Terminal to find the affected `Service` across all clusters by running:
```bash
searc kind:Service name:deployment-example
```


4. Release `v2` to your feature candidate cluster to address the vulnerability:
```bash
./run-deployment.sh -v v2-alpha
```

After reconciliation, refreshing on the load balancer should show that your feature candidate cluster has been upgraded to `v2` of the app. Notice (after a minute) that the Policy violations decreases by one.

5. Release `v2` to stable clusters, to address remaining policy violations:
```bash
./run-deployment.sh -v v2
```
