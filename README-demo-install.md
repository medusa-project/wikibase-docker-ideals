## Wikibase Docker Read me for UIUC Library demo installation

This readme covers the installation steps for the demo implementation (demo.authorities.library.illinois.edu).
Also discussed is how the system is implemented in AWS and the important changes that were made to the code base
cloned from https://github.com/wmde/wikibase-docker.

This readme has three sections:
- AWS implementation.
- Important changes made after cloning from https://github.com/wmde/wikibase-docker.
- Installation steps.

### AWS implementation
Outline:
- Implemented in the Library's medusa project AWS account.
- The system runs on the medusa-demo EC2.
- All the services, elasticsearch, mysql, the wdqs (wikibase query service) all run 
on the EC2 and store data there.  Quickstatments is not installed as of this writing.
- Internet Traffic is routed to the EC2 via our demo AWS ALB (Application Load Balancer).
  The ALB along with Amazon's Certificate Manager hanlde the TLS certificates for this 
  implementation. The ALB with the associtated target groups route 
  demo.authorities.library.illinois to port 8181 
  (the wikibase webpages) on the EC2, and demo.authorities-sparql.library.illinois.edu 
  to port 8282 (the sparql query interface) on the EC2.
- Terraform was used to provision the AWS resources. The repo for the terraform code
is at https://code.library.illinois.edu/projects/TER/repos/aws-wikibase-demo-service/browse
  
### Important Changes made to https://github.com/wmde/wikibase-docker
Note: the Library's https://github.com/medusa-project/wikibase-docker-ideals repo was 
cloned from the master branch, commit 7b52e2a (7b52e2a9cbe74ff40ff41adf493d7f4d20b21dd3) of 
https://github.com/wmde/wikibase-docker

Changes needed to get SPARQL queries to work:
- In the docker-compose.yml file, in the "wdqs:" service section, and then in 
the "environment:" section set the WIKIBASE_HOST environment variable to the IP 
address and port 8181 of the host EC2.  Example:  WIKIBASE_HOST=10.225.250.218:8181.  
This is needed for the sparql query inteface to retreive results correctly and show 
valid links to items in the result set.
Once fully implemeted this variable will be set the system URL. Example: 
WIKIBASE_HOST=demo.authorities.library.illinois.edu.
- In the docker-compose.yml file, in the "wdqs:" service section, and then in 
the "environment:" section set the WIKIBASE_HOST environment variable to the IP 
address and port 8181 of the host EC2.  Example:  WIKIBASE_HOST=10.225.250.218:8181.  
This is needed for the sparql query inteface to retreive results correctly and show 
valid links to items in the result set.
Once fully implemeted this variable will be set the system URL. Example: 
WIKIBASE_HOST=demo.authorities.library.illinois.edu.

Changes needed to git new login validation and forgot password emails to work:
- A new folder called "uiuc-library-config" was created for any files need to change 
configuration settings for the UIUC Library.
- The file ./wikibase/1.35/base/LocalSettings.php.template was copied to ./uiuc-library-config
- Then the file ./uiuc-library-config had additional configuration settings added to 
the end of the file. See the contents in the file after the line **"# Additions for UIUC Library wikibase"**. 
These are the settings needed to get emails to work.
- Then in the docker-compose.yml file, in the "wikibase:" service section, and then in
the "volumes:" section a line was added to mount the new file over the file in the docker container. 
That line is "- ./uiuc-library-config/LocalSettings.php.template:/LocalSettings.php.template"

Changes to store secrets in a .env file, instead of storing them directly in the docker-compose.yml file. This
change also includes updating the .gitignore file so that the .env is not stored in github repository.  A new
file called env-template was created that has the template for the .env file contents.

Changes to disable **Quickstatements** : In the docker-compose.yml the quickstatements section has been commented out.

### Implementation instructions.

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
- then run terraform plan to inspect the changes terraform plans to make: terraform plan
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

Once you have cloned the repo, installed dependencies and created/updated the .env file, you can now start wikibase docker.
```
# to start wikibase
cd /home/wikibase/wikibase-docker-ideals
docker-compose up
# or to run int detached mode (in the background) use the -d option as below #
docker-compose up -d
```



 