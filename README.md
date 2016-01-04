# miab (mobilize-in-a-box)
a leaner, meaner mobilize-in-a-box.

## SETUP
Assuming you have [docker](https://www.docker.com/) installed, you are welcome to use any/all containers built from this repo (in addition to the [ohmage/docker](https://github.com/ohmage/docker) repo) to run a fully-featured mobilize stack. If you're quite familiar with docker, have at it! Below are alternate options for using mobilize-in-a-box if you are new to docker, or even if you'd prefer to fore-go docker altogether. 

## DOCKER-COMPOSE
A `docker-compose.yml` file is available at the root of this project which defines the interactions between the docker containers.  Please ensure `docker` and `docker-compose` are both installed before executing.

Execute `docker-compose up -d` to create the instances as default (or edit `docker-compose.yml` as needed) and get going!

### Notes
`docker-compose`, while not without detractors, is a really fast way of setting up an infrastructure with a bunch of loosely coupled moving parts.  Please take a look at the bullets below for some helpful hints!

  * If you're using the `boot2docker` osx docker environment, you may have some mysql permissions issues (please see the `docker-compose.yml` file for some hints on resolving)
  * All data will be persisted in the `.data` directory alongside the `docker-compose.yml` file. Adjust to your needs.
  * It is highly suggested that you change the `MYSQL_ROOT_PASSWORD` environment variable before executing `docker-compose up`
  * If you'd like to sync the accounts from ohmage to rstudio (yes, we realize this is quite quirky!) ensure that the rstudio container has the environment variable `SYNC` set to `1` (set to `0` to turn off).  You can also customize the sync frequency with `SYNC_SECONDS` environment variable, which defaults to `120`.

## VAGRANT
TODO: a vagrant box which sets up docker-compose and runs as above. 


## MANUAL/LEGACY INSTALL
The original composition of mobilize-in-a-box can be found from this [pre-release](https://github.com/mobilizingcs-ops/mobilize-in-a-box/tree/v0.0.1-alpha#manual). Note that these instructions are aging and don't reflect every piece of the infrastructure. Essentially, this provides some simple instructions for resolving dependencies (java, tomcat7, nginx, opencpu, rstudio, wiki) and getting set up assuming you are using a very specific infrastructure (namely, ubuntu 12.04). The use of the docker-compose or vagrant methods above is far preferred.