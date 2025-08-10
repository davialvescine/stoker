import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart'; // Adicionar este import
import '../../providers/inventory_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/responsive_wrapper.dart';
import '../item/item_details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  final _codeController = TextEditingController();

  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || !mounted) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    _processCode(code);
  }

  void _processCode(String code) {
    final navigator = Navigator.of(context);

    if (code.startsWith('stoker_item_')) {
      final itemId = code.replaceFirst('stoker_item_', '');
      final item = context.read<InventoryProvider>().getItemById(itemId);

      navigator.pop();

      if (item != null && mounted) {
        navigator.push(
          MaterialPageRoute(builder: (_) => ItemDetailsScreen(itemId: item.id)),
        );
      } else {
        CustomSnackBar.show(
          context,
          message: 'Item não encontrado',
          isError: true,
        );
      }
    } else {
      navigator.pop();
      CustomSnackBar.show(context, message: 'QR Code inválido', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Versão web com input manual
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escanear QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: ResponsiveWrapper(
            maxWidth: 400,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Scanner de QR Code não disponível na versão web',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Digite o código do item manualmente:',
                    style: TextStyle(color: kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Código do Item',
                      hintText: 'stoker_item_xxxxx',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Buscar Item',
                    icon: Icons.search,
                    onPressed: () {
                      if (_codeController.text.isNotEmpty) {
                        _processCode(_codeController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Versão mobile com câmera
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onQRCodeDetected,
          ),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: kPrimaryColor, width: 3),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
          ),
        ],
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
