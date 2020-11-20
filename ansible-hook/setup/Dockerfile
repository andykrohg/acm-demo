FROM registry.redhat.io/ansible-tower-37/ansible-tower-rhel7:3.7.3
USER root
RUN umask 0022
RUN virtualenv /var/lib/awx/venv/ansible
RUN /var/lib/awx/venv/ansible/bin/pip install -U openshift google-auth
USER awx
