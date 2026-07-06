import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final order = invoice.order;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoice.companyName ?? 'Parts Inventory',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: ${invoice.getFormattedDate(order.createdAt)}', style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Order ID: ${order.id.substring(0, 12)}', style: pw.TextStyle(fontSize: 12)),
                    if (order.dispatchedAt != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Dispatched: ${invoice.getFormattedDate(order.dispatchedAt!)}', style: pw.TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    if (order.customerName != null)
                      pw.Text(order.customerName!, style: pw.TextStyle(fontSize: 12)),
                    if (order.customerPhone != null)
                      pw.Text(order.customerPhone!, style: pw.TextStyle(fontSize: 12)),
                    if (order.customerAddress != null)
                      pw.Text(order.customerAddress!, style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Items', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Qty', 'Price', 'Total'],
            data: order.items
                .map(
                  (item) => [
                    item.name,
                    item.quantity.toString(),
                    'Rs ${item.price.toStringAsFixed(2)}',
                    'Rs ${item.subtotal.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            cellStyle: pw.TextStyle(fontSize: 11),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildTotalRow('Subtotal:', 'Rs ${invoice.subtotal.toStringAsFixed(2)}'),
                if (invoice.tax > 0)
                  _buildTotalRow('Tax:', 'Rs ${invoice.tax.toStringAsFixed(2)}'),
                _buildTotalRow('Total:', 'Rs ${invoice.total.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(invoice.companyAddress ?? 'Karachi, Pakistan', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(invoice.companyPhone ?? '+92 300 1234567', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateQrLabelPdf(String partId, String name) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('QR LABEL', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: partId,
                  width: 170,
                  height: 170,
                ),
                pw.SizedBox(height: 16),
                pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Part ID: $partId', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Scan this QR code on the Billing screen to add this part to cart.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }
}
