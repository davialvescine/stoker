import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/colors.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../providers/movement_provider.dart';
import '../../models/item.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/responsive_wrapper.dart';

enum MovementType { checkout, checkin }

class QuickMovementScanner extends StatefulWidget {
  final MovementType movementType;

  const QuickMovementScanner({super.key, required this.movementType});

  @override
  State<QuickMovementScanner> createState() => _QuickMovementScannerState();
}

class _QuickMovementScannerState extends State<QuickMovementScanner> {
  final MobileScannerController cameraController = MobileScannerController();
  final _codeController = TextEditingController();
  bool _isProcessing = false;

  String? _selectedBorrowerId;
  final List<Item> _scannedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.movementType == MovementType.checkout) {
      // Para check-out, precisamos selecionar mutuário primeiro
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectBorrower();
      });
    }
  }

  Future<void> _selectBorrower() async {
    final borrowerProvider = context.read<BorrowerProvider>();
    if (borrowerProvider.items.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Nenhum mutuário cadastrado',
        isError: true,
      );
      Navigator.of(context).pop();
      return;
    }

    final borrowerId = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Mutuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quem está pegando os equipamentos?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Mutuário',
                border: OutlineInputBorder(),
              ),
              items: borrowerProvider.items
                  .map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name),
                      ))
                  .toList(),
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (borrowerId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _selectedBorrowerId = borrowerId);
  }

  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || !mounted) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    await _processCode(code);
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processCode(String code) async {
    if (code.startsWith('stoker_item_')) {
      final itemId = code.replaceFirst('stoker_item_', '');
      final inventoryProvider = context.read<InventoryProvider>();
      final item = inventoryProvider.getItemById(itemId);

      if (item == null) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Item não encontrado',
            isError: true,
          );
        }
        return;
      }

      // Validar status do item
      if (widget.movementType == MovementType.checkout) {
        if (item.status != 'Disponível') {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: '${item.name} já está emprestado',
              isError: true,
            );
          }
          return;
        }
      } else {
        // Check-in
        if (item.status != 'Emprestado') {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: '${item.name} não está emprestado',
              isError: true,
            );
          }
          return;
        }
      }

      // Adicionar à lista se ainda não foi escaneado
      if (!_scannedItems.any((i) => i.id == item.id)) {
        setState(() => _scannedItems.add(item));
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: '${item.name} adicionado',
          );
        }
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'QR Code inválido',
          isError: true,
        );
      }
    }
  }

  Future<void> _processManualCode() async {
    if (_codeController.text.isEmpty) return;
    await _processCode(_codeController.text);
    _codeController.clear();
  }

  Future<void> _confirmMovement() async {
    if (_scannedItems.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Escaneie pelo menos um item',
        isError: true,
      );
      return;
    }

    if (widget.movementType == MovementType.checkout &&
        _selectedBorrowerId == null) {
      CustomSnackBar.show(
        context,
        message: 'Selecione um mutuário',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.movementType == MovementType.checkout
              ? 'Confirmar Empréstimo'
              : 'Confirmar Devolução',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_scannedItems.length} ${_scannedItems.length == 1 ? 'item' : 'itens'}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._scannedItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    final movementProvider = context.read<MovementProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final borrowerProvider = context.read<BorrowerProvider>();

    try {
      final itemIds = _scannedItems.map((item) => item.id).toList();

      final success = await movementProvider.addMovementsForItems(
        itemIds: itemIds,
        borrowerId: widget.movementType == MovementType.checkout
            ? _selectedBorrowerId!
            : (await movementProvider.getLastMovement(itemIds.first))?.borrowerId ?? '',
        movementType: widget.movementType == MovementType.checkout
            ? 'Empréstimo'
            : 'Devolução',
        newStatus: widget.movementType == MovementType.checkout
            ? 'Emprestado'
            : 'Disponível',
        inventoryProvider: inventoryProvider,
      );

      if (!mounted) return;

      if (success) {
        await Future.wait([
          inventoryProvider.fetch(),
          movementProvider.fetch(),
        ]);

        if (!mounted) return;

        final borrower = borrowerProvider.getBorrowerById(_selectedBorrowerId ?? '');
        final borrowerName = borrower?.name ?? 'Desconhecido';

        CustomSnackBar.show(
          context,
          message: widget.movementType == MovementType.checkout
              ? 'Empréstimo para $borrowerName realizado!'
              : 'Devolução realizada!',
        );

        Navigator.of(context).pop();
      } else {
        CustomSnackBar.show(
          context,
          message: 'Falha na operação',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Erro: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCheckout = widget.movementType == MovementType.checkout;
    final title = isCheckout ? 'Check-Out (Empréstimo)' : 'Check-In (Devolução)';
    final color = isCheckout ? Colors.orange : Colors.green;

    if (kIsWeb) {
      return _buildWebVersion(title, color);
    }

    return _buildMobileVersion(title, color);
  }

  Widget _buildWebVersion(String title, Color color) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ResponsiveWrapper(
          maxWidth: 600,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 80, color: kPrimaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Scanner não disponível na web',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Digite o código do item:',
                  style: TextStyle(color: kTextSecondary),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código do Item',
                    hintText: 'stoker_item_xxxxx',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  onSubmitted: (_) => _processManualCode(),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Adicionar Item',
                  icon: Icons.add,
                  onPressed: _processManualCode,
                ),
                const SizedBox(height: 32),
                _buildScannedItemsList(),
                const Spacer(),
                if (_scannedItems.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text('Confirmar ${_scannedItems.length} ${_scannedItems.length == 1 ? 'item' : 'itens'}'),
                    onPressed: _isProcessing ? null : _confirmMovement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileVersion(String title, Color color) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          if (_scannedItems.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_scannedItems.length}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () => _showScannedItems(),
            ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onQRCodeDetected,
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
            ),
            child: CustomPaint(
              painter: ScannerOverlayPainter(color: color),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
              ),
              child: Column(
                children: [
                  Text(
                    'Escaneie o QR Code do item',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_scannedItems.length} ${_scannedItems.length == 1 ? 'item adicionado' : 'itens adicionados'}',
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (_scannedItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _confirmMovement,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text('Confirmar ${_scannedItems.length}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _scannedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showScannedItems(),
              icon: const Icon(Icons.list),
              label: Text('Ver ${_scannedItems.length}'),
              backgroundColor: color,
            )
          : null,
    );
  }

  Widget _buildScannedItemsList() {
    if (_scannedItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Nenhum item escaneado',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Itens Escaneados (${_scannedItems.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_scannedItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _scannedItems.clear());
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Limpar'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _scannedItems.length,
                itemBuilder: (context, index) {
                  final item = _scannedItems[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(item.name),
                    subtitle: Text(item.category),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _scannedItems.removeAt(index));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScannedItems() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Itens Escaneados (${_scannedItems.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _scannedItems.length,
                itemBuilder: (context, index) {
                  final item = _scannedItems[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(item.name),
                    subtitle: Text(item.category),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() => _scannedItems.removeAt(index));
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    cameraController.dispose();
    super.dispose();
  }
}

// Custom painter para desenhar overlay do scanner
class ScannerOverlayPainter extends CustomPainter {
  final Color color;

  ScannerOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final rectSize = 250.0;
    final halfSize = rectSize / 2;
    final cornerLength = 40.0;

    // Desenhar cantos
    // Top-left
    canvas.drawLine(
      Offset(centerX - halfSize, centerY - halfSize),
      Offset(centerX - halfSize + cornerLength, centerY - halfSize),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - halfSize, centerY - halfSize),
      Offset(centerX - halfSize, centerY - halfSize + cornerLength),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(centerX + halfSize, centerY - halfSize),
      Offset(centerX + halfSize - cornerLength, centerY - halfSize),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + halfSize, centerY - halfSize),
      Offset(centerX + halfSize, centerY - halfSize + cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(centerX - halfSize, centerY + halfSize),
      Offset(centerX - halfSize + cornerLength, centerY + halfSize),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - halfSize, centerY + halfSize),
      Offset(centerX - halfSize, centerY + halfSize - cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(centerX + halfSize, centerY + halfSize),
      Offset(centerX + halfSize - cornerLength, centerY + halfSize),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + halfSize, centerY + halfSize),
      Offset(centerX + halfSize, centerY + halfSize - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
