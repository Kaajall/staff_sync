const mysql = require('mysql');
const dotenv = require('dotenv');
const util = require('util');

dotenv.config();

// Create MySQL connection
const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '12345678', // ✅ Use correct variable name
    database: process.env.DB_NAME || 'staffsync'
});

// Connect to DB
db.connect(err => {
    if (err) {
        console.error('Database connection failed:', err);
    } else {
        console.log('✅ Connected to MySQL database');
    }
});
db.query = util.promisify(db.query);

module.exports = db;
