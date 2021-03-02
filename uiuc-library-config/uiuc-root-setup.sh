#
# This script installs software, and creates the service user wikibase
#

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

#
# THE STEPS BELOW RUN AS THE wikibase USER
#
# change to wikibase user and clone wikibase-docker-ideals
# (note that this step does not setup ssh keys)
sudo su - wikibase
# setup ssh key for git hub
# more info at: : https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh
mkdir .ssh
cd .ssh
# RUN this manually, as it prompts for file (leave blank), and pass phrase (leave blank): ssh-keygen -t ed25519 -C "jmtroy2@illinois.edu"
# eval "$(ssh-agent -s)"
# THEN A MANUAL STEP: Add ssh key to github (see: https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account 

# git clone git@github.com:medusa-project/wikibase-docker-ideals.git
