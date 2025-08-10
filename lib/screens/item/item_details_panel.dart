import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/item.dart';
import '../../providers/movement_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/dialogs/modern_edit_item_dialog.dart';
import '../../widgets/dialogs/modern_delete_item_dialog.dart';
import '../../widgets/dialogs/modern_borrow_dialog.dart';
import '../../widgets/dialogs/modern_return_dialog.dart';
import '../../widgets/item/info_row.dart';

class ItemDetailsPanel extends StatelessWidget {
  final Item item;
  final VoidCallback onClose;

  const ItemDetailsPanel({
    super.key,
    required this.item,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final movements = context
        .watch<MovementProvider>()
        .items
        .where((m) => m.itemId == item.id)
        .toList();
    final borrowers = context.watch<BorrowerProvider>();

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QR Code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: 'stoker_item_${item.id}',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Informações
                  _buildInfoSection('Informações do Item', [
                    InfoRow(
                      'Status',
                      item.status,
                      _getStatusColor(item.status),
                    ),
                    InfoRow('Categoria', item.category),
                    InfoRow('Tipo', item.type),
                    if (item.location != null && item.location!.isNotEmpty)
                      InfoRow('Localização', item.location!),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      InfoRow('Observações', item.notes!),
                  ]),
                  const SizedBox(height: 24),
                  // Histórico
                  _buildInfoSection(
                    'Histórico de Movimentações',
                    movements.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhuma movimentação registrada',
                                style: TextStyle(color: kTextSecondary),
                              ),
                            ),
                          ]
                        : movements.map((movement) {
                            final borrower = borrowers.getBorrowerById(
                              movement.borrowerId,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    movement.type == "Devolução"
                                    ? kWarningColor
                                    : kSuccessColor,
                                child: Icon(
                                  movement.type == "Devolução"
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                movement.type == "Devolução"
                                    ? 'Devolvido por ${borrower?.name ?? "Desconhecido"}'
                                    : 'Emprestado para ${borrower?.name ?? "Desconhecido"}',
                              ),
                              subtitle: Text(
                                '${movement.date.day}/${movement.date.month}/${movement.date.year} às ${movement.date.hour}:${movement.date.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Ações
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Editar',
                          icon: Icons.edit,
                          backgroundColor: Colors.orange,
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) => ModernEditItemDialog(item: item),
                            );
                            if (result == true && context.mounted) {
                              onClose();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Deletar',
                          icon: Icons.delete,
                          backgroundColor: kErrorColor,
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  ModernDeleteItemDialog(item: item),
                            );
                            if (result == true && context.mounted) {
                              onClose();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: item.status == "Disponível"
                        ? 'Realizar Empréstimo'
                        : 'Realizar Devolução',
                    icon: item.status == "Disponível"
                        ? Icons.output
                        : Icons.input,
                    backgroundColor: item.status == "Disponível"
                        ? kSuccessColor
                        : kWarningColor,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => item.status == "Disponível"
                            ? ModernBorrowDialog(item: item)
                            : ModernReturnDialog(item: item),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

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
}
