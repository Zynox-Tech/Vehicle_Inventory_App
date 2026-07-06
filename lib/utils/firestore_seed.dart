import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds Firestore with sample documents for collections used by the app.
/// This helper is safe to run in debug mode and skips documents that already exist.
Future<void> seedFirestoreCollections() async {
  final firestore = FirebaseFirestore.instance;

  await _ensureDocument(
    firestore.collection('users').doc('sample-user'),
    {
      'email': 'sample@parts.com',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    },
  );

  await _ensureDocument(
    firestore.collection('parts').doc('sample-part'),
    {
      'name': 'Sample Part',
      'category': 'General',
      'price': 1000.0,
      'quantity': 10,
      'lowStockThreshold': 3,
      'qrData': 'sample-part',
    },
  );

  await _ensureDocument(
    firestore.collection('orders').doc('sample-order'),
    {
      'userId': 'sample-user',
      'items': [
        {
          'partId': 'sample-part',
          'name': 'Sample Part',
          'price': 1000.0,
          'quantity': 1,
        },
      ],
      'total': 1000.0,
      'paymentMethod': 'cashOnDelivery',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'customerName': 'Sample Customer',
      'customerPhone': '+923001234567',
      'customerAddress': 'Sample Address',
    },
  );

  await _ensureDocument(
    firestore.collection('invoices').doc('sample-invoice'),
    {
      'invoiceNumber': 'INV-SAMPLE-001',
      'generatedAt': FieldValue.serverTimestamp(),
      'companyName': 'Parts Inventory',
      'companyPhone': '+92 300 1234567',
      'companyAddress': 'Karachi, Pakistan',
      'order': {
        'userId': 'sample-user',
        'items': [
          {
            'partId': 'sample-part',
            'name': 'Sample Part',
            'price': 1000.0,
            'quantity': 1,
          },
        ],
        'total': 1000.0,
        'paymentMethod': 'cashOnDelivery',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
    },
  );

  await _ensureDocument(
    firestore.collection('sales').doc('sample-sale'),
    {
      'total': 1000.0,
      'createdAt': FieldValue.serverTimestamp(),
    },
  );

  await _ensureDocument(
    firestore.collection('delivery_sessions').doc('sample-delivery-session'),
    {
      'orderId': 'sample-order',
      'customerId': 'sample-user',
      'staffId': 'sample-staff',
      'staffLabel': 'Sample Staff',
      'customerAddress': 'Sample Address',
      'destinationLatitude': 24.8607,
      'destinationLongitude': 67.0011,
      'staffLatitude': 24.8607,
      'staffLongitude': 67.0011,
      'distanceMeters': 0.0,
      'etaMinutes': 0.0,
      'isActive': false,
      'status': 'sample',
      'startedAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    },
  );
}

Future<void> _ensureDocument(
  DocumentReference<Map<String, Object?>> docRef,
  Map<String, Object?> data,
) async {
  final snapshot = await docRef.get();
  if (!snapshot.exists) {
    await docRef.set(data);
  }
}
