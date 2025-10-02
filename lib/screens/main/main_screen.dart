import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive_helper.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/borrower_provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/kit_provider.dart';
import '../../navigation/navigation_item.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'kits_screen.dart';
import 'borrowers_screen.dart';
import 'profile_screen.dart';
import './report_screen.dart';
import './status_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const InventoryScreen(),
    const KitsScreen(),
    const StatusScreen(),
    const BorrowersScreen(),
    const ReportScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Inventário',
    ),
    NavigationItem(
      icon: Icons.inventory_outlined,
      activeIcon: Icons.inventory,
      label: 'Kits',
    ),
    NavigationItem(
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz,
      label: 'Status',
    ),
    NavigationItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Mutuários',
    ),
    NavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment,
      label: 'Relatório',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAllData());
  }

  Future<void> _fetchAllData() async {
    if (mounted) {
      await Future.wait([
        context.read<InventoryProvider>().fetch(),
        context.read<BorrowerProvider>().fetch(),
        context.read<MovementProvider>().fetch(),
      ]).then((_) {
        if (mounted) {
          final allItems = context.read<InventoryProvider>().items;
          context.read<KitProvider>().fetch(allItems);
        }
      });
    }
  }

  // NOVO: Widget para construir o Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          for (int i = 0; i < _navigationItems.length; i++)
            ListTile(
              leading: Icon(
                _currentIndex == i
                    ? _navigationItems[i].activeIcon
                    : _navigationItems[i].icon,
              ),
              title: Text(_navigationItems[i].label),
              selected: _currentIndex == i,
              onTap: () {
                setState(() => _currentIndex = i);
                Navigator.pop(context); // Fecha o drawer após a seleção
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);

    // Lógica para telas grandes permanece a mesma
    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: ResponsiveHelper.isDesktop(context),
              minExtendedWidth: 200,
              destinations: _navigationItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    // ALTERADO: Lógica para telas pequenas agora usa AppBar e Drawer
    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_currentIndex].label), // Mostra o título da tela atual
      ),
      drawer: _buildDrawer(), // Adiciona o menu lateral
      body: _screens[_currentIndex],
      // REMOVIDO: O BottomNavigationBar não é mais necessário
    );
  }
}