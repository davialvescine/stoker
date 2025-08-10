import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/kit_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/hover_card.dart';
import '../../widgets/common/responsive_wrapper.dart';
import '../../widgets/common/status_card.dart';
import '../../widgets/dialogs/batch_print_dialog.dart';
import '../../widgets/dialogs/checkout_dialog.dart';
import '../../widgets/dialogs/checkin_dialog.dart';
import '../scanner/qr_scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refreshData(BuildContext context) async {
    await Future.wait([
      context.read<InventoryProvider>().fetch(),
      context.read<BorrowerProvider>().fetch(),
      context.read<MovementProvider>().fetch(),
    ]);

    if (!context.mounted) return;

    final allItems = context.read<InventoryProvider>().items;
    await context.read<KitProvider>().fetch(allItems);
  }

  void _showBatchPrintDialog(BuildContext context) {
    final inventory = context.read<InventoryProvider>();
    if (inventory.items.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Nenhum item disponível para impressão',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => BatchPrintDialog(items: inventory.items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final borrowers = context.watch<BorrowerProvider>();
    final movements = context.watch<MovementProvider>();
    final kits = context.watch<KitProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body:
          (inventory.isLoading ||
                  borrowers.isLoading ||
                  movements.isLoading ||
                  kits.isLoading) &&
              inventory.items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : RefreshIndicator(
              onRefresh: () => _refreshData(context),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ResponsiveWrapper(
                    child: GridView.count(
                      crossAxisCount: ResponsiveHelper.getGridColumns(context),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: ResponsiveHelper.isDesktop(context)
                          ? 1.5
                          : 1.1,
                      children: [
                        StatusCard(
                          title: 'Total de Itens',
                          value: inventory.items.length.toString(),
                          icon: Icons.inventory_2,
                          color: kPrimaryColor,
                        ),
                        StatusCard(
                          title: 'Disponíveis',
                          value: inventory.availableItems.length.toString(),
                          icon: Icons.check_circle,
                          color: kSuccessColor,
                        ),
                        StatusCard(
                          title: 'Emprestados',
                          value: inventory.borrowedItems.length.toString(),
                          icon: Icons.schedule,
                          color: kWarningColor,
                        ),
                        StatusCard(
                          title: 'Mutuários',
                          value: borrowers.items.length.toString(),
                          icon: Icons.people,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ResponsiveWrapper(
                    maxWidth: 800,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ações Rápidas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!kIsWeb || !ResponsiveHelper.isMobile(context))
                          CustomButton(
                            text: 'Escanear QR Code',
                            icon: Icons.qr_code_scanner,
                            backgroundColor: Colors.purple,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QRScannerScreen(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Imprimir Etiquetas em Lote',
                          icon: Icons.print,
                          backgroundColor: Colors.teal,
                          onPressed: () => _showBatchPrintDialog(context),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveHelper.isMobile(context)
                            ? Column(
                                children: [
                                  CustomButton(
                                    text: '➡️ Check-out',
                                    icon: Icons.output,
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => const CheckoutDialog(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    text: '⬅️ Check-in',
                                    icon: Icons.input,
                                    backgroundColor: kSuccessColor,
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => const CheckinDialog(),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Fazer Emprestimo',
                                      icon: Icons.output,
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => const CheckoutDialog(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Receber Devolução',
                                      icon: Icons.input,
                                      backgroundColor: kSuccessColor,
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => const CheckinDialog(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ResponsiveWrapper(
                    maxWidth: 800,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Últimas Movimentações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (movements.items.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'Nenhuma movimentação ainda.',
                                  style: TextStyle(color: kTextSecondary),
                                ),
                              ),
                            ),
                          )
                        else
                          ...movements.recentMovements.map((movement) {
                            final item = inventory.getItemById(movement.itemId);
                            final borrower = borrowers.getBorrowerById(
                              movement.borrowerId,
                            );

                            return HoverCard(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: movement.type == "checkout"
                                      ? kWarningColor
                                      : kSuccessColor,
                                  child: Icon(
                                    movement.type == "checkout"
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  item?.name ?? 'Item não encontrado',
                                ),
                                subtitle: Text(
                                  '${movement.type == "checkout" ? "Para" : "De"} ${borrower?.name ?? "Desconhecido"}',
                                ),
                                trailing: Text(
                                  '${movement.date.day}/${movement.date.month}',
                                  style: const TextStyle(color: kTextSecondary),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
