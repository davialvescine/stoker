import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stoker/providers/auth_provider.dart';
import 'package:stoker/providers/inventory_provider.dart';
import 'package:stoker/providers/borrower_provider.dart';
import 'package:stoker/providers/movement_provider.dart';
import 'package:stoker/providers/kit_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_wrapper.dart';

class StokerApp extends StatelessWidget {
  const StokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => BorrowerProvider()),
        ChangeNotifierProvider(create: (_) => MovementProvider()),
        ChangeNotifierProvider(create: (_) => KitProvider()),
      ],
      child: MaterialApp(
        title: 'Stoker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}
