Mail log parser. Test task.

= Initial database configuration =

Exec following lines in PostgreSQL console to create database and role to connect

CREATE DATABASE gpbtest ENCODING 'utf-8';
CREATE ROLE gpbtest LOGIN PASSWORD 'test';

Initialize database schema

psql -H localhost -p 5432 -U postgres gpbtest < schema.sql

Replace database hostname and port with appropriate vvalues if necessary.
Same values should be set in logparser configuration file

= Configuration file =

logparser connect to database with credentials stored in configuration file logparser.conf
By default script looking for this file in working directory. Dies if file not found.
Different location of configuration file can be specified via LOGPARSERCONF environment variable

Configuration file is a structure defined as a Perl hashref. Example follows:

`{
    database => {
        dsn             => 'dbi:Pg:dbname=gpbtest;host=127.0.0.1;port=5432',
        username        => 'postgres',
        password        => '',
        options => {
            AutoCommit => 0
        }
    },
    commit_after => 1000
}`

- database - section to defined connection parameters
  - dsn - data source locator in Perl DBI notation
  - username - database user name. The one created on step 'Database configuration' should be used
  - password - database access password
  - options - DBI driver options
    - AutoCommit - disable per-line commits
- commit_after - commit after this amount to input lines being read. 1 by default

Further configuration parameters couls appear in future versions.

= Parser exec =

`logparser.pl [ <logfile> ]`

Script can be invoced manually of scheduled to run in crontab.

logfile - path to emails log file. If not specified stdin will be used.

= Run in dicker =

Docker based test environment configuration provided. To run test in docker use following commands

`docker-compose build`
`docker-compose up`

THey'll build and connect to each other two docker containers. One with PostgreSQL database, second with
log parser and WUI application.

Initial database should be created during first db container start. If it doesn't happen one can apply db schema manually

- list running containers

`docker ps`
`CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                    PORTS                              NAMES`
`c8c10bc8bf47        gpbtest_web         "/usr/local/bin/hypn…"   6 minutes ago       Up 4 seconds              0.0.0.0:8080->8080/tcp             gpbtest_web_1`
`b2f4adf9b494        gpbtest_db          "docker-entrypoint.s…"   41 minutes ago      Up 35 seconds (healthy)   5432/tcp, 0.0.0.0:5433->5433/tcp   gpbtest_db_1`


- connect to db container

`$ docker exec -it b2f4adf9b494 psql -U postgres gpbtest`
`psql (12.2 (Debian 12.2-2.pgdg100+1))`
`Type "help" for help.`
`gpbtest=#`

- init db schema

`gpbtest=# \i scripts/schema.sql`


- connect to web container

`$ docker exec -it c8c10bc8bf47 /bin/bash`

- parse reference maillog data

`gpbtest@c8c10bc8bf47:/var/www/gpbtest$ ./logparser.pl maillog`


Now we have data parsed and loaded into db table. Open WUI URL localhost:8080 in browser to perform search across data.
