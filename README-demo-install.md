## Wikibase Docker Read me for UIUC Library demo installation

This readme covers the installation steps for the demo implementation (demo.authorities.library.illinois.edu).
Also discussed is how the system is implemented in AWS and the important changes that were made to the 
Wikimedia Deutschland code
cloned from https://github.com/wmde/wikibase-docker.

This readme has three sections:
- AWS implementation.
- Important changes made after cloning from https://github.com/wmde/wikibase-docker.
- Installation steps.

### AWS implementation
Outline:
- Implemented in the Library's medusa project AWS account.
- The system runs on the wikibase-demo EC2.
- All the services, elasticsearch, mysql, the wdqs (wikidata query service) run 
on the EC2 and all the data is stored in the EBS volume attached to the EC2store.  
- Quickstatments is not installed as of this writing.
- Internet Traffic is routed to the EC2 via our demo AWS ALB (Application Load Balancer).
  The ALB along with Amazon's Certificate Manager hanlde the TLS certificates for this 
  implementation. The ALB with the associtated target groups route 
  demo.authorities.library.illinois to port 8181 
  (the wikibase webpages), and demo.authorities-sparql.library.illinois.edu 
  to port 8282 (the sparql query interface) on the EC2.
- Terraform was used to provision the AWS resources. The repo for the terraform code
is at https://code.library.illinois.edu/projects/TER/repos/aws-wikibase-demo-service/browse
  
### Important Changes made to https://github.com/wmde/wikibase-docker
Note: the Library's https://github.com/medusa-project/wikibase-docker-ideals repo was 
cloned from the master branch, commit 7b52e2a (7b52e2a9cbe74ff40ff41adf493d7f4d20b21dd3) of 
https://github.com/wmde/wikibase-docker

**Change to "hard code" the default docker network to 172.24.0.0/16**
- This change is so the IP range of the default docker network is fixed to 172.24.0.0/16. This allows the firewall (iptables) on the EC2 to allow traffic from the docker containers (whose IPs fall in that range) to the localhost. The change was to add a networks section to the docker-compose.yml file with settings for the default network.

**Changes needed to get SPARQL queries to work:**
- In the docker-compose.yml file, in the "wdqs:" service section, and then in 
the "environment:" section, the WIKIBASE_HOST environment variable is set to the IP 
address and port 8181 of the host EC2.  Example:  **WIKIBASE_HOST=10.225.250.218:8181**.  
This is needed for the SPARQL query interface to retrieve results correctly and for the results to show 
valid links to items.
Once fully implemeted this variable will be set the system URL. Example: 
**WIKIBASE_HOST=demo.authorities.library.illinois.edu**.
- In the docker-compose.yml file, in the "wdqs-updater:" service section, and then in 
the "environment:" section, the WIKIBASE_HOST environment variable is also set to the IP 
address and port 8181 of the host EC2.  Example:  **WIKIBASE_HOST=10.225.250.218:8181**.  
This is needed for the SPARQL query interface to retrieve results correctly and for the results to show 
valid links to items.
Once fully implemeted this variable will be set the system URL. Example: 
**WIKIBASE_HOST=demo.authorities.library.illinois.edu**.

**Changes needed so new login validation and forgot password emails work:**
- A new folder called "uiuc-library-config" was created for any files need to change 
configuration settings for the UIUC Library.
- The file ./wikibase/1.35/base/LocalSettings.php.template was copied to ./uiuc-library-config
- Then the file ./uiuc-library-config had additional configuration settings added to 
the end of the file. See the contents of the file after the line **"# Additions for UIUC Library wikibase"**. 
These are the settings needed to get emails to work.
- Then in the docker-compose.yml file, in the "wikibase:" service section, and then in
the "volumes:" section, a line was added to mount the new file over the file in the docker container. 
That line is **"- ./uiuc-library-config/LocalSettings.php.template:/LocalSettings.php.template"**.

**Changes to store secrets in a .env file**, instead of storing them directly in the docker-compose.yml file. This
also includes updating the .gitignore file so that the .env is not stored in github repository.  A new
file called env-template was created that has the template (but not the actual secrets) for the .env file contents.

Changes to disable **Quickstatements** : In the docker-compose.yml the quickstatements section has been commented out.

### Installation Steps.

##### Provision AWS resources with terraform.

This section does not go into detail about how to use terraform.  However the terraform repo 
at https://code.library.illinois.edu/projects/TER/repos/aws-wikibase-demo-service/browse can be used
to provision the EC2 wikibase runs on, and to configure the ALB listener rules, and target groups to route
internet traffic to the EC2.  Note: the terraform repository that manages certificates for medusa project EC2s, 
including wikibase-demo is at https://code.library.illinois.edu/projects/TER/repos/aws-acm-certs-medusa/browse ,

Generally, the steps to provision the resources are:
- clone the terraform repository: git clone https://code.library.illinois.edu/scm/ter/aws-wikibase-demo-service.git
- logon to AWS login: aws login
- AWS login will prompt for your password, request 2-factor authentication, and prompt you to select the proper AWS 
account.
- Change to the local repositories folder and Run: terraform init
- Then run terraform plan to inspect the changes terraform plans to make: terraform plan
- Then run terraform apply to make the changes: terraform apply

##### Install wikibase and dependencies on the EC2

Installation steps:

from your local machine ssh into the EC2 as the centos user. Below assumes you have stored the 
.pem file in your .ssh and that aws-authorities-demo.library.illinois.edu routes to the EC2.
```
ssh -i ~/.ssh/medusa_prod.pem centos@aws-authorities-demo.library.illinois.edu
```

Once on the EC2 command line the below commands can be run:
```
# Install Docker
# more info at: https://docs.docker.com/engine/install/centos/
sudo yum install -y yum-utils

sudo yum-config-manager \
   --add-repo \
   https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io

# start docker
systemctl start docker
# check docker status
systemctl status docker

# setup docker to start on reboot
# more info at: https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# install docker compose
# more info at: https://docs.docker.com/compose/install/
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# install emacs
sudo yum install emacs

# install git
sudo yum install git

# create wikibase service user and add to docker group
sudo useradd --system --create-home --groups docker wikibase
```

Then the follow commands are run as the wikibase user
```
#
# THE STEPS BELOW RUN AS THE wikibase USER
#
# change to wikibase user and clone wikibase-docker-ideals
# (note that this step does not setup ssh keys)
sudo su - wikibase

# clone the wikibase-docker-ideals repository using https (directions for ssh are below, but commented out)
cd /home/wikibase
git clone https://github.com/medusa-project/wikibase-docker-ideals.git

# BELOW ARE INSTUCTIONS IF USING SSH to interact with github is neede - THESE STEPS ARE COMMENTED OUT.
# setup ssh key for git hub
# more info at: : https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh
# mkdir -p .ssh
# cd .ssh
# RUN the below  manually, as it prompts for file (leave blank), and pass phrase (leave blank):
# ssh-keygen -t ed25519 -C "jmtroy2@illinois.edu"
# then run the below
# eval "$(ssh-agent -s)"
# THEN A MANUAL STEP: Add ssh key to github (see: https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account 
# Then change the directory back to /home/wikibase, and clone the wikibase-dockers-ideals.git
# cd /home/wikibase
# git clone git@github.com:medusa-project/wikibase-docker-ideals.git

# before running follow the instructions to create the .env file
cp env-template .env
# edit the .env file and update with passwords and correct host name for wikibase-host
emacs .env
```

The next step is to open the new .env file with the emacs editor.  Below are the changes you need to make.
- Set the Wikibase Docker Admin password. Example: ENV_VAR_WikibaseDockerAdminPass=**some password no one will guess**
- Set the DB_PASS for the wikibase container and the MYSQL_PASSWORD for the MariaDB container. 
The password for both are the same. Example: ENV_VAR_sqlpass=**another password no one will guess**
- Set the password for smtp.sparkpostmail.com. note: key is also on box: https://uofi.app.box.com/notes/738717931489. 
Example: ENV_VAR_sparkpostpass=**look in box or ask IMS for the sparkpost password**
- DNS or IP address and port values needed for the wdqs and wdqs-updater containers. Example: ENV_VAR_wikibase_host_and_port=**10.225.250.218:8181** 
or ENV_VAR_wikibase_host_and_port=**demo.authorities.library.illinois.edu**
- Add any email address below so they are not stored in the public github. Example: NV_VAR_uiuc_email_sender=**<PUT EMAIL SENDING LOGIN CONFIRMATION AND PASSWORD CHANGE HERE>**

##### Start Wikibase

Once you have cloned the repo, installed dependencies and created/updated the .env file, you can now start wikibase docker.
```
# to start wikibase
cd /home/wikibase/wikibase-docker-ideals
docker-compose up
# or to run int detached mode (in the background) use the -d option as below #
docker-compose up -d
```

##### Run ansible kick starter scripts

This section describes how the which playbooks were to initial the EC2 with settings recommended by IMS.
Importantly, it also provided the order, and options to run each of the playbooks.

The playbooks used were
- new_server_tags.yml
- aws_medusa_managed_state_demo_wikibase.yml
- wikibase-demo.yml

Assuming you have already cloned ansible-master to your local machine ( git clone https://code.library.illinois.edu/scm/ansible/ansible-master.git ),
you will need to copy 2 playbooks from the templates folder up on level to the
ansible-master folder:
```
cd ansible-master
cp templates/aws_medusa_managed_state_demo_wikibase.yml ./
cp templates/wikibase-demo.yml ./
```

Then from the ansible-master folder run the 3 playbooks:
```
ansible-playbook -i "aws-authorities-demo.library.illinois.edu," new_server_tags.yml --tags init,production,users,aws -u centos --private-key ~/.ssh/medusa_prod.pem --extra-vars "uiuc_fqdn=aws-authorities-demo.library.illinois.edu" --vault-password-file ~/.ansible/avp1.txt
ansible-playbook -i "aws-authorities-demo.library.illinois.edu," aws_medusa_managed_state_demo_wikibase.yml -u centos --private-key ~/.ssh/medusa_prod.pem --vault-password-file ~/.ansible/avp1.txt
ansible-playbook -i "aws-authorities-demo.library.illinois.edu," --vault-password-file ~/.ansible/avp1.txt wikibase-demo.yml
```







 