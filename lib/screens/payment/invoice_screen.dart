import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../models/invoice.dart';
import '../../models/order.dart';
import '../../services/pdf_service.dart';

class InvoiceScreen extends StatefulWidget {
  final Invoice invoice;
  
  static const routeName = '/invoice';

  const InvoiceScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Invoice',
            onPressed: _shareInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Invoice',
            onPressed: _downloadPDF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInvoiceContent(),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceContent() {
    final invoice = widget.invoice;
    final order = invoice.order;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(invoice),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Order Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Invoice Number:', invoice.invoiceNumber),
                    const SizedBox(height: 8),
                    _buildDetailRow('Order ID:', order.id.substring(0, 12)),
                    const SizedBox(height: 8),
                    _buildDetailRow('Date:', invoice.getFormattedDate(order.createdAt)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.dispatchedAt != null)
                      _buildDetailRow('Dispatched:', invoice.getFormattedDate(order.dispatchedAt!)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Customer Details
          if (order.customerName != null || order.customerPhone != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill To:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (order.customerName != null)
                  Text(
                    order.customerName!,
                    style: const TextStyle(fontSize: 13),
                  ),
                if (order.customerPhone != null)
                  Text(
                    order.customerPhone!,
                    style: const TextStyle(fontSize: 13),
                  ),
                if (order.customerAddress != null)
                  Text(
                    order.customerAddress!,
                    style: const TextStyle(fontSize: 13),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
              ],
            ),

          // Items Table
          _buildItemsTable(order),
          const SizedBox(height: 24),

          // Totals
          _buildTotalSection(invoice),
        ],
      ),
    );
  }

  Widget _buildHeader(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          invoice.companyName ?? 'Parts Inventory',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'INVOICE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'QTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items
        ...order.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == order.items.length - 1;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Rs ${item.price.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Rs ${item.subtotal.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotalSection(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalRow(
                'Subtotal:',
                'Rs ${invoice.subtotal.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              if (invoice.tax > 0)
                Column(
                  children: [
                    _buildTotalRow(
                      'Tax:',
                      'Rs ${invoice.tax.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Rs ${invoice.total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTotalRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.home),
          label: const Text('Back to Home'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Pop invoice and any previous screens
          },
        ),
      ],
    );
  }

  Future<void> _shareInvoice() async {
    try {
      final bytes = await PdfService.generateInvoicePdf(widget.invoice);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'invoice_${widget.invoice.invoiceNumber}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to share invoice PDF: $error')),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    try {
      final bytes = await PdfService.generateInvoicePdf(widget.invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'invoice_${widget.invoice.invoiceNumber}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to generate invoice PDF: $error')),
        );
      }
    }
  }
}
