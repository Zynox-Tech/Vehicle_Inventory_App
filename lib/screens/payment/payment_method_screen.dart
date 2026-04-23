import 'package:flutter/material.dart';
import '../../models/order.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final double totalAmount;
  final Function(PaymentMethod) onPaymentMethodSelected;

  static const routeName = '/payment-method';

  const PaymentMethodSelectionScreen({
    super.key,
    required this.totalAmount,
    required this.onPaymentMethodSelected,
  });

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  PaymentMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Amount Display Card
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs ${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Payment Methods
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Cash on Delivery Option
                _buildPaymentMethodCard(
                  context,
                  method: PaymentMethod.cashOnDelivery,
                  title: 'Cash on Delivery',
                  description: 'Pay when you receive your order',
                  icon: Icons.local_shipping,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Online Payment Option
                _buildPaymentMethodCard(
                  context,
                  method: PaymentMethod.online,
                  title: 'Online Payment',
                  description: 'Card, Bank Transfer, or Digital Wallet',
                  icon: Icons.payment,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedMethod == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Please select a payment method to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _selectedMethod == null
                      ? null
                      : () {
                          widget.onPaymentMethodSelected(_selectedMethod!);
                          Navigator.pop(context, _selectedMethod);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context, {
    required PaymentMethod method,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedMethod == method;
    final borderColor = isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.3);
    final backgroundColor = isSelected
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : isDark
            ? Colors.grey.withOpacity(0.1)
            : Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (PaymentMethod? value) {
                if (value != null) {
                  setState(() {
                    _selectedMethod = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
