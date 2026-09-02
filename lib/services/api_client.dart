import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/services/token_storage.dart';

/// Couche reseau centralisee (app admin). Non branchee sur les ecrans
/// existants pour l'instant : ils continuent d'appeler http.get/http.post
/// directement. Reutilise apiUri() de mesfonctions.dart pour une URL
/// strictement identique a l'existant.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeoutParDefaut = Duration(seconds: 15);

  static final ApiClient instance = ApiClient();

  final http.Client _client;

  Uri _uri(String path) {
    final chemin = path.startsWith('/') ? path.substring(1) : path;
    return apiUri(chemin);
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await TokenStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path, {Duration? timeout}) async {
    return _client
        .get(_uri(path), headers: await _headers())
        .timeout(timeout ?? _timeoutParDefaut);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Duration? timeout,
  }) async {
    return _client
        .post(
          _uri(path),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout ?? _timeoutParDefaut);
  }

  Future<Map<String, String>> _headersAuthSeul() async {
    final headers = <String, String>{};
    final token = await TokenStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> postForm(
    String path, {
    required Map<String, String> fields,
    Duration? timeout,
  }) async {
    return _client
        .post(_uri(path), headers: await _headersAuthSeul(), body: fields)
        .timeout(timeout ?? _timeoutParDefaut);
  }

  Future<http.Response> postMultipart(
    String path, {
    required Map<String, String> fields,
    String? filePath,
    String fileField = 'file',
    Duration? timeout,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headersAuthSeul());
    request.fields.addAll(fields);
    if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath),
      );
    }
    final streamed = await _client
        .send(request)
        .timeout(timeout ?? _timeoutParDefaut);
    return http.Response.fromStream(streamed);
  }

  void close() => _client.close();
}
