import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kit_provider.dart';
import '../common/custom_snackbar.dart';

class AddKitDialog extends StatefulWidget {
  const AddKitDialog({super.key});

  @override
  State<AddKitDialog> createState() => _AddKitDialogState();
}

class _AddKitDialogState extends State<AddKitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<Item> _selectedItems = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createKit() async {
    if (!_formKey.currentState!.validate() || _selectedItems.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Preencha o nome e selecione pelo menos um item.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final itemIds = _selectedItems.map((item) => item.id).toList();
    final kitProvider = context.read<KitProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    final success = await kitProvider.createKit(
      _nameController.text.trim(),
      itemIds,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Kit criado com sucesso!');
      await kitProvider.fetch(inventoryProvider.items);
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao criar o kit.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableItems = context.watch<InventoryProvider>().availableItems;

    return AlertDialog(
      insetPadding: ResponsiveHelper.isLargeScreen(context)
          ? const EdgeInsets.symmetric(horizontal: 200, vertical: 100)
          : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      title: const Text('Criar Novo Kit'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Kit',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'Nome do Kit'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecione os itens para o kit:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: availableItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum item disponível.',
                              style: TextStyle(color: kTextSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableItems.length,
                            itemBuilder: (context, index) {
                              final item = availableItems[index];
                              return CheckboxListTile(
                                title: Text(item.name),
                                subtitle: Text(item.category),
                                value: _selectedItems.contains(item),
                                onChanged: (isSelected) {
                                  setState(() {
                                    if (isSelected == true) {
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
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createKit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Criar Kit'),
        ),
      ],
    );
  }
}
