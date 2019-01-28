#!/bin/bash

# oidc-agent configuration
test -e /home/ubuntu/tmp/oidc-agent.env && . /home/ubuntu/tmp/oidc-agent.env
export ORCHENT_AGENT_ACCOUNT=laniakea-marco
export ORCHENT_URL="https://paas-orchestrator.cloud.ba.infn.it"

# Run check script.
/usr/bin/python /opt/control-script/control-script.py -m laniakea.testuser@gmail.com -c "/opt/control-script/health-check.sh" -u "https://paas-orchestrator.cloud.ba.infn.it" -r /opt/control-script/node_with_image.yaml
