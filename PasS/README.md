INDIGO PaaS check script
========================

This script deploy a small VM using INDIGO PaaS and send an e-mail to the configured address if the deployment fails.

To be used with a cron job.

Requirements
------------

The script exploits oidc-agent and orchent: https://github.com/maricaantonacci/deep-tutorials/blob/master/orchent_tutorial.md

Copy this script in the same directory of INDIGO PaaS check script: https://raw.githubusercontent.com/indigo-dc/orchestrator/master/tools/monitoring-probes/health-check.sh

Installation
------------

Clone the git repository and configure a cron job.

Cron job
--------
Run

``cronatab -e``

and add this line:

``0 */2 * * * /opt/control-script/control-script.sh``
