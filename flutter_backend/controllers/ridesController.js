const db = require('../models/db');
const haversine = require('../utils/haversine'); // We'll create this next

exports.startRide = (req, res) => {
  const { staff_id, mission_id, vehicle_type, start_lat, start_lng, start_time } = req.body;

  const sql = `INSERT INTO staff_rides (staff_id, mission_id, vehicle_type, start_lat, start_lng, start_time)
               VALUES (?, ?, ?, ?, ?, ?)`;

  db.query(sql, [staff_id, mission_id, vehicle_type, start_lat, start_lng, start_time], (err, result) => {
    if (err) return res.status(500).json({ error: err });
    res.json({ ride_id: result.insertId });
  });
};

exports.addRideLocation = (req, res) => {
  const ride_id = req.params.ride_id;
  const { lat, lng, timestamp } = req.body;

  const sql = `INSERT INTO ride_locations (ride_id, lat, lng, timestamp)
               VALUES (?, ?, ?, ?)`;

  db.query(sql, [ride_id, lat, lng, timestamp], (err) => {
    if (err) return res.status(500).json({ error: err });
    res.json({ message: 'Location saved' });
  });
};

exports.endRide = (req, res) => {
  const ride_id = req.params.ride_id;
  const { end_lat, end_lng, end_time } = req.body;

  const getLocationsSql = `SELECT lat, lng FROM ride_locations WHERE ride_id = ? ORDER BY timestamp`;

  db.query(getLocationsSql, [ride_id], (err, locations) => {
    if (err) return res.status(500).json({ error: err });

    let totalDistance = 0;
    for (let i = 1; i < locations.length; i++) {
      const prev = locations[i - 1];
      const curr = locations[i];
      totalDistance += haversine(prev.lat, prev.lng, curr.lat, curr.lng);
    }

    const updateSql = `UPDATE staff_rides
                       SET end_lat = ?, end_lng = ?, end_time = ?, total_distance_km = ?
                       WHERE id = ?`;

    db.query(updateSql, [end_lat, end_lng, end_time, totalDistance.toFixed(2), ride_id], (err) => {
      if (err) return res.status(500).json({ error: err });
      res.json({ message: 'Ride ended', total_distance_km: totalDistance.toFixed(2) });
    });
  });
};

exports.getRideLocations = (req, res) => {
  const ride_id = req.params.ride_id;
  const sql = `SELECT lat, lng, timestamp FROM ride_locations WHERE ride_id = ? ORDER BY timestamp`;

  db.query(sql, [ride_id], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    res.json(results);
  });
};
