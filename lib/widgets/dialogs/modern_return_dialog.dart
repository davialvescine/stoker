import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../models/movement.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/movement_provider.dart';
import '../common/custom_snackbar.dart';

Future<void> showModernReturnDialog(BuildContext context, {Item? item}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return ModernReturnDialog(item: item);
    },
  );
}

class ModernReturnDialog extends StatefulWidget {
  final Item? item;

  const ModernReturnDialog({super.key, this.item});

  @override
  State<ModernReturnDialog> createState() => _ModernReturnDialogState();
}

class _ModernReturnDialogState extends State<ModernReturnDialog> {
  bool _isLoading = false;
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.item != null) {
        final inventoryProvider = context.read<InventoryProvider>();
        if (inventoryProvider.borrowedItems.any(
          (item) => item.id == widget.item!.id,
        )) {
          setState(() {
            _selectedItemId = widget.item!.id;
          });
        } else {
          setState(() {
            _selectedItemId = null;
          });
        }
      }
    });
  }

  Future<void> _performReturn() async {
    if (_selectedItemId == null) {
      CustomSnackBar.show(
        context,
        message: 'Selecione um item para devolver.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final movementProvider = context.read<MovementProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    final selectedItem = inventoryProvider.borrowedItems.firstWhere(
      (item) => item.id == _selectedItemId!,
      orElse: () => throw Exception('Item emprestado não encontrado'),
    );

    final lastMovement = movementProvider.items.firstWhere(
      (m) => m.itemId == selectedItem.id && m.type == 'checkout',
      orElse: () => Movement(
        id: '',
        itemId: '',
        borrowerId: 'unknown',
        type: '',
        date: DateTime.now(),
      ),
    );

    final movement = Movement(
      id: '',
      itemId: selectedItem.id,
      borrowerId: lastMovement.borrowerId,
      type: 'Devolução',
      date: DateTime.now(),
    );

    final success = await movementProvider.addMovement(movement, inventoryProvider);

    if (!mounted) return;

    if (success) {
      await inventoryProvider.fetch();
      await movementProvider.fetch();

      if (!mounted) return;
      CustomSnackBar.show(context, message: 'Devolução registrada com sucesso!');
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha na devolução.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar Devolução',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.item != null)
                  Text(
                    'Confirmar a devolução do item: ${widget.item!.name}?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                else
                  Consumer<InventoryProvider>(
                    builder: (context, inventory, child) {
                      final currentSelectedItem =
                          inventory.borrowedItems.any(
                            (item) => item.id == _selectedItemId,
                          )
                          ? _selectedItemId
                          : null;
                      return DropdownButtonFormField<String>(
                        value: currentSelectedItem,
                        hint: const Text('Selecione o item a devolver'),
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: inventory.borrowedItems
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (itemId) =>
                            setState(() => _selectedItemId = itemId),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading || _selectedItemId == null
                          ? null
                          : _performReturn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Devolver'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}