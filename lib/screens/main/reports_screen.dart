import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/borrower_provider.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedBorrowerId;
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    
    final borrowerProvider = context.watch<BorrowerProvider>();
    final borrowers = borrowerProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                    items: borrowers
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
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  child: const Text('Selecionar Período'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Placeholder
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('Placeholder'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
