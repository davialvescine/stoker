import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive_helper.dart';
import '../../models/item.dart';
import '../../models/movement.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/kit_provider.dart';
import '../common/custom_snackbar.dart';

class CheckoutDialog extends StatefulWidget {
  // MUDANÇA: O item agora é opcional
  final Item? item;

  const CheckoutDialog({super.key, this.item});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedItemId;
  String? _selectedKitId;
  String? _selectedBorrowerId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.item != null ? 0 : 0,
    );

    // Delay pre-selection until after the first frame and providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.item != null) {
        final inventoryProvider = context.read<InventoryProvider>();
        if (inventoryProvider.availableItems.any(
          (item) => item.id == widget.item!.id,
        )) {
          setState(() {
            _selectedItemId = widget.item!.id;
          });
        } else {
          setState(() {
            _selectedItemId =
                null; // Item not available for checkout, so don't pre-select
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performCheckout() async {
    if (!mounted) return;

    final isKitCheckout = _tabController.index == 1;

    final inventoryProvider = context.read<InventoryProvider>();
    final kitProvider = context.read<KitProvider>();
    final borrowerProvider = context.read<BorrowerProvider>();

    final selectedBorrower = _selectedBorrowerId != null
        ? borrowerProvider.getBorrowerById(_selectedBorrowerId!)
        : null;

    if (selectedBorrower == null) {
      CustomSnackBar.show(context, message: 'Selecione um mutuário.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final movementProvider = context.read<MovementProvider>();
    bool success = false;

    try {
      if (isKitCheckout) {
        final selectedKit = _selectedKitId != null
            ? kitProvider.kits.firstWhere((kit) => kit.id == _selectedKitId!)
            : null;

        if (selectedKit == null) {
          CustomSnackBar.show(context, message: 'Selecione um kit.', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final itemIds = selectedKit.items
            .where((item) => item.status == 'Disponível')
            .map((item) => item.id)
            .toList();

        if (itemIds.isEmpty) {
          if (context.mounted) {
            CustomSnackBar.show(
              context,
              message: 'Todos os itens deste kit já estão emprestados.',
              isError: true,
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        success = await movementProvider.addMovementsForItems(
          itemIds: itemIds,
          borrowerId: selectedBorrower.id,
          movementType: 'Empréstimo',
          newStatus: 'Emprestado',
          inventoryProvider: inventoryProvider,
        );
      } else {
        final selectedItem = _selectedItemId != null
            ? inventoryProvider.availableItems
                .firstWhere((item) => item.id == _selectedItemId!)
            : null;

        if (selectedItem == null) {
          CustomSnackBar.show(context, message: 'Selecione um item.', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        success = await movementProvider.addMovement(
          Movement(
            id: '',
            itemId: selectedItem.id,
            borrowerId: selectedBorrower.id,
            type: 'Empréstimo',
            date: DateTime.now(),
          ),
          inventoryProvider,
        );
      }
    } catch (e) {
      debugPrint('Erro no Emprestimo: $e');
      success = false;
    }

    if (!mounted) return;

    if (success) {
      await Future.wait([
        context.read<InventoryProvider>().fetch(),
        context.read<MovementProvider>().fetch(),
      ]);

      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: 'Emprestimo realizado com sucesso!',
      );
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context,
        message: 'Falha no emprestimo.',
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
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.isLargeScreen(context)
                ? 500
                : double.infinity,
          ),
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
                  'Realizar Empréstimo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.item == null) ...[
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Item'),
                      Tab(text: 'Kit'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Consumer<InventoryProvider>(
                          builder: (context, inventory, child) {
                            final currentSelectedItem =
                                inventory.availableItems.any(
                                  (item) => item.id == _selectedItemId,
                                )
                                ? _selectedItemId
                                : null;
                            return DropdownButtonFormField<String>(
                              value: currentSelectedItem,
                              hint: const Text('Selecione um item'),
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: inventory.availableItems
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.id,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (itemId) =>
                                  setState(() => _selectedItemId = itemId),
                            );
                          },
                        ),
                        Consumer<KitProvider>(
                          builder: (context, kitProvider, child) =>
                              DropdownButtonFormField<String>(
                                value: _selectedKitId,
                                hint: const Text('Selecione um kit'),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: kitProvider.kits
                                    .map(
                                      (kit) => DropdownMenuItem(
                                        value: kit.id,
                                        child: Text(kit.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (kitId) =>
                                    setState(() => _selectedKitId = kitId),
                              ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      "Item a ser emprestado",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Text(
                      widget.item!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Consumer<BorrowerProvider>(
                  builder: (context, borrowers, child) =>
                      DropdownButtonFormField<String>(
                        value: _selectedBorrowerId,
                        hint: const Text('Selecione um mutuário'),
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: borrowers.items
                            .map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            )
                            .toList(),
                        onChanged: (borrowerId) =>
                            setState(() => _selectedBorrowerId = borrowerId),
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
                      onPressed: _isLoading ? null : _performCheckout,
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirmar'),
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
}
