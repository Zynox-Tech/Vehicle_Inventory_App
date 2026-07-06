import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/delivery_session.dart';
import '../models/order.dart' as order_models;
import 'order_service.dart';

class DeliveryTrackingService {
  DeliveryTrackingService._internal();

  static final DeliveryTrackingService instance = DeliveryTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrderService _orderService = OrderService();

  static const String _collection = 'delivery_sessions';

  StreamSubscription<Position>? _positionSubscription;
  String? _activeOrderId;
  DeliverySession? _activeSession;

  Stream<DeliverySession?> watchSession(String orderId) {
    return _firestore.collection(_collection).doc(orderId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return DeliverySession.fromDoc(doc);
    });
  }

  Future<DeliverySession> startDelivery({
    required order_models.Order order,
    required String staffId,
    required String staffLabel,
  }) async {
    await _ensureLocationPermissions();

    if (_activeOrderId != null && _activeOrderId != order.id) {
      await stopTracking();
    }

    final currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    final destination = order.customerLatitude != null && order.customerLongitude != null
        ? LocationPoint(order.customerLatitude!, order.customerLongitude!)
        : await _resolveDestination(order.customerAddress, currentPosition);

    final session = DeliverySession(
      orderId: order.id,
      customerId: order.userId,
      staffId: staffId,
      staffLabel: staffLabel,
      customerAddress: order.customerAddress,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
      staffLatitude: currentPosition.latitude,
      staffLongitude: currentPosition.longitude,
      staffAccuracy: currentPosition.accuracy,
      staffSpeed: currentPosition.speed,
      staffHeading: currentPosition.heading,
      distanceMeters: Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        destination.latitude,
        destination.longitude,
      ),
      etaMinutes: _estimateEtaMinutes(
        currentPosition.latitude,
        currentPosition.longitude,
        destination.latitude,
        destination.longitude,
        currentPosition.speed,
      ),
      isActive: true,
      status: 'active',
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );

    await _firestore.collection(_collection).doc(order.id).set(session.toMap(), SetOptions(merge: true));
    await _orderService.updateOrderStatus(order.id, order_models.OrderStatus.dispatched);
    await _firestore.collection('orders').doc(order.id).set({
      'deliverySessionId': order.id,
    }, SetOptions(merge: true));

    _activeOrderId = order.id;
    _activeSession = session;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 15,
      ),
    ).listen((position) {
      unawaited(_pushLocation(order.id, position));
    });

    return session;
  }

  Future<void> markDelivered(order_models.Order order) async {
    await stopTracking();
    await _firestore.collection(_collection).doc(order.id).set({
      'isActive': false,
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _orderService.updateOrderStatus(order.id, order_models.OrderStatus.delivered);
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeOrderId = null;
    _activeSession = null;
  }

  Future<void> _pushLocation(String orderId, Position position) async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    final destinationLatitude = session.destinationLatitude;
    final destinationLongitude = session.destinationLongitude;
    final distanceMeters = destinationLatitude != null && destinationLongitude != null
        ? Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destinationLatitude,
            destinationLongitude,
          )
        : null;

    final etaMinutes = distanceMeters != null
        ? _estimateEtaMinutes(
            position.latitude,
            position.longitude,
            destinationLatitude ?? position.latitude,
            destinationLongitude ?? position.longitude,
            position.speed,
          )
        : null;

    await _firestore.collection(_collection).doc(orderId).set({
      'staffLatitude': position.latitude,
      'staffLongitude': position.longitude,
      'staffAccuracy': position.accuracy,
      'staffSpeed': position.speed,
      'staffHeading': position.heading,
      'distanceMeters': distanceMeters,
      'etaMinutes': etaMinutes,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureLocationPermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required for delivery tracking.');
    }
  }

  Future<LocationPoint> _resolveDestination(String? address, Position fallbackPosition) async {
    if (address != null && address.trim().isNotEmpty) {
      try {
        final results = await locationFromAddress(address);
        if (results.isNotEmpty) {
          return LocationPoint(results.first.latitude, results.first.longitude);
        }
      } catch (_) {
        // Fall back to the live location when geocoding fails.
      }
    }

    return LocationPoint(fallbackPosition.latitude, fallbackPosition.longitude);
  }

  double? _estimateEtaMinutes(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    double speedMetersPerSecond,
  ) {
    final distanceMeters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
    final speed = speedMetersPerSecond > 1 ? speedMetersPerSecond : 10.0;
    return (distanceMeters / speed) / 60.0;
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;

  const LocationPoint(this.latitude, this.longitude);
}