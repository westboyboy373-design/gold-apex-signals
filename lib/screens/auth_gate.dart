import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'main_scaffold.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session = supabase.auth.currentSession;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() => _session = data.session);
      if (_session != null) _initAppState();
    });
    if (_session != null) _initAppState();
  }

  Future<void> _initAppState() async {
    if (_initializing) return;
    _initializing = true;
    await context.read<AppState>().initialize();
    _initializing = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const LoginScreen();

    final app = context.watch<AppState>();
    if (app.loading || app.currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    return const MainScaffold();
  }
}
