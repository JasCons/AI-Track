# Live Track Feature - Grab-Style Transit Tracking

## Overview
A real-time Google Maps transit tracking feature similar to Grab, showing live vehicle positions along predefined routes like "Sapang Palay - PITX".

## Features Implemented

### 1. Live Track Page (`lib/pages/live_track_page.dart`)
- Full-screen Google Maps view
- Real-time vehicle marker updates
- Route polylines showing the complete path
- Start/end point markers with custom colors
- Route selection dropdown
- ETA display
- Vehicle simulation controls

### 2. Vehicle Simulator Service (`lib/services/vehicle_simulator.dart`)
- Simulates vehicle movement along routes
- Updates Firestore every 5 seconds
- Calculates dynamic ETA based on remaining distance
- Supports multiple simultaneous vehicle simulations
- Clean start/stop controls

### 3. Predefined Routes
Currently includes:
- **Sapang Palay - PITX**: Major route through Manila (9 waypoints)
- **Cubao - Alabang**: EDSA corridor route (6 waypoints)

### 4. Firestore Integration
- `vehicles` collection stores real-time positions
- Document structure:
  ```
  {
    route: "Sapang Palay - PITX",
    lat: 14.8167,
    lng: 121.0500,
    plateNumber: "ABC-1234",
    eta: 45,
    timestamp: <server timestamp>
  }
  ```

### 5. Security Rules
Added to `firestore.rules`:
```
match /vehicles/{vehicleId} {
  allow read: if true; // Public read for tracking
  allow write: if request.auth != null; // Authenticated write
}
```

## How to Use

### For Passengers:
1. Log in to the app
2. Open menu and select "Live Track"
3. Choose a route from the dropdown
4. Tap "Start Simulation" to see a vehicle moving
5. Watch the orange vehicle marker move along the blue route
6. Check the ETA displayed at the top

### For Developers:
1. Add new routes in `_routes` map in `live_track_page.dart`
2. Format: `'Route Name': [LatLng(...), LatLng(...), ...]`
3. Start simulation with `VehicleSimulator.instance.startSimulation()`
4. Stop with `VehicleSimulator.instance.stopSimulation()`

## Map Markers

| Marker Color | Meaning |
|--------------|---------|
| Green | Starting point |
| Red | Destination |
| Orange | Live vehicle position |
| Blue line | Route path |

## Technical Details

### Real-time Updates
- Uses Firestore snapshots for live data
- Updates every 5 seconds during simulation
- Automatic marker repositioning
- ETA recalculation on each update

### Performance
- Efficient marker management (removes old, adds new)
- Bounds calculation for optimal camera positioning
- Minimal re-renders using setState strategically

### Future Enhancements
- [ ] Multiple vehicles on same route
- [ ] Real GPS tracking (replace simulation)
- [ ] Traffic-aware ETA
- [ ] Route deviation alerts
- [ ] Passenger pickup/dropoff points
- [ ] Driver app for real position updates
- [ ] Push notifications for arrival
- [ ] Historical route playback

## Integration with Existing Features

The Live Track feature integrates with:
- **Menu Page**: Added "Live Track" menu item
- **Auth Service**: Requires authentication for simulation control
- **Firestore**: Uses existing Firebase setup
- **Transit Track**: Complements the existing transit tracking page

## Testing

To test the feature:
1. Run `flutter run`
2. Log in as any user (passenger or operator)
3. Navigate to Live Track from menu
4. Select "Sapang Palay - PITX"
5. Tap "Start Simulation"
6. Observe vehicle moving from Sapang Palay toward PITX
7. Check ETA updates in real-time

## Notes

- Simulation is for demo purposes only
- In production, replace with actual GPS data from vehicles
- Ensure Firestore rules are deployed: `firebase deploy --only firestore:rules`
- Google Maps API key must be configured in Android/iOS manifests
- Vehicle positions persist in Firestore until overwritten

## Dependencies

Already included in `pubspec.yaml`:
- `google_maps_flutter: ^2.4.0`
- `cloud_firestore: ^4.7.1`
- `firebase_core: ^2.15.0`

No additional dependencies required.
