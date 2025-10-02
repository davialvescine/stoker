import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kit.dart';
import '../../providers/kit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../common/custom_snackbar.dart';

class DeleteKitDialog extends StatefulWidget {
  final Kit kit;

  const DeleteKitDialog({super.key, required this.kit});

  @override
  State<DeleteKitDialog> createState() => _DeleteKitDialogState();
}

class _DeleteKitDialogState extends State<DeleteKitDialog> {
  bool _isLoading = false;

  Future<void> _deleteKit() async {
    setState(() => _isLoading = true);

    final kitProvider = context.read<KitProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    final success = await kitProvider.deleteKit(widget.kit.id);

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Kit excluído com sucesso!');
      await kitProvider.fetch(inventoryProvider.items);
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao excluir o kit.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir Kit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tem certeza que deseja excluir este kit?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Text(
                        '${widget.kit.items.length} ${widget.kit.items.length == 1 ? 'item' : 'itens'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Os itens não serão excluídos, apenas o agrupamento do kit.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteKit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Excluir'),
        ),
      ],
    );
  }
}
