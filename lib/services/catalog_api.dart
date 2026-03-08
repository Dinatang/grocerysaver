// Cliente HTTP para catalogo, categorias, tiendas y comparacion de precios.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cache_status_reader.dart';

/// Error especifico del modulo de catalogo.
class CatalogApiException implements Exception {
  CatalogApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

/// Servicio de acceso al catalogo y sus filtros principales.
class CatalogApi {
  CatalogApi(String baseUrl)
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final String baseUrl;
  String? _lastCacheStatus;

  String? get lastCacheStatus => _lastCacheStatus;

  /// Obtiene el listado de tiendas disponibles.
  Future<List<dynamic>> getStores() async {
    const endpoint = '/stores/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: const {'Accept': 'application/json'},
    );
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);
    final data = _decode(res, endpoint: endpoint);
    final stores = data['stores'];
    if (stores is List<dynamic>) {
      return stores;
    }
    throw CatalogApiException(
      'Respuesta invalida en $endpoint: no contiene stores.',
      statusCode: res.statusCode,
    );
  }

  /// Obtiene el listado de categorias consumidas por la UI.
  Future<List<dynamic>> getCategories() async {
    const endpoint = '/categories/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: const {'Accept': 'application/json'},
    );
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);
    final data = _decode(res, endpoint: endpoint);
    final categories = data['categories'];
    if (categories is List<dynamic>) {
      return categories;
    }
    throw CatalogApiException(
      'Respuesta invalida en $endpoint: no contiene categories.',
      statusCode: res.statusCode,
    );
  }

  /// Obtiene productos filtrando por categoria y texto cuando aplica.
  Future<List<dynamic>> getProducts({int? categoryId, String? search}) async {
    const endpoint = '/products/';
    final query = <String, String>{};
    if (categoryId != null) {
      query['category_id'] = '$categoryId';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    final res = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);
    final data = _decode(res, endpoint: endpoint);
    final products = data['products'];
    if (products is List<dynamic>) {
      return products;
    }
    throw CatalogApiException(
      'Respuesta invalida en $endpoint: no contiene products.',
      statusCode: res.statusCode,
    );
  }

  /// Ejecuta la comparacion de precios por id o nombre de producto.
  Future<Map<String, dynamic>> comparePrices({
    int? productId,
    String? product,
  }) async {
    const endpoint = '/compare-prices/';
    final query = <String, String>{};
    if (productId != null) {
      query['product_id'] = '$productId';
    }
    if (product != null && product.trim().isNotEmpty) {
      query['product'] = product.trim();
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    final res = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);
    return _decode(res, endpoint: endpoint);
  }

  /// Valida el contrato JSON del backend antes de entregar datos a la UI.
  Map<String, dynamic> _decode(http.Response res, {required String endpoint}) {
    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    final body = res.body.trim();

    if (!contentType.contains('application/json')) {
      throw CatalogApiException(
        'Respuesta no JSON (${res.statusCode}) en $endpoint: ${_preview(body)}',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw CatalogApiException(
        'Formato de respuesta no valido en $endpoint.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw CatalogApiException(
      _extractMessage(decoded).isEmpty
          ? 'Error al consultar catalogo.'
          : _extractMessage(decoded),
      statusCode: res.statusCode,
    );
  }

  /// Busca el mejor texto de error posible para mostrar en pantalla.
  String _extractMessage(Map<String, dynamic> data) {
    if (data['detail'] != null) return data['detail'].toString();
    if (data['message'] != null) return data['message'].toString();
    if (data['error'] != null) return data['error'].toString();
    if (data.isNotEmpty) return data.toString();
    return '';
  }

  /// Recorta respuestas largas antes de incluirlas en una excepcion.
  String _preview(String body) {
    if (body.isEmpty) return '(sin contenido)';
    const limit = 180;
    if (body.length <= limit) return body;
    return '${body.substring(0, limit)}...';
  }
}
