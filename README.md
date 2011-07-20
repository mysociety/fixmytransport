#FixMyTransport

#Prerequisites

Ruby 1.8.7

#Installation


##OS X


###Get the code:

    git clone https://github.com/mysociety/fixmytransport

In a terminal, navigate to the fixmytransport folder where this
install guide lives.

You will also want to install mySociety's common ruby libraries. Run:

    git submodule update --init

to fetch the contents of the submodule.

Copy config/general.example to config/general

###Configure the database:

Install Postgres and PostGIS - OSX installers are available at
http://www.kyngchaos.com/software/postgres

* copy database.yml-example to database.yml in fixmytransport/config
* edit it to point to your local postgresql database in the development
  and test sections and create the databases:

Become the 'postgres' user (sudo su - postgres) (or whatever user postgres is running as)

```psql template1``` to get into command tool

```\l``` to list databases

    CREATE DATABASE fixmytransport_development encoding = 'UTF8';
    CREATE DATABASE fixmytransport_test encoding = 'UTF8';

Make sure that the user specified in database.yml exists, and has full
permissions on this database.

    CREATE USER <username> WITH CREATEUSER;
    ALTER USER <username> WITH PASSWORD '<password>';
    ALTER USER <username> WITH CREATEDB;
    GRANT ALL PRIVILEGES ON DATABASE fixmytransport_development TO <username>;
    GRANT ALL PRIVILEGES ON DATABASE fixmytransport_test TO <username>;    	
    ALTER DATABASE fixmytransport_development OWNER TO <username>;
    ALTER DATABASE fixmytransport_test OWNER TO <username>;


The following commands need to be run at the command line following db creation for each of fixmytransport_development and fixmytransport_test:

    createlang  plpgsql [database name]
    psql [yourdb] < /usr/local/pgsql/share/contrib/postgis-1.5/postgis.sql
    psql [yourdb] < /usr/local/pgsql/share/contrib/postgis-1.5/spatial_ref_sys.sql

Also, SRID 27700 (British National Grid) is incorrect in some installs of PostGIS. After you’ve installed and got a PostGIS template, log in to it and make sure the proj4text column of SRID 27700 in the spatial_ref_sys table includes +datum=OSGB36.

###To load a new binary Postgres dump file:

1. Create the file from an existing database with pg_dump -p [Postgres port number] --schema=public -Fc YOURDB > YOURDB.sql.dump
2. rake db:load_from_binary FILE=YOURDB.sql.dump