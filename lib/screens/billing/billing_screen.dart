import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/part.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../payment/invoice_screen.dart';
import 'qr_scanner_screen.dart';

class BillingScreen extends StatefulWidget {
  static const routeName = '/billing';
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final Map<String, Map<String, dynamic>> _cart = {}; // id -> {part, qty}

  double get total => _cart.values.fold(0.0, (p, m) => p + (m['part'] as Part).price * (m['qty'] as int));

  Future<void> _scan() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (code == null || code.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('parts').doc(code).get();
    if (!doc.exists) return;
    final part = Part.fromDoc(doc);
    setState(() {
      final current = _cart[part.id];
      if (current == null) {
        _cart[part.id] = {'part': part, 'qty': 1};
      } else {
        _cart[part.id]!['qty'] = (current['qty'] as int) + 1;
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    if (context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Create order items
        final orderItems = <OrderItem>[];
        for (final m in _cart.values) {
          final p = m['part'] as Part;
          final q = m['qty'] as int;
          orderItems.add(
            OrderItem(
              partId: p.id,
              name: p.name,
              price: p.price,
              quantity: q,
            ),
          );
        }

        // Create order with default payment method
        final orderService = OrderService();
        final orderId = await orderService.createOrder(
          items: orderItems,
          total: total,
          paymentMethod: PaymentMethod.cashOnDelivery,
          customerName: 'Staff Sale',
          notes: 'Order from billing (staff)',
        );

        // Update stock
        final batch = FirebaseFirestore.instance.batch();
        for (final m in _cart.values) {
          final p = m['part'] as Part;
          final q = m['qty'] as int;
          final ref = FirebaseFirestore.instance.collection('parts').doc(p.id);
          batch.update(ref, {'quantity': p.quantity - q});
        }
        await batch.commit();

        setState(() { _cart.clear(); });

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);

          // Show invoice directly
          final invoice = await orderService.getInvoice(orderId);
          if (invoice != null && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceScreen(invoice: invoice),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating order: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Tip: Generate a QR label from Inventory (⋮ > QR Label). Scanning adds item(s) to the cart.'),
          ),
          // Place the scanner action above the checkout bar to avoid overlapping the button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _cart.values.map((m) {
                final p = m['part'] as Part;
                final q = m['qty'] as int;
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('Rs ${p.price.toStringAsFixed(2)} x $q = Rs ${(p.price*q).toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.orange), onPressed: () {
                        setState(() { if (q>1) m['qty']=q-1; else _cart.remove(p.id); });
                      }),
                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.orange), onPressed: () {
                        setState(() { m['qty']=q+1; });
                      }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                        setState(() { _cart.remove(p.id); });
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.black54),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: Rs ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: _checkout, child: const Text('Checkout'))
              ],
            ),
          )
        ],
      ),
    );
  }
}
