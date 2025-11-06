# Predictive API Documentation

## Overview
The AI-Track predictive API uses a machine learning model to estimate transit arrival times based on route characteristics, time of day, and traffic patterns.

## Architecture

### Backend (Node.js + Express)
- **Location**: `server/api/index.js`
- **Model**: `server/api/model/predictor.js`
- **Port**: 3333 (default)

### Flutter Client
- **Service**: `lib/services/prediction_service.dart`
- **Integration**: `lib/pages/transit_track.dart`

## API Endpoints

### POST /predict
Predicts transit arrival time based on route features.

**Request:**
```json
{
  "features": [distance_km, hour_of_day, day_of_week, traffic_factor],
  "token": "firebase_id_token_optional"
}
```

**Response:**
```json
{
  "success": true,
  "score": 0.75
}
```

**Feature Vector:**
1. `distance_km` - Distance between current location and destination (0-100)
2. `hour_of_day` - Current hour (0-23)
3. `day_of_week` - Day of week (1=Monday, 7=Sunday)
4. `traffic_factor` - Traffic multiplier (1.0=normal, 1.5=peak hours)

**Score Interpretation:**
- Score ranges from 0 to 1
- Converted to minutes: `estimated_minutes = score * 60`
- Example: score 0.5 = 30 minutes estimated arrival

### GET /routes
Fetches available routes for a vehicle type.

**Request:**
```
GET /routes?vehicle=lrt-1&type=rail
```

**Response:**
```json
[
  {
    "id": "route123",
    "name": "North to South",
    "vehicle": "lrt-1",
    "type": "rail",
    "coordinates": [
      {"lat": 14.5995, "lng": 120.9842},
      {"lat": 14.6042, "lng": 120.9822}
    ]
  }
]
```

## Running the Server

### 1. Install Dependencies
```powershell
cd server/api
npm install
```

### 2. Start Server
```powershell
npm start
```

Server runs on `http://localhost:3333`

### 3. Test Endpoint
```powershell
curl -X POST http://localhost:3333/predict -H "Content-Type: application/json" -d "{\"features\": [5.2, 8, 1, 1.5]}"
```

## Flutter Integration

### Using PredictionService

```dart
import 'package:helloworld/services/prediction_service.dart';

final result = await PredictionService.instance.predictArrival(
  routeId: 'route123',
  currentLat: 14.5995,
  currentLng: 120.9842,
  destLat: 14.6042,
  destLng: 120.9822,
);

if (result.success) {
  print('Estimated arrival: ${result.estimatedMinutes} minutes');
}
```

### Emulator Configuration
- Android emulator uses `10.0.2.2` to access host machine
- Default baseUrl: `http://10.0.2.2:3333`
- For physical devices, use your machine's IP address

## Model Details

### Current Implementation
- Simple logistic regression model (demo)
- Weights stored in `server/api/model/weights.json`
- Sigmoid activation function

### Improving the Model

**Option 1: Train Custom Model**
```python
# Example with scikit-learn
from sklearn.linear_model import LogisticRegression
import json

# Train on historical data
model = LogisticRegression()
model.fit(X_train, y_train)

# Export weights
weights = {
    "w": model.coef_[0].tolist(),
    "b": float(model.intercept_[0])
}
with open('weights.json', 'w') as f:
    json.dump(weights, f)
```

**Option 2: Use TensorFlow/PyTorch**
- Train a neural network
- Export to ONNX format
- Serve with TensorFlow Serving or TorchServe

**Option 3: Cloud ML Services**
- Google Cloud AI Platform
- AWS SageMaker
- Azure ML

## Traffic Factor Calculation

Peak hours (higher traffic):
- Morning: 7:00 AM - 9:00 AM (factor: 1.5)
- Evening: 5:00 PM - 7:00 PM (factor: 1.5)
- Normal hours: factor 1.0

## Distance Calculation

Uses Haversine formula for great-circle distance:
```dart
double distance = calculateDistance(lat1, lng1, lat2, lng2);
// Returns distance in kilometers
```

## Security Considerations

### Production Checklist
- [ ] Enable HTTPS/TLS
- [ ] Require Firebase authentication tokens
- [ ] Add rate limiting (e.g., express-rate-limit)
- [ ] Validate input ranges
- [ ] Add request logging
- [ ] Set up monitoring/alerts
- [ ] Use environment variables for config
- [ ] Add CORS restrictions

### Example: Add Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/predict', limiter);
```

## Testing

### Unit Tests (Backend)
```javascript
// server/api/test/predictor.test.js
const { predict } = require('../model/predictor');

test('predict returns score between 0 and 1', () => {
  const score = predict([5, 8, 1, 1.5]);
  expect(score).toBeGreaterThanOrEqual(0);
  expect(score).toBeLessThanOrEqual(1);
});
```

### Integration Tests (Flutter)
```dart
// test/prediction_service_test.dart
test('predictArrival returns valid result', () async {
  final result = await PredictionService.instance.predictArrival(
    routeId: 'test',
    currentLat: 14.5995,
    currentLng: 120.9842,
    destLat: 14.6042,
    destLng: 120.9822,
  );
  expect(result.success, true);
  expect(result.estimatedMinutes, isNotNull);
});
```

## Next Steps

1. **Collect Real Data**: Gather historical transit times and route data
2. **Train Better Model**: Use collected data to train a more accurate model
3. **Add Real-time Updates**: Stream live vehicle locations
4. **Implement Caching**: Cache predictions for frequently requested routes
5. **Add Analytics**: Track prediction accuracy and improve over time
