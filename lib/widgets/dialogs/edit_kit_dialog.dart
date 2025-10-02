import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/item.dart';
import '../../models/kit.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/kit_provider.dart';
import '../common/custom_snackbar.dart';

class EditKitDialog extends StatefulWidget {
  final Kit kit;

  const EditKitDialog({super.key, required this.kit});

  @override
  State<EditKitDialog> createState() => _EditKitDialogState();
}

class _EditKitDialogState extends State<EditKitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final Set<Item> _selectedItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kit.name);
    _selectedItems = Set<Item>.from(widget.kit.items);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateKit() async {
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

    final success = await kitProvider.updateKit(
      widget.kit.id,
      _nameController.text.trim(),
      itemIds,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Kit atualizado com sucesso!');
      await kitProvider.fetch(inventoryProvider.items);
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao atualizar o kit.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = context.watch<InventoryProvider>().items;

    return AlertDialog(
      insetPadding: ResponsiveHelper.isLargeScreen(context)
          ? const EdgeInsets.symmetric(horizontal: 200, vertical: 100)
          : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      title: const Text('Editar Kit'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selecione os itens para o kit:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedItems.length} selecionado${_selectedItems.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: allItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum item disponível.',
                              style: TextStyle(color: kTextSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              return CheckboxListTile(
                                title: Text(item.name),
                                subtitle: Text('${item.category} • ${item.status}'),
                                value: _selectedItems.contains(item),
                                secondary: Icon(
                                  item.status == 'Disponível'
                                      ? Icons.check_circle
                                      : Icons.info,
                                  color: item.status == 'Disponível'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
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
          onPressed: _isLoading ? null : _updateKit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
