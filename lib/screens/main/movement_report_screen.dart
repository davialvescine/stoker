import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/borrower_provider.dart';

class MovementReportScreen extends StatelessWidget {
  const MovementReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movementProvider = Provider.of<MovementProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final borrowerProvider = Provider.of<BorrowerProvider>(context);
    final movements = movementProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Movimentações'),
      ),
      body: ListView.builder(
        itemCount: movements.length,
        itemBuilder: (context, index) {
          final movement = movements[index];
          final item = inventoryProvider.getItemById(movement.itemId);
          final borrower = borrowerProvider.getBorrowerById(movement.borrowerId);

          return ListTile(
            title: Text(item?.name ?? 'Item não encontrado'),
            subtitle: Text(
                '${movement.type} por ${borrower?.name ?? 'Mutuário não encontrado'} em ${movement.date}'),
          );
        },
      ),
    );
  }
}
