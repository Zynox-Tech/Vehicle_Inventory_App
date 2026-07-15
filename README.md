# Real-Time Vehicle Parts Inventory & Billing System

A modern **Flutter and Firebase-based vehicle parts management application** designed to digitize inventory operations, billing, customer management, and delivery tracking.

The application provides a complete solution for vehicle parts businesses with features including inventory management, QR-based billing, real-time order tracking, and live delivery monitoring.

---

# Developed By

## Zynox Tech

**Website:** https://zynoxtech.site
**Email:** [hello@zynoxtech.site](mailto:hello@zynoxtech.site)
**Location:** Abbottabad, Pakistan

Zynox Tech is a software development company specializing in:

* Mobile Application Development
* Web Application Development
* Enterprise Software Solutions
* Artificial Intelligence Solutions
* Business Automation Systems
* Custom Digital Products

We build scalable and reliable technology solutions that help businesses improve efficiency and transform their operations digitally.

For software development services and technology partnerships:

**Website:** https://zynoxtech.site
**Email:** [hello@zynoxtech.site](mailto:hello@zynoxtech.site)

---

# Project Overview

The **Real-Time Vehicle Parts Inventory & Billing System** is a complete mobile application built for vehicle parts businesses.

The system helps manage:

* Vehicle parts inventory
* Customer orders
* Billing operations
* Staff activities
* Delivery tracking
* Stock monitoring

The application uses Firebase cloud services to provide real-time data synchronization and secure user management.

---

# Features

## Authentication System

* Secure user registration and login
* Staff and customer roles
* Firebase Authentication integration
* Role-based application access

---

## Inventory Management

* Add, update, and delete vehicle parts
* Manage stock quantities
* Search and filter products
* Low-stock alerts
* Real-time inventory updates

---

## Billing System

* QR code-based part scanning
* Cart management
* Automatic billing calculation
* Sales record management
* Transaction history

---

## Delivery Tracking

* Order status management
* Live location tracking
* Map-based delivery monitoring
* Distance calculation
* Estimated delivery time

---

## Customer Features

* Browse available parts
* Place orders
* Track deliveries
* View order history

---

## Staff Features

* Manage inventory
* Process customer orders
* Update delivery status
* Monitor sales activities

---

# Application Screenshots

Explore the mobile interfaces, inventory operations, billing functionality, and real-time vehicle parts management workflow.

## Application and Inventory Interface

<p align="center">
  <img src="https://github.com/user-attachments/assets/99e26fd4-af9a-40c7-baa6-ba4c3c89fe99" alt="Vehicle Inventory Application Interface" width="28%" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/082c2b4e-ff73-4572-ac81-d3d75eb2d770" alt="Vehicle Parts Inventory Interface" width="28%" />
</p>

## Inventory and Billing Management

<p align="center">
  <img src="https://github.com/user-attachments/assets/6b17dd94-bc28-49ee-880f-117c5c21596d" alt="Inventory Management Interface" width="28%" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/fc45c61c-fc86-448b-9631-6431385845b0" alt="Vehicle Parts Billing Interface" width="28%" />
</p>

## Orders and Delivery Tracking

<p align="center">
  <img src="https://github.com/user-attachments/assets/8fc270d0-3fd0-4d96-bcee-04c2a19c5511" alt="Customer Order Management Interface" width="28%" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/a145d621-be33-42f7-9621-814a2119cae7" alt="Live Delivery Tracking Interface" width="28%" />
</p>

---

# Technology Stack

## Mobile Application

* Flutter
* Dart

## Backend Services

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Services

## Additional Integrations

* Google Maps API
* QR Code Scanner
* Real-Time GPS Tracking

---

# Application Architecture

The application follows a structured mobile and cloud-based architecture.

```text
Flutter Mobile Application
          ↓
Application Services
          ↓
Firebase Cloud Services
          ↓
Cloud Firestore
```

Real-time Firebase synchronization allows inventory, orders, and delivery information to remain updated across the application.

---

# Getting Started

## Requirements

Before running this project, install:

* Flutter SDK 3.x
* Android Studio
* Android Emulator or Physical Device
* Firebase Account
* Git

Verify Flutter installation:

```bash
flutter doctor
```

---

# Clone the Repository

Clone the project using Git:

```bash
git clone https://github.com/Zynox-Tech/Vehicle_Inventory_App.git
```

Navigate into the project:

```bash
cd Vehicle_Inventory_App
```

Install project dependencies:

```bash
flutter pub get
```

---

# Firebase Setup

## 1. Create a Firebase Project

Create a new project using the Firebase Console:

```text
https://console.firebase.google.com
```

---

## 2. Configure the Android Application

Add an Android application using the package name:

```text
com.example.parts
```

Download:

```text
google-services.json
```

Place the file inside:

```text
android/app/
```

---

## 3. Enable Firebase Services

Enable the following Firebase services:

* Firebase Authentication
* Email and Password Authentication
* Cloud Firestore Database

---

## 4. Configure Google Maps

Enable the **Google Maps SDK for Android**.

Update:

```text
android/app/src/main/res/values/google_maps_api.xml
```

Add your Google Maps API key to the configuration.

> Do not commit private API keys or sensitive Firebase credentials to a public repository.

---

# Run the Application

Start the Flutter application:

```bash
flutter run
```

The application can run on:

* Android Emulator
* Physical Android Device

Ensure that the device is detected by Flutter before running the application.

Check connected devices using:

```bash
flutter devices
```

---

# Application Workflow

## Customer Flow

```text
Register Account
       ↓
Browse Vehicle Parts
       ↓
Place Order
       ↓
Track Order Status
       ↓
Monitor Live Delivery
```

Customers can browse available parts, create orders, and monitor delivery progress through the mobile application.

---

## Staff Flow

```text
Staff Login
     ↓
Manage Inventory
     ↓
Process Orders
     ↓
Generate Bills
     ↓
Manage Deliveries
```

Staff members can manage vehicle parts inventory, process customer orders, generate bills, and manage delivery operations.

---

# Project Structure

```text
Vehicle_Inventory_App/

├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   ├── services/
│   ├── firebase/
│   └── main.dart
│
├── android/
│
├── ios/
│
├── assets/
│
├── pubspec.yaml
│
└── README.md
```

---

# Firestore Database Structure

The application uses Cloud Firestore to maintain users, vehicle parts, sales, orders, and delivery information.

## Users Collection

```text
users/{uid}

{
  email,
  role,
  createdAt
}
```

---

## Parts Collection

```text
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

## Sales Collection

```text
sales/{saleId}

{
  partIds,
  total,
  createdAt
}
```

---

## Orders Collection

```text
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

## Delivery Sessions Collection

```text
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

# Real-Time Data Management

Firebase provides real-time synchronization for application data.

This allows the system to maintain updated information for:

* Inventory quantities
* Customer orders
* Order status
* Delivery sessions
* Staff activities

Changes stored in Cloud Firestore can be reflected across connected application sessions.

---

# QR-Based Billing

The application supports QR-based vehicle part identification.

The billing workflow includes:

```text
Scan Part QR Code
        ↓
Identify Vehicle Part
        ↓
Add Part to Cart
        ↓
Calculate Bill
        ↓
Record Sale
```

This workflow helps simplify product identification and billing operations.

---

# Delivery Tracking

The delivery module provides real-time order and delivery monitoring.

The system can manage:

* Staff location
* Customer destination
* Delivery distance
* Estimated arrival time
* Delivery status

Google Maps integration provides map-based delivery visualization.

---

# Troubleshooting

## Firebase Connection Issues

Check that:

* `google-services.json` exists
* Firebase project configuration is correct
* The Android package name matches Firebase configuration
* Firebase Authentication is enabled
* Cloud Firestore is configured

Run:

```bash
flutter clean
flutter pub get
```

Then restart the application.

---

## Flutter Build Issues

Update Flutter packages:

```bash
flutter pub upgrade
```

Check the Flutter environment:

```bash
flutter doctor
```

Resolve any reported Android SDK or development environment issues.

---

# Security Considerations

Production deployments should consider:

* Secure Firebase Security Rules
* Role-based Firestore access
* API key restrictions
* Secure authentication flows
* Input validation
* Location permission management
* Protection of sensitive configuration files

Firebase and Google Maps configuration files should be managed carefully when maintaining public repositories.

---

# Future Improvements

Planned improvements include:

* Firebase Storage for product images
* Push notifications
* Advanced admin dashboard
* Offline mode support
* AI-based inventory forecasting
* Automated stock recommendations
* Background location tracking
* Advanced sales analytics
* PDF invoice generation
* Multi-branch inventory management

---

# License

This project is developed for educational and commercial software demonstration purposes.

Review the repository licensing terms before redistribution or commercial reuse.

---

# About Zynox Tech

Zynox Tech develops modern and scalable digital solutions for businesses and organizations.

Our services include:

* Mobile Applications
* Web Applications
* Enterprise Software
* Artificial Intelligence Solutions
* Custom Business Automation
* Digital Product Development

We focus on building reliable and user-centered technology solutions that help organizations improve their digital operations.

For custom software solutions and technology partnerships:

**Website:** https://zynoxtech.site
**Email:** [hello@zynoxtech.site](mailto:hello@zynoxtech.site)
**Location:** Abbottabad, Pakistan

---

<div align="center">

### Developed by **Zynox Tech**

**Building Modern Technology Solutions for Businesses and Organizations**

</div>
