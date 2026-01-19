import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';

class InventoryService {
  Future<Map<String, dynamic>> getInventory(int userId) async {
    final url = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.inventoryEndpoint +
          '?usuario_id=$userId',
    );

    final response = await http.get(url);
    return jsonDecode(response.body);
  }
}
