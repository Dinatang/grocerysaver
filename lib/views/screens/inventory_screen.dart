import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../models/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();

    // 🔹 Reemplaza 1 por el ID real del usuario logueado
    Future.microtask(() {
      context.read<InventoryViewModel>().fetchInventory(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryVM = context.watch<InventoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
      ),
      body: _buildBody(inventoryVM),
    );
  }

  Widget _buildBody(InventoryViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (vm.inventory.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos en el inventario',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: vm.inventory.length,
      itemBuilder: (context, index) {
        final Product product = vm.inventory[index];

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text(product.nombre),
            subtitle: Text(
              'Cantidad: ${product.cantidad}\n'
              'Caduca: ${product.fechaCaducidad}',
            ),
          ),
        );
      },
    );
  }
}
