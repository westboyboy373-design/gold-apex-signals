import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'post_signal_tab.dart';
import 'verify_payments_tab.dart';
import 'manage_admins_tab.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Post Signal'),
              Tab(text: 'Payments'),
              Tab(text: 'Admins'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PostSignalTab(),
            VerifyPaymentsTab(),
            ManageAdminsTab(),
          ],
        ),
      ),
    );
  }
}
