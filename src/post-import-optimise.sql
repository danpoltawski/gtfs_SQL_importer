create table danp_stop_times (
  trip_rowid int,
  stop_rowid int,
  stop_sequence int NOT NULL,
  stop_headsign text,
  departure_time_seconds int,
  danp_last_stop bool
);

create index dan_dep_time_index on danp_stop_times(departure_time_seconds);
create index dan_stop_id_index  on danp_stop_times(stop_rowid);
create index dan_trip_id_index  on danp_stop_times(trip_rowid);

INSERT INTO danp_stop_times SELECT t.ROWID, s.ROWID, st.stop_sequence, st.stop_headsign, st.departure_time_seconds, st.danp_last_stop
FROM gtfs_stop_times st
JOIN gtfs_stops s ON s.stop_id = st.stop_id
JOIN gtfs_trips t ON t.trip_id = st.trip_id;

DROP TABLE gtfs_stop_times;
