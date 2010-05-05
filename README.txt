FixMyTransport
--------------

If using PostGIS, the following commands need to be run following db creation:

createlang  plpgsql [database name]
/usr/share/postgresql-8.3-postgis/lwpostgis.sql
/usr/share/postgresql-8.3-postgis/spatial_ref_sys.sql

Also, SRID 27700 (British National Grid) is incorrect in some installs of PostGIS. After you’ve installed and got a PostGIS template, log in to it and make sure the proj4text column of SRID 27700 includes +datum=OSGB36.