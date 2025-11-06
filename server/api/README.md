AI-Track API
=================

This is a small demo API for the AI-Track project. It contains a lightweight predictive model and an Express HTTP server with a `/predict` endpoint.

Quick start
-----------

1. Install dependencies:

```powershell
cd server/api
npm install
```

2. (Optional) Provide a Firebase service account JSON to enable token verification:

- Place the file at `server/serviceAccountKey.json` or set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path.

3. Start the server:

```powershell
npm start
```

API
---

- GET /health
  - Returns server health.

- POST /predict
  - Body: `{ "features": [number, number, ...], "token": "<firebase id token optional>" }`
  - Returns: `{ success: true, score: <0..1> }`

Example curl
------------

```powershell
curl -X POST http://localhost:3333/predict -H "Content-Type: application/json" -d '{"features": [1,0,0,0]}'
```

Integrating from Flutter
------------------------

Use `http` or `dio` to POST JSON to the endpoint. If you want to require authenticated requests, pass the Firebase ID token:

```dart
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
final res = await http.post(Uri.parse('http://10.0.2.2:3333/predict'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'features': [1,0,0,0], 'token': idToken}),
);
```

Notes
-----

- This model is only for demonstration. Replace it with a proper trained model (TensorFlow, PyTorch, ONNX) served via TF Serving, TorchServe, or a managed cloud ML service for production.
- Protect the endpoint: enable HTTPS, require token verification, add rate limiting and input validation before putting this into production.
