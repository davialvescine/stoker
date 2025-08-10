import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../models/movement.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/movement_provider.dart';
import '../common/custom_snackbar.dart';

class CheckinDialog extends StatefulWidget {
  // MUDANÇA: O item agora é opcional (pode ser nulo)
  final Item? item;

  const CheckinDialog({super.key, this.item});

  @override
  State<CheckinDialog> createState() => _CheckinDialogState();
}

class _CheckinDialogState extends State<CheckinDialog> {
  bool _isLoading = false;
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    // Delay pre-selection until after the first frame and providers are ready
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
            _selectedItemId = null; // Item not borrowed, so don't pre-select
          });
        }
      }
    });
  }

  Future<void> _performCheckin() async {
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
      type: 'checkin',
      date: DateTime.now(),
    );

    await movementProvider.addMovement(movement, inventoryProvider);
    await inventoryProvider.updateItemStatus(selectedItem.id, "Disponível");

    if (!mounted) return;
    await inventoryProvider.fetch();
    await movementProvider.fetch();

    if (!mounted) return;
    CustomSnackBar.show(context, message: 'Devolução realizada com sucesso!');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Se um item foi passado, mostra uma confirmação simples.
    // Senão, mostra um dropdown para seleção.
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Receber Devolução',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading || _selectedItemId == null
                          ? null
                          : _performCheckin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirmar'),
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
