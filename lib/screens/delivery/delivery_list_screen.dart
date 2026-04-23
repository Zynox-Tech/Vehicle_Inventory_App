import 'package:flutter/material.dart';
import '../../models/order.dart' as order_models;
import '../../services/order_service.dart';

class DeliveryListScreen extends StatelessWidget {
  static const routeName = '/deliveries';
  const DeliveryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Management'),
        elevation: 0,
      ),
      body: StreamBuilder<List<order_models.Order>>(
        stream: orderService.getOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load deliveries: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders = snap.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders to deliver',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _DeliveryOrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _DeliveryOrderCard extends StatefulWidget {
  final order_models.Order order;

  const _DeliveryOrderCard({required this.order});

  @override
  State<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends State<_DeliveryOrderCard> {
  late order_models.OrderStatus _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  Future<void> _updateStatus(order_models.OrderStatus newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final orderService = OrderService();
      await orderService.updateOrderStatus(widget.order.id, newStatus);
      setState(() => _selectedStatus = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Delivery status updated'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _selectedStatus = widget.order.status);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _getStatusLabel(order_models.OrderStatus status) {
    switch (status) {
      case order_models.OrderStatus.pending:
        return 'Pending';
      case order_models.OrderStatus.confirmed:
        return 'Confirmed';
      case order_models.OrderStatus.dispatched:
        return 'Out for Delivery';
      case order_models.OrderStatus.delivered:
        return 'Delivered';
      case order_models.OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(order_models.OrderStatus status) {
    switch (status) {
      case order_models.OrderStatus.pending:
        return Colors.orangeAccent;
      case order_models.OrderStatus.confirmed:
        return Colors.blueAccent;
      case order_models.OrderStatus.dispatched:
        return Colors.purpleAccent;
      case order_models.OrderStatus.delivered:
        return Colors.greenAccent;
      case order_models.OrderStatus.cancelled:
        return Colors.redAccent;
    }
  }

  IconData _getStatusIcon(order_models.OrderStatus status) {
    switch (status) {
      case order_models.OrderStatus.pending:
        return Icons.schedule;
      case order_models.OrderStatus.confirmed:
        return Icons.check_circle;
      case order_models.OrderStatus.dispatched:
        return Icons.local_shipping;
      case order_models.OrderStatus.delivered:
        return Icons.done_all;
      case order_models.OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_selectedStatus);
    final statusLabel = _getStatusLabel(_selectedStatus);
    final statusIcon = _getStatusIcon(_selectedStatus);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Current Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            // Customer Details
            _buildDetailRow('Customer', widget.order.customerName ?? 'N/A'),
            _buildDetailRow('Phone', widget.order.customerPhone ?? 'N/A'),
            if (widget.order.customerAddress != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.order.customerAddress!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            // Items Summary
            Text(
              '${widget.order.items.length} items - Rs ${widget.order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 12),

            // Status Update Dropdown
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<order_models.OrderStatus>(
                  isExpanded: true,
                  value: _selectedStatus,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  items: const [
                    DropdownMenuItem(
                      value: order_models.OrderStatus.pending,
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: order_models.OrderStatus.confirmed,
                      child: Text('Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: order_models.OrderStatus.dispatched,
                      child: Text('Out for Delivery'),
                    ),
                    DropdownMenuItem(
                      value: order_models.OrderStatus.delivered,
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: order_models.OrderStatus.cancelled,
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: _isUpdating
                      ? null
                      : (value) {
                          if (value != null && value != _selectedStatus) {
                            _updateStatus(value);
                          }
                        },
                ),
              ),
            ),
            if (_isUpdating)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Updating...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

