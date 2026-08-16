import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/supabase_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surfaceElevated,
                child: Icon(Icons.person, color: AppColors.gold, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.currentUsername, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(app.isAdmin ? 'Administrator' : 'Member', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          _tile(Icons.monetization_on_outlined, 'Coin balance', '${app.coinsBalance} coins'),
          _tile(Icons.verified_outlined, 'Active plan', app.hasActivePlan ? app.activePlan.label : 'None'),
          _tile(Icons.notifications_outlined, 'Notifications', 'On'),
          _tile(Icons.dark_mode_outlined, 'Theme', 'Dark (default)'),
          if (app.isAdmin) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings, size: 18),
                label: const Text('Open Admin Panel'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out'),
              onPressed: () => supabase.auth.signOut(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
