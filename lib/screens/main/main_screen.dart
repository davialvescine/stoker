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
    // Tela de Status
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

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);

    return Scaffold(
      body: isLargeScreen
          ? Row(
              children: [
                // Navegação lateral para telas grandes
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
            )
          : _screens[_currentIndex],
      bottomNavigationBar: isLargeScreen
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: _navigationItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
