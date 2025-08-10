import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/item.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/responsive_wrapper.dart';

class QrLabelScreen extends StatelessWidget {
  final Item item;
  const QrLabelScreen({super.key, required this.item});

  Future<Uint8List> _generatePdfLabel(PdfPageFormat format) async {
    final pdf = pw.Document();

    final qrImage = pw.BarcodeWidget(
      barcode: pw.Barcode.qrCode(),
      data: 'stoker_item_${item.id}',
      width: 150,
      height: 150,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  item.name,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                qrImage,
                pw.SizedBox(height: 10),
                pw.Text(
                  'ID: ${item.id}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiqueta QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printLabel(context),
          ),
        ],
      ),
      body: Center(
        child: ResponsiveWrapper(
          maxWidth: 400,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: 'stoker_item_${item.id}',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${item.id}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Imprimir Etiqueta',
                  icon: Icons.print_outlined,
                  onPressed: () => _printLabel(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _printLabel(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => _generatePdfLabel(format),
      );
    } catch (e) {
      debugPrint('Erro ao imprimir: $e');
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Erro ao gerar PDF para impressão.',
          isError: true,
        );
      }
    }
  }
}
