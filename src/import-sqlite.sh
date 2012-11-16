#!/bin/bash
set -e

[ -f transit.db ] && rm transit.db
[ -f google_transit.zip ] && rm  google_transit.zip
[ -d feed ] && rm -r feed
curl -O http://www.transperth.wa.gov.au/TimetablePDFs/GoogleTransit/google_transit.zip
mkdir feed
cd feed
unzip ../google_transit.zip
cd ..
cat gtfs_tables.sqlite <(python import_gtfs_to_sql.py feed nocopy) | sqlite3 transit.db
cat post-import.sql | sqlite3 transit.db
echo 'VACUUM;' | sqlite3 transit.db
