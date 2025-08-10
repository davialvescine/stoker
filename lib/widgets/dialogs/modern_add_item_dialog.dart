import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../models/item.dart';
import '../../providers/inventory_provider.dart';
import '../common/custom_snackbar.dart';

class ModernAddItemDialog extends StatefulWidget {
  const ModernAddItemDialog({super.key});

  @override
  State<ModernAddItemDialog> createState() => _ModernAddItemDialogState();
}

class _ModernAddItemDialogState extends State<ModernAddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _serialNumberController = TextEditingController();
  String _selectedType = AppStrings.equipment;
  String _selectedCategory = AppStrings.categories.first;
  bool _isInsured = false;
  Item? _selectedMainItem;
  bool _isLoading = false;
  XFile? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final itemToAdd = Item(
      id: '', // O ID será gerado pelo Supabase
      name: _nameController.text.trim(),
      type: _selectedType,
      category: _selectedCategory,
      status: AppStrings.available,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      serialNumber: _serialNumberController.text.trim(),
      isInsured: _isInsured,
      mainItemId: _selectedMainItem?.id,
    );

    final success = await context.read<InventoryProvider>().addItem(
      itemToAdd,
      imageFile: _selectedImage,
    );
    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Item adicionado com sucesso!');
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao adicionar o item.',
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adicionar Novo Item',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Item',
                        ),
                        validator: (value) =>
                            Validators.required(value, 'Nome'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: [AppStrings.equipment, AppStrings.accessory]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items: AppStrings.categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                      TextFormField(
                        controller: _serialNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Série (Opcional)',
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Item Assegurado'),
                        value: _isInsured,
                        onChanged: (value) => setState(() => _isInsured = value),
                      ),
                      if (_selectedType == AppStrings.accessory)
                        Consumer<InventoryProvider>(
                          builder: (context, inventoryProvider, child) {
                            final mainItems = inventoryProvider.items
                                .where((item) => item.type == AppStrings.equipment)
                                .toList();
                            return DropdownButtonFormField<Item>(
                              value: _selectedMainItem,
                              decoration: const InputDecoration(
                                labelText: 'Item Principal (Opcional)',
                              ),
                              items: mainItems
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (item) =>
                                  setState(() => _selectedMainItem = item),
                            );
                          },
                        ),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Localização (Opcional)',
                        ),
                      ),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações (Opcional)',
                        ),
                        maxLines: 3,
                      ),
                    ],
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
                        onPressed: _isLoading ? null : _addItem,
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
                            : const Text('Adicionar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _selectedImage != null
              ? (kIsWeb
                    ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.grey.shade600,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicionar Foto',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
