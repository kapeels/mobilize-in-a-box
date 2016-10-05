# miab (mobilize-in-a-box)
a leaner, meaner mobilize-in-a-box.

## SETUP
Assuming you have [docker](https://www.docker.com/) installed, you are welcome to use any/all containers built from this repo (in addition to the [ohmage/server](https://hub.docker.com/r/ohmage/server/) container on the docker hub) to run a fully-featured mobilize stack. If you're quite familiar with docker, have at it! Below are alternate options for using mobilize-in-a-box if you are new to docker, or even if you'd prefer to fore-go docker altogether. 

## DOCKER-COMPOSE
A `docker-compose.yml` file is available at the root of this project which defines the interactions between the docker containers.  Please ensure `docker` and `docker-compose` are both installed before executing. As of this writing, you'll need docker `1.12+` and docker-compose `1.8.1+`.

Execute `docker-compose up -d` to create the instances as default (or edit `docker-compose.yml` as needed) and get going! Please see the [components](#components) section below for a more detailed look at the toolset.

### miab in production
If you happen to be interested in using our "mobilize-in-a-box" install method in production, you're certainly welcome to do so! As a starter, you should definitely read the [using compose in production](https://docs.docker.com/compose/production/) page on the docker site. Beyond that, You'll likely want to reference the `docker-compose.production.yml` file in this repository for some tweaks/hints that we suggest (and are using ourselves). In particular:

  * You'll need to add SSL to secure client interactions. We've provided the internal side of the configuration for using the [dockercloud/haproxy](https://github.com/docker/dockercloud-haproxy) container. You can use that haproxy container to do SSL termination for many services, not limiting to just mobilize-in-a-box!
  * You'll need to set and secure your secrets. see the `.env` for an example of containing all mobilize-related secrets in a single file.
  * You'll likely need to modify the `MYSQL_USER_QUERY` used to sync ohmage users to rstudio users to limit your rstudio users to a smaller subset (or handle rstudio user creation in a completely separate manner).
  * `ohmage` needs to occasionally send emails for menial "password reset"-like features and account creation (should you choose to have it enabled).  Since outgoing smtp can be a hassle or drammatically different depending on your environment, we've opted to provide a suggestion for using [mailgun](https://mailgun.com) which allows 10,000 emails/month for free. Check out the `mail` service in `docker-compose.production.yml` if you'd like to join in! (see the note on ohmage db config options below!)
  * If you intend to use `user_setup` apis (to allow teachers to create their own classes/students) you may want to take a look at the `pw` service and modify to fit your needs. This container offers moderate-length, easy to type passwords from a dictionary for the "initial passwords" (students must change on first login). You may prefer a more secure method, and we leave that up to you. If you'd prefer not to run your own container for this in production, you can use our endpoint at https://pw.mobilizingcs.org.
  * ohmage database configuration options: ohmage has some functionality you may choose to enable/disable, or configure to fit your needs. These can be modified by updating a few rows in the ohmage db: `docker-compose -f docker-compose.yml -f docker-compose.production.yml exec db mysql -uroot -p ohmage -e 'update preference set p_value="{desired_value}" where p_key="{preference_name_below}";'
    * `recaptcha_(public,private)_key`: if you'd like to enable account creation, you'll need to get recaptcha keys [here](https://developers.google.com/recaptcha/docs/start)
    * `fully_qualified_domain_name`: ohmage uses this preference to send proper links in emails. Set this to whereever your server is located!
    * `self_registration_enabled`: allow or disallow self-registration.
    * `user_setup_enabled`: allows a permission to be delegated to a set of users that allow them to generate accounts on their own (a teacher/student-like feature).

### Notes
`docker-compose`, while not without detractors, is a really fast way of setting up an infrastructure with a bunch of loosely coupled moving parts.  Please take a look at the bullets below for some helpful hints!

  * If you're using the `boot2docker` osx docker environment, you may have some mysql permissions issues (please see the `docker-compose.yml` file for some hints on resolving)
  * All data will be persisted in the `.data` directory alongside the `docker-compose.yml` file. Adjust to your needs.
  * If you'd like to sync the accounts from ohmage to rstudio (yes, we realize this is quite quirky!) ensure that the rstudio container has the environment variable `SYNC` set to `1` (set to `0` to turn off).  You can also customize the sync frequency with `SYNC_SECONDS` environment variable, which defaults to `120`.

## VAGRANT
`git clone` this repository and run `vagrant up` (you may want to up the ram a bit). The result should be a vagrant box running at `192.168.33.100` that is configured just as the docker-compose option above!


## MANUAL/LEGACY INSTALL
The original composition of mobilize-in-a-box can be found from this [pre-release](https://github.com/mobilizingcs-ops/mobilize-in-a-box/tree/v0.0.1-alpha#manual). Note that these instructions are aging and don't reflect every piece of the infrastructure. Essentially, this provides some simple instructions for resolving dependencies (java, tomcat7, nginx, opencpu, rstudio, wiki) and getting set up assuming you are using a very specific infrastructure (namely, ubuntu 12.04). The use of the docker-compose or vagrant methods above is far preferred.

## COMPONENTS
`TODO`
