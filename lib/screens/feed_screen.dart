import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/signal_card.dart';
import 'signal_detail_screen.dart';
import 'wallet_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.insights, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            const Text('GOLD APEX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15)),
          ],
        ),
        actions: [
          _CoinPill(balance: app.coinsBalance, hasPlan: app.hasActivePlan),
          const SizedBox(width: 12),
        ],
      ),
      body: app.signals.isEmpty
          ? const Center(child: Text('No signals posted yet.', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.signals.length,
              itemBuilder: (context, i) {
                final signal = app.signals[i];
                return SignalCard(
                  signal: signal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignalDetailScreen(signal: signal)),
                  ),
                  onUnlockRequested: () => _handleUnlock(context, signal),
                );
              },
            ),
    );
  }

  void _handleUnlock(BuildContext context, TradingSignal signal) async {
    final app = context.read<AppState>();
    if (app.coinsBalance < TradingSignal.coinCost) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('Not enough coins'),
          content: const Text(
            'You need 50 coins to unlock this signal. Top up your wallet or grab a plan to unlock everything.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
              child: const Text('Top Up'),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await app.unlockSignal(signal);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signal unlocked — 50 coins deducted.')),
      );
    }
  }
}

class _CoinPill extends StatelessWidget {
  final int balance;
  final bool hasPlan;
  const _CoinPill({required this.balance, required this.hasPlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 16),
          const SizedBox(width: 6),
          Text('$balance', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          if (hasPlan) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified, color: AppColors.gold, size: 14),
          ],
        ],
      ),
    );
  }
}
