// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/rooms/presentation/screens/rooms_screen.dart';
import '../../features/payments/presentation/screens/keuangan_screen.dart';
import '../../features/payments/presentation/screens/payment_form_screen.dart';
import '../../features/reports/presentation/screens/laporan_screen.dart';
import '../../features/tenants/presentation/screens/tenant_form_screen.dart';
import '../../features/tenants/presentation/screens/tenant_detail_screen.dart';
import '../../features/tenants/presentation/screens/move_tenant_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/dashboard',
    ),
    // Payment routes
    GoRoute(
      path: '/payments/add',
      builder: (context, state) => const PaymentFormScreen(),
    ),
    GoRoute(
      path: '/payments/add/:tenantId',
      builder: (context, state) => PaymentFormScreen(tenantId: int.parse(state.pathParameters['tenantId']!)),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/rooms',
              builder: (context, state) => const RoomsScreen(),
            ),
            // Tenant routes
            GoRoute(
              path: '/rooms/tenants/add',
              builder: (context, state) => const TenantFormScreen(),
            ),
            GoRoute(
              path: '/rooms/tenants/:id',
              builder: (context, state) => TenantDetailScreen(tenantId: int.parse(state.pathParameters['id']!)),
            ),
            GoRoute(
              path: '/rooms/tenants/:id/edit',
              builder: (context, state) => TenantFormScreen(tenantId: int.parse(state.pathParameters['id']!)),
            ),
            GoRoute(
              path: '/rooms/tenants/:id/move',
              builder: (context, state) => MoveTenantScreen(tenantId: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/keuangan',
              builder: (context, state) => const KeuanganScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/laporan',
              builder: (context, state) => const LaporanScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Kamar & Penghuni',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Keuangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
