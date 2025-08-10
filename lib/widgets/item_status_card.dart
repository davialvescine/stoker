import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../models/item.dart';
import '../models/movement.dart';
import '../models/borrower.dart';
import '../providers/movement_provider.dart';
import '../providers/borrower_provider.dart';
import '../screens/item/item_details_screen.dart';
import '../core/extensions/image_chunk_event_extension.dart';

enum ItemDisplayStatus { available, borrowed }

class ItemStatusCard extends StatelessWidget {
  final Item item;
  final ItemDisplayStatus displayStatus;

  const ItemStatusCard({
    super.key,
    required this.item,
    required this.displayStatus,
  });

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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailsScreen(itemId: item.id)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
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
                  if (displayStatus == ItemDisplayStatus.available)
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (displayStatus == ItemDisplayStatus.borrowed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Com: ${borrower?.name ?? "Desconhecido"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Desde: ${lastMovement != null ? "${lastMovement.date.day}/${lastMovement.date.month}/${lastMovement.date.year}" : "Data desconhecida"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
