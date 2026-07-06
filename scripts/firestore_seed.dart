import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const projectId = 'parts-74299';
const databaseId = '(default)';
const firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/$databaseId/documents';

void main() async {
  final client = await createAuthClient();

  final collections = {
    'users': {
      'docId': 'sample-user',
      'fields': {
        'email': 'sample@parts.com',
        'role': 'customer',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    },
    'parts': {
      'docId': 'sample-part',
      'fields': {
        'name': 'Sample Part',
        'category': 'General',
        'price': 1000.0,
        'quantity': 10,
        'lowStockThreshold': 3,
        'qrData': 'sample-part',
      },
    },
    'orders': {
      'docId': 'sample-order',
      'fields': {
        'userId': 'sample-user',
        'items': [
          {
            'partId': 'sample-part',
            'name': 'Sample Part',
            'price': 1000.0,
            'quantity': 1,
          },
        ],
        'total': 1000.0,
        'paymentMethod': 'cashOnDelivery',
        'status': 'pending',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'customerName': 'Sample Customer',
        'customerPhone': '+923001234567',
        'customerAddress': 'Sample Address',
      },
    },
    'invoices': {
      'docId': 'sample-invoice',
      'fields': {
        'invoiceNumber': 'INV-SAMPLE-001',
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'companyName': 'Parts Inventory',
        'companyPhone': '+92 300 1234567',
        'companyAddress': 'Karachi, Pakistan',
        'order': {
          'userId': 'sample-user',
          'items': [
            {
              'partId': 'sample-part',
              'name': 'Sample Part',
              'price': 1000.0,
              'quantity': 1,
            },
          ],
          'total': 1000.0,
          'paymentMethod': 'cashOnDelivery',
          'status': 'pending',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      },
    },
    'sales': {
      'docId': 'sample-sale',
      'fields': {
        'total': 1000.0,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    },
    'delivery_sessions': {
      'docId': 'sample-delivery-session',
      'fields': {
        'orderId': 'sample-order',
        'customerId': 'sample-user',
        'staffId': 'sample-staff',
        'staffLabel': 'Sample Staff',
        'customerAddress': 'Sample Address',
        'destinationLatitude': 24.8607,
        'destinationLongitude': 67.0011,
        'staffLatitude': 24.8607,
        'staffLongitude': 67.0011,
        'distanceMeters': 0.0,
        'etaMinutes': 0.0,
        'isActive': false,
        'status': 'sample',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    },
  };

  for (final entry in collections.entries) {
    final collection = entry.key;
    final docId = entry.value['docId'] as String;
    final fields = entry.value['fields'] as Map<String, Object>;

    stdout.writeln('Checking collection "$collection"...');
    final hasDocs = await collectionHasAnyDocuments(collection, client);
    if (hasDocs) {
      stdout.writeln(
        '  Collection "$collection" already has documents. Skipping sample creation.',
      );
      continue;
    }

    stdout.writeln(
      '  Collection "$collection" is empty. Creating sample document "$docId".',
    );
    final created = await createDocument(collection, docId, fields, client);
    if (created) {
      stdout.writeln('  Created sample document in "$collection".');
    } else {
      stderr.writeln('  Failed to create sample document in "$collection".');
    }
  }

  stdout.writeln('\nDone.');
  client.close();
}

Future<http.Client> createAuthClient() async {
  final credentialsPath =
      Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  final oauthToken = Platform.environment['FIREBASE_OAUTH_TOKEN'];

  if ((credentialsPath == null || credentialsPath.isEmpty) &&
      (oauthToken == null || oauthToken.isEmpty)) {
    stderr.writeln('ERROR: Authentication is not configured.');
    stderr.writeln(
      'Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON file with Firestore access,\n'
      'or set FIREBASE_OAUTH_TOKEN to a valid OAuth access token.',
    );
    stderr.writeln('Example (PowerShell):');
    stderr.writeln(
      '\$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\service-account.json"',
    );
    stderr.writeln('Use a service account key file for the safest auth flow.');
    exit(1);
  }

  if (credentialsPath != null && credentialsPath.isNotEmpty) {
    final jsonString = File(credentialsPath).readAsStringSync();
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
    return await clientViaServiceAccount(
      credentials,
      const [
        'https://www.googleapis.com/auth/datastore',
        'https://www.googleapis.com/auth/cloud-platform',
      ],
    );
  }

  return BearerClient(oauthToken!);
}

class BearerClient extends http.BaseClient {
  final String token;
  final http.Client _inner;

  BearerClient(this.token, [http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $token';
    return _inner.send(request);
  }
}

Future<bool> collectionHasAnyDocuments(
  String collection,
  http.Client client,
) async {
  final uri = Uri.parse('$firestoreBase/$collection?pageSize=1');
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    stderr.writeln(
      'ERROR checking collection "$collection": ${response.statusCode}',
    );
    stderr.writeln(response.body);
    return false;
  }
  final data = json.decode(response.body) as Map<String, dynamic>;
  final docs = data['documents'] as List<dynamic>?;
  return docs != null && docs.isNotEmpty;
}

Future<bool> createDocument(
  String collection,
  String docId,
  Map<String, Object> fields,
  http.Client client,
) async {
  final uri = Uri.parse('$firestoreBase/$collection?documentId=$docId');
  final response = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'fields': _wrapFields(fields)}),
  );

  if (response.statusCode == 200) {
    return true;
  }

  stderr.writeln('ERROR creating document $collection/$docId: ${response.statusCode}');
  stderr.writeln(response.body);
  return false;
}

Map<String, dynamic> _wrapFields(Map<String, Object> fields) {
  return fields.map((key, value) => MapEntry(key, _wrapValue(value)));
}

Map<String, dynamic> _wrapValue(Object? value) {
  if (value is String) {
    return {'stringValue': value};
  }
  if (value is bool) {
    return {'booleanValue': value};
  }
  if (value is int) {
    return {'integerValue': value.toString()};
  }
  if (value is double) {
    return {'doubleValue': value};
  }
  if (value is DateTime) {
    return {'timestampValue': value.toUtc().toIso8601String()};
  }
  if (value is Map<String, Object>) {
    return {
      'mapValue': {'fields': _wrapFields(value)},
    };
  }
  if (value is List<Object>) {
    return {
      'arrayValue': {'values': value.map(_wrapValue).toList()},
    };
  }
  return {'stringValue': value?.toString() ?? ''};
}
