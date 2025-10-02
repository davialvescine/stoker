
import 'package:flutter/material.dart';
import './movement_report_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       // title: const Text('Relatórios'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Relatório de Movimentações'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MovementReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
