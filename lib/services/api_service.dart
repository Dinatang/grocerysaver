// Servicio ligero para comparaciones puntuales fuera del CatalogApi principal.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'cache_status_reader.dart';

/// Expone helpers estaticos para endpoints aislados del catalogo.
class ApiService {
  ApiService._();

  static String get baseUrl => ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');
  static String? _lastCacheStatus;

  static String? get lastCacheStatus => _lastCacheStatus;

  /// Consulta la mejor opcion de compra usando el identificador del producto.
  static Future<Map<String, dynamic>> comparePricesByProductId(
    int productId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/compare-prices/',
    ).replace(queryParameters: {'product_id': '$productId'});

    final res = await http.get(uri, headers: const {'Accept': 'application/json'});
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);

    final dynamic decoded = jsonDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception(
      (data['detail'] ?? data['message'] ?? 'Error al comparar precios')
          .toString(),
    );
  }
}
