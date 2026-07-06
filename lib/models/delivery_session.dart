import 'package:cloud_firestore/cloud_firestore.dart';

class DeliverySession {
  final String orderId;
  final String? customerId;
  final String? staffId;
  final String? staffLabel;
  final String? customerAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? staffLatitude;
  final double? staffLongitude;
  final double? staffAccuracy;
  final double? staffSpeed;
  final double? staffHeading;
  final double? distanceMeters;
  final double? etaMinutes;
  final bool isActive;
  final String status;
  final DateTime? startedAt;
  final DateTime? lastUpdatedAt;
  final DateTime? completedAt;

  const DeliverySession({
    required this.orderId,
    this.customerId,
    this.staffId,
    this.staffLabel,
    this.customerAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.staffLatitude,
    this.staffLongitude,
    this.staffAccuracy,
    this.staffSpeed,
    this.staffHeading,
    this.distanceMeters,
    this.etaMinutes,
    this.isActive = false,
    this.status = 'idle',
    this.startedAt,
    this.lastUpdatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'staffId': staffId,
      'staffLabel': staffLabel,
      'customerAddress': customerAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'staffLatitude': staffLatitude,
      'staffLongitude': staffLongitude,
      'staffAccuracy': staffAccuracy,
      'staffSpeed': staffSpeed,
      'staffHeading': staffHeading,
      'distanceMeters': distanceMeters,
      'etaMinutes': etaMinutes,
      'isActive': isActive,
      'status': status,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'lastUpdatedAt': lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory DeliverySession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return DeliverySession(orderId: doc.id);
    }

    return DeliverySession(
      orderId: (data['orderId'] as String?) ?? doc.id,
      customerId: data['customerId'] as String?,
      staffId: data['staffId'] as String?,
      staffLabel: data['staffLabel'] as String?,
      customerAddress: data['customerAddress'] as String?,
      destinationLatitude: (data['destinationLatitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destinationLongitude'] as num?)?.toDouble(),
      staffLatitude: (data['staffLatitude'] as num?)?.toDouble(),
      staffLongitude: (data['staffLongitude'] as num?)?.toDouble(),
      staffAccuracy: (data['staffAccuracy'] as num?)?.toDouble(),
      staffSpeed: (data['staffSpeed'] as num?)?.toDouble(),
      staffHeading: (data['staffHeading'] as num?)?.toDouble(),
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble(),
      etaMinutes: (data['etaMinutes'] as num?)?.toDouble(),
      isActive: data['isActive'] as bool? ?? false,
      status: data['status'] as String? ?? 'idle',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}