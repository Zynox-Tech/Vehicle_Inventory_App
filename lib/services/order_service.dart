import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../models/invoice.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';
  static const String _invoicesCollection = 'invoices';

  /// Create a new order with payment method and customer details
  Future<String> createOrder({
    required List<OrderItem> items,
    required double total,
    required PaymentMethod paymentMethod,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? customerLatitude,
    double? customerLongitude,
    DateTime? expectedDeliveryAt,
    String? notes,
  }) async {
    try {
      final orderRef = _firestore.collection(_ordersCollection).doc();
      
      final order = Order(
        id: orderRef.id,
        userId: userId,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        expectedDeliveryAt: expectedDeliveryAt,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        customerLatitude: customerLatitude,
        customerLongitude: customerLongitude,
        notes: notes,
      );

      await orderRef.set(order.toMap());
      
      // Create invoice
      await _createInvoice(order);
      
      return order.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Create invoice for an order
  Future<void> _createInvoice(Order order) async {
    try {
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        order: order,
        generatedAt: DateTime.now(),
      );

      await _firestore.collection(_invoicesCollection).doc(order.id).set(invoice.toMap());
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  /// Get order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection(_ordersCollection).doc(orderId).get();
      if (!doc.exists) return null;
      return Order.fromDoc(doc);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Get invoice by order ID
  Future<Invoice?> getInvoice(String orderId) async {
    try {
      final orderDoc = await _firestore.collection(_ordersCollection).doc(orderId).get();
      if (!orderDoc.exists) return null;
      
      final order = Order.fromDoc(orderDoc);
      
      final invoiceDoc = await _firestore.collection(_invoicesCollection).doc(orderId).get();
      if (!invoiceDoc.exists) return null;

      final data = invoiceDoc.data();
      if (data == null) return null;

      return Invoice(
        invoiceNumber: data['invoiceNumber'] ?? 'INV-${orderId.substring(0, 8)}',
        order: order,
        generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        companyName: data['companyName'] as String?,
        companyPhone: data['companyPhone'] as String?,
        companyAddress: data['companyAddress'] as String?,
      );
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  /// Get all orders
  Stream<List<Order>> getOrders() {
    return _firestore
        .collection(_ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromDoc(doc))
              .toList();
        });
  }

  /// Get user-specific orders (without requiring composite index)
  Stream<List<Order>> getUserOrders(String userId) {
    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromDoc(doc))
              .toList();
          // Sort client-side to avoid composite index requirement
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get orders by payment method
  Stream<List<Order>> getOrdersByPaymentMethod(PaymentMethod paymentMethod) {
    final method = paymentMethod == PaymentMethod.cashOnDelivery ? 'cashOnDelivery' : 'online';
    return _firestore
        .collection(_ordersCollection)
        .where('paymentMethod', isEqualTo: method)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromDoc(doc))
              .toList();
        });
  }

  /// Get orders by status
  Stream<List<Order>> getOrdersByStatus(OrderStatus status) {
    final statusStr = status.toString().split('.').last;
    return _firestore
        .collection(_ordersCollection)
        .where('status', isEqualTo: statusStr)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromDoc(doc))
              .toList();
        });
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final orderRef = _firestore.collection(_ordersCollection).doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception('Order not found');
        }

        final currentOrder = Order.fromDoc(orderSnapshot);
        final currentStatus = currentOrder.status;

        // Only decrement inventory once when transitioning to confirmed.
        if (newStatus == OrderStatus.confirmed && currentStatus != OrderStatus.confirmed) {
          for (final item in currentOrder.items) {
            final partRef = _firestore.collection('parts').doc(item.partId);
            final partSnapshot = await transaction.get(partRef);
            if (!partSnapshot.exists) {
              throw Exception('Part ${item.partId} not found');
            }

            final partQuantity = (partSnapshot.data()?['quantity'] ?? 0) as int;
            if (partQuantity < item.quantity) {
              throw Exception('Insufficient stock for part ${item.partId}');
            }

            transaction.update(partRef, {
              'quantity': FieldValue.increment(-item.quantity),
            });
          }

          transaction.update(orderRef, {
            'status': newStatus.toString().split('.').last,
            'confirmedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final updateData = <String, dynamic>{
            'status': newStatus.toString().split('.').last,
          };

          if (newStatus == OrderStatus.dispatched) {
            updateData['dispatchedAt'] = FieldValue.serverTimestamp();
          } else if (newStatus == OrderStatus.delivered) {
            updateData['deliveredAt'] = FieldValue.serverTimestamp();
          }

          if (newStatus == OrderStatus.confirmed) {
            updateData['confirmedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(orderRef, updateData);
        }
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Stream<Order?> watchOrder(String orderId) {
    return _firestore.collection(_ordersCollection).doc(orderId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return Order.fromDoc(doc);
    });
  }

  /// Update order with payment transaction ID
  Future<void> updatePaymentTransaction(String orderId, String transactionId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'paymentTransactionId': transactionId,
      });
    } catch (e) {
      throw Exception('Failed to update payment transaction: $e');
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, OrderStatus.cancelled);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final totalOrders = await _firestore.collection(_ordersCollection).count().get();
      
      final pendingOrders = await _firestore
          .collection(_ordersCollection)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      
      final deliveredOrders = await _firestore
          .collection(_ordersCollection)
          .where('status', isEqualTo: 'delivered')
          .count()
          .get();

      final codOrders = await _firestore
          .collection(_ordersCollection)
          .where('paymentMethod', isEqualTo: 'cashOnDelivery')
          .count()
          .get();

      return {
        'totalOrders': totalOrders.count,
        'pendingOrders': pendingOrders.count,
        'deliveredOrders': deliveredOrders.count,
        'codOrders': codOrders.count,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }
}
