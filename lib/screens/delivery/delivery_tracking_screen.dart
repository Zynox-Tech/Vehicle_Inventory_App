import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_session.dart';
import '../../models/order.dart' as order_models;
import '../../services/auth_service.dart';
import '../../services/delivery_tracking_service.dart';
import '../../services/order_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({required this.orderId, super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();
  final OrderService _orderService = OrderService();

  bool _autoFollow = true;
  String? _lastFitSignature;

  List<Marker> _buildMarkers(DeliverySession session) {
    final markers = <Marker>[];

    if (session.staffLatitude != null && session.staffLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(session.staffLatitude!, session.staffLongitude!),
          width: 60,
          height: 60,
          child: const Icon(Icons.delivery_dining, color: Colors.blueAccent, size: 30),
        ),
      );
    }

    if (session.destinationLatitude != null && session.destinationLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(session.destinationLatitude!, session.destinationLongitude!),
          width: 60,
          height: 60,
          child: const Icon(Icons.flag, color: Colors.redAccent, size: 30),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines(DeliverySession session) {
    if (session.staffLatitude == null || session.staffLongitude == null) {
      return const [];
    }

    if (session.destinationLatitude == null || session.destinationLongitude == null) {
      return const [];
    }

    return [
      Polyline(
        points: [
          LatLng(session.staffLatitude!, session.staffLongitude!),
          LatLng(session.destinationLatitude!, session.destinationLongitude!),
        ],
        color: Colors.orangeAccent,
        strokeWidth: 5,
      ),
    ];
  }

  Future<void> _fitMap(List<LatLng> points) async {
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
  }

  String _statusLabel(order_models.Order? order, DeliverySession session) {
    if (order != null) {
      return order.status.toString().split('.').last.toUpperCase();
    }
    return session.status.toUpperCase();
  }

  String _formatDistance(double? meters) {
    if (meters == null) {
      return 'Unavailable';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatEta(double? minutes) {
    if (minutes == null) {
      return 'Unavailable';
    }
    final rounded = minutes.ceil();
    if (rounded < 60) {
      return '$rounded min';
    }
    return '${rounded ~/ 60} h ${rounded % 60} min';
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return 'Waiting';
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Tracking')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Open a dispatched order to view live tracking.'),
          ),
        ),
      );
    }

    return StreamBuilder<order_models.Order?>(
      stream: _orderService.watchOrder(widget.orderId),
      builder: (context, orderSnapshot) {
        final order = orderSnapshot.data;
        final auth = context.read<AuthService>();

        return StreamBuilder<DeliverySession?>(
          stream: DeliveryTrackingService.instance.watchSession(widget.orderId),
          builder: (context, sessionSnapshot) {
            final session = sessionSnapshot.data;

            if (order == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Live Tracking')),
                body: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Order not found.'),
                  ),
                ),
              );
            }

            if (session == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Live Tracking')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.status == order_models.OrderStatus.dispatched
                              ? 'Delivery is marked dispatched. Live tracking starts when the delivery route begins.'
                              : 'Tracking will appear once delivery starts for order #${order.id.substring(0, 8).toUpperCase()}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        if ((order.status == order_models.OrderStatus.confirmed ||
                                order.status == order_models.OrderStatus.dispatched) &&
                            auth.isLoggedIn &&
                            auth.role == 'staff')
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Delivery'),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await DeliveryTrackingService.instance.startDelivery(
                                  order: order,
                                  staffId: auth.user!.uid,
                                  staffLabel: auth.user!.email ?? 'Staff member',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Unable to start delivery: $e')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final markers = _buildMarkers(session);
            final polylines = _buildPolylines(session);
            final mapPoints = markers.map((marker) => marker.point).toList();
            final signature = mapPoints.map((point) => '${point.latitude},${point.longitude}').join('|');

            if (_autoFollow && signature.isNotEmpty && signature != _lastFitSignature) {
              _lastFitSignature = signature;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitMap(mapPoints);
              });
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Live Tracking'),
                actions: [
                  IconButton(
                    tooltip: _autoFollow ? 'Disable auto-follow' : 'Enable auto-follow',
                    icon: Icon(_autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed),
                    onPressed: () {
                      setState(() {
                        _autoFollow = !_autoFollow;
                        _lastFitSignature = null;
                      });
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final center = (session.staffLatitude != null && session.staffLongitude != null)
                            ? LatLng(session.staffLatitude!, session.staffLongitude!)
                            : (session.destinationLatitude != null && session.destinationLongitude != null
                                ? LatLng(session.destinationLatitude!, session.destinationLongitude!)
                                : const LatLng(0, 0));

                        return Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: center,
                                initialZoom: 14,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.parts',
                                ),
                                MarkerLayer(markers: markers),
                                PolylineLayer(polylines: polylines),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _TrackingInfoPanel(
                    session: session,
                    order: order,
                    statusLabel: _statusLabel(order, session),
                    distanceLabel: _formatDistance(session.distanceMeters),
                    etaLabel: _formatEta(session.etaMinutes),
                    updatedLabel: _formatTime(session.lastUpdatedAt),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TrackingInfoPanel extends StatelessWidget {
  final DeliverySession session;
  final order_models.Order? order;
  final String statusLabel;
  final String distanceLabel;
  final String etaLabel;
  final String updatedLabel;

  const _TrackingInfoPanel({
    required this.session,
    required this.order,
    required this.statusLabel,
    required this.distanceLabel,
    required this.etaLabel,
    required this.updatedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Order #${session.orderId.substring(0, 8).toUpperCase()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.local_shipping, text: 'Status: $statusLabel'),
              _InfoChip(icon: Icons.route, text: 'Distance: $distanceLabel'),
              _InfoChip(icon: Icons.schedule, text: 'ETA: $etaLabel'),
              _InfoChip(icon: Icons.update, text: 'Updated: $updatedLabel'),
            ],
          ),
          if (session.customerAddress != null && session.customerAddress!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              session.customerAddress!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (order != null) ...[
            const SizedBox(height: 12),
            Text(
              'Payment: ${order!.paymentMethod == order_models.PaymentMethod.cashOnDelivery ? 'Cash on Delivery' : 'Online Payment'}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.orangeAccent),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}