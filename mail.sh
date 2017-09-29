#!/bin/bash

echo -e "$(python3 $MAIL_SCRIPT_PATH $1 $AGAVE_TICKER_DB)" | mail -s "Jobs statistics" ghiban@cshl.edu perezde@cshl.edu 
