import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ManageAdminsTab extends StatefulWidget {
  const ManageAdminsTab({super.key});

  @override
  State<ManageAdminsTab> createState() => _ManageAdminsTabState();
}

class _ManageAdminsTabState extends State<ManageAdminsTab> {
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Add Admin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(hintText: 'Username or email'),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                final name = _usernameCtrl.text.trim();
                if (name.isEmpty) return;
                final error = await context.read<AppState>().addAdmin(name);
                if (!context.mounted) return;
                if (error == null) {
                  _usernameCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added as admin.')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Current Admins (${app.admins.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ...app.admins.map((a) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceElevated,
                  child: Icon(Icons.shield, color: AppColors.gold, size: 18),
                ),
                title: Text(a.username),
                subtitle: Text(a.isPrimary ? 'Primary admin' : 'Admin', style: const TextStyle(fontSize: 12)),
                trailing: a.isPrimary
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.sell),
                        onPressed: () => context.read<AppState>().removeAdmin(a),
                      ),
              ),
            )),
      ],
    );
  }
}
