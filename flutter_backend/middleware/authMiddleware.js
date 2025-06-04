const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Extracts token after "Bearer"

  if (!token) return res.status(401).json({ message: 'Token not provided' });

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid token' });

    req.user = user; // { id, role, iat, exp }
    next();
  });
}

module.exports = authenticateToken;
