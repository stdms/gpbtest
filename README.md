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

