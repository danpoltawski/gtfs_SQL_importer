create table danp_computed_stops (
  stop_id text , --REFERENCES gtfs_stops(stop_id),
  route_type  int
);

INSERT INTO danp_computed_stops SELECT DISTINCT(stop_id), '2' AS route_type FROM gtfs_stop_times WHERE trip_id IN 
(SELECT trip_id FROM gtfs_trips tr JOIN gtfs_routes ro ON ro.route_id = tr.route_id WHERE ro.route_type = 2);

INSERT INTO danp_computed_stops SELECT DISTINCT(stop_id), '3' AS route_type FROM gtfs_stop_times WHERE trip_id IN 
(SELECT trip_id FROM gtfs_trips tr JOIN gtfs_routes ro ON ro.route_id = tr.route_id WHERE ro.route_type = 3);

INSERT INTO danp_computed_stops SELECT DISTINCT(stop_id), '4' AS route_type FROM gtfs_stop_times WHERE trip_id IN 
(SELECT trip_id FROM gtfs_trips tr JOIN gtfs_routes ro ON ro.route_id = tr.route_id WHERE ro.route_type = 4);

CREATE INDEX danp_route_type_idx ON danp_computed_stops (stop_id, route_type);

-- work out last stop...
create temporary table danp_computed_last_stops (
  stop_id text , --REFERENCES gtfs_stops(stop_id),
  trip_id text,
  max_sequence int
);
CREATE INDEX temp_computed ON danp_computed_last_stops (stop_id, trip_id);

INSERT INTO danp_computed_last_stops SELECT stop_id, trip_id, MAX(stop_sequence) FROM gtfs_stop_times GROUP BY trip_id;

ALTER TABLE gtfs_stop_times ADD COLUMN danp_last_stop bool;

UPDATE gtfs_stop_times SET danp_last_stop = 1
WHERE stop_sequence != 1 AND stop_id IN (SELECT stop_id FROM danp_computed_last_stops
WHERE gtfs_stop_times.trip_id = danp_computed_last_stops.trip_id
AND gtfs_stop_times.stop_id = danp_computed_last_stops.stop_id);

DROP table danp_computed_last_stops;

-- Fix 'broken data' to work with earlier versions of app.
UPDATE gtfs_routes set route_short_name = upper(substr(route_long_name, 0, 4)) WHERE route_short_name is null;
UPDATE gtfs_routes set route_long_name = route_short_name WHERE route_long_name is null;
