import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/constants/strings.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/responsive_wrapper.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveWrapper(
              maxWidth: 400,
              child: Padding(
                padding: kDefaultPadding,
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.appTagline,
                      style: TextStyle(fontSize: 16, color: kTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    CustomButton(
                      text: 'Entrar',
                      icon: Icons.login,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Criar Conta',
                      icon: Icons.person_add,
                      isSecondary: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
