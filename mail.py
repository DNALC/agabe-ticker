import sqlite3
import pandas as pd
from datetime import datetime, timedelta
import numpy as np
import sys

today = datetime.today()
today = today.replace(hour=9, minute=0, second=0, microsecond=0)
previous_date = today - timedelta(days=int(sys.argv[1]))
dates = (previous_date.isoformat(), today.isoformat(), )

conn = sqlite3.connect(str(sys.argv[2]))
c = conn.cursor()
c.execute("SELECT * FROM completed WHERE created BETWEEN ? and ?", dates)
data = c.fetchall()
c.close()

db = pd.DataFrame(data, columns=['id', 'status', 'executionSystem', 'owner', 'appId', 'created', 'submitTime', 'startTime', 'endTime'])

jobs_count = len(db)
status_count = db.status.value_counts()

def count(series, key):
    try:
        return series[key]
    except:
        return 0

finished = count(status_count, 'FINISHED')
killed = count(status_count, 'KILLED')
failed = count(status_count, 'FAILED')
stopped = count(status_count, 'STOPPED')

if (int(sys.argv[1]) == 1):
    mail_body = "Daily report \n"
else:
    mail_body = "Weekly report \n"    
mail_body = mail_body + "Jobs: \t \t" + str(jobs_count) + "\n" +     "Finished jobs: \t" + str(finished)  + "\n" +     "Killed jobs: \t" + str(killed)  + "\n" +     "Failed jobs: \t" + str(failed)  + "\n" +     "Stopped jobs: \t" + str(stopped)  + "\n"

times = np.ones( (jobs_count, 2) )

def sub_dates(a, b):
    if a != None and b != None:
        a, b = datetime.strptime(a, '%Y-%m-%dT%H:%M:%S.%f-05:00'), datetime.strptime(b, '%Y-%m-%dT%H:%M:%S.%f-05:00')
        return (a - b).total_seconds()
    else:
        return float('nan')

data = db.get(['status','created', 'submitTime', 'startTime']).T.to_dict()
for i in range(0, len(data)):
    row = data[i]
    a, b = sub_dates(row['submitTime'], row['created']), sub_dates(row['startTime'], row['submitTime'])
    times[i] = [a, b]

mail_body = mail_body + "\n"    "Submit time: " + "\n" +     "Average: \t\t" + str(np.nanmean(times[:, 0])) + "\n" +     "Median: \t\t" + str(np.nanmedian(times[:, 0])) + "\n" +     "Minimum: \t" + str(np.nanmin(times[:, 0])) + "\n" +     "Maximum: \t" + str(np.nanmax(times[:, 0])) + "\n"

mail_body = mail_body + "\n"    "Queue time: " + "\n" +     "Average: \t\t" + str(np.nanmean(times[:, 1])) + "\n" +     "Median: \t\t" + str(np.nanmedian(times[:, 1])) + "\n" +     "Minimum: \t" + str(np.nanmin(times[:, 1])) + "\n" +     "Maximum: \t" + str(np.nanmax(times[:, 1])) + "\n"

print(mail_body)
