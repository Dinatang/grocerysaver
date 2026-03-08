// Cliente HTTP y modelos tipados para el modulo de clima.
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'cache_status_reader.dart';

/// Error especifico para fallos del modulo de clima.
class WeatherApiException implements Exception {
  WeatherApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

/// Snapshot listo para renderizar clima actual y pronostico.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.daily,
  });

  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
  final List<WeatherDaily> daily;
}

/// Modelo de un dia del pronostico extendido.
class WeatherDaily {
  const WeatherDaily({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  final String date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
}

/// Servicio para consultar clima por ciudad o coordenadas.
class WeatherApi {
  WeatherApi({String? baseUrl})
      : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), '');

  final String _baseUrl;
  String? _lastCacheStatus;

  String? get lastCacheStatus => _lastCacheStatus;

  /// Atajo semantico para consultas por ciudad.
  Future<WeatherSnapshot> getCurrentByCity(String city) {
    return getCurrent(city: city);
  }

  /// Atajo semantico para consultas por coordenadas.
  Future<WeatherSnapshot> getCurrentByCoords({
    required double lat,
    required double lon,
  }) {
    return getCurrent(lat: lat, lon: lon);
  }

  /// Consulta el backend y adapta distintas variantes del payload de clima.
  Future<WeatherSnapshot> getCurrent({
    String? city,
    double? lat,
    double? lon,
  }) async {
    final normalizedCity = city?.trim() ?? '';
    final query = <String, String>{};

    if (normalizedCity.isNotEmpty) query['city'] = normalizedCity;
    if (lat != null && lon != null) {
      query['lat'] = lat.toString();
      query['lon'] = lon.toString();
    }
    if (query.isEmpty) {
      throw WeatherApiException('Ingresa una ciudad o coordenadas.');
    }

    final uri = Uri.parse('$_baseUrl/weather/').replace(queryParameters: query);
    final res = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);

    final data = _decode(res);
    final current = _extractCurrent(data);

    final cityName =
        (data['city'] ?? data['name'] ?? normalizedCity).toString();
    final country = (data['country'] ?? data['country_code'] ?? '').toString();

    return WeatherSnapshot(
      city: cityName.isEmpty ? normalizedCity : cityName,
      country: country,
      temperature: _asDouble(_pick(current, [
        'temperature',
        'temperature_2m',
        'temp',
      ])),
      feelsLike: _asDouble(_pick(current, [
        'feels_like',
        'apparent_temperature',
        'feelsLike',
      ])),
      humidity: _asInt(_pick(current, [
        'humidity',
        'relative_humidity_2m',
      ])),
      windSpeed: _asDouble(_pick(current, [
        'wind_speed',
        'wind_speed_10m',
        'windSpeed',
      ])),
      weatherCode: _asInt(_pick(current, [
        'weather_code',
        'code',
      ])),
      isDay: _asBool(_pick(current, [
        'is_day',
        'isDay',
      ])),
      daily: _parseDaily(data['daily'] ?? data['forecast'] ?? data['days']),
    );
  }

  /// Convierte la respuesta JSON en un mapa valido o lanza excepcion tipada.
  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.trim();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw WeatherApiException(
        'Error consultando clima.',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw WeatherApiException('Respuesta invalida del clima.');
    }
    return decoded;
  }

  /// Algunos backends anidan `current`; otros devuelven el clima al nivel raiz.
  Map<String, dynamic> _extractCurrent(Map<String, dynamic> data) {
    final current = data['current'];
    if (current is Map<String, dynamic>) return current;
    return data;
  }

  /// Busca la primera clave disponible dentro de un conjunto equivalente.
  dynamic _pick(Map<String, dynamic> src, List<String> keys) {
    for (final key in keys) {
      final value = src[key];
      if (value != null) return value;
    }
    return null;
  }

  /// Soporta forecast como lista de objetos o como arrays paralelos tipo Open-Meteo.
  List<WeatherDaily> _parseDaily(dynamic raw) {
    // Lista de objetos {date,max,min,weather_code}
    if (raw is List) {
      final list = <WeatherDaily>[];
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final date = (item['date'] ?? item['time'] ?? '').toString();
        if (date.isEmpty) continue;
        list.add(
          WeatherDaily(
            date: date,
            maxTemp: _asDouble(_pick(item, [
              'max',
              'max_temp',
              'temperature_2m_max',
            ])),
            minTemp: _asDouble(_pick(item, [
              'min',
              'min_temp',
              'temperature_2m_min',
            ])),
            weatherCode: _asInt(_pick(item, [
              'weather_code',
              'code',
            ])),
          ),
        );
      }
      if (list.isNotEmpty) return list;
    }

    // Formato Open-Meteo (arrays paralelos)
    if (raw is Map<String, dynamic>) {
      final times = raw['time'];
      final maxTemps = raw['temperature_2m_max'] ?? raw['max'];
      final minTemps = raw['temperature_2m_min'] ?? raw['min'];
      final codes = raw['weather_code'] ?? raw['code'];
      if (times is List &&
          maxTemps is List &&
          minTemps is List &&
          codes is List) {
        final length = [
          times.length,
          maxTemps.length,
          minTemps.length,
          codes.length,
        ].reduce((a, b) => a < b ? a : b);

        final list = <WeatherDaily>[];
        for (var i = 0; i < length; i++) {
          list.add(
            WeatherDaily(
              date: times[i].toString(),
              maxTemp: _asDouble(maxTemps[i]),
              minTemp: _asDouble(minTemps[i]),
              weatherCode: _asInt(codes[i]),
            ),
          );
        }
        return list;
      }
    }

    return const [];
  }

  /// Convierte numeros tolerando strings enviados por el backend.
  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  /// Convierte enteros tolerando strings y decimales.
  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  /// Acepta bool, numeros y strings comunes usados por APIs heterogeneas.
  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }
    return false;
  }
}
