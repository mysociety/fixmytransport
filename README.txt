FixMyTransport
--------------

If using PostGIS, the following commands need to be run at the command line following db creation:

createlang  plpgsql [database name]
psql [yourdb] < /usr/share/postgresql-8.3-postgis/lwpostgis.sql
psql [yourdb] < /usr/share/postgresql-8.3-postgis/spatial_ref_sys.sql

Also, SRID 27700 (British National Grid) is incorrect in some installs of PostGIS. After you’ve installed and got a PostGIS template, log in to it and make sure the proj4text column of SRID 27700 in the spatial_ref_sys table includes +datum=OSGB36.

Set the OPTION_USE_SPATIAL_EXTENSIONS option to 1 if you are using PostGIS.

To install Postgres and PostGIS on OSX
--------------------------------------
1) sudo port install postgresql84 
2) sudo port install postgis  

To load a new binary Postgres dump file:
----------------------------------------
1) Create the file from an existing database with pg_dump -p [Postgres port number] --schema=public -Fc YOURDB > YOURDB.sql.dump
2) rake db:load_from_binary FILE=YOURDB.sql.dump