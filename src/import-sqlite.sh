#!/bin/bash

cat gtfs_tables.sqlite <(python import_gtfs_to_sql.py feed nocopy) | sqlite3 transit.db
cat post-import.sql | sqlite3 transit.db
