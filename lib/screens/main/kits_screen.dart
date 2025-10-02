import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/kit.dart';
import '../../providers/kit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/dialogs/add_kit_dialog.dart';
import '../../widgets/dialogs/edit_kit_dialog.dart';
import '../../widgets/dialogs/delete_kit_dialog.dart';
import '../../widgets/dialogs/modern_borrow_dialog.dart';

class KitsScreen extends StatelessWidget {
  const KitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kitProvider = context.watch<KitProvider>();
    final kits = kitProvider.kits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final inventory = context.read<InventoryProvider>();
              await kitProvider.fetch(inventory.items);
            },
          ),
        ],
      ),
      body: kitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : kits.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    final inventory = context.read<InventoryProvider>();
                    await kitProvider.fetch(inventory.items);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: kits.length,
                    itemBuilder: (context, index) {
                      return _KitCard(kit: kits[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddKitDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo Kit'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum kit criado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie kits para agrupar equipamentos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddKitDialog(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeiro Kit'),
          ),
        ],
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  final Kit kit;

  const _KitCard({required this.kit});

  @override
  Widget build(BuildContext context) {
    final availableCount = kit.items.where((i) => i.status == 'Disponível').length;
    final totalCount = kit.items.length;
    final allAvailable = availableCount == totalCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: allAvailable ? kSuccessColor : kWarningColor,
          child: Icon(
            Icons.inventory_2,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          kit.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '$totalCount ${totalCount == 1 ? 'item' : 'itens'} • $availableCount disponível${availableCount != 1 ? 'is' : ''}',
          style: TextStyle(
            color: allAvailable ? kSuccessColor : kTextSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSuccessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Disponível',
                  style: TextStyle(
                    color: kSuccessColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kWarningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Parcial',
                  style: TextStyle(
                    color: kWarningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itens do Kit:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...kit.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            item.status == 'Disponível'
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 18,
                            color: item.status == 'Disponível'
                                ? kSuccessColor
                                : kWarningColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.status == 'Disponível'
                                  ? kSuccessColor
                                  : kWarningColor,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(context),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Excluir'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showEditDialog(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: allAvailable
                          ? () => showModernBorrowDialog(context, item: null)
                          : null,
                      icon: const Icon(Icons.assignment_turned_in, size: 18),
                      label: const Text('Emprestar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditKitDialog(kit: kit),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DeleteKitDialog(kit: kit),
    );
  }
}
