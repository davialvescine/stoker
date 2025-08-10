import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'responsive_wrapper.dart';

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ResponsiveWrapper(
            maxWidth: 400,
            child: Padding(
              padding: kDefaultPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: kErrorColor),
                  const SizedBox(height: 24),
                  const Text(
                    'Erro de Inicialização',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verifique sua conexão com a internet e tente novamente.',
                    style: TextStyle(fontSize: 16, color: kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Recarregar o app
                      runApp(
                        const MaterialApp(
                          home: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
