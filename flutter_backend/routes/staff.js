const express = require('express');
const db = require('../db');
const router = express.Router();
router.use(express.json());

// ✅ Get Staff List
router.get('/', (req, res) => {
    const sql = `SELECT id, username, email, phone, role FROM users WHERE role = 'staff'`;

    db.query(sql, (err, results) => {
        if (err) {
            console.error("Database Error:", err);
            return res.status(500).json({ message: "Database error" });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: "No staff found" });
        }

        res.status(200).json({
            message: "Staff list retrieved successfully",
            data: results
        });
    });
});



// ✅ Get Assigned Locations
router.get('/locations', (req, res) => {
    db.query('SELECT * FROM locations', (err, results) => {
        if (err) return res.status(500).json({ message: 'Error fetching locations' });
        res.json(results);
    });
});

// ✅ Submit Visit (Photo + Remark)
router.post('/visit', (req, res) => {
    try {
            const { staff_id, location, latitude, longitude, photo, remark } = req.body;

            if (!staff_id || !location || !latitude || !longitude || !photo || !remark) {
                return res.status(400).json({ message: "All fields are required" });
            }

            // Insert into MySQL
            const sql = "INSERT INTO visits (staff_id, location, latitude, longitude, photo, remark, visit_time) VALUES (?, ?, ?, ?, ?, ?, NOW())";
            db.query(sql, [staff_id, location, latitude, longitude, photo, remark], (err, result) => {
                if (err) {
                    console.error("Database Error:", err);
                    return res.status(500).json({ message: "Error submitting visit", error: err.message });
                }
                res.status(201).json({ message: "Location submitted successfully", id: result.insertId });
            });

    } catch (error) {
            console.error("Server Error:", error);
            res.status(500).json({ message: "Internal Server Error", error: error.message });
    }
});

// ✅ Staff Visit History
router.get('/visits/:staff_id', (req, res) => {
    const { staff_id } = req.params;
    const sql = `SELECT * FROM visits WHERE staff_id = ? ORDER BY visit_time DESC`;

    db.query(sql, [staff_id], (err, results) => {
        if (err) {
            console.error("Database Error:", err);
            return res.status(500).json({ message: "Error fetching visits" });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: "No visits found for this staff" });
        }

        res.status(200).json({
            message: "Visit history retrieved successfully",
            data: results
        });
    });
});

router.put('/missions/:id/mark-visited', (req, res) => {
    const { id } = req.params;
    const sql = `UPDATE missions SET status = 'visited', visited_at = NOW() WHERE id = ?`;

    db.query(sql, [id], (err, result) => {
        if (err) {
            console.error("Database Error:", err);
            return res.status(500).json({ message: "Error updating mission status" });
        }

        res.status(200).json({ message: "Mission marked as visited successfully" });
    });
});



module.exports = router;
