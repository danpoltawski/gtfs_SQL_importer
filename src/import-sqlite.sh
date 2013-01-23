#!/bin/bash
set -e

timestamp=`date +%Y%m%d%H%M`
filename=transit-${timestamp}.db

[ -f google_transit.zip ] && rm  google_transit.zip
[ -d feed ] && rm -r feed
curl -O http://www.transperth.wa.gov.au/TimetablePDFs/GoogleTransit/google_transit.zip
mkdir feed
cd feed
unzip ../google_transit.zip
cd ..
cat gtfs_tables.sqlite <(python import_gtfs_to_sql.py feed nocopy) | sqlite3 $filename
cat post-import.sql | sqlite3 $filename
echo 'CREATE TABLE shouldirun_config (name, value);' | sqlite3 $filename
echo "INSERT INTO shouldirun_config VALUES ('version', '$timestamp');" | sqlite3 $filename
echo 'VACUUM;' | sqlite3 $filename
sha512=(`shasum -a 512 $filename`)
gzip $filename
cat << EOF > $timestamp.json
{
    "version": "$timestamp",
    "url": "",
    "sha512": "$sha512",
    "description": "Timetable update from Transperth. Updated `date`."
}
EOF
