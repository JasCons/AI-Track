const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const path = require('path');

const { predict } = require('./model/predictor');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Optional: initialize firebase-admin if service account present
const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, '..', 'serviceAccountKey.json');
if (require('fs').existsSync(saPath)) {
  try {
    admin.initializeApp({ credential: admin.credential.cert(require(saPath)) });
    console.log('firebase-admin initialized');
  } catch (err) {
    console.warn('Failed to initialize firebase-admin:', err);
  }
} else {
  console.log('No service account found for firebase-admin; running without admin privileges');
}

// Health endpoint
app.get('/health', (req, res) => res.json({ status: 'ok', time: Date.now() }));

// Example predict endpoint
// Accepts JSON body { features: [num, num, ...], token: '<firebase id token optional>' }
app.post('/predict', async (req, res) => {
  try {
    const { features, token } = req.body || {};
    if (!Array.isArray(features)) return res.status(400).json({ error: 'features must be an array of numbers' });

    // Optional token verification
    if (token && admin.apps.length) {
      try {
        const decoded = await admin.auth().verifyIdToken(token);
        // attach user info if needed
        req.user = decoded;
      } catch (err) {
        return res.status(401).json({ error: 'Invalid auth token' });
      }
    }

    const score = predict(features);
    return res.json({ success: true, score });
  } catch (err) {
    console.error('Predict error', err);
    return res.status(500).json({ error: 'internal error' });
  }
});

// Transit register endpoint
// Body: { transitName, transitType, licenseId, plateNumber, operatorUid?, metadata? }
app.post('/transit/register', async (req, res) => {
  try {
    const { transitName, transitType, licenseId, plateNumber, operatorUid, metadata } = req.body || {};
    if (!transitName || !transitType || !licenseId || !plateNumber) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Optional auth verification if token present
    if (req.body.token && admin.apps.length) {
      try {
        const decoded = await admin.auth().verifyIdToken(req.body.token);
        // prefer server-provided operatorUid
        req.user = decoded;
      } catch (err) {
        return res.status(401).json({ error: 'Invalid auth token' });
      }
    }

    // If firebase-admin initialized, persist to Firestore
    if (admin.apps.length) {
      const db = admin.firestore();
      const docRef = await db.collection('transit').add({
        transitName,
        transitType,
        licenseId,
        plateNumber,
        operatorUid: operatorUid || (req.user && req.user.uid) || null,
        metadata: metadata || {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return res.json({ success: true, id: docRef.id });
    }

    // Fallback: return a generated id when no Firestore available
    const id = `transit-${Date.now()}`;
    return res.json({ success: true, id });
  } catch (err) {
    console.error('Transit register error', err);
    return res.status(500).json({ error: 'internal error' });
  }
});

// Routes endpoint - returns available routes for vehicle/type
app.get('/routes', async (req, res) => {
  try {
    const { vehicle, type } = req.query;
    if (!vehicle || !type) {
      return res.status(400).json({ error: 'vehicle and type query params required' });
    }

    // If firebase-admin initialized, fetch from Firestore
    if (admin.apps.length) {
      const db = admin.firestore();
      const snapshot = await db.collection('routes')
        .where('vehicle', '==', vehicle)
        .where('type', '==', type)
        .get();
      
      const routes = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      return res.json(routes);
    }

    // Fallback: return empty array
    return res.json([]);
  } catch (err) {
    console.error('Routes fetch error', err);
    return res.status(500).json({ error: 'internal error' });
  }
});

const port = process.env.PORT || 3333;
app.listen(port, () => console.log(`AI-Track API listening on http://localhost:${port}`));
