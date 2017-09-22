#!/bin/bash

if [ -z "$AGAVE_TICKER_DB" ]; then
    echo "You need to set \$AGAVE_TICKER_DB var.."
    exit 0
fi

#create db
sqlite3 $AGAVE_TICKER_DB <<EOS

-- create tables
-- 'current' stores the ids of the jobs that are currently being performed
create table current(id char(37) PRIMARY KEY);

-- 'finished' stores the ids of the jobs that have finished (i.e. job's status is FINISHED, KILLED, FAILED, or STOPPED)
create table completed(id char(37) PRIMARY KEY, status varchar(8) NOT NULL, name varchar(50) NOT NULL, owner varchar(50) NOT NULL, appId varchar(50) NOT NULL, created datetime NOT NULL, submitTime datetime NOT NULL, startTime datetime, endtime datetime);

EOS
