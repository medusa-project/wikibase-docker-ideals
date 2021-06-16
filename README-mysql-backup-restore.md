## Wikibase Docker Read me mysql backups and restores

This readme explains steps to backup and restore the MySQL **only** when the source and destination are 
running the same version of Wikibase.  If you plan to restore a database to a newer version of
Wikibase see **Manual:Restoring a wiki from backup:** in the References section below.

These instructions also only cover the backup and restore of the MySQL database.  It does not 
cover the backup and restore of any files, such as associated images.  At the time of writing 
there were no images, or other files, that needed to be backed up and restored to move the data
from one server to another as installation and testing process.  NOTE: the EC2's EBS volumes do
have snapshots created by AWS Backup, but those restore procedures are not addressed in this readme.

These instructions DO cover the building (or rebuilding) of the WDQS (wikidata query service) datastore, which
will happen automatically if the WDQS datastore is not present.  The WDQS datastore is needed to run SPARQL 
queries. 

### Back up a database

Ssh into the host EC2, and switch to the wikibase service user, and cd into the folder where wikibase
implemented (likely wikibase-docker-ideals - where the docker-compose.yml file is).  In these 
instructions the host is assumed to be aws-authorities-demo.library.illinois.edu (it might be different
depending on the scenario)
```
ssh -i ~/.ssh/medusa_prod.pem centos@aws-authorities-demo.library.illinois.edu
# or #
ssh aws-authorities-demo.library.illinois.edu

sudo su - wikibase
cd wikibase-docker-ideals
```

Then run the commands below to make a MySQL backup file of the database.

```
# first run docker-compose ps to list the container names (left)
docker-compose ps
                 Name                               Command               State          Ports        
------------------------------------------------------------------------------------------------------
wikibase-docker-ideals_elasticsearch_1   /usr/local/bin/docker-entr ...   Up      9200/tcp, 9300/tcp  
wikibase-docker-ideals_mysql_1           docker-entrypoint.sh mysqld      Up      3306/tcp            
wikibase-docker-ideals_wdqs-frontend_1   /entrypoint.sh nginx -g da ...   Up      0.0.0.0:8282->80/tcp
wikibase-docker-ideals_wdqs-proxy_1      /bin/sh -c "/entrypoint.sh"      Up      0.0.0.0:8989->80/tcp
wikibase-docker-ideals_wdqs-updater_1    /entrypoint.sh /runUpdate.sh     Up                          
wikibase-docker-ideals_wdqs_1            /entrypoint.sh /runBlazegr ...   Up      9999/tcp            
wikibase-docker-ideals_wikibase_1        /bin/bash /entrypoint.sh         Up      0.0.0.0:8181->80/tcp

# then using the mysql container name, run the command to create the backup file
# be sure to change <pass_word_for_wikiuser> to the actual password.

docker exec -it wikibase-docker-ideals_mysql_1 mysqldump -u wikiuser --password=<pass_word_for_wikiuser> my_wiki > mybackup.sql
```
After creating the backup file, check the file and make sure it was created successfully, sometimes the mysql 
restarts itself and the backup fails.  if the output looks like it does below, try running
the command again.
```
cat mybackup.sql
OCI runtime exec failed: exec failed: container_linux.go:370: starting container process caused: exec: "-it": executable file not found in $PATH: unknown
```

### Move the backup file (if needed) to the destination server

I performed these procedures using a MAC, so if you are using a Windows machine the commands to move
files might be different.

From the mac command line copy the backup file to the mac file system, and then copy it to the destination server. (Again, source and destination servers 
will depend on the scenario)
```
scp -i ~/.ssh/medusa_prod.pem centos@aws-authorities-demo.library.illinois.edu:/home/wikibase/wikibase-docker-ideals/mybackup.sql ./ 
scp -i ~/.ssh/medusa_prod.pem mybackup.sql centos@<destination server>:/<path to destination file location>/
```

### Once the backup.sql file is on the destination server, restore it to the MySQL database.

My experience is that I had to copy the backup file into the running MySQL container, and 
then execute the needed commands from within the container.

```
# run docker-compose ps to get the container names
docker-compose ps
                 Name                               Command               State          Ports        
------------------------------------------------------------------------------------------------------
wikibase-docker-ideals_elasticsearch_1   /usr/local/bin/docker-entr ...   Up      9200/tcp, 9300/tcp  
wikibase-docker-ideals_mysql_1           docker-entrypoint.sh mysqld      Up      3306/tcp            
wikibase-docker-ideals_wdqs-frontend_1   /entrypoint.sh nginx -g da ...   Up      0.0.0.0:8282->80/tcp
wikibase-docker-ideals_wdqs-proxy_1      /bin/sh -c "/entrypoint.sh"      Up      0.0.0.0:8989->80/tcp
wikibase-docker-ideals_wdqs-updater_1    /entrypoint.sh /runUpdate.sh     Up                          
wikibase-docker-ideals_wdqs_1            /entrypoint.sh /runBlazegr ...   Up      9999/tcp            
wikibase-docker-ideals_wikibase_1        /bin/bash /entrypoint.sh         Up      0.0.0.0:8181->80/tcp

# Then do a docker-compose stop (to stop all services), 
# and a docker-compose up mysql, so only the mysql container is running
docker-compose stop
docker-compose start mysql

# copy the backup.sql file into the container
docker cp mybackup.sql wikibase-docker-ideals_mysql_1:/
# then start a terminal session within the container
docker exec -it wikibase-docker-ideals_mysql_1 bash
# then start a mysql command line sesion
mysql -u wikiuser -p<wikiuser password>
# drop the my_wiki database
MariaDB [(none)]> DROP DATABASE my_wiki;
# create a new my_wiki database
MariaDB [(none)]> CREATE DATABASE my_wiki;
# exit the mysql command line
MariaDB [(none)]> exit
# from the container command line, copy the backup.sql file into the my_wiki Database.
mysql -u wikiuser -p<wikiuser password> my_wiki < backup0224a.sql
# exit the container
exit

```

### Restart Wikibase on the destination server

It's likely you will need to delete the WDQS (wikibase query service) **volume** before restarting wikibase. When
you restart wikibase, it should detect that the volume is missing and create a new one using the data from the
restored database.

```
# list the container volumes - so you can see the names of the volumes
docker volume ls
DRIVER    VOLUME NAME
local     wikibase-docker-ideals_mediawiki-images-data
local     wikibase-docker-ideals_mediawiki-mysql-data
local     wikibase-docker-ideals_query-service-data
local     wikibase-docker-ideals_quickstatements-data
# delete the query-service-data volume - you must do a docker-compose down first
docker-compose down
docker volume rm wikibase-docker-ideals_query-service-data
# restart wikibase with docker-compose up
docker-compose up
```






### References:

Manual:Backing up a wiki: https://www.mediawiki.org/wiki/Manual:Backing_up_a_wiki

Manual:Restoring a wiki from backup: https://www.mediawiki.org/wiki/Manual:Restoring_a_wiki_from_backup

