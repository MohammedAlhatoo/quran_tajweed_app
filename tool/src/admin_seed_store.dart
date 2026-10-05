import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';

/// A request that Firestore refused.
class FirestoreRequestException implements Exception {
  const FirestoreRequestException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'HTTP $statusCode: $body';
}

/// A [SeedStore] over the Firestore REST API.
///
/// It is used with administrative credentials, which the security rules do
/// not apply to. It only reads collections and merges fields into documents:
/// it has no way to delete.
class AdminSeedStore implements SeedStore {
  AdminSeedStore(
    this._client,
    this.projectId, {
    this.rootUrl = 'https://firestore.googleapis.com/',
  });

  /// The OAuth scope the client needs.
  static const String scope = 'https://www.googleapis.com/auth/datastore';

  final http.Client _client;
  final String projectId;
  final String rootUrl;

  static const _serverTimestamp = _ServerTimestamp();

  static const int _pageSize = 300;

  /// Firestore allows at most 500 writes in a commit.
  static const int _batchSize = 200;

  String get _documents =>
      'projects/$projectId/databases/(default)/documents';

  @override
  Object get timestamp => _serverTimestamp;

  @override
  Future<Map<String, Map<String, dynamic>>> readAll(String collection) async {
    final documents = <String, Map<String, dynamic>>{};
    String? pageToken;
    do {
      final response = await _client.get(
        Uri.parse('${rootUrl}v1/$_documents/$collection').replace(
          queryParameters: {'pageSize': '$_pageSize', 'pageToken': ?pageToken},
        ),
      );
      final page = _body(response);
      for (final document in page['documents'] as List? ?? const []) {
        final name = document['name'] as String;
        documents[name.split('/').last] = {
          for (final field in (document['fields'] as Map? ?? const {}).entries)
            field.key as String: _decode(field.value as Map),
        };
      }
      pageToken = page['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
    return documents;
  }

  @override
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  ) async {
    final entries = documents.entries.toList();
    for (var i = 0; i < entries.length; i += _batchSize) {
      final response = await _client.post(
        Uri.parse('${rootUrl}v1/$_documents:commit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'writes': [
            for (final entry in entries.skip(i).take(_batchSize))
              _mergeWrite('$_documents/$collection/${entry.key}', entry.value),
          ],
        }),
      );
      _body(response);
    }
  }

  static Map<String, dynamic> _body(http.Response response) {
    if (response.statusCode != 200) {
      throw FirestoreRequestException(response.statusCode, response.body);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// A write that sets only the given fields and keeps the others of an
  /// existing document.
  static Map<String, Object?> _mergeWrite(
    String name,
    Map<String, Object?> data,
  ) {
    final fields = <String, Object?>{};
    final timestamps = <String>[];
    for (final field in data.entries) {
      if (identical(field.value, _serverTimestamp)) {
        timestamps.add(field.key);
      } else {
        fields[field.key] = _encode(field.value);
      }
    }
    return {
      'update': {'name': name, 'fields': fields},
      'updateMask': {'fieldPaths': fields.keys.map(_path).toList()},
      if (timestamps.isNotEmpty)
        'updateTransforms': [
          for (final field in timestamps)
            {'fieldPath': _path(field), 'setToServerValue': 'REQUEST_TIME'},
        ],
    };
  }

  static final _simpleName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static String _path(String field) => _simpleName.hasMatch(field)
      ? field
      : '`${field.replaceAll(r'\', r'\\').replaceAll('`', r'\`')}`';

  static Map<String, Object?> _encode(Object? value) => switch (value) {
    null => {'nullValue': null},
    bool() => {'booleanValue': value},
    int() => {'integerValue': '$value'},
    double() => {'doubleValue': value},
    String() => {'stringValue': value},
    List() => {
      'arrayValue': {'values': value.map(_encode).toList()},
    },
    Map() => {
      'mapValue': {
        'fields': {
          for (final entry in value.entries)
            '${entry.key}': _encode(entry.value),
        },
      },
    },
    _ => throw ArgumentError.value(value, 'value', 'Not a Firestore value'),
  };

  static Object? _decode(Map<dynamic, dynamic> value) {
    final MapEntry(key: type, value: content) = value.entries.first;
    return switch (type) {
      'nullValue' => null,
      'integerValue' => int.parse(content as String),
      'doubleValue' => (content as num).toDouble(),
      'timestampValue' => DateTime.parse(content as String),
      'arrayValue' => [
        for (final item in (content as Map)['values'] as List? ?? const [])
          _decode(item as Map),
      ],
      'mapValue' => {
        for (final field in ((content as Map)['fields'] as Map? ?? const {})
            .entries)
          field.key as String: _decode(field.value as Map),
      },
      _ => content,
    };
  }
}

class _ServerTimestamp {
  const _ServerTimestamp();
}
