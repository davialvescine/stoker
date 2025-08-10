import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/item.dart';

class BatchOperationsScreen extends StatefulWidget {
  const BatchOperationsScreen({super.key});

  @override
  State<BatchOperationsScreen> createState() => _BatchOperationsScreenState();
}

class _BatchOperationsScreenState extends State<BatchOperationsScreen> {
  final List<Item> _selectedItems = [];

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final items = inventoryProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operações em Lote'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return CheckboxListTile(
                  title: Text(item.name),
                  subtitle: Text(item.category),
                  value: _selectedItems.contains(item),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems.add(item);
                      } else {
                        _selectedItems.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _selectedItems.isNotEmpty ? () {} : null,
                  child: const Text('Registrar Empréstimo'),
                ),
                ElevatedButton(
                  onPressed: _selectedItems.isNotEmpty ? () {} : null,
                  child: const Text('Registrar Devolução'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
