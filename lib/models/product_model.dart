class Product {
  final int id;
  final String nombre;
  final int cantidad;
  final String fechaCaducidad;

  Product({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.fechaCaducidad,
  });

  /// Crear objeto desde JSON (API → App)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.parse(json['id'].toString()),
      nombre: json['nombre'],
      cantidad: int.parse(json['cantidad'].toString()),
      fechaCaducidad: json['fecha_caducidad'],
    );
  }

  /// Convertir objeto a JSON (App → API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cantidad': cantidad,
      'fecha_caducidad': fechaCaducidad,
    };
  }
}
