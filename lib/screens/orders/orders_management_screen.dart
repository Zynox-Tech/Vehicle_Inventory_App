import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_tracking_service.dart';
import '../../services/order_service.dart';
import '../payment/invoice_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  static const routeName = '/orders-management';
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  final orderService = OrderService();
  OrderStatus? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
      ),
      body: Column(
        children: [
          // Filter by status
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilterChip(null, 'All Orders'),
                  ...OrderStatus.values.map((status) {
                    final statusName = status.toString().split('.').last;
                    return _buildStatusFilterChip(status, statusName);
                  }),
                ],
              ),
            ),
          ),

          // Orders list
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: selectedStatus == null
                  ? orderService.getOrders()
                  : orderService.getOrdersByStatus(selectedStatus!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }

                final orders = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(OrderStatus? status, String label) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedStatus = selected ? status : null;
          });
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final paymentText = order.paymentMethod == PaymentMethod.cashOnDelivery ? 'COD' : 'Online';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final invoice = await orderService.getInvoice(order.id);
          if (invoice != null && mounted && context.mounted) {
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceScreen(invoice: invoice),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      order.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items summary
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (order.items.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...order.items.take(2).map((item) {
                        return Text(
                          '• ${item.name} x${item.quantity}',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      if (order.items.length > 2)
                        Text(
                          '• +${order.items.length - 2} more',
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (order.status == OrderStatus.confirmed || order.status == OrderStatus.dispatched)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Delivery'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final auth = context.read<AuthService>();
                        try {
                          await DeliveryTrackingService.instance.startDelivery(
                            order: order,
                            staffId: auth.user!.uid,
                            staffLabel: auth.user?.email ?? 'Staff member',
                          );
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Delivery started successfully')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Unable to start delivery: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ),

              // Footer row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs ${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'confirm' && order.status == OrderStatus.pending) {
                        await orderService.updateOrderStatus(order.id, OrderStatus.confirmed);
                      } else if (value == 'dispatch' && order.status == OrderStatus.confirmed) {
                        final auth = context.read<AuthService>();
                        await DeliveryTrackingService.instance.startDelivery(
                          order: order,
                          staffId: auth.user!.uid,
                          staffLabel: auth.user?.email ?? 'Staff member',
                        );
                      } else if (value == 'deliver' && order.status == OrderStatus.dispatched) {
                        await DeliveryTrackingService.instance.markDelivered(order);
                      } else if (value == 'cancel') {
                        await orderService.cancelOrder(order.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      if (order.status == OrderStatus.pending)
                        const PopupMenuItem<String>(
                          value: 'confirm',
                          child: Text('Mark as Confirmed'),
                        ),
                      if (order.status == OrderStatus.confirmed)
                        const PopupMenuItem<String>(
                          value: 'dispatch',
                          child: Text('Start Delivery'),
                        ),
                      if (order.status == OrderStatus.dispatched)
                        const PopupMenuItem<String>(
                          value: 'deliver',
                          child: Text('Mark as Delivered'),
                        ),
                      if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
                        const PopupMenuDivider(),
                      if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
                        const PopupMenuItem<String>(
                          value: 'cancel',
                          child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.dispatched:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
