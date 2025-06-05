require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');
const app = express();
const db = require('./db'); // ✅ Import database connection
const staffRoutes = require('./routes/staff');
const adminRoutes = require('./routes/admin');
const authRoutes = require('./routes/auth');
const missionsRouter = require('./routes/missions');




const app = express();
const PORT = process.env.PORT || 3000;

// ✅ Apply CORS before defining routes
app.use(cors());
app.use(express.json()); // ✅ Ensure JSON parsing is applied once
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));


// ✅ Check for missing JWT Secret
if (!process.env.JWT_SECRET) {
    console.warn("⚠️ Warning: JWT_SECRET is not set in .env file. Using default secret!");
}

if (!process.env.JWT_REFRESH_SECRET) {
    console.warn("⚠️ Warning: JWT_REFRESH_SECRET is not set in .env file. Using default secret!");
}

// ✅ Mount Routes
app.use('/auth', authRoutes);
app.use('/staff', staffRoutes);
app.use('/admin', adminRoutes);
app.use('/missions', missionsRouter);
console.log("✅ Mounted missions route at /missions");


// ✅ Register a New User
app.post('/register', async (req, res) => {
    try {
        const { username, email, phone, password, role } = req.body;

        if (!email && !phone) {
            return res.status(400).json({ message: 'Email or phone number required' });
        }

        if (!username || !email || !phone || !password || !role) {
              return res.status(400).json({ error: "Missing fields" });
        }
        // ✅ Check if user already exists
        const checkSql = `SELECT * FROM users WHERE email = ? OR phone = ?`;
        const [existingUser] = await db.query(checkSql, [email, phone]);
        if (existingUser.length > 0) {
            return res.status(409).json({ message: 'User already exists' });

        }


        const hashedPassword = await bcrypt.hash(password, 10);
        const sql = `INSERT INTO users (username, email, phone, password, role) VALUES (?, ?, ?, ?, ?)`;

        await db.query(sql, [username, email, phone, hashedPassword, role]);

        res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
        console.error("Database Error:", error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// ✅ Secure User Login
app.post('/login', async (req, res) => {
    try {
        const { email, phone, password } = req.body;

        if (!email && !phone) {
            return res.status(400).json({ message: "Email or phone is required" });
        }

        const sql = email
            ? `SELECT * FROM users WHERE email = ?`
            : `SELECT * FROM users WHERE phone = ?`;

        db.query(sql, [email || phone], async (err, results) => {
            if (err) {
                console.error("Database Error:", err.message);
                return res.status(500).json({ error: err.message });
            }

            if (!results || results.length === 0) {
                return res.status(404).json({ message: 'User not found' });
            }

            const user = results[0]; // ✅ Assign user correctly

            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) {
                return res.status(401).json({ message: 'Invalid credentials' });
            }

            // ✅ Generate Tokens after verifying the user
            const accessToken = jwt.sign(
                { id: user.id, role: user.role },
                process.env.JWT_SECRET,
                { expiresIn: process.env.ACCESS_TOKEN_EXPIRY || '7d' }
            );

            const refreshToken = jwt.sign(
                { id: user.id },
                process.env.JWT_REFRESH_SECRET,
                { expiresIn: process.env.REFRESH_TOKEN_EXPIRY || '7d' }
            );

            res.json({ accessToken, refreshToken, role: user.role });
        });

    } catch (error) {
        console.error("Database Error:", error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});


// ✅ Global Error Handler
app.use((err, req, res, next) => {
    console.error("Error:", err.message);
    res.status(500).json({ message: "Internal Server Error" });
});

// ✅ Test API Endpoints
app.get('/your-endpoint', (req, res) => res.json({ message: "API is working!" }));
app.get('/test', (req, res) => res.json({ message: "Test endpoint is working!" }));

// ✅ Start Server
app.listen(PORT, () => {
    console.log(`✅ Server running on http://192.168.1.17:${PORT}`);
});
// ✅ Handle 404 errors
app.use((req, res) => {
    res.status(404).json({ message: "Route not found" });
});
