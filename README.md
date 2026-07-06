# Real-Time Vehicle Parts Inventory & Billing (Flutter + Firebase)

Dark theme (black/orange/white) app for vehicle parts management.

Features: Authentication (staff & customer), inventory CRUD, search/filtering, low-stock alerts, QR scanning & billing, delivery status tracking, and live map-based delivery tracking.

## 1. Prerequisites
* Flutter SDK 3.x
* Android Studio emulator or real device
* Firebase project

## 2. Firebase Setup (Android)
1. Create project at https://console.firebase.google.com.
2. Add Android app with package name: `com.example.parts`.
3. Download `google-services.json` and copy to `android/app/`.
4. Enable Email/Password in Authentication.
5. Create Firestore (Production mode).
6. Enable Google Maps SDK for Android in Google Cloud Console and replace the placeholder in `android/app/src/main/res/values/google_maps_api.xml`.
7. (Optional) Add initial collections: `users`, `parts`, `sales`, `orders`, `delivery_sessions`.

Security rules (basic dev example):
```
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		match /users/{uid} {
			allow read, write: if request.auth != null && request.auth.uid == uid;
		}
		match /parts/{id} {
			allow read: if true; // Everyone can view parts
			allow write: if request.auth != null; // Require login for writes
		}
		match /sales/{id} {
			allow read, write: if request.auth != null;
		}
		match /orders/{id} {
			allow read, write: if request.auth != null;
		}
		match /delivery_sessions/{orderId} {
			allow read, write: if request.auth != null;
		}
	}
}
```

## 3. Install Packages
```powershell
flutter pub get
```

## 4. Run
```powershell
flutter run
```

## 5. Usage Flow
1. Register (choose role: customer or staff).
2. Staff: Add parts, edit quantities.
3. Anyone: View parts list; low stock shows a red warning icon.
4. Billing: Scan QR (uses part document ID); confirm cart & checkout.
5. Reports: View sales totals (today/week/month).
6. Delivery: Staff confirms an order, starts delivery, and shares live GPS while the app is open.
7. Customer: Open My Orders or Track Delivery to see live staff movement, distance, ETA, and status updates.

## 6. Part Images
Add `imageUrl` with HTTPS link in part doc. Future improvement: integrate Firebase Storage upload (create a storage bucket, use `firebase_storage` plugin, upload file, store download URL).

## 7. Firestore Document Shapes
```
parts/{partId} => { name, category, price, quantity, lowStockThreshold, imageUrl?, qrData }
sales/{saleId} => { partIds:[], total, createdAt }
orders/{orderId} => { status, createdAt, confirmedAt?, dispatchedAt?, deliveredAt?, deliverySessionId?, items? }
delivery_sessions/{orderId} => { orderId, customerId, staffId, staffLabel, customerAddress, destinationLatitude, destinationLongitude, staffLatitude, staffLongitude, distanceMeters, etaMinutes, isActive, status, startedAt, lastUpdatedAt, completedAt? }
users/{uid} => { email, role, createdAt }
```

## 8. Future Enhancements
* Firebase Storage for images
* Push notifications for low stock
* Role-based admin dashboard
* Offline caching
* AI-based stock prediction
* Background delivery tracking if you later add a backend or foreground Android service

## 9. Troubleshooting
If Firebase init fails: ensure `google-services.json` exists and run `flutter clean; flutter pub get`.

## 10. License
Academic / FYP usage.
