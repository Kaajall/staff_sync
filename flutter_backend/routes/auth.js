const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const authenticateToken = require('../middleware/authMiddleware');

const router = express.Router();

// Generate Tokens
const generateAccessToken = (user) => {
    return jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
        expiresIn: process.env.ACCESS_TOKEN_EXPIRY || '15m'
    });
};

const generateRefreshToken = (user) => {
    return jwt.sign({ id: user.id }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: process.env.REFRESH_TOKEN_EXPIRY || '7d'
    });
};

// 🟢 Register Route
router.post('/register', async (req, res) => {
    try {
        const { username, email, phone, password, role } = req.body;
        if (!email && !phone) {
            return res.status(400).json({ message: 'Email or phone required' });
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        const sql = `INSERT INTO users (username, email, phone, password, role) VALUES (?, ?, ?, ?, ?)`;
        const phoneValue = phone && phone.length > 0 ? phone : null;
        db.query(sql, [username, email, phone, hashedPassword, role], (err, result) => {
            if (err) return res.status(500).json({ error: 'Database error' });

            res.status(201).json({ message: 'User registered successfully' });
        });
    } catch (error) {
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

// 🟢 Login Route
router.post('/login', (req, res) => {
    try {
        const { email, phone, password } = req.body;
        if (!email) return res.status(400).json({ message: "Email required" });

        const sql = email
            ? `SELECT * FROM users WHERE email = ?`
            : `SELECT * FROM users WHERE phone = ?`;


        db.query(sql, [email || phone], async (err, results) => {
            if (err) return res.status(500).json({ error: err.message || 'Database error' });
            if (results.length === 0) return res.status(401).json({ message: 'Invalid credentials' });

            const user = results[0];
            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });

            // Generate Tokens
            const accessToken = generateAccessToken(user);
            const refreshToken = generateRefreshToken(user);

            // Store Refresh Token in DB
            db.query(`UPDATE users SET refresh_token = ? WHERE id = ?`, [refreshToken, user.id]);

            res.json({ accessToken, refreshToken, role:user.role});
        });
    } catch (error) {
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

router.get('/user', authenticateToken, (req, res) => {
  const userId = req.user.id;

  db.query(
    'SELECT id, username, email, phone, role FROM users WHERE id = ?',
    [userId],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error' });
      if (results.length === 0) return res.status(404).json({ message: 'User not found' });

      res.json(results[0]);
    }
  );
});


// 🟢 Refresh Token Route
router.post('/refresh', (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(401).json({ message: "Refresh token required" });
    }

    console.log("Received Refresh Token:", refreshToken); // Debugging

    jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, (err, decoded) => {
        if (err) {
            console.error("Refresh Token Verification Error:", err); // Debugging
            return res.status(403).json({ message: "Invalid refresh token" });
        }

        // Generate new Access Token
        const newAccessToken = generateAccessToken({ id: decoded.id, role: decoded.role });

        res.json({ accessToken: newAccessToken });
    });
});


// 🟢 Logout Route (Clears Refresh Token)
router.post('/logout', (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ message: "Refresh token required" });

    db.query(`UPDATE users SET refresh_token = NULL WHERE refresh_token = ?`, [refreshToken], (err, result) => {
        if (err) return res.status(500).json({ message: "Database error" });

        res.json({ message: "Logged out successfully" });
    });
});

module.exports = router;
