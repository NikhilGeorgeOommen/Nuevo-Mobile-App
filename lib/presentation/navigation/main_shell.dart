import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/utils/responsive_utils.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Main Shell with Bottom Navigation
/// Wraps all main app screens with persistent bottom navigation bar
class MainShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;
  
  const MainShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF9F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool disableTabs = false;
    
    final dashboardState = ref.watch(homeDashboardProvider);
    dashboardState.whenData((dashboard) {
      if (dashboard.yourProgram == null) {
        disableTabs = true;
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: disableTabs
          ? IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.5,
                child: _buildBottomNavigationBar(context),
              ),
            )
          : _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentIndex = _getIndexFromPath(currentPath);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTapped(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF964A38), // Brown/Rust
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: ResponsiveUtils.fontSize(context, base: 12),
        unselectedFontSize: ResponsiveUtils.fontSize(context, base: 12),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        backgroundColor: Colors.white,
        items: [
          _buildNavItem(
            context,
            label: 'Home',
            assetPath: 'assets/images/nav_home.png',
            isSelected: currentIndex == 0,
          ),
          _buildNavItem(
            context,
            label: 'My Plan',
            assetPath: 'assets/images/nav_my_plan.png',
            isSelected: currentIndex == 1,
          ),
          _buildNavItem(
            context,
            label: 'Health',
            assetPath: 'assets/images/health_insight.png', // Reusing health insight icon
            isSelected: currentIndex == 2,
          ),
          _buildNavItem(
            context,
            label: 'Appointments',
            assetPath: 'assets/images/nav_appointments.png',
            isSelected: currentIndex == 3,
          ),
          _buildNavItem(
            context,
            label: 'Profile',
            assetPath: 'assets/images/nav_profile.png',
            isSelected: currentIndex == 4,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    BuildContext context, {
    required String label,
    required String assetPath,
    required bool isSelected,
  }) {
    // Responsive icon size
    final iconSize = ResponsiveUtils.iconSize(context, base: 24);
    
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          color: AppColors.textSecondary, // Grey when unselected
        ),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF964A38),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          color: Colors.white,
        ),
      ),
      label: label,
    );
  }

  int _getIndexFromPath(String path) {
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/my-plan')) return 1;
    if (path.startsWith('/health')) return 2;
    if (path.startsWith('/appointments')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {

    switch (index) {
      case 0:

        context.go('/home');
        break;
      case 1:
        /// ...
        context.go('/my-plan');
        break;
      case 2:
        context.go('/health');
        break;
      case 3:

        context.go('/appointments');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
