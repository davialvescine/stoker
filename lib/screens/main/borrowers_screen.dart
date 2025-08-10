import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';

import '../../providers/borrower_provider.dart';
import '../../widgets/common/hover_card.dart';
import '../../widgets/common/responsive_wrapper.dart';
import '../../widgets/dialogs/add_borrower_dialog.dart';
import '../../widgets/dialogs/edit_borrower_dialog.dart';
import '../../widgets/dialogs/delete_borrower_dialog.dart';

class BorrowersScreen extends StatelessWidget {
  const BorrowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BorrowerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mutuários')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetch(),
        child: provider.isLoading && provider.items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : provider.items.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum mutuário cadastrado.',
                  style: TextStyle(color: kTextSecondary),
                ),
              )
            : ResponsiveWrapper(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final borrower = provider.items[index];
                    return HoverCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Text(
                            borrower.name.isNotEmpty
                                ? borrower.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('Nome: ${borrower.name}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (borrower.email != null &&
                                borrower.email!.isNotEmpty)
                              Text('Email: ${borrower.email!}'),
                            if (borrower.phone != null &&
                                borrower.phone!.isNotEmpty)
                              Text('Telefone: ${borrower.phone!}'),
                            if (borrower.company != null &&
                                borrower.company!.isNotEmpty)
                              Text('Empresa: ${borrower.company!}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    EditBorrowerDialog(borrower: borrower),
                              );
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    DeleteBorrowerDialog(borrower: borrower),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Deletar'),
                                ),
                              ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddBorrowerDialog(),
        ),
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
