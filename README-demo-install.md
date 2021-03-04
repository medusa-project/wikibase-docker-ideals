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