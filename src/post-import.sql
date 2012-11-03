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
