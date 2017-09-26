#!/bin/bash

if [ -z "$AGAVE_TICKER_DB" ]; then
    echo "You need to set \$AGAVE_TICKER_DB var.."
    exit 0
fi

if [ -z "$AGAVE_TICKER_JOB_FILE" ]; then
    echo "You need to set \$AGAVE_TICKER_JOB_FILE var.."
    exit 0
fi


# check if db exists. Else creates database
if [ ! -s $AGAVE_TICKER_DB ] 
then
	. ./db_schema.sh
fi

# submit job and keep job id
id=$(jobs-submit -F $AGAVE_TICKER_JOB_FILE  | sed 's/Successfully submitted job //')


if [ ! -z "$id" ]
then
	# store id into db
	(sqlite3 $AGAVE_TICKER_DB "INSERT INTO current VALUES('$id')") \
		|| echo $(date +%Y-%m-%d%n%H:%M:%S) "Failure to insert id $id into CURRENT"
else
	echo $(date +%Y-%m-%d%n%H:%M:%S) "No id produced"
fi

# check job status for each job in 'current'
ids=$(sqlite3 $AGAVE_TICKER_DB "SELECT * FROM current")

for id in $ids 
do
	status=$(jobs-status $id)

	if [ "$status" == "FINISHED" ] || [ "$status" == "KILLED" ] || [ "$status" == "FAILED" ] || [ "$status" == "STOPPED" ]
	then
		jobsList=$(jobs-list -v $id)
		name=$(echo $jobsList | jq '.name')
		owner=$(echo $jobsList | jq '.owner')
		appId=$(echo $jobsList | jq '.appId')
		created=$(echo $jobsList | jq '.created')
		submitTime=$(echo $jobsList | jq '.submitTime')
		startTime=$(echo $jobsList | jq '.startTime')
		endTime=$(echo $jobsList | jq '.endTime')
		
		( 
		 # inserts id and job information into COMPLETED 
		 # if the data was successfully inserted into COMPLETED, the id is deleted from CURRENT. Else, an error message is displayed
		(sqlite3 $AGAVE_TICKER_DB "INSERT INTO completed VALUES('$id', '$status', $name, $owner, $appId, $created, $submitTime, $startTime, $endTime)") && \
				( (sqlite3 $AGAVE_TICKER_DB "DELETE FROM current WHERE id='$id'") || \
					echo $(date +%Y-%m-%d%n%H:%M:%S) "Failure to delete $id from CURRENT") ) || \
			( 
			# there are two situations in which id and job information cannot be inserted into COMPLETED:  
			# 1. Failure with db connection 
			# 2. id is in COMPLETED, but could not be deleted from CURRENT in a previous execution
			ids2=$(sqlite3 $AGAVE_TICKER_DB "select current.id from current, completed where current.id = completed.id")
			if grep $id <<< $ids2
			# if id is in both CURRENT and COMPLETED, then id is deleted from CURRENT. Else, an error message is desplayed.
				then (sqlite3 $AGAVE_TICKER_DB "DELETE FROM current WHERE id='$id'") 
				else echo $(date +%Y-%m-%d%n%H:%M:%S) "Failure to insert $id into COMPLETED"
			fi
		)

	fi
done
