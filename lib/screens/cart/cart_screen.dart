import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartService();

  @override
  void initState() {
    super.initState();
    cart.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          IconButton(
            tooltip: 'Clear cart',
            onPressed: cart.isEmpty ? null : () => cart.clear(),
            icon: const Icon(Icons.delete_outline),
          )
        ],
      ),
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          final entries = cart.items.entries.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == entries.length) {
                return _CartFooter(entries: entries, cart: cart);
              }
              final e = entries[index];
              return _CartItemTile(partId: e.key, qty: e.value, cart: cart);
            },
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final String partId;
  final int qty;
  final CartService cart;
  const _CartItemTile({required this.partId, required this.qty, required this.cart});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('parts').doc(partId).get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const ListTile(title: Text('Loading item...'));
        }
        final d = snap.data!;
        final data = d.data();
        if (data == null) {
          return ListTile(
            title: Text('Unknown item $partId'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => cart.remove(partId),
            ),
          );
        }
        final title = data['name'] as String? ?? 'Item';
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final imageUrl = data['imageUrl'] as String?;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Title + Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                      )
                    else
                      const Icon(Icons.settings, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quantity + Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity controls (compact)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: qty > 1 ? () => cart.setQuantity(partId, qty - 1) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: qty > 1 ? Colors.white : Colors.white38,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$qty',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          InkWell(
                            onTap: () => cart.setQuantity(partId, qty + 1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Remove button
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => cart.remove(partId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartFooter extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final CartService cart;
  const _CartFooter({required this.entries, required this.cart});

  @override
  Widget build(BuildContext context) {
  return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('parts')
          .where(FieldPath.documentId, whereIn: entries.map((e) => e.key).toList())
          .get(),
      builder: (context, snap) {
        double total = 0.0;
        if (snap.hasData) {
          final docs = snap.data!.docs;
          final byId = {for (final d in docs) d.id: d};
          for (final e in entries) {
            final d = byId[e.key];
            final price = d != null ? (d.data()['price'] as num?)?.toDouble() ?? 0.0 : 0.0;
            total += price * e.value;
          }
        }
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {
                  // Navigate to payment method screen
                  Navigator.of(context).pushNamed(
                    '/payment-method',
                    arguments: total,
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}
