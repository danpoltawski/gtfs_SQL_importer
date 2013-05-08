#!/bin/bash
set -e

timestamp=`date +%Y%m%d%H%M`
timestampfilename=`date +%Y-%m-%d-%H%M`
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
cat << EOF > $timestampfilename.json
{
    "version": "$timestamp",
    "url": "https://d36ldssoaigick.cloudfront.net/${filename}.gz",
    "sha512": "$sha512",
    "description": "Timetable update from Transperth. Updated `date`."
}
EOF
echo "Now Run:"
echo "s3cmd put --acl-public ${filename}.gz s3://shouldirun"
echo "s3cmd info s3://shouldirun/${filename}.gz"
