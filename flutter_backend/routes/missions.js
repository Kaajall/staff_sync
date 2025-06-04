const express = require('express');
const router = express.Router();
const pool = require('../db');
const axios = require('axios');
const util = require('util');
require('dotenv').config();

pool.query = util.promisify(pool.query);

// Utility: Get coordinates from Google Maps API
async function getCoordinates(locationName) {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(locationName)}&key=${apiKey}`;

  try {
    const res = await axios.get(url);
    const data = res.data;
    if (data.status === 'OK') {
      const { lat, lng } = data.results[0].geometry.location;
      return { latitude: lat, longitude: lng };
    } else {
      throw new Error('Geocoding failed: ' + data.status);
    }
  } catch (err) {
    throw new Error('Error connecting to Google Maps API: ' + err.message);
  }
}

// POST /missions - Add a mission
router.post('/', async (req, res) => {
  const { staff_id, name } = req.body;

  try {
    const { latitude, longitude } = await getCoordinates(name);
    const sql = 'INSERT INTO missions (staff_id, name, latitude, longitude) VALUES (?, ?, ?, ?)';
    await pool.query(sql, [staff_id, name, latitude, longitude]);
    res.json({ success: true, message: 'Mission added successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to add mission' });
  }
});

// GET /missions/:staff_id - Get missions for a staff
router.get('/:staff_id', async (req, res) => {
  const { staff_id } = req.params;
  try {
    const rows = await pool.query('SELECT * FROM missions WHERE staff_id = ?', [staff_id]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch missions' });
  }
});

// PUT /missions/:id - Update mission status
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    const sql = "UPDATE missions SET status = ? WHERE id = ?";
    await pool.query(sql, [status, id]);
    res.json({ success: true, message: 'Mission updated successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update mission' });
  }
});

// POST /missions/complete/:id - Mark mission as completed
router.post('/complete/:id', async (req, res) => {
  const { id } = req.params;
  const { remarks, image_url, lat, lng } = req.body;

  console.log("Incoming Data:", { id, remarks, image_url, lat, lng });

  // Validate required fields
  if (!remarks || !image_url || !lat || !lng) {
    return res.status(400).json({ success: false, message: 'Missing required fields in request body' });
  }

  const sql = `
    UPDATE missions
    SET
      status = 'completed',
      remarks = ?,
      image_url = ?,
      completed_lat = ?,
      completed_lng = ?,
      completed_at = NOW()
    WHERE id = ?
  `;

  try {
    const result = await pool.query(sql, [remarks, image_url, lat, lng, id]);
    console.log("Update Result:", result);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'No mission found with this ID' });
    }

    res.json({ success: true, message: 'Mission marked as complete' });
  } catch (err) {
    console.error('SQL Error:', err);
    res.status(500).json({ error: 'Failed to mark mission as complete' });
  }
});

module.exports = router;
