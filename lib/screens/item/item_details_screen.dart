import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/colors.dart';
import '../../models/item.dart';
import '../../providers/inventory_provider.dart'; // Provider de inventário
import '../../providers/movement_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/dialogs/modern_borrow_dialog.dart';
import '../../widgets/dialogs/modern_return_dialog.dart';
import '../../widgets/dialogs/modern_edit_item_dialog.dart';
import '../../widgets/dialogs/modern_delete_item_dialog.dart';
import '../item/qr_label_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  // Alterado para receber o ID em vez do objeto inteiro, para evitar estado obsoleto
  final String itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    // --- MUDANÇA PRINCIPAL PARA ATUALIZAÇÃO DE ESTADO ---
    // Usamos 'context.watch' para que a tela reconstrua quando o provider notificar.
    // Buscamos o item mais recente diretamente do provider a cada reconstrução.
    final inventoryProvider = context.watch<InventoryProvider>();
    final Item item = inventoryProvider.getItemById(itemId)!;
    // --- FIM DA MUDANÇA ---

    final movements = context
        .watch<MovementProvider>()
        .items
        .where((m) => m.itemId == item.id)
        .toList();
    final borrowers = context.watch<BorrowerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QrLabelScreen(item: item)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- NOVO WIDGET PARA EXIBIR A IMAGEM ---
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 200,
                color: Colors.grey.shade200,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        // Mostra um indicador de progresso enquanto a imagem carrega
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        // Mostra um ícone de erro se a imagem não puder ser carregada
                        errorBuilder: (context, error, stackTrace) {
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Erro ao carregar imagem',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          );
                        },
                      )
                    : const Column(
                        // Placeholder se não houver imagem
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Nenhuma imagem',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- FIM DO NOVO WIDGET ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    QrImageView(
                      data: 'stoker_item_${item.id}',
                      version: QrVersions.auto,
                      size: 150.0,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ID: ${item.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMobileInfoRow(
                      'Status',
                      item.status,
                      _getStatusColor(item.status),
                    ),
                    _buildMobileInfoRow('Categoria', item.category),
                    _buildMobileInfoRow('Tipo', item.type),
                    if (item.location != null && item.location!.isNotEmpty)
                      _buildMobileInfoRow('Localização', item.location!),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      _buildMobileInfoRow('Observações', item.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Histórico Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (movements.isEmpty)
                      const Text(
                        'Nenhuma movimentação registrada',
                        style: TextStyle(color: kTextSecondary),
                      )
                    else
                      ...movements.take(5).map((movement) {
                        final borrower = borrowers.getBorrowerById(
                          movement.borrowerId,
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: movement.type == "checkout"
                                ? kWarningColor
                                : kSuccessColor,
                            child: Icon(
                              movement.type == "checkout"
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            movement.type == "checkout"
                                ? 'Para ${borrower?.name ?? "Desconhecido"}'
                                : 'De ${borrower?.name ?? "Desconhecido"}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${movement.date.day}/${movement.date.month}/${movement.date.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Ações
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Editar',
                    icon: Icons.edit,
                    backgroundColor: Colors.orange,
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (_) => ModernEditItemDialog(item: item),
                      );
                      // A tela já vai atualizar automaticamente por causa do 'watch'
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
                        builder: (_) => ModernDeleteItemDialog(item: item),
                      );
                      if (result == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ação baseada no status
            CustomButton(
              text: item.status == "Disponível"
                  ? 'Registrar Empréstimo'
                  : 'Registrar Devolução',
              icon: item.status == "Disponível" ? Icons.output : Icons.input,
              backgroundColor: item.status == "Disponível"
                  ? kSuccessColor
                  : kWarningColor,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => item.status == "Disponível"
                      // Passa o ID do item para o diálogo, se necessário
                      ? ModernBorrowDialog(item: item)
                      : ModernReturnDialog(item: item),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ... (o restante do código do arquivo, como _buildMobileInfoRow e _getStatusColor, permanece o mesmo) ...
  Widget _buildMobileInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
                fontSize: 14,
              ),
            ),
          ),
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
