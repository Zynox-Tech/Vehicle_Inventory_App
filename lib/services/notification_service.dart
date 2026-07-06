import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../models/part.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  static const String _channelId = 'parts_inventory_alerts';
  static const String _channelName = 'Parts Inventory Alerts';
  static const String _channelDescription = 'Local alerts for stock, orders, and payments.';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  SharedPreferences? _prefs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _partsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _staffOrdersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customerOrdersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customerDeliverySubscription;

  String? _userId;
  String? _role;
  bool _initialized = false;
  bool _partsPrimed = false;
  bool _staffOrdersPrimed = false;
  bool _customerOrdersPrimed = false;
  bool _customerDeliveryPrimed = false;

  final Map<String, String> _lastLowStockSignatures = <String, String>{};
  final Map<String, OrderStatus> _lastCustomerOrderStatuses = <String, OrderStatus>{};
  final Set<String> _seenStaffOrderIds = <String>{};
  final Set<String> _notifiedNearbyDeliveries = <String>{};

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _notifications.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> updateSession({required String? userId, required String? role}) async {
    await initialize();

    if (_userId == userId && _role == role) return;

    await _stopListeners();
    _userId = userId;
    _role = role;

    if (userId == null || role == null) return;

    if (role == 'staff') {
      await _startStaffListeners();
    } else if (role == 'customer') {
      await _startCustomerListeners(userId);
    }
  }

  Future<void> notifyPaymentSuccessful({
    required String referenceId,
    required double amount,
  }) async {
    await initialize();

    final key = 'payment_success:$referenceId';
    if (!await _shouldSendPersistent(key)) return;

    await _showNotification(
      id: _notificationId(key),
      title: 'Payment successful',
      body: 'Your payment of ${amount.toStringAsFixed(2)} was completed successfully.',
      payload: referenceId,
    );
  }

  Future<void> dispose() async {
    await _stopListeners();
    _initialized = false;
  }

  Future<void> _startStaffListeners() async {
    _partsPrimed = false;
    _staffOrdersPrimed = false;
    _seenStaffOrderIds.clear();
    _lastLowStockSignatures.clear();

    _partsSubscription = _firestore.collection('parts').snapshots().listen(
          _handlePartsSnapshot,
          onError: _handleListenerError,
        );
    _staffOrdersSubscription = _firestore.collection('orders').snapshots().listen(
          _handleStaffOrdersSnapshot,
          onError: _handleListenerError,
        );
  }

  Future<void> _startCustomerListeners(String userId) async {
    _customerOrdersPrimed = false;
    _customerDeliveryPrimed = false;
    _lastCustomerOrderStatuses.clear();
    _notifiedNearbyDeliveries.clear();

    _customerOrdersSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          _handleCustomerOrdersSnapshot,
          onError: _handleListenerError,
        );

    _customerDeliverySubscription = _firestore
        .collection('delivery_sessions')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .listen(
          _handleCustomerDeliverySnapshot,
          onError: _handleListenerError,
        );
  }

  Future<void> _stopListeners() async {
    await _partsSubscription?.cancel();
    await _staffOrdersSubscription?.cancel();
    await _customerOrdersSubscription?.cancel();
    await _customerDeliverySubscription?.cancel();
    _partsSubscription = null;
    _staffOrdersSubscription = null;
    _customerOrdersSubscription = null;
    _customerDeliverySubscription = null;
    _partsPrimed = false;
    _staffOrdersPrimed = false;
    _customerOrdersPrimed = false;
    _customerDeliveryPrimed = false;
  }

  void _handlePartsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_partsPrimed) {
      for (final doc in snapshot.docs) {
        final part = Part.fromDoc(doc);
        if (part.isLowStock) {
          _lastLowStockSignatures[part.id] = _lowStockSignature(part);
        }
      }
      _partsPrimed = true;
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.doc.metadata.hasPendingWrites) continue;

      final part = Part.fromDoc(change.doc);
      if (change.type == DocumentChangeType.removed) {
        _lastLowStockSignatures.remove(part.id);
        continue;
      }

      if (!part.isLowStock) {
        _lastLowStockSignatures.remove(part.id);
        continue;
      }

      final signature = _lowStockSignature(part);
      final previousSignature = _lastLowStockSignatures[part.id];
      if (previousSignature == signature) continue;

      _lastLowStockSignatures[part.id] = signature;
      unawaited(_showNotification(
        id: _notificationId('low_stock:${part.id}:$signature'),
        title: 'Low stock alert',
        body: '${part.name} is low on stock: ${part.quantity} left, threshold ${part.lowStockThreshold}.',
        payload: part.id,
      ));
    }
  }

  void _handleStaffOrdersSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_staffOrdersPrimed) {
      for (final doc in snapshot.docs) {
        _seenStaffOrderIds.add(doc.id);
      }
      _staffOrdersPrimed = true;
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.doc.metadata.hasPendingWrites || change.type != DocumentChangeType.added) continue;
      if (_seenStaffOrderIds.contains(change.doc.id)) continue;

      _seenStaffOrderIds.add(change.doc.id);
      final order = Order.fromDoc(change.doc);
      unawaited(_showNotification(
        id: _notificationId('new_order:${order.id}'),
        title: 'New order received',
        body: '${order.customerName ?? 'A customer'} placed order #${order.id.substring(0, 8).toUpperCase()}.',
        payload: order.id,
      ));
    }
  }

  void _handleCustomerOrdersSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_customerOrdersPrimed) {
      for (final doc in snapshot.docs) {
        final order = Order.fromDoc(doc);
        _lastCustomerOrderStatuses[order.id] = order.status;
      }
      _customerOrdersPrimed = true;
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.doc.metadata.hasPendingWrites) continue;

      final order = Order.fromDoc(change.doc);
      if (change.type == DocumentChangeType.removed) {
        _lastCustomerOrderStatuses.remove(order.id);
        continue;
      }

      final previousStatus = _lastCustomerOrderStatuses[order.id];
      _lastCustomerOrderStatuses[order.id] = order.status;
      if (previousStatus == null) continue;

      if (_isNotifiableTransition(previousStatus, order.status)) {
        final title = order.status == OrderStatus.confirmed
            ? 'Order confirmed'
            : order.status == OrderStatus.dispatched
                ? 'Delivery started'
                : 'Order delivered';
        final body = order.status == OrderStatus.confirmed
            ? 'Your order #${order.id.substring(0, 8).toUpperCase()} has been confirmed.'
            : order.status == OrderStatus.dispatched
                ? 'Your order #${order.id.substring(0, 8).toUpperCase()} is now out for delivery.'
                : 'Your order #${order.id.substring(0, 8).toUpperCase()} has been delivered.';

        unawaited(_showNotification(
          id: _notificationId('order_status:${order.id}:${order.status.name}'),
          title: title,
          body: body,
          payload: order.id,
        ));
      }

      _maybeNotifyDeliveryReminder(order, previousStatus);
    }
  }

  void _handleCustomerDeliverySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_customerDeliveryPrimed) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if ((data['isActive'] as bool?) ?? false) {
          final distance = (data['distanceMeters'] as num?)?.toDouble();
          if (distance != null && distance <= 500) {
            _notifiedNearbyDeliveries.add(doc.id);
          }
        }
      }
      _customerDeliveryPrimed = true;
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.doc.metadata.hasPendingWrites) continue;

      final data = change.doc.data();
      if (data == null) continue;

      final isActive = data['isActive'] as bool? ?? false;
      final distance = (data['distanceMeters'] as num?)?.toDouble();

      if (!isActive) {
        _notifiedNearbyDeliveries.remove(change.doc.id);
        continue;
      }

      if (distance == null || distance > 500 || _notifiedNearbyDeliveries.contains(change.doc.id)) continue;

      _notifiedNearbyDeliveries.add(change.doc.id);
      unawaited(_showNotification(
        id: _notificationId('delivery_nearby:${change.doc.id}'),
        title: 'Driver nearby',
        body: 'Your delivery for order #${change.doc.id.substring(0, 8).toUpperCase()} is nearby.',
        payload: change.doc.id,
      ));
    }
  }

  void _handleListenerError(Object error, StackTrace stackTrace) {
    if (_isPermissionDeniedError(error)) {
      debugPrint('NotificationService listener skipped due to missing Firestore permission: $error');
      return;
    }

    debugPrint('NotificationService listener error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  bool _isPermissionDeniedError(Object error) {
    return (error is FirebaseException && error.code == 'permission-denied') ||
        error.toString().contains('permission-denied') ||
        error.toString().contains('permission denied');
  }

  void _maybeNotifyDeliveryReminder(Order order, OrderStatus previousStatus) {
    final expectedDeliveryAt = order.expectedDeliveryAt;
    if (expectedDeliveryAt == null) return;
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) return;

    final key = 'order_eta:${order.id}:${expectedDeliveryAt.toIso8601String()}';
    if (previousStatus == order.status) return;

    unawaited(_showUniquePersistentNotification(
      key: key,
      title: 'Delivery reminder',
      body: 'Order #${order.id.substring(0, 8).toUpperCase()} is expected around ${_formatTimestamp(expectedDeliveryAt)}.',
      payload: order.id,
    ));
  }

  bool _isNotifiableTransition(OrderStatus previousStatus, OrderStatus currentStatus) {
    return previousStatus == OrderStatus.pending && currentStatus == OrderStatus.confirmed ||
        previousStatus == OrderStatus.confirmed && currentStatus == OrderStatus.dispatched ||
        previousStatus == OrderStatus.dispatched && currentStatus == OrderStatus.delivered;
  }

  Future<void> _showUniquePersistentNotification({
    required String key,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await _shouldSendPersistent(key)) return;

    await _showNotification(
      id: _notificationId(key),
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<bool> _shouldSendPersistent(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final marker = prefs.getString(key);
    if (marker == key) return false;
    await prefs.setString(key, key);
    return true;
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  int _notificationId(String value) {
    return value.hashCode & 0x7fffffff;
  }

  String _lowStockSignature(Part part) {
    return '${part.quantity}:${part.lowStockThreshold}';
  }

  String _formatTimestamp(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
