const express = require('express');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3200;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Reverse-proxy API calls to the backend so the browser only ever talks to this origin.
// Works unchanged in local dev, Docker Compose, and Kubernetes - only BACKEND_URL differs.
app.use('/api', async (req, res) => {
  const target = `${BACKEND_URL}/api${req.url}`;
  try {
    const hasBody = !['GET', 'HEAD'].includes(req.method);
    const upstream = await fetch(target, {
      method: req.method,
      headers: { 'Content-Type': 'application/json' },
      body: hasBody ? JSON.stringify(req.body ?? {}) : undefined
    });
    const bodyText = await upstream.text();
    res
      .status(upstream.status)
      .set('Content-Type', upstream.headers.get('content-type') || 'application/json')
      .send(bodyText);
  } catch (err) {
    res.status(502).json({ message: `Frontend proxy could not reach backend: ${err.message}` });
  }
});

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Green frontend is running',
    version: 'green',
    port: PORT
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Green frontend server running on port ${PORT}`);
});