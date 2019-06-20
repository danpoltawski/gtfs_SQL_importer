#!/bin/bash
set -e

timestamp=`date +%Y%m%d%H%M`
timestampfilename=`date +%Y-%m-%d-%H%M`
filename=perth-${timestamp}.db

[ -f google_transit.zip ] && rm  google_transit.zip
[ -d feed ] && rm -r feed
curl -O  http://www.transperth.wa.gov.au/TimetablePDFs/GoogleTransit/Production/google_transit.zip
mkdir feed
cd feed
unzip ../google_transit.zip
cd ..
echo "importing data";
cat gtfs_tables.sqlite <(/usr/bin/python import_gtfs_to_sql.py feed nocopy) | sqlite3 $filename
echo "running post-import";
cat post-import.sql | sqlite3 $filename
echo 'CREATE TABLE shouldirun_config (name, value);' | sqlite3 $filename
echo "INSERT INTO shouldirun_config VALUES ('version', '$timestamp');" | sqlite3 $filename
echo "running vaccum";
echo 'VACUUM;' | sqlite3 $filename
echo "running shrunk optimise";
cat post-import-optimise.sql | sqlite3 $filename
echo 'VACUUM;' | sqlite3 $filename
filesize=$(wc -c < $filename)
bzip2 $filename
bzipfilesize=$(wc -c < $filename.bz2)
totalfilesize=$(($bzipfilesize + $filesize))
cat << EOF > $timestampfilename.json
    {
        "version": "$timestamp",
        "bzip2-url": "https://shouldirun.com/update-files/${filename}.bz2",
        "filesize": $totalfilesize,
        "description": "Timetable update from Transperth. Updated `date`."
    }
EOF
read -p "Do you want to upload? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
        # do dangerous stuff
    echo "Now Run:"
    scp $timestampfilename.json shouldirun:
    echo "scp $shrunkfilename.bz2 shouldirun:/srv/shouldirun.com/update-files/"
    scp $shrunkfilename.bz2 shouldirun:/srv/shouldirun.com/update-files/
fi
