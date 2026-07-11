# Real-Time Vehicle Parts Inventory & Billing System

A modern Flutter and Firebase-based vehicle parts management application designed to digitize inventory operations, billing, customer management, and delivery tracking.

The application provides a complete solution for vehicle parts businesses with features including inventory management, QR-based billing, real-time order tracking, and live delivery monitoring.

---

# Developed By

## Zynox Tech

Website: https://zynoxtech.site  
Email: hello@zynoxtech.site  
Location: Abbottabad, Pakistan

Zynox Tech is a software development company specializing in:

- Mobile Application Development
- Web Application Development
- Enterprise Software Solutions
- Artificial Intelligence Solutions
- Business Automation Systems
- Custom Digital Products

We build scalable and reliable technology solutions that help businesses improve efficiency and transform their operations digitally.

For software development services and technology partnerships:

Website: https://zynoxtech.site  
Email: hello@zynoxtech.site

---

# Project Overview

Real-Time Vehicle Parts Inventory & Billing is a complete mobile application built for vehicle parts businesses.

The system helps manage:

- Vehicle parts inventory
- Customer orders
- Billing operations
- Staff activities
- Delivery tracking
- Stock monitoring

The application uses Firebase cloud services to provide real-time data synchronization and secure user management.

---

# Features

## Authentication System

- Secure user registration and login
- Staff and customer roles
- Firebase Authentication integration
- Role-based application access

---

## Inventory Management

- Add, update, and delete vehicle parts
- Manage stock quantities
- Search and filter products
- Low-stock alerts
- Real-time inventory updates

---

## Billing System

- QR code-based part scanning
- Cart management
- Automatic billing calculation
- Sales record management
- Transaction history

---

## Delivery Tracking

- Order status management
- Live location tracking
- Map-based delivery monitoring
- Distance calculation
- Estimated delivery time

---

## Customer Features

- Browse available parts
- Place orders
- Track deliveries
- View order history

---

## Staff Features

- Manage inventory
- Process customer orders
- Update delivery status
- Monitor sales activities

---

# Technology Stack

## Mobile Application

- Flutter
- Dart

## Backend Services

- Firebase Authentication
- Firebase Firestore
- Firebase Cloud Services

## Additional Integrations

- Google Maps API
- QR Code Scanner
- Real-time GPS Tracking

---

# Getting Started

## Requirements

Before running this project, install:

- Flutter SDK 3.x
- Android Studio
- Android Emulator or Physical Device
- Firebase Account

Verify Flutter installation:

```bash
flutter doctor
```

---

# Firebase Setup

## 1. Create Firebase Project

Create a project from:

```
https://console.firebase.google.com
```

---

## 2. Configure Android Application

Add Android application with package name:

```
com.example.parts
```

Download:

```
google-services.json
```

and place it inside:

```
android/app/
```

---

## 3. Enable Firebase Services

Enable:

- Firebase Authentication
- Email/Password Login
- Cloud Firestore Database

---

## 4. Configure Google Maps

Enable Google Maps SDK for Android.

Update:

```
android/app/src/main/res/values/google_maps_api.xml
```

with your API key.

---

# Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/Vehicle_Inventory_App.git
```

Navigate into the project:

```bash
cd Vehicle_Inventory_App
```

Install dependencies:

```bash
flutter pub get
```

---

# Run Application

Start the application:

```bash
flutter run
```

The application will run on:

- Android Emulator
- Physical Android Device

---

# Application Workflow

## Customer Flow

1. Register account
2. Browse available vehicle parts
3. Place order
4. Track delivery status
5. Monitor live delivery location

---

## Staff Flow

1. Login as staff
2. Add and manage inventory
3. Process customer orders
4. Generate bills
5. Start and manage deliveries

---

# Project Structure

```
Vehicle_Inventory_App/

├── lib/

│   ├── screens/
│   ├── widgets/
│   ├── models/
│   ├── services/
│   ├── firebase/
│   └── main.dart

├── android/

├── ios/

├── assets/

├── pubspec.yaml

└── README.md
```

---

# Firestore Database Structure

## Users

```
users/{uid}

{
 email,
 role,
 createdAt
}
```

---

## Parts

```
parts/{partId}

{
 name,
 category,
 price,
 quantity,
 lowStockThreshold,
 imageUrl,
 qrData
}
```

---

## Sales

```
sales/{saleId}

{
 partIds,
 total,
 createdAt
}
```

---

## Orders

```
orders/{orderId}

{
 status,
 createdAt,
 confirmedAt,
 dispatchedAt,
 deliveredAt,
 items
}
```

---

## Delivery Sessions

```
delivery_sessions/{orderId}

{
 orderId,
 customerId,
 staffId,
 staffLocation,
 destinationLocation,
 distance,
 eta,
 status
}
```

---

# Future Improvements

Planned improvements:

- Firebase Storage for product images
- Push notifications
- Advanced admin dashboard
- Offline mode support
- AI-based inventory forecasting
- Automated stock recommendations
- Background location tracking

---

# Troubleshooting

## Firebase Connection Issues

Check:

- `google-services.json` exists
- Firebase project configuration
- Correct package name

Run:

```bash
flutter clean
flutter pub get
```

---

## Build Issues

Update Flutter packages:

```bash
flutter pub upgrade
```

---

# License

This project is developed for educational and commercial software demonstration purposes.

---

# About Zynox Tech

Zynox Tech develops modern digital solutions for businesses and organizations.

Our services include:

- Mobile Applications
- Web Applications
- Enterprise Software
- AI Solutions
- Custom Business Automation

Website:

https://zynoxtech.site

Email:

hello@zynoxtech.site

Location:

Abbottabad, Pakistan

---

Developed by **Zynox Tech**
