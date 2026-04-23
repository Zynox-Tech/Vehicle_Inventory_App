import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';
import '../../models/part.dart';
import 'part_edit_screen.dart';
import 'part_detail_screen.dart';
import 'qr_label_screen.dart';

class PartsListScreen extends StatefulWidget {
  static const routeName = '/parts';
  final bool readOnly;
  const PartsListScreen({super.key, this.readOnly = false});

  @override
  State<PartsListScreen> createState() => _PartsListScreenState();
}

class _PartsListScreenState extends State<PartsListScreen> {
  String _query = '';
  String _categoryFilter = 'All';
  RangeValues _priceRange = const RangeValues(0, 20000);
  // Removed local cart; using persistent CartService
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
  // CartService now auto-loads per current user; keep explicit load for safety.
  _cartService.load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isStaff = auth.role == 'staff' && !widget.readOnly;
    final isCustomerView = widget.readOnly || auth.role == 'customer';
    return Scaffold(
      appBar: AppBar(
        title: Text(isCustomerView ? 'Browse Parts' : 'Parts Inventory'),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'Add Part',
              icon: const Icon(Icons.add_box),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartEditScreen(),
                  ),
                );
              },
            ),
          if (isCustomerView)
            AnimatedBuilder(
              animation: _cartService,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      tooltip: 'Cart',
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () => Navigator.pushNamed(context, CartScreen.routeName),
                    ),
                    if (_cartService.totalItems > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Text(
                          '${_cartService.totalItems}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartEditScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Part'),
            )
          : null,
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search parts...'),
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _categoryFilter,
                  dropdownColor: Colors.black,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Engine', child: Text('Engine')),
                    DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                    DropdownMenuItem(value: 'Body', child: Text('Body')),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Range'),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 20000,
                  divisions: 200,
                  labels: RangeLabels(
                    _priceRange.start.toStringAsFixed(0),
                    _priceRange.end.toStringAsFixed(0),
                  ),
                  onChanged: (v) => setState(() => _priceRange = v),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('parts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No parts'));
                }
                final docs = snapshot.data!.docs;
                final parts = docs.map((d) => Part.fromDoc(d)).where((p) {
                  final matchQuery = p.name.toLowerCase().contains(_query);
                  final matchCat = _categoryFilter == 'All' || p.category == _categoryFilter;
                  final matchPrice = p.price >= _priceRange.start && p.price <= _priceRange.end;
                  return matchQuery && matchCat && matchPrice;
                }).toList();
                if (parts.isEmpty) return const Center(child: Text('No matching parts'));

                if (isCustomerView) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = 2;
                      if (width >= 1400) {
                        crossAxisCount = 5;
                      } else if (width >= 1100) {
                        crossAxisCount = 4;
                      } else if (width >= 800) {
                        crossAxisCount = 3;
                      }
            return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
              // Make cards taller to avoid vertical overflow
              childAspectRatio: 0.55,
                        ),
                        itemCount: parts.length,
                        itemBuilder: (context, i) {
                          final part = parts[i];
                          return _PartCard(
                            part: part,
                            onAddToCart: () async {
                              await _cartService.add(part.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added ${part.name} to cart')),
                                );
                              }
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PartDetailScreen(part: part),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                }

                // Staff list view
                return ListView.builder(
                  itemCount: parts.length,
                  itemBuilder: (context, i) {
                    final part = parts[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: part.isLowStock ? Colors.redAccent : Colors.white12,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: isStaff
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartEditScreen(existing: part),
                                  ),
                                )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: part.imageUrl != null && part.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          part.imageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: Colors.white10,
                                              child: const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stack) => Container(
                                            color: Colors.white10,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: Colors.orange),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white10,
                                          child: Center(
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  part.isLowStock ? Colors.redAccent : Colors.orange,
                                              child: Text(part.name.isNotEmpty ? part.name[0].toUpperCase() : '?'),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            part.name,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (part.isLowStock)
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
                                    const SizedBox(height: 4),
                                    Text(part.category, style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _InfoChip(label: 'Qty', value: '${part.quantity}'),
                                        _InfoChip(label: 'Price', value: 'Rs ${part.price.toStringAsFixed(0)}'),
                                        _InfoChip(label: 'Threshold', value: '${part.lowStockThreshold}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                tooltip: 'Actions',
                                icon: const Icon(Icons.more_vert),
                                elevation: 8,
                                color: Colors.grey[900],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PartEditScreen(existing: part)),
                                    );
                                  } else if (v == 'qr') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QrLabelScreen(partId: part.id, name: part.name),
                                      ),
                                    );
                                  } else if (v == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete part'),
                                        content: Text('Are you sure you want to delete "${part.name}"? This cannot be undone.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              try {
                                                await FirebaseFirestore.instance.collection('parts').doc(part.id).delete();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${part.name}')));
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                                }
                                              }
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [Icon(Icons.edit, color: Colors.orange), SizedBox(width: 12), Text('Edit')]),
                                  ),
                                  PopupMenuItem(
                                    value: 'qr',
                                    child: Row(children: [Icon(Icons.qr_code_2, color: Colors.lightBlueAccent), SizedBox(width: 12), Text('QR Label')]),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [Icon(Icons.delete, color: Colors.redAccent), SizedBox(width: 12), Text('Delete')]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PartCard extends StatefulWidget {
  final Part part;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;
  const _PartCard({required this.part, required this.onAddToCart, this.onTap});

  @override
  State<_PartCard> createState() => _PartCardState();
}

class _PartCardState extends State<_PartCard> {
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    return Material(
      color: Colors.transparent,
      child: InkWell(
  onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: part.isLowStock ? Colors.redAccent : Colors.white12,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Image area with badges (50% height)
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SizedBox.expand(
                        child: part.imageUrl != null && part.imageUrl!.isNotEmpty
                            ? Image.network(
                                part.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.white10,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stack) => Container(
                                  color: Colors.white10,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.orange),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.white10,
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor:
                                        part.isLowStock ? Colors.redAccent : Colors.orange,
                                    child: Text(part.name.isNotEmpty ? part.name[0].toUpperCase() : '?'),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: part.isLowStock
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Low stock', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => setState(() => _fav = !_fav),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(_fav ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content (50% height)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        part.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(part.category, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('Rs ${part.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 6),
                          if (part.quantity > 0)
                            const Text('In stock', style: TextStyle(color: Colors.greenAccent, fontSize: 12))
                          else
                            const Text('Out of stock', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Add to cart',
                            onPressed: part.quantity > 0 ? widget.onAddToCart : null,
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'View QR',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrLabelScreen(partId: part.id, name: part.name),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_2, color: Colors.lightBlueAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
