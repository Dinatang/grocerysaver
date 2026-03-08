// Cliente HTTP para provincias y cantones usados en el modulo de clima.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'cache_status_reader.dart';

/// Servicio de consulta geografica para datos administrativos del Ecuador.
class EcuadorGeoApi {
  EcuadorGeoApi({String? baseUrl})
    : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), '');

  final String _baseUrl;
  String? _lastCacheStatus;

  String? get lastCacheStatus => _lastCacheStatus;

  /// Devuelve las provincias que el backend expone para el selector.
  Future<List<Map<String, dynamic>>> getProvinces() async {
    final res = await http.get(Uri.parse('$_baseUrl/geo/ecuador/provinces/'));
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);
    final body = _decodeBody(
      res,
      errorMessage: 'Error cargando provincias',
      key: 'provinces',
    );
    return body;
  }

  /// Devuelve los cantones asociados a una provincia especifica.
  Future<List<Map<String, dynamic>>> getCantonsByProvinceId(
    int provinceId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/geo/ecuador/cantons/?province_id=$provinceId'),
    );
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);
    final body = _decodeBody(
      res,
      errorMessage: 'Error cargando cantones',
      key: 'cantons',
    );
    return body;
  }

  /// Normaliza la respuesta JSON y valida la lista esperada en `key`.
  List<Map<String, dynamic>> _decodeBody(
    http.Response res, {
    required String errorMessage,
    required String key,
  }) {
    if (res.statusCode != 200) {
      throw Exception('$errorMessage (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('$errorMessage: respuesta invalida');
    }

    final rawList = decoded[key];
    if (rawList is! List) {
      throw Exception('$errorMessage: campo "$key" invalido');
    }

    return rawList.whereType<Map<String, dynamic>>().toList();
  }
}
