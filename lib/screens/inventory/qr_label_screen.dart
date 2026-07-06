import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/pdf_service.dart';

class QrLabelScreen extends StatefulWidget {
  final String partId;
  final String name;
  const QrLabelScreen({super.key, required this.partId, required this.name});

  @override
  State<QrLabelScreen> createState() => _QrLabelScreenState();
}

class _QrLabelScreenState extends State<QrLabelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Label'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download QR Label',
            onPressed: _downloadQrLabel,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: widget.partId,
                    version: QrVersions.auto,
                    size: 220.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Part ID: ${widget.partId}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan this on Billing screen to add to cart',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Print Label'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _printQrLabel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _shareQrLabel,
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

  Future<void> _downloadQrLabel() async {
    try {
      final bytes = await PdfService.generateQrLabelPdf(widget.partId, widget.name);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'qr_label_${widget.partId}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create QR label PDF: $error')),
        );
      }
    }
  }

  Future<void> _printQrLabel() async {
    try {
      final bytes = await PdfService.generateQrLabelPdf(widget.partId, widget.name);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'qr_label_${widget.partId}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to print QR label PDF: $error')),
        );
      }
    }
  }

  Future<void> _shareQrLabel() async {
    try {
      final bytes = await PdfService.generateQrLabelPdf(widget.partId, widget.name);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'qr_label_${widget.partId}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to share QR label PDF: $error')),
        );
      }
    }
  }
}

