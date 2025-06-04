const express = require("express");
const db = require("../db"); // ✅ MySQL database connection
const router = express.Router();

router.get('/test', (req, res) => {
    res.send({ message: 'GET request successful' });
});

// Handle POST request at /test
router.post('/test', (req, res) => {
    res.send({ message: 'POST request successful' });
});


// ✅ Get Staff List (From MySQL)
router.get("/staff", (req, res) => {
    db.query('SELECT id, username, email, phone FROM users WHERE role="staff"', (err, results) => {
        if (err) return res.status(500).json({ message: "Error fetching staff list" });
        res.json(results);
    });
});

// ✅ Get Visit History (Fixing Error)
router.get("/visits", (req, res) => {
    db.query("SELECT * FROM visits", (err, results) => {
        if (err) {
            console.error("Error fetching visit history:", err);
            return res.status(500).json({ message: "Server error" });
        }
        res.json(results);
    });
});

module.exports = router;
