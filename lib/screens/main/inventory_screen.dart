import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../models/item.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/dialogs/modern_add_item_dialog.dart';
import '../../widgets/dialogs/modern_borrow_dialog.dart';
import '../../widgets/dialogs/modern_return_dialog.dart';
import '../item/item_details_screen.dart';
import '../item/batch_movement_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true; // New state variable for layout toggle

  @override
  void initState() {
    super.initState();
    final provider = context.read<InventoryProvider>();
    _searchController.addListener(
      () => provider.search(_searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final groupedItems = inventoryProvider.groupedItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventário'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_on),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar item...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: inventoryProvider.isLoading && groupedItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : groupedItems.isEmpty
          ? const Center(child: Text('Nenhum item encontrado.'))
          : RefreshIndicator(
              onRefresh: () => inventoryProvider.fetch(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedItems.length,
                itemBuilder: (context, index) {
                  final entry = groupedItems[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 12.0,
                          top: index > 0 ? 24.0 : 0,
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _isGridView
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        ResponsiveHelper.getGridColumns(
                                          context,
                                        ),
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: entry.value.length,
                              itemBuilder: (context, itemIndex) {
                                return _ItemGridCard(
                                  item: entry.value[itemIndex],
                                );
                              },
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entry.value.length,
                              itemBuilder: (context, itemIndex) {
                                return _ItemListTile(
                                  item: entry.value[itemIndex],
                                );
                              },
                            ),
                    ],
                  );
                },
              ),
            ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_shopping_cart),
            label: 'Novo Empréstimo',
            onTap: () => showModernBorrowDialog(context, item: null),
          ),
          SpeedDialChild(
            child: const Icon(Icons.remove_shopping_cart),
            label: 'Nova Devolução',
            onTap: () => showModernReturnDialog(context, item: null),
          ),
          SpeedDialChild(
            child: const Icon(Icons.playlist_add_check),
            label: 'Empréstimo em Lote',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BatchMovementScreen(
                  movementType: 'Empréstimo',
                ),
              ),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.playlist_add),
            label: 'Devolução em Lote',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BatchMovementScreen(
                  movementType: 'Devolução',
                ),
              ),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Novo Item',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ModernAddItemDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemGridCard extends StatelessWidget {
  final Item item;
  const _ItemGridCard({required this.item});

  Color _getStatusColor(String status) {
    switch (status) {
      case "Disponível":
        return kSuccessColor;
      case "Emprestado":
        return kWarningColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailsScreen(itemId: item.id)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.camera_alt, color: Colors.grey),
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemListTile extends StatelessWidget {
  final Item item;
  const _ItemListTile({required this.item});

  Color _getStatusColor(String status) {
    switch (status) {
      case "Disponível":
        return kSuccessColor;
      case "Emprestado":
        return kWarningColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.camera_alt, color: Colors.grey),
                    ),
                  ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.category),
            Text(
              'Status: ${item.status}',
              style: TextStyle(color: _getStatusColor(item.status)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailsScreen(itemId: item.id),
            ),
          );
        },
      ),
    );
  }
}