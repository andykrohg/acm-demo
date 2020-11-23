1. Deploy ACM to OpenShift using the Operator. 
2. Deploy Ansible Tower (tested with 3.7.3), ensuring that the `openshift` `google-auth` pip modules are installed. One way to do this would be use my custom task-runner image for an openshift deployment, specifying `kubernetes_task_image: quay.io/akrohg/ansible-task` in the `group_vars` of your [openshift installer](https://releases.ansible.com/ansible-tower/setup_openshift/). I installed Tower in this way on the **ACM Hub cluster**.
3. Edit the `vars` in `ansible-hook/setup/main.yml` to provide creds and endpoints for Ansible Tower, your Hub cluster, and your spoke clusters.
4. Setup Ansible Tower: `ansible-playbook ansible-hook/setup/main.yml`
5. Deploy an Apache HTTPD load balancer to your **hub cluster**.
```bash
oc apply -k load-balancer
```
6. Add the app subscription to your **hub cluster**:
```bash
oc apply -k subscription
```