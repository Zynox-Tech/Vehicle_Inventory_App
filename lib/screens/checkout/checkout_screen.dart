import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/paymob_service.dart';
import '../../services/notification_service.dart';
import '../../models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Payment Method Selection Screen
class PaymentMethodScreen extends StatefulWidget {
  static const routeName = '/payment-method';
  final double total;

  const PaymentMethodScreen({required this.total, super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cashOnDelivery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Total
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Rs ${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Cash on Delivery Option
            _buildPaymentOption(
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              icon: Icons.local_shipping_outlined,
              method: PaymentMethod.cashOnDelivery,
              isSelected: _selectedMethod == PaymentMethod.cashOnDelivery,
              onTap: () {
                setState(() => _selectedMethod = PaymentMethod.cashOnDelivery);
              },
            ),
            const SizedBox(height: 16),

            // Online Payment Option
            _buildPaymentOption(
              title: 'Online Payment',
              subtitle: 'Pay now with card/bank transfer',
              icon: Icons.payment,
              method: PaymentMethod.online,
              isSelected: _selectedMethod == PaymentMethod.online,
              onTap: () {
                setState(() => _selectedMethod = PaymentMethod.online);
              },
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/checkout',
                    arguments: {
                      'total': widget.total,
                      'paymentMethod': _selectedMethod,
                    },
                  );
                },
                child: const Text(
                  'Continue to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required PaymentMethod method,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey[900],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.orange[200] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.orange,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _locationLoading = true;
  String? _locationError;
  String? _selectedAddress;
  bool _isLoading = false;
  late double _total;
  late PaymentMethod _paymentMethod;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _nameController = TextEditingController(text: auth.user?.email?.split('@').first ?? '');
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();
    _loadCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _total = args?['total'] ?? 0.0;
    _paymentMethod = args?['paymentMethod'] ?? PaymentMethod.cashOnDelivery;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cart = CartService();
      final auth = context.read<AuthService>();
      final orderService = OrderService();

      // Get cart items with part details
      final cartItems = <OrderItem>[];
      for (final entry in cart.items.entries) {
        final partDoc = await FirebaseFirestore.instance
            .collection('parts')
            .doc(entry.key)
            .get();

        if (partDoc.exists) {
          final data = partDoc.data()!;
          cartItems.add(
            OrderItem(
              partId: entry.key,
              name: data['name'] ?? 'Unknown',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              quantity: entry.value,
            ),
          );
        }
      }

      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty')),
        );
        return;
      }

      // If online payment is selected, process payment first
      if (_paymentMethod == PaymentMethod.online) {
        await _processOnlinePayment();
        return;
      }

      // Create order for Cash on Delivery
      final orderId = await orderService.createOrder(
        items: cartItems,
        total: _total,
        paymentMethod: _paymentMethod,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerAddress: _addressController.text,
        customerLatitude: _selectedLocation?.latitude,
        customerLongitude: _selectedLocation?.longitude,
        notes: _notesController.text,
        userId: auth.user!.uid,
      );

      // Clear cart
      await cart.clear();

      if (mounted) {
        // Navigate to success page
        Navigator.of(context).pushReplacementNamed(
          OrderSuccessScreen.routeName,
          arguments: {
            'orderId': orderId,
            'total': _total,
            'paymentMethod': _paymentMethod,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final location = LatLng(position.latitude, position.longitude);
      final address = await _addressFromLatLng(location);
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _selectedLocation ??= location;
        _locationLoading = false;
        _locationError = null;
        if (_addressController.text.isEmpty) {
          _selectedAddress = address;
          _addressController.text = address;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = e.toString();
      });
    }
  }

  Future<String> _addressFromLatLng(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isEmpty) {
        return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
      }
      final placemark = placemarks.first;
      final parts = <String>[];
      if (placemark.street?.trim().isNotEmpty ?? false) parts.add(placemark.street!);
      if (placemark.locality?.trim().isNotEmpty ?? false) parts.add(placemark.locality!);
      if (placemark.administrativeArea?.trim().isNotEmpty ?? false) parts.add(placemark.administrativeArea!);
      if (placemark.country?.trim().isNotEmpty ?? false) parts.add(placemark.country!);
      return parts.isNotEmpty ? parts.join(', ') : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    } catch (_) {
      return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    }
  }

  Future<void> _openAddressPicker() async {
    final initial = _selectedLocation ?? _currentLocation;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => AddressMapPickerScreen(
          initialLocation: initial,
          initialAddress: _addressController.text,
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedLocation = result['location'] as LatLng?;
      _selectedAddress = result['address'] as String?;
      if (_selectedAddress != null) {
        _addressController.text = _selectedAddress!;
      }
    });
  }

  Future<void> _processOnlinePayment() async {
    try {
      final paymobService = PaymobService();
      
      // Process card payment (you can also add options for JazzCash and EasyPaisa)
      final response = await paymobService.processCardPayment(
        context: context,
        amount: _total,
      );

      if (response != null && paymobService.isPaymentSuccessful(response)) {
        await NotificationService.instance.notifyPaymentSuccessful(
          referenceId: response.transactionID ?? DateTime.now().microsecondsSinceEpoch.toString(),
          amount: _total,
        );
        // Payment successful - now create the order
        await _createOrderAfterPayment(response.transactionID ?? '');
      } else {
        // Payment failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed: ${response?.message ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrderAfterPayment(String transactionId) async {
    try {
      final cart = CartService();
      final auth = context.read<AuthService>();
      final orderService = OrderService();

      // Get cart items
      final cartItems = <OrderItem>[];
      for (final entry in cart.items.entries) {
        final partDoc = await FirebaseFirestore.instance
            .collection('parts')
            .doc(entry.key)
            .get();

        if (partDoc.exists) {
          final data = partDoc.data()!;
          cartItems.add(
            OrderItem(
              partId: entry.key,
              name: data['name'] ?? 'Unknown',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              quantity: entry.value,
            ),
          );
        }
      }

      // Create order with transaction ID
      final orderId = await orderService.createOrder(
        items: cartItems,
        total: _total,
        paymentMethod: _paymentMethod,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerAddress: _addressController.text,
        customerLatitude: _selectedLocation?.latitude,
        customerLongitude: _selectedLocation?.longitude,
        notes: _notesController.text,
        userId: auth.user!.uid,
      );

      // Store transaction ID in Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentTransactionId': transactionId,
        'paymentStatus': 'completed',
      });

      // Clear cart
      await cart.clear();

      if (mounted) {
        // Navigate to success page
        Navigator.of(context).pushReplacementNamed(
          OrderSuccessScreen.routeName,
          arguments: {
            'orderId': orderId,
            'total': _total,
            'paymentMethod': _paymentMethod,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Section
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          Text(
                            'Rs ${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Method:',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          Text(
                            _paymentMethod == PaymentMethod.cashOnDelivery
                                ? 'Cash on Delivery'
                                : 'Online Payment',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Delivery Address Section
              const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Name required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Phone required' : null,
              ),
                      const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                readOnly: true,
                onTap: _openAddressPicker,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: _openAddressPicker,
                  ),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Address required' : null,
              ),
              const SizedBox(height: 8),
              if (_locationLoading)
                const Text('Detecting your current location...', style: TextStyle(color: Colors.white70))
              else if (_locationError != null)
                Text('Location error: $_locationError', style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Special Instructions (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

class OrderSuccessScreen extends StatelessWidget {
  static const routeName = '/order-success';

  final String orderId;
  final double total;
  final PaymentMethod paymentMethod;

  const OrderSuccessScreen({
    required this.orderId,
    required this.total,
    required this.paymentMethod,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),

              // Thank You Message
              const Text(
                'Thank You!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Your order has been placed successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),

              // Order Details Card
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailRow('Order ID', orderId.substring(0, 12) + '...'),
                      const Divider(color: Colors.white24),
                      _buildDetailRow(
                        'Total Amount',
                        'Rs ${total.toStringAsFixed(2)}',
                        isAmount: true,
                      ),
                      const Divider(color: Colors.white24),
                      _buildDetailRow(
                        'Payment Method',
                        paymentMethod == PaymentMethod.cashOnDelivery
                            ? 'Cash on Delivery'
                            : 'Online Payment',
                      ),
                      const Divider(color: Colors.white24),
                      _buildDetailRow(
                        'Status',
                        'Pending',
                        statusColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What Happens Next?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✓ Your order is confirmed\n✓ You will receive updates on delivery status\n✓ Our team will prepare your order for dispatch\n✓ Payment will be collected on delivery',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/my-orders',
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                      child: const Text('View Orders'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(color: Colors.white),
                      ),
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

class AddressMapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String initialAddress;

  const AddressMapPickerScreen({required this.initialLocation, required this.initialAddress, super.key});

  @override
  State<AddressMapPickerScreen> createState() => _AddressMapPickerScreenState();
}

class _AddressMapPickerScreenState extends State<AddressMapPickerScreen> {
  late LatLng _selectedLocation;
  String? _address;
  bool _updatingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(24.8607, 67.0011);
    _address = widget.initialAddress.isNotEmpty ? widget.initialAddress : null;
    if (_address == null) {
      _updateAddress(_selectedLocation);
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    setState(() {
      _updatingAddress = true;
    });
    final address = await _reverseGeocode(location);
    if (!mounted) return;
    setState(() {
      _address = address;
      _updatingAddress = false;
    });
  }

  Future<String> _reverseGeocode(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isEmpty) {
        return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
      }
      final placemark = placemarks.first;
      final parts = <String>[];
      if (placemark.street?.trim().isNotEmpty ?? false) parts.add(placemark.street!);
      if (placemark.locality?.trim().isNotEmpty ?? false) parts.add(placemark.locality!);
      if (placemark.administrativeArea?.trim().isNotEmpty ?? false) parts.add(placemark.administrativeArea!);
      if (placemark.country?.trim().isNotEmpty ?? false) parts.add(placemark.country!);
      return parts.isNotEmpty ? parts.join(', ') : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    } catch (_) {
      return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Delivery Location')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15,
                onTap: (tapPosition, point) async {
                  setState(() {
                    _selectedLocation = point;
                  });
                  await _updateAddress(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.parts',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected address', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  _address ?? 'Tap on the map to choose a location',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updatingAddress
                        ? null
                        : () {
                            Navigator.of(context).pop({
                              'location': _selectedLocation,
                              'address': _address ?? '',
                            });
                          },
                    child: _updatingAddress
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Use this location'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDetailRow(
    String label,
    String value, {
    bool isAmount = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAmount ? Colors.orange : statusColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

