#!/bin/bash
set -e

timestamp=`date +%Y%m%d%H%M`
timestampfilename=`date +%Y-%m-%d-%H%M`
filename=transit-${timestamp}.db
shrunkfilename=shrunk-$filename

[ -f google_transit.zip ] && rm  google_transit.zip
[ -d feed ] && rm -r feed
curl -O  http://www.transperth.wa.gov.au/TimetablePDFs/GoogleTransit/Production/google_transit.zip
mkdir feed
cd feed
unzip ../google_transit.zip
cd ..
echo "importing data";
cat gtfs_tables.sqlite <(python import_gtfs_to_sql.py feed nocopy) | sqlite3 $filename
echo "running post-import";
cat post-import.sql | sqlite3 $filename
echo 'CREATE TABLE shouldirun_config (name, value);' | sqlite3 $filename
echo "INSERT INTO shouldirun_config VALUES ('version', '$timestamp');" | sqlite3 $filename
echo "running vaccum";
echo 'VACUUM;' | sqlite3 $filename
cp $filename $shrunkfilename
echo "running shrunk optimise";
cat post-import-optimise.sql | sqlite3 $shrunkfilename
echo 'VACUUM;' | sqlite3 $shrunkfilename
sha512=(`shasum -a 512 $filename`)
shrunksha512=(`shasum -a 512 $shrunkfilename`)
gzip $filename
gzip $shrunkfilename
read -p "Do you want to upload? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
        # do dangerous stuff
cat << EOF > $timestampfilename.json
    {
        "version": "$timestamp",
        "url": "http://updates.shouldirun.com/${filename}.gz",
        "sha512": "$sha512",
        "shrunk-url": "http://shouldirun.com/update-files/${shrunkfilename}.gz",
        "shrunk-sha512": "$shrunksha512",
        "description": "Timetable update from Transperth. Updated `date`."
    }
EOF
    echo "Now Run:"
    scp $timestampfilename.json shouldirun:
    echo "scp $shrunkfilename.gz shouldirun:/srv/shouldirun.com/update-files/"
    scp $shrunkfilename.gz shouldirun:/srv/shouldirun.com/update-files/
    echo "$HOME/bin/upcs -c shouldirun $filename.gz"
    $HOME/bin/upcs -c shouldirun $filename.gz
fi
