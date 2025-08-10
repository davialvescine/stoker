
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movement.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../models/item.dart';
import '../../models/borrower.dart';

class BatchMovementScreen extends StatefulWidget {
  final String movementType; // "Empréstimo" ou "Devolução"

  const BatchMovementScreen({super.key, required this.movementType});

  @override
  State<BatchMovementScreen> createState() => _BatchMovementScreenState();
}

class _BatchMovementScreenState extends State<BatchMovementScreen> {
  final List<Item> _selectedItems = [];
  Borrower? _selectedBorrower;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final borrowerProvider = Provider.of<BorrowerProvider>(context, listen: false);
    final items = widget.movementType == 'Empréstimo'
        ? inventoryProvider.availableItems
        : inventoryProvider.borrowedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.movementType} em Lote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedItems.isNotEmpty &&
                    (widget.movementType == 'Devolução' ||
                        _selectedBorrower != null)
                ? _executeBatchMovement
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.movementType == 'Empréstimo')
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<Borrower>(
                      value: _selectedBorrower,
                      hint: const Text('Selecione um mutuário'),
                      items: borrowerProvider.items
                          .map((borrower) => DropdownMenuItem(
                                value: borrower,
                                child: Text(borrower.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBorrower = value;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = _selectedItems.contains(item);
                      return CheckboxListTile(
                        title: Text(item.name),
                        subtitle: Text(item.category),
                        value: isSelected,
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
              ],
            ),
    );
  }

  Future<void> _executeBatchMovement() async {
    setState(() {
      _isLoading = true;
    });

    final movementProvider = context.read<MovementProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    

    bool success = true;

    if (widget.movementType == 'Devolução') {
      for (final item in _selectedItems) {
        final lastMovement = await movementProvider.getLastMovement(item.id);
        if (lastMovement != null) {
          final result = await movementProvider.addMovement(
            Movement(
              id: '',
              itemId: item.id,
              borrowerId: lastMovement.borrowerId,
              type: 'Devolução',
              date: DateTime.now(),
              userId: movementProvider.supabase.auth.currentUser!.id,
            ),
            inventoryProvider,
          );
          if (!result) success = false;
        } else {
          success = false; // Falha se não encontrar movimento anterior
        }
      }
    } else {
      final itemIds = _selectedItems.map((item) => item.id).toList();
      final borrowerId = _selectedBorrower!.id;
      success = await movementProvider.addMovementsForItems(
        itemIds: itemIds,
        borrowerId: borrowerId,
        movementType: widget.movementType,
        newStatus: 'Emprestado',
        inventoryProvider: inventoryProvider,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.movementType} em lote realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao realizar ${widget.movementType} em lote.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}
