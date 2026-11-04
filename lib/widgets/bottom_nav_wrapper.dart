import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../infrastructure/routes/admin_routes.dart';
import 'app_ui.dart';

class BottomNavWrapper extends StatelessWidget {
  final Widget child;

  const BottomNavWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        items: [
          AppNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => Get.offAllNamed(AdminRoutes.mainScreen),
          ),
          AppNavItem(
            icon: Icons.task_alt_rounded,
            label: 'Tasks',
            onTap: () => Get.offAllNamed(
              AdminRoutes.mainScreen,
              arguments: {'tab': 1},
            ),
          ),
          AppNavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Calendar',
            onTap: () => Get.offAllNamed(
              AdminRoutes.mainScreen,
              arguments: {'tab': 2},
            ),
          ),
          AppNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () => Get.offAllNamed(
              AdminRoutes.mainScreen,
              arguments: {'tab': 3},
            ),
          ),
        ],
      ),
    );
  }
}
