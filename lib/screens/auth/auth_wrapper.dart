import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../main/main_screen.dart';
import 'welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            );
          case AuthStatus.authenticated:
            return const MainScreen();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const WelcomeScreen();
        }
      },
    );
  }
}
