import 'package:intl/intl.dart';
import '../models/order.dart';

class Invoice {
  final String invoiceNumber;
  final Order order;
  final DateTime generatedAt;
  final String? companyName;
  final String? companyPhone;
  final String? companyAddress;

  Invoice({
    required this.invoiceNumber,
    required this.order,
    required this.generatedAt,
    this.companyName = 'Parts Inventory',
    this.companyPhone = '+92 300 1234567',
    this.companyAddress = 'Karachi, Pakistan',
  });

  String getFormattedDate(DateTime date) {
    return DateFormat('dd MMM yyyy - hh:mm a').format(date);
  }

  String getFormattedCurrency(double amount) {
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  String getStatusBadge() {
    switch (order.status) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.dispatched:
        return 'DISPATCHED';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String getPaymentMethodText() {
    return order.paymentMethod == PaymentMethod.cashOnDelivery
        ? 'Cash on Delivery (COD)'
        : 'Online Payment';
  }

  double get subtotal => order.items.fold(0, (sum, item) => sum + item.subtotal);
  
  double get tax => subtotal * 0.0; // Can be modified if needed
  
  double get total => subtotal + tax;

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'order': order.toMap(),
      'generatedAt': generatedAt,
      'companyName': companyName,
      'companyPhone': companyPhone,
      'companyAddress': companyAddress,
    };
  }
}
