import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String partId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.partId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      partId: data['partId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 0,
    );
  }
}

enum PaymentMethod { cashOnDelivery, online }

enum OrderStatus { pending, confirmed, dispatched, delivered, cancelled }

class Order {
  final String id;
  final String? userId;
  final List<OrderItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final DateTime? expectedDeliveryAt;
  final String? deliverySessionId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final double? customerLatitude;
  final double? customerLongitude;
  final String? paymentTransactionId;
  final String? notes;

  Order({
    required this.id,
    this.userId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.confirmedAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.expectedDeliveryAt,
    this.deliverySessionId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerLatitude,
    this.customerLongitude,
    this.paymentTransactionId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'dispatchedAt': dispatchedAt != null ? Timestamp.fromDate(dispatchedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'expectedDeliveryAt': expectedDeliveryAt != null ? Timestamp.fromDate(expectedDeliveryAt!) : null,
      'deliverySessionId': deliverySessionId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerLatitude': customerLatitude,
      'customerLongitude': customerLongitude,
      'paymentTransactionId': paymentTransactionId,
      'notes': notes,
    };
  }

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Order(
      id: doc.id,
      userId: data['userId'] as String?,
      items: List<OrderItem>.from(
        (data['items'] as List<dynamic>?)?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)) ?? [],
      ),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] == 'online' ? PaymentMethod.online : PaymentMethod.cashOnDelivery,
      status: _stringToOrderStatus(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      dispatchedAt: (data['dispatchedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      expectedDeliveryAt: (data['expectedDeliveryAt'] as Timestamp?)?.toDate(),
      deliverySessionId: data['deliverySessionId'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      customerAddress: data['customerAddress'] as String?,
      customerLatitude: (data['customerLatitude'] as num?)?.toDouble(),
      customerLongitude: (data['customerLongitude'] as num?)?.toDouble(),
      paymentTransactionId: data['paymentTransactionId'] as String?,
      notes: data['notes'] as String?,
    );
  }

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      userId: data['userId'] as String?,
      items: List<OrderItem>.from(
        (data['items'] as List<dynamic>?)?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)) ?? [],
      ),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] == 'online' ? PaymentMethod.online : PaymentMethod.cashOnDelivery,
      status: _stringToOrderStatus(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      dispatchedAt: (data['dispatchedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      expectedDeliveryAt: (data['expectedDeliveryAt'] as Timestamp?)?.toDate(),
      deliverySessionId: data['deliverySessionId'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      customerAddress: data['customerAddress'] as String?,
      customerLatitude: (data['customerLatitude'] as num?)?.toDouble(),
      customerLongitude: (data['customerLongitude'] as num?)?.toDouble(),
      paymentTransactionId: data['paymentTransactionId'] as String?,
      notes: data['notes'] as String?,
    );
  }

  static OrderStatus _stringToOrderStatus(String status) {
    switch (status) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'dispatched':
        return OrderStatus.dispatched;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
