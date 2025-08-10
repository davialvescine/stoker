import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'widgets/common/error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://mqclxarauqgeimyfigow.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xY2x4YXJhdXFnZWlteWZpZ293Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzMDIzMDEsImV4cCI6MjA2ODg3ODMwMX0.mgDgZHPjgbNacNhb79t8A8TVdMB2Tp9_26SCvxU3grw',
      debug: false,
    );
    runApp(const StokerApp());
  } catch (e) {
    debugPrint('Erro na inicialização: $e');
    runApp(const ErrorApp());
  }
}
