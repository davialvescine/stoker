import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/hover_card.dart';
import '../../widgets/common/responsive_wrapper.dart';
import '../../widgets/dialogs/responsive_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        //title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Nenhum usuário logado.',
                style: TextStyle(color: kTextSecondary),
              ),
            )
          : Center(
              child: ResponsiveWrapper(
                maxWidth: 600,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: kPrimaryColor,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        user.email ?? 'Usuário',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 32),
                    HoverCard(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Sobre o App'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showAboutDialog(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Sair da Conta',
                      icon: Icons.logout,
                      backgroundColor: kErrorColor,
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Sair da Conta',
        content: 'Tem certeza que deseja sair?',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: kErrorColor),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Sobre o ${AppStrings.appName}',
        content:
            '${AppStrings.appName} é um sistema de gestão de inventário.\n\nVersão: ${AppStrings.version}',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
