import 'package:flutter/material.dart';
import '../../models/part.dart';
import '../../services/cart_service.dart';
import '../checkout/checkout_screen.dart';

class PartDetailScreen extends StatefulWidget {
  final Part part;
  const PartDetailScreen({super.key, required this.part});

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  final CartService _cart = CartService();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _cart.load();
  }

  Future<void> _addToCart() async {
    await _cart.add(widget.part.id, qty: _qty);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${widget.part.name} x$_qty to cart')),
    );
  }

  Future<void> _buyNow() async {
    if (widget.part.quantity <= 0) return;
    
    // Calculate total for this single item
    final total = widget.part.price * _qty;
    
    // Navigate to payment method screen with total
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(total: total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.part;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(
                          p.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: Colors.white10,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.orange)),
                          ),
                        )
                      : Container(
                          color: Colors.white10,
                          child: Center(
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: p.isLowStock ? Colors.redAccent : Colors.orange,
                              child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(p.category),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Rs ${p.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(p.quantity > 0 ? Icons.check_circle : Icons.cancel, color: p.quantity > 0 ? Colors.greenAccent : Colors.redAccent),
                  const SizedBox(width: 6),
                  Text(p.quantity > 0 ? 'In stock (${p.quantity})' : 'Out of stock'),
                  const SizedBox(width: 12),
                  if (p.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.redAccent, size: 16),
                          SizedBox(width: 4),
                          Text('Low stock', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Quantity'),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          onPressed: () => setState(() => _qty++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                      ),
                      onPressed: p.quantity > 0 ? _addToCart : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: p.quantity > 0 ? _buyNow : null,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Buy Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
