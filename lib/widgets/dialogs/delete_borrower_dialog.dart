import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/borrower.dart';
import '../../providers/borrower_provider.dart';
import '../common/custom_snackbar.dart';

class DeleteBorrowerDialog extends StatefulWidget {
  final Borrower borrower;

  const DeleteBorrowerDialog({super.key, required this.borrower});

  @override
  State<DeleteBorrowerDialog> createState() => _DeleteBorrowerDialogState();
}

class _DeleteBorrowerDialogState extends State<DeleteBorrowerDialog> {
  bool _isLoading = false;

  Future<void> _deleteBorrower() async {
    setState(() => _isLoading = true);

    final success = await context.read<BorrowerProvider>().deleteBorrower(
      widget.borrower.id,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(context, message: 'Mutuário deletado com sucesso!');
      Navigator.of(context).pop(true);
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha ao deletar mutuário.',
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deletar Mutuário'),
      content: Text(
        'Tem certeza que deseja deletar o mutuário "${widget.borrower.name}"?',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteBorrower,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Deletar'),
        ),
      ],
    );
  }
}
