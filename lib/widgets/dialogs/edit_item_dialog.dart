// lib/widgets/dialogs/edit_item_dialog.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/validators.dart';
import '../../models/item.dart';
import '../../providers/inventory_provider.dart';
import '../common/custom_snackbar.dart';

class EditItemDialog extends StatefulWidget {
  final Item item;
  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _locationController;
  late String _selectedType;
  late String _selectedCategory;

  bool _isLoading = false;
  XFile? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _notesController = TextEditingController(text: widget.item.notes);
    _locationController = TextEditingController(text: widget.item.location);
    _selectedType = widget.item.type;
    _selectedCategory = widget.item.category;
    _currentImageUrl = widget.item.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _deleteImage() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Foto'),
        content: const Text(
          'Tem certeza que deseja remover a foto deste item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    final provider = context.read<InventoryProvider>();
    final success = await provider.deleteItemImage(
      widget.item.id,
      _currentImageUrl,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _currentImageUrl = null;
          CustomSnackBar.show(context, message: 'Foto removida com sucesso!');
        });
      } else {
        CustomSnackBar.show(
          context,
          message: 'Falha ao remover a foto.',
          isError: true,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedItem = Item(
      id: widget.item.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      location: _locationController.text.trim(),
      status: widget.item.status,
      imageUrl: _currentImageUrl,
    );

    final provider = context.read<InventoryProvider>();
    final success = await provider.updateItem(
      updatedItem,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Item atualizado com sucesso!');
      Navigator.of(context).pop(true);
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao atualizar o item.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Editar Item',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Item',
                        ),
                        validator: (value) =>
                            Validators.required(value, 'Nome'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: ["Equipamento", "Acessório"]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items:
                            [
                                  "Câmeras",
                                  "Lentes",
                                  "Suporte",
                                  "Áudio",
                                  "Iluminação",
                                  "Outro",
                                ]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Localização (Opcional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações (Opcional)',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
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
                      onPressed: _isLoading ? null : _updateItem,
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
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar'),
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

  Widget _buildImagePicker() {
    return Stack(
      children: [
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImagePreview(),
            ),
          ),
        ),
        if (_currentImageUrl != null && _selectedImage == null)
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: _deleteImage,
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return kIsWeb
          ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
          : Image.file(File(_selectedImage!.path), fit: BoxFit.cover);
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(_currentImageUrl!, fit: BoxFit.cover);
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, color: Colors.grey),
        SizedBox(height: 8),
        Text('Adicionar/Alterar Foto', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
