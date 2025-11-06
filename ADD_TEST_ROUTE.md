# Add Test Route to Firestore

The Transit Track page needs routes in Firestore to display the map and prediction features.

## Quick Fix: Add Test Route via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. Click **Start collection**
5. Collection ID: `routes`
6. Add document with these fields:

```
Document ID: (auto-generate)

Fields:
- name: "North Avenue to Baclaran" (string)
- vehicle: "lrt-1" (string)
- type: "rail" (string)
- coordinates: (array)
  - 0: (map)
    - lat: 14.6564 (number)
    - lng: 121.0320 (number)
  - 1: (map)
    - lat: 14.6500 (number)
    - lng: 121.0250 (number)
  - 2: (map)
    - lat: 14.5350 (number)
    - lng: 120.9980 (number)
```

7. Click **Save**

## Or Use Flutter to Add Route

Run this in your app (add to debug page):

```dart
await FirestoreService.instance.addRoute(
  name: 'North Avenue to Baclaran',
  vehicle: 'lrt-1',
  type: 'rail',
  coordinates: [
    {'lat': 14.6564, 'lng': 121.0320},
    {'lat': 14.6500, 'lng': 121.0250},
    {'lat': 14.5350, 'lng': 120.9980},
  ],
);
```

## After Adding Route

1. Go to Transit Track page
2. Select **Rail** → **LRT-1**
3. Click **Refresh routes**
4. Select the route from dropdown
5. Map will appear with markers and route line
6. Click **Predict Arrival Time** button
