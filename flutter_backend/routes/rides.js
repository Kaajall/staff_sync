const express = require('express');
const router = express.Router();
const pool = require('../db'); // Adjust path according to your project structure
const axios = require('axios');
require('dotenv').config


// Start ride
router.post('/start', async (req, res) => {
  try {
    const { staff_id, mission_id, vehicle_type, start_lat, start_lng } = req.body;

    const result = await pool.query(
      `INSERT INTO staff_rides (staff_id, mission_id, vehicle_type, start_lat, start_lng)
       VALUES (?, ?, ?, ?, ?)`,
      [staff_id, mission_id, vehicle_type, start_lat, start_lng]
    );

    res.json({ ride_id: result.insertId });
  } catch (err) {
    console.error('Error starting ride:', err);
    res.status(500).json({ error: 'Failed to start ride' });
  }
});


// Save live location
router.post('/:ride_id/locations', async (req, res) => {
  try {
    const { ride_id } = req.params;
    const { lat, lng } = req.body;

    await pool.query(
      `INSERT INTO ride_locations (ride_id, lat, lng) VALUES (?, ?, ?)`,
      [ride_id, lat, lng]
    );

    res.json({ message: 'Location saved' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to save location' });
  }
});



// POST /api/rides/end

router.post('/:ride_id/end', async (req, res) => {
  const { ride_id } = req.params;
  const { end_lat, end_lng } = req.body;

  if (!ride_id || !end_lat || !end_lng) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Save end location and current timestamp
    await pool.query(
      `UPDATE staff_rides SET end_lat = ?, end_lng = ?, end_time = CURRENT_TIMESTAMP WHERE id = ?`,
      [end_lat, end_lng, ride_id]
    );

    // Get all ride locations
    const locations = await pool.query(
      `SELECT lat, lng FROM ride_locations WHERE ride_id = ? ORDER BY timestamp ASC`,
      [ride_id]
    );

    if (!locations || locations.length < 2) {
      return res.status(400).json({ error: 'Not enough location data to calculate distance' });
    }

    const origin = `${locations[0].lat},${locations[0].lng}`;
    const destination = `${locations[locations.length - 1].lat},${locations[locations.length - 1].lng}`;
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;

    const response = await axios.get(`https://maps.googleapis.com/maps/api/directions/json`, {
      params: {
        origin,
        destination,
        key: apiKey
      }
    });
    console.log('Google Maps API response:', response.data);
    const routes = response.data.routes;
    if (!routes || routes.length === 0) {
      return res.status(500).json({ error: 'Unable to fetch route from Google Maps' });
    }

    const distanceMeters = routes[0].legs[0].distance.value;
    const distanceKm = (distanceMeters / 1000).toFixed(2);

    // Update total distance
    await pool.query(
      `UPDATE staff_rides SET total_distance_km = ? WHERE id = ?`,
      [distanceKm, ride_id]
    );

    res.json({ message: 'Ride ended and distance updated', distance_km: distanceKm });
  } catch (err) {
    console.error('Error ending ride:', err);
    res.status(500).json({ error: 'Server error' });
  }
});





// Get locations for a ride
router.get('/:ride_id/locations', async (req, res) => {
  try {
    const { ride_id } = req.params;
    const result = await pool.query(
      `SELECT lat, lng, timestamp FROM ride_locations WHERE ride_id=? ORDER BY timestamp`,
      [ride_id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch locations' });
  }
});

// Get all active rides with latest location
router.get('/active', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT sr.id as ride_id, sr.staff_id, sr.mission_id, sr.vehicle_type, sr.start_time,
        rl.lat, rl.lng, rl.timestamp as last_location_time
      FROM staff_rides sr
      LEFT JOIN LATERAL (
        SELECT lat, lng, timestamp FROM ride_locations WHERE ride_id = sr.id ORDER BY timestamp DESC LIMIT 1
      ) rl ON true
      WHERE sr.end_time IS NULL
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch active rides' });
  }
});

module.exports = router;
