import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/borrower.dart';
import '../../providers/borrower_provider.dart';
import '../common/custom_snackbar.dart';

class AddBorrowerDialog extends StatefulWidget {
  const AddBorrowerDialog({super.key});

  @override
  State<AddBorrowerDialog> createState() => _AddBorrowerDialogState();
}

class _AddBorrowerDialogState extends State<AddBorrowerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  bool _isLoading = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _addBorrower() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<BorrowerProvider>().addBorrower(
      Borrower(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneFormatter.getUnmaskedText().isEmpty
            ? null
            : _phoneFormatter.getUnmaskedText(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
      ),
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Mutuário adicionado com sucesso!');
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao adicionar mutuário.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: ResponsiveHelper.isLargeScreen(context)
          ? const EdgeInsets.symmetric(horizontal: 200, vertical: 100)
          : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      title: const Text('Adicionar Mutuário'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.required(value, 'Nome'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.email(value);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Empresa (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addBorrower,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}
