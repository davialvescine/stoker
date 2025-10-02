import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../models/item.dart';
import '../common/custom_snackbar.dart';

class BatchPrintDialog extends StatefulWidget {
  final List<Item> items;

  const BatchPrintDialog({super.key, required this.items});

  @override
  State<BatchPrintDialog> createState() => _BatchPrintDialogState();
}

class _BatchPrintDialogState extends State<BatchPrintDialog> {
  final Set<String> _selectedItemIds = {};
  int _labelsPerRow = 2;
  int _labelsPerPage = 8;
  bool _isLoading = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Se há itens pré-selecionados (vindo da tela de inventário)
    _selectedItemIds.addAll(widget.items.map((item) => item.id));
    _selectAll = _selectedItemIds.length == widget.items.length;
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedItemIds.addAll(widget.items.map((item) => item.id));
      } else {
        _selectedItemIds.clear();
      }
    });
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
      _selectAll = _selectedItemIds.length == widget.items.length;
    });
  }

  Future<Uint8List> _generateBatchPdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final selectedItems = widget.items
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();

    // Calcular quantas páginas serão necessárias
    final totalLabels = selectedItems.length;
    final totalPages = (totalLabels / _labelsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * _labelsPerPage;
      final endIndex = (startIndex + _labelsPerPage).clamp(0, totalLabels);
      final pageItems = selectedItems.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: pageItems
                    .map((item) => _buildLabelWidget(item))
                    .toList(),
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildLabelWidget(Item item) {
    final labelWidth = (PdfPageFormat.a4.width - 60) / _labelsPerRow - 10;
    final labelHeight = labelWidth * 0.8;

    return pw.Container(
      width: labelWidth,
      height: labelHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            item.name,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            maxLines: 2,
          ),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: 'stoker_item_${item.id}',
              width: labelWidth * 0.6,
              height: labelWidth * 0.6,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'ID: ${item.id.substring(0, 8)}...',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6),
          ),
        ],
      ),
    );
  }

  Future<void> _printLabels() async {
    if (_selectedItemIds.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Selecione pelo menos um item para imprimir',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => _generateBatchPdf(format),
        name: 'Etiquetas_Lote_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '${_selectedItemIds.length} etiquetas geradas com sucesso!',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Erro ao gerar PDF em lote: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Erro ao gerar PDF para impressão.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = widget.items
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();

    return AlertDialog(
      insetPadding: ResponsiveHelper.isLargeScreen(context)
          ? const EdgeInsets.symmetric(horizontal: 100, vertical: 50)
          : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      title: const Text(
        'Impressão de Etiquetas em Lote',
        textAlign: TextAlign.center,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configurações de layout
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configurações de Layout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Etiquetas por linha:'),
                                DropdownButtonFormField<int>(
                                  value: _labelsPerRow,
                                  items: [1, 2, 3, 4]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text('$value'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _labelsPerRow = value!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Etiquetas por página:'),
                                DropdownButtonFormField<int>(
                                  value: _labelsPerPage,
                                  items: [4, 6, 8, 10, 12, 16]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text('$value'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _labelsPerPage = value!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Seleção de itens
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Itens Selecionados (${_selectedItemIds.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _toggleSelectAll,
                          child: Text(
                            _selectAll ? 'Desmarcar Todos' : 'Selecionar Todos',
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Itens Selecionados (${_selectedItemIds.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _toggleSelectAll,
                          child: Text(
                            _selectAll ? 'Desmarcar Todos' : 'Selecionar Todos',
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 8),

              // Lista de itens
              Expanded(
                child: Card(
                  child: widget.items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Nenhum item disponível.',
                              style: TextStyle(color: kTextSecondary),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            final isSelected = _selectedItemIds.contains(
                              item.id,
                            );
                            return CheckboxListTile(
                              title: Text(item.name),
                              subtitle: Text('${item.category} • ${item.type}'),
                              value: isSelected,
                              onChanged: (value) => _toggleItem(item.id),
                              dense: true,
                            );
                          },
                        ),
                ),
              ),

              // Preview info
              if (selectedItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: kPrimaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Serão geradas ${selectedItems.length} etiquetas em ${(selectedItems.length / _labelsPerPage).ceil()} página(s)',
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8.0, // Add some spacing between the buttons
          runSpacing: 4.0, // Add some spacing when the buttons wrap
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _printLabels,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Imprimir Etiquetas'),
            ),
          ],
        ),
      ],
    );
  }
}
