import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/product_model.dart';

class InventoryViewModel extends ChangeNotifier {
  final InventoryService _inventoryService;

  InventoryViewModel(this._inventoryService);

  bool isLoading = false;
  String? errorMessage;

  List<Product> inventory = [];

  /// Obtener inventario por usuario
  Future<void> fetchInventory(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _inventoryService.getInventory(userId);

      if (result['status'] == 'success') {
        inventory = (result['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        errorMessage = result['message'] ?? 'No se pudo obtener el inventario';
      }
    } catch (e) {
      errorMessage = 'Error de conexión con el servidor';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Limpiar inventario (logout o refresh)
  void clearInventory() {
    inventory.clear();
    notifyListeners();
  }
}
