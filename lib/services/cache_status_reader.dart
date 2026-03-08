// Helper pequeno para leer el estado de cache devuelto por el backend.
class CacheStatusReader {
  const CacheStatusReader._();

  /// Extrae el header `x-cache-status` si viene presente.
  static String? fromHeaders(Map<String, String> headers) {
    final value = headers['x-cache-status']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
