// lib/screens/main/status_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/borrower.dart';
import '../../models/item.dart';
import '../../models/movement.dart';
import '../../providers/borrower_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/movement_provider.dart';
import '../../core/utils/responsive_helper.dart';
import '../../widgets/item_status_card.dart';
import '../../core/extensions/image_chunk_event_extension.dart';
import '../item/item_details_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true; // New state variable for layout toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final availableItems = inventoryProvider.availableItems;
    final borrowedItems = inventoryProvider.borrowedItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status dos Itens'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Disponíveis (${availableItems.length})'),
            Tab(text: 'Emprestados (${borrowedItems.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ItemsStatusView(
            items: availableItems,
            displayStatus: ItemDisplayStatus.available,
            isGridView: _isGridView,
          ),
          _ItemsStatusView(
            items: borrowedItems,
            displayStatus: ItemDisplayStatus.borrowed,
            isGridView: _isGridView,
          ),
        ],
      ),
    );
  }
}

class _ItemsStatusView extends StatelessWidget {
  final List<Item> items;
  final ItemDisplayStatus displayStatus;
  final bool isGridView;

  const _ItemsStatusView({
    required this.items,
    required this.displayStatus,
    required this.isGridView,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          displayStatus == ItemDisplayStatus.available
              ? 'Nenhum item disponível no momento.'
              : 'Nenhum item emprestado no momento.',
          style: const TextStyle(color: kTextSecondary),
        ),
      );
    }

    return isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.getGridColumns(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ItemStatusCard(item: item, displayStatus: displayStatus);
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _StatusItemListTile(
                item: item,
                displayStatus: displayStatus,
              );
            },
          );
  }
}

class _StatusItemListTile extends StatelessWidget {
  final Item item;
  final ItemDisplayStatus displayStatus;

  const _StatusItemListTile({required this.item, required this.displayStatus});

  @override
  Widget build(BuildContext context) {
    Movement? lastMovement;
    Borrower? borrower;

    if (displayStatus == ItemDisplayStatus.borrowed) {
      final movementProvider = context.watch<MovementProvider>();
      final borrowerProvider = context.watch<BorrowerProvider>();
      try {
        lastMovement = movementProvider.items.lastWhere(
          (m) => m.itemId == item.id && m.type == 'checkout',
        );
        borrower = borrowerProvider.getBorrowerById(lastMovement.borrowerId);
      } catch (e) {
        debugPrint('Erro ao buscar movimento ou mutuário: $e');
      }
    }

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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.sum(
                            loadingProgress.cumulativeBytesLoaded,
                            loadingProgress.expectedTotalBytes ?? 1,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
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
        subtitle: displayStatus == ItemDisplayStatus.available
            ? Text(item.category)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Com: ${borrower?.name ?? "Desconhecido"}',
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                  Text(
                    'Desde: ${lastMovement != null ? "${lastMovement.date.day}/${lastMovement.date.month}/${lastMovement.date.year}" : "Data desconhecida"}',
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
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
