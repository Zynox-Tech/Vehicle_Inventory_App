import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatelessWidget {
  static const routeName = '/reports';
  const ReportsScreen({super.key});

  Stream<_OrderSummary> _summaryForRange(DateTime start, DateTime end) {
    final q = FirebaseFirestore.instance
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThan: end)
        .snapshots();

    return q.map((snap) {
      final total = snap.docs.fold<double>(0, (prev, doc) {
        final data = doc.data();
        return prev + ((data['total'] ?? 0) as num).toDouble();
      });
      return _OrderSummary(total: total, count: snap.docs.length);
    });
  }

  Future<void> _exportOrdersCsv(BuildContext context, DateTime since) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: since)
          .orderBy('createdAt', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No orders found in the selected range.')),
        );
        return;
      }

      final rows = <List<String>>[
        [
          'order_id',
          'date',
          'customer_name',
          'customer_phone',
          'payment_method',
          'status',
          'total',
          'items_count',
          'customer_address',
          'notes',
          'customer_latitude',
          'customer_longitude',
        ],
      ];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final items = (data['items'] as List<dynamic>?) ?? <dynamic>[];
        rows.add([
          doc.id,
          createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt) : '',
          data['customerName'] as String? ?? '',
          data['customerPhone'] as String? ?? '',
          data['paymentMethod'] as String? ?? '',
          data['status'] as String? ?? '',
          ((data['total'] ?? 0) as num).toString(),
          items.length.toString(),
          data['customerAddress'] as String? ?? '',
          data['notes'] as String? ?? '',
          (data['customerLatitude'] as num?)?.toString() ?? '',
          (data['customerLongitude'] as num?)?.toString() ?? '',
        ]);
      }

      final csv = rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
      final tempDir = await getTemporaryDirectory();
      final fileName = 'sales_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csv, flush: true);

      await Share.shareXFiles([
        XFile(file.path, name: fileName, mimeType: 'text/csv')
      ], subject: 'Sales report (last 30 days)');
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $error')),
      );
    }
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday-1));
    final monthStart = DateTime(now.year, now.month);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Today', _summaryForRange(todayStart, todayStart.add(const Duration(days: 1)))) ,
          _tile('This Week', _summaryForRange(weekStart, weekStart.add(const Duration(days: 7)))) ,
          _tile('This Month', _summaryForRange(monthStart, DateTime(now.year, now.month + 1))) ,
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download sales CSV (last 30 days)'),
            onPressed: () async {
              final since = DateTime.now().subtract(const Duration(days: 30));
              await _exportOrdersCsv(context, since);
            },
          )
        ],
      ),
    );
  }

  Widget _tile(String title, Stream<_OrderSummary> summary$) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ');
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: StreamBuilder<_OrderSummary>(
          stream: summary$,
          builder: (context, snap) {
            final summary = snap.data;
            return Text('Total Sales: ${fmt.format(summary?.total ?? 0)} | Orders: ${summary?.count ?? 0}');
          },
        ),
      ),
    );
  }
}

class _OrderSummary {
  final double total;
  final int count;

  _OrderSummary({required this.total, required this.count});
}
